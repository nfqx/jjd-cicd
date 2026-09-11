public with sharing class ReturnOrderController {
    @AuraEnabled(cacheable=false)
    public static PrefillWrapper retrievePrefill(Id caseId){
        return null;
    }

    @AuraEnabled(cacheable=false)
    public static Order lookupSearchOrder(String searchText){
        return null;
    }

    @AuraEnabled(cacheable=false)
    public static Invoice lookupSearchInvoice(String searchText){
        return null;
    }

    @AuraEnabled(cacheable=false)
    public static SearchWrapper searchProducts(Id caseId){
        return null;
    }

    @AuraEnabled(cacheable=false)
    public static String createCase(
        Case caseRec,
        Account account,
        String returnOrderType,
        String creditIssuance,
        String returnReason,
        String referenceType,
        String noDocumentReason,
        String shippingCondition,
        Date requestedPickupDate,
        String addressStreet,
        String addressCity,
        String addressPostalCode,
        String addressCountry,
        List<ProductWrapper> productWrappers
    ){
        return null;
    }

    public class PrefillWrapper{
        @AuraEnabled public Case caseRec;
        @AuraEnabled public Account acc; 
    }
    public class SearchWrapper{
        @AuraEnabled public List<ProductWrapper> products;
        @AuraEnabled public Integer resultCount; 
    }
    public class ProductWrapper{
        @AuraEnabled public Id productId;
        @AuraEnabled public Integer quantity;
        @AuraEnabled public String quantityUnitOfMeasure; 
        @AuraEnabled public String returnReason; 
        @AuraEnabled public String creditIssuance; 
        @AuraEnabled public String batch; 
        @AuraEnabled public Date bestBeforeDate; 
        @AuraEnabled public String description; 
    }
}