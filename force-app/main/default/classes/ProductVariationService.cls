/**
 *  SAP -> Salesforce product variation sync logic.
 *
 * One SAP A_Product becomes a Variation Parent Product2; each unit of measure
 * (to_ProductUnitsOfMeasure row) becomes a Variation Product child Product2 linked
 * via ProductAttribute.
 *
 * Two-phase per batch:
 *   Phase 1 - Structure: missing parent  -> ConnectApi.CommerceCatalogManagement
 *             .compositeCommerceProductCreate (Type "Base" + attributeSetInfo);
 *             missing child -> .compositeCommerceVariationCreate (auto-creates the
 *             ProductAttribute linkage with variationAttributes {Unit__c}).
 *   Phase 2 - Data: ALL fields (parents + children, created + existing) are written
 *             via one bulk Product2 DML pass. Commerce calls only ever set the
 *             minimal structural fields; everything else goes through DML.
 */
public with sharing class ProductVariationService {
    
    public class ProductVariationException extends Exception {}
    
    // ---- Product2 field sets (API names), drive both coercion and which column type ----
    private static final Set<String> PRODUCT_STRING_FIELDS = new Set<String>{
        'Name', 'ProductCode', 'StockKeepingUnit', 'ERPProductNumber__c', 'MaterialType__c',
        'IndustrySector__c', 'QuantityUnitOfMeasure', 'BaseUnitCode__c', 'GTIN__c', 'EAN__c', 'Description__c',
        'BaseProductCode__c', 'OldProductNumber__c'
    };
    private static final Set<String> PRODUCT_DECIMAL_FIELDS = new Set<String>{
        'NetWeight__c', 'GrossWeight__c', 'Factor__c'
    };
    private static final Set<String> PRODUCT_DATE_FIELDS = new Set<String>{
        'ActivationDate__c'
    };
    private static final Set<String> PRODUCT_DATETIME_FIELDS = new Set<String>{
        'ERPLastChanged__c'
    };
    // Checkbox fields. JJD-34 release flags arrive as true/false on every record so a
    // removed SAP channel resets the flag to false (never left stale).
    private static final Set<String> PRODUCT_BOOLEAN_FIELDS = new Set<String>{
        'IsActive', 'BioProduct__c', 'BioFairTradeProduct__c',
        'ReleasedForRetail__c', 'ReleasedForAHS__c', 'ReleasedForExport__c'
    };
    
    // Minimal fields sent to the Commerce create calls (structure only). The confirmed
    // org-tested bodies set more, but data is applied via DML in phase 2 instead.
    private static final Set<String> STRUCTURE_STRING_FIELDS = new Set<String>{
        'Name', 'ProductCode', 'StockKeepingUnit'
    };
    
    private static final String FIELD_SKU = 'StockKeepingUnit';
    private static final String FIELD_ERP_NUMBER = 'ERPProductNumber__c';
    private static final String FIELD_IS_ACTIVE = 'IsActive';
    private static final String FIELD_TYPE = 'Type';
    private static final String FIELD_ERP_LAST_SYNC = 'ERPLastSync__c';
    private static final String VARIATION_ATTR_UNIT = 'Unit__c';
    private static final String PARENT_TYPE_BASE = 'Base';
    
    private static final String OP_CREATED = 'created';
    private static final String OP_UPDATED = 'updated';
    private static final String OP_FAILED = 'failed';
    
    private static final String KEY_PARENT = 'parent';
    private static final String KEY_VARIATIONS = 'variations';
    
    /**
     * Process one batch of pre-grouped products. Each element of products is
     * { "parent": {...}, "variations": [ {...}, ... ] }.
     */
    public static List<ProductResult> processBatch(String webStoreId, String attributeSetId, List<Object> products) {
        List<ProductGroup> groups = parseGroups(products);
        Set<String> allSkus = collectAllSkus(groups);
        Map<String, Id> idBySku = loadExistingBySku(allSkus);
        
        List<ProductResult> results = new List<ProductResult>();
        
        // Phase 1 - establish structure via Commerce; classify create vs update.
        for (ProductGroup grp : groups) {
            results.add(processStructure(grp, idBySku, webStoreId, attributeSetId));
        }
        
        // Phase 2 - write all data fields via one bulk Product2 DML pass.
        applyData(groups, results, allSkus);
        
        return results;
    }
    
    private static ProductResult processStructure(
        ProductGroup grp,
    Map<String, Id> idBySku,
    String webStoreId,
    String attributeSetId
    ) {
        ProductResult result = new ProductResult();
        result.erpProductNumber = strField(grp.parent, FIELD_ERP_NUMBER);
        result.parentSku = strField(grp.parent, FIELD_SKU);
        
        try {
            if (String.isBlank(result.parentSku)) {
                throw new ProductVariationException('Parent is missing ' + FIELD_SKU);
            }
            
            Id parentId;
            if (idBySku.containsKey(result.parentSku)) {
                parentId = idBySku.get(result.parentSku);
                result.parentOperation = OP_UPDATED;
            } else {
                parentId = createParent(grp.parent, webStoreId, attributeSetId);
                result.parentOperation = OP_CREATED;
            }
            result.parentId = parentId;
            
            List<Map<String, Object>> newVariations = new List<Map<String, Object>>();
            for (Map<String, Object> variation : grp.variations) {
                String sku = strField(variation, FIELD_SKU);
                if (String.isNotBlank(sku) && idBySku.containsKey(sku)) {
                    result.variationsUpdated++;
                } else {
                    newVariations.add(variation);
                    result.variationsCreated++;
                }
            }
            
            if (!newVariations.isEmpty()) {
                createVariations(parentId, newVariations, webStoreId);
            }
            
            result.success = true;
        } catch (Exception errorException) {
            result.success = false;
            result.parentOperation = OP_FAILED;
            result.message = errorException.getMessage();
        }
        
        return result;
    }
    
    private static void applyData(List<ProductGroup> groups, List<ProductResult> results, Set<String> allSkus) {
        // Re-read SKUs so newly created parents/children resolve to Ids.
        Map<String, Id> idBySku = loadExistingBySku(allSkus);
        
        List<Product2> toUpdate = new List<Product2>();
        List<Integer> ownerResultIndex = new List<Integer>();
        
        for (Integer i = 0; i < groups.size(); i++) {
            if (results[i].success != true) {
                continue;
            }
            ProductGroup grp = groups[i];
            
            Id parentId = idBySku.get(strField(grp.parent, FIELD_SKU));
            if (parentId != null) {
                toUpdate.add(buildProduct2(parentId, grp.parent));
                ownerResultIndex.add(i);
            }
            for (Map<String, Object> variation : grp.variations) {
                Id variationId = idBySku.get(strField(variation, FIELD_SKU));
                if (variationId != null) {
                    toUpdate.add(buildProduct2(variationId, variation));
                    ownerResultIndex.add(i);
                }
            }
        }
        
        if (toUpdate.isEmpty()) {
            return;
        }
        
        // allOrNone=false: one bad row (e.g. an out-of-set picklist value, OQ-P1)
        // doesn't sink the batch; the failure is reported on its ProductResult.
        List<Database.SaveResult> saveResults = Database.update(toUpdate, false);
        for (Integer j = 0; j < saveResults.size(); j++) {
            if (!saveResults[j].isSuccess()) {
                Integer idx = ownerResultIndex[j];
                results[idx].success = false;
                String detail = saveResults[j].getErrors().isEmpty()
                    ? 'Data update failed'
                    : saveResults[j].getErrors()[0].getMessage();
                results[idx].message = appendMessage(results[idx].message, 'Data update failed: ' + detail);
            }
        }
    }
    
    // ---- Commerce (ConnectApi) — structure only ----
    
    private static Id createParent(Map<String, Object> parent, String webStoreId, String attributeSetId) {
        ConnectApi.CompositeCommerceProductInputRepresentation input =
            new ConnectApi.CompositeCommerceProductInputRepresentation();
        
        Map<String, String> fields = buildStringMap(parent, STRUCTURE_STRING_FIELDS);
        fields.put(FIELD_TYPE, PARENT_TYPE_BASE);
        fields.put(FIELD_IS_ACTIVE, 'true');
        input.productFields = fields;
        
        if (String.isNotBlank(attributeSetId)) {
            ConnectApi.AttributeSetInputRepresentation attributeSet =
                new ConnectApi.AttributeSetInputRepresentation();
            attributeSet.id = attributeSetId;
            input.attributeSetInfo = attributeSet;
        }
        
        ConnectApi.CompositeCommerceProductOutputRepresentation output;
        try {
            output = ConnectApi.CommerceCatalogManagement.compositeCommerceProductCreate(webStoreId, input);
        } catch (Exception createException) {
            // A catchable ConnectApi error surfaces its real reason here.
            throw new ProductVariationException('Parent create failed: ' + createException.getMessage());
        }

        if (output == null || output.success != true || String.isBlank(output.productId)) {
            throw new ProductVariationException('Parent create failed: ' + describeSafe(output));
        }
        return (Id) output.productId;
    }
    
    private static void createVariations(Id parentId, List<Map<String, Object>> newVariations, String webStoreId) {
        ConnectApi.CompositeCommerceVariationInputRepresentation input =
            new ConnectApi.CompositeCommerceVariationInputRepresentation();
        input.parentProductId = parentId;
        
        List<ConnectApi.ProductVariationInputRepresentation> variations =
            new List<ConnectApi.ProductVariationInputRepresentation>();
        
        for (Map<String, Object> variation : newVariations) {
            ConnectApi.ProductVariationInputRepresentation rep =
                new ConnectApi.ProductVariationInputRepresentation();
            
            Map<String, String> fields = buildStringMap(variation, STRUCTURE_STRING_FIELDS);
            fields.put(FIELD_IS_ACTIVE, 'true');
            rep.productFields = fields;
            
            Map<String, String> attributes = new Map<String, String>();
            String unit = strField(variation, VARIATION_ATTR_UNIT);
            if (String.isNotBlank(unit)) {
                attributes.put(VARIATION_ATTR_UNIT, unit);
            }
            rep.variationAttributes = attributes;
            
            variations.add(rep);
        }
        input.variations = variations;
        
        ConnectApi.CompositeCommerceVariationOutputRepresentation output;
        try{
            output = ConnectApi.CommerceCatalogManagement.compositeCommerceVariationCreate(webStoreId, input);
        } catch(Exception e){
             throw new ProductVariationException('Variation create failed: ' + e.getMessage());
        }
        
        if (output == null || output.success != true) {
            throw new ProductVariationException('Variation create failed: ' + describeSafe(output));
        }
    }
    
    // ---- Data DML builder ----
    
    private static Product2 buildProduct2(Id recordId, Map<String, Object> record) {
        Product2 product = new Product2(Id = recordId);
        
        for (String fieldName : PRODUCT_STRING_FIELDS) {
            Object value = record.get(fieldName);
            if (value != null && String.isNotBlank(String.valueOf(value))) {
                product.put(fieldName, String.valueOf(value));
            }
        }
        for (String fieldName : PRODUCT_DECIMAL_FIELDS) {
            Decimal value = parseDecimal(record.get(fieldName));
            if (value != null) {
                product.put(fieldName, value);
            }
        }
        for (String fieldName : PRODUCT_DATE_FIELDS) {
            Date value = parseDate(record.get(fieldName));
            if (value != null) {
                product.put(fieldName, value);
            }
        }
        for (String fieldName : PRODUCT_DATETIME_FIELDS) {
            Datetime value = parseDateTime(record.get(fieldName));
            if (value != null) {
                product.put(fieldName, value);
            }
        }
        for (String fieldName : PRODUCT_BOOLEAN_FIELDS) {
            Boolean value = parseBoolean(record.get(fieldName));
            if (value != null) {
                product.put(fieldName, value);
            }
        }
        
        product.put(FIELD_ERP_LAST_SYNC, Datetime.now());
        return product;
    }
    
    // ---- Parsing / grouping ----
    
    private static List<ProductGroup> parseGroups(List<Object> products) {
        List<ProductGroup> groups = new List<ProductGroup>();
        for (Object item : products) {
            Map<String, Object> productMap = (Map<String, Object>) item;
            ProductGroup grp = new ProductGroup();
            grp.parent = (Map<String, Object>) productMap.get(KEY_PARENT);
            if (grp.parent == null) {
                throw new ProductVariationException('Each product requires a "parent" object');
            }
            grp.variations = new List<Map<String, Object>>();
            Object variationsRaw = productMap.get(KEY_VARIATIONS);
            if (variationsRaw instanceof List<Object>) {
                for (Object variationItem : (List<Object>) variationsRaw) {
                    grp.variations.add((Map<String, Object>) variationItem);
                }
            }
            groups.add(grp);
        }
        return groups;
    }
    
    private static Set<String> collectAllSkus(List<ProductGroup> groups) {
        Set<String> skus = new Set<String>();
        for (ProductGroup grp : groups) {
            String parentSku = strField(grp.parent, FIELD_SKU);
            if (String.isNotBlank(parentSku)) {
                skus.add(parentSku);
            }
            for (Map<String, Object> variation : grp.variations) {
                String sku = strField(variation, FIELD_SKU);
                if (String.isNotBlank(sku)) {
                    skus.add(sku);
                }
            }
        }
        return skus;
    }
    
    private static Map<String, Id> loadExistingBySku(Set<String> skus) {
        Map<String, Id> idBySku = new Map<String, Id>();
        if (skus.isEmpty()) {
            return idBySku;
        }
        for (Product2 product : [SELECT Id, StockKeepingUnit FROM Product2 WHERE StockKeepingUnit IN :skus]) {
            if (product.StockKeepingUnit != null) {
                idBySku.put(product.StockKeepingUnit, product.Id);
            }
        }
        return idBySku;
    }
    
    // ---- Coercion helpers ----
    
    private static Map<String, String> buildStringMap(Map<String, Object> record, Set<String> fieldNames) {
        Map<String, String> result = new Map<String, String>();
        for (String fieldName : fieldNames) {
            Object value = (record == null) ? null : record.get(fieldName);
            if (value != null && String.isNotBlank(String.valueOf(value))) {
                result.put(fieldName, String.valueOf(value));
            }
        }
        return result;
    }
    
    private static String strField(Map<String, Object> record, String key) {
        Object value = (record == null) ? null : record.get(key);
        return value == null ? null : String.valueOf(value);
    }
    
    private static Decimal parseDecimal(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Decimal) {
            return (Decimal) value;
        }
        if (value instanceof Integer) {
            return Decimal.valueOf((Integer) value);
        }
        String stringValue = String.valueOf(value);
        if (String.isBlank(stringValue)) {
            return null;
        }
        try {
            return Decimal.valueOf(stringValue.trim().replace(',', '.'));
        } catch (Exception parseException) {
            return null;
        }
    }
    
    private static Date parseDate(Object value) {
        if (value == null) {
            return null;
        }
        String stringValue = String.valueOf(value).trim();
        if (String.isBlank(stringValue)) {
            return null;
        }
        try {
            // Accept yyyy-MM-dd or the date portion of an ISO datetime.
            return Date.valueOf(stringValue.length() >= 10 ? stringValue.substring(0, 10) : stringValue);
        } catch (Exception parseException) {
            return null;
        }
    }
    
    private static Datetime parseDateTime(Object value) {
        if (value == null) {
            return null;
        }
        String stringValue = String.valueOf(value).trim();
        if (String.isBlank(stringValue)) {
            return null;
        }
        // ISO 8601 (e.g. 2026-06-29T12:00:00.000Z) deserializes cleanly to Datetime.
        try {
            return (Datetime) JSON.deserialize('"' + stringValue + '"', Datetime.class);
        } catch (Exception isoException) {
            try {
                return Datetime.valueOf(stringValue.replace('T', ' ').replace('Z', ''));
            } catch (Exception fallbackException) {
                return null;
            }
        }
    }
    
    private static Boolean parseBoolean(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        String stringValue = String.valueOf(value).trim().toLowerCase();
        if (stringValue == 'true' || stringValue == '1' || stringValue == 'x' || stringValue == 'yes') {
            return true;
        }
        if (stringValue == 'false' || stringValue == '0' || stringValue == '' || stringValue == 'no') {
            return false;
        }
        return null;
    }
    
    private static String describeSafe(Object value) {
        if (value == null) {
            return 'null';
        }
        try {
            // Do NOT JSON.serialize a ConnectApi output rep here. Serializing a
            // FAILED CompositeCommerce*OutputRepresentation (one carrying
            // variationErrorDetails) triggers an uncatchable Salesforce platform
            // error ("Gack") that escapes this try/catch and 500s the whole batch.
            // String.valueOf uses the rep's toString, which is safe.
            return String.valueOf(value);
        } catch (Exception describeException) {
            return 'unavailable';
        }
    }
    
    private static String appendMessage(String existing, String addition) {
        return String.isBlank(existing) ? addition : existing + '; ' + addition;
    }
    
    // ---- DTOs ----
    
    private class ProductGroup {
        Map<String, Object> parent;
        List<Map<String, Object>> variations;
    }
    
    public class ProductResult {
        public String erpProductNumber;
        public String parentSku;
        public String parentId;
        public String parentOperation;   // created | updated | failed
        public Integer variationsCreated = 0;
        public Integer variationsUpdated = 0;
        public Boolean success;
        public String message;
    }
}