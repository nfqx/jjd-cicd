/* 
* @date 2019-03-14
* @version 1.0.0
*
* @group Utility
*
* @description Metadata utility class
*/
public with sharing class MetadataUtil {

    /**
     * get FieldSet for given sObject
     *
     * @param  sObject      sObject API Name
     * @param  fieldSetName Field Set API Name
     * @return              List<String> of field API names defined in FieldSet
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldSetFields(String objectName, String fieldSetName) {
        List<String> fields = new List<String>();

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describe = sObjectType.getDescribe();
        Schema.FieldSet fieldSet = describe.fieldsets.getMap().get(fieldSetName);
        
        if(fieldSet != null) {
            List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();

            for(Schema.FieldSetMember fsm : fieldSetMembers) {
                fields.add(fsm.getFieldPath());
            }
        }
        
        return fields;
    }

    /**
     * get FieldSet field meta information api-name / label
     *
     * @param  sObject      sObject API Name
     * @param  fieldSetName Field Set API Name
     * @return              List<FieldMeta> of field API names defined in FieldSet
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldMeta> getFieldSetFieldMeta(String objectName, String fieldSetName) {
        List<FieldMeta> fields = new List<FieldMeta>();

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describe = sObjectType.getDescribe();
        Schema.FieldSet fieldSet = describe.fieldsets.getMap().get(fieldSetName);
        
        if(fieldSet != null) {
            fields = filterFieldSet(fieldSet.getFields(), sObjectType);
        }
        
        return fields;
    }

    /**
     * get field set properties for SObject
     * @param  sObjectType  type of SObject to retrieve field set
     * @param  fieldSetName field set Name
     * @return              List<FieldSetProperties> of field set information
     */
    @AuraEnabled
    public static List<FieldSetProperties> getFieldSetProperties(String sObjectType, String fieldSetName) {
        List<FieldSetProperties> fieldSetProperties = new List<FieldSetProperties>();

        // describe sobject of target sobject
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(sObjectType);

        if(sObjType != null)
        {
            Schema.DescribeSObjectResult describe = sObjType.getDescribe();

            if(describe != null) {
                Schema.FieldSet fieldSet = describe.FieldSets.getMap().get(fieldSetName);

                if(fieldSet != null) {
                    // build FieldSetProperties
                    for( Schema.FieldSetMember fieldSetMember : fieldSet.getFields() ){
                        FieldSetProperties fieldSetProp = new FieldSetProperties();
                        
                        fieldSetProp.label = String.valueOf(fieldSetMember.getLabel()); 
                        fieldSetProp.fieldName = String.valueOf(fieldSetMember.getFieldPath());

                        String type = String.valueOf(fieldSetMember.getType()).toLowerCase();
                        fieldSetProp.type = type;
                        
                        fieldSetProperties.add(fieldSetProp);
                    }     
                }
            }
        }

        return fieldSetProperties;
    }

    /**
     * filter FieldSet for permission and visiblity and build field meta
     * @param  fieldSetMembers FieldSet Members
     * @param  sObjectType     Schema.SObjectType
     * @return                 List<FieldMeta> list of FieldSet fields including meta data
     */
    private static List<FieldMeta> filterFieldSet(List<Schema.FieldSetMember> fieldSetMembers, Schema.SObjectType sObjectType ) {
        List<FieldMeta> fields = new List<FieldMeta>();
        Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();

        for(Schema.FieldSetMember fsm : fieldSetMembers) {
            String fieldApi = fsm.getFieldPath();
            
            if(fieldMap.get(fieldApi) != null)
            {
                Schema.DescribeFieldResult field = fieldMap.get(fieldApi).getDescribe();

                if(field.isAccessible()) {
                    FieldMeta fm = new FieldMeta();
                    fm.objectApiName = sObjectType.getDescribe().getName();
                    fm.apiName = field.getName();
                    fm.schema = fm.objectApiName + '.' + fm.apiName;
                    fm.label = field.getLabel();
                    fm.type = field.getType().name();
                    fm.isCalculated = field.isCalculated();
                    fm.isUpdateable = field.isUpdateable();
                    fm.isCreateable = field.isCreateable();
                    fm.digest = field.getDigits();
                    fm.precision = field.getPrecision();
                    fm.scale = field.getScale();
                    fm.length = field.getLength();
                    fm.isEditable = fm.isCalculated == false && (fm.isUpdateable || fm.isCreateable);
                    fm.describe = JSON.serialize(field);

                    if(field.isNameField()) {
                        fm.isNameField = true;
                    }

                    fields.add(fm);
                }
            }
        }

        return fields;
    }

    /**
     * get SObject API names
     * @return   List<String> of API SObject API names
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getSObjectAPINames(){
        List<String> sobjectList = new List<String>();

        for(Schema.SObjectType sobjectType: Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult describeSObject = sobjectType.getDescribe();

            if(describeSObject.isAccessible() && describeSObject.isQueryable()) {
                String name = describeSObject.getName();

                if(!name.containsIgnoreCase('history') && !name.containsIgnoreCase('tag') && !name.containsIgnoreCase('share') && !name.containsIgnoreCase('feed')) {
                    sobjectList.add(name);
                }

                sobjectList.sort();
            }
        }

        return sobjectList;
    }

    /**
     * get name field of SObject
     * @param  objectApiName SObject Api name
     * @return               Name field Api name
     */
    public static String getObjectNameFieldApiName(String objectApiName){
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

        for(String key : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(key).getDescribe();
            if(fieldDescribe.isNameField()) {
                return fieldDescribe.getName();
            }
        }

        return null;
    }

    /**
     * get name field of SObject
     * @param  describeResult DescribeSObjectResult of SObject
     * @return                Name field Api name
     */
    public static String getObjectNameFieldApiName(Schema.DescribeSObjectResult describeResult){
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

        for(String key : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(key).getDescribe();
            if(fieldDescribe.isNameField()) {
                return fieldDescribe.getName();
            }
        }

        return null;
    }

    /**
     * get lookup field reference object api names
     * @param  objectApiName Parent SObject Api name
     * @param  fieldApiName  Lookup field Api name
     * @param  searchable    Searchabel in SOSL query
     * @return               List<String> of SObject Api names of referenced object types
     */
    public static List<String> getLookupReferenceObjectTypes(String objectApiName, String fieldApiName, Boolean searchable) {
        List<String> targetObjectNames = new List<String>();

        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        Schema.DescribeFieldResult fieldDescribe = describeResult.fields.getMap().get(fieldApiName).getDescribe();

        if(fieldDescribe.isAccessible()) {
            List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();

            for(Schema.SObjectType reference : referenceTo){
                Schema.DescribeSObjectResult targetDescribe = reference.getDescribe();

                if(targetDescribe.isAccessible()) {
                    if(searchable == true) {
                        if(targetDescribe.isSearchable() == true) {
                            targetObjectNames.add(targetDescribe.getName());
                        }
                    }
                    else {
                        targetObjectNames.add(targetDescribe.getName());
                    }
                }
            }
        }
    
        return targetObjectNames;
    }

     /**
      * get SObject field lables
      * @param  objectApiName objectApiName description
      * @return   Map<String, String> field api names - field label
      */
    public static Map<String, String> getFieldLabels(String objectApiName) {
        Map<String, String> fieldLabelMap = new Map<String, String>();

        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();

        if(describeResult != null) {
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

            for(String key : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(key).getDescribe();
                fieldLabelMap.put(fieldDescribe.getName(), fieldDescribe.getLabel());
            }
        }

        return fieldLabelMap;    
    }

    /**
     * checks if a field exists in a SObject
     * @param  objectApiName SObject API Name
     * @param  fieldApiName  Field API Name
     * @return               true if field exists
     */
    public static Boolean fieldExists(String objectApiName, String fieldApiName) {
        
        Set<String> objectFields = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().keySet();
        if(objectFields.contains(fieldApiName.toLowerCase())) {
            return true;
        }

        return false;
    }

    /**
     * checks if a field is type of picklist
     * @param  objectApiName SObject API Name
     * @param  fieldApiName  Field API Name
     * @return               true field is a type of picklist
     */
    public static Boolean isPicklistField(String objectApiName, String fieldApiName) {
        
        if(fieldExists(objectApiName, fieldApiName)) {
            Schema.SObjectField field = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().get(fieldApiName);

            if(field != null) {
                Schema.DescribeFieldResult describe = field.getDescribe();
                
                if(describe.getType() == Schema.DisplayType.PICKLIST) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * checks if a object type exists
     * @param  objectApiName object type api name to check
     * @return               true if object exists
     */
    public static Boolean objectExists(String objectApiName) {
        for (Schema.SObjectType sObjectType : Schema.getGlobalDescribe().values() ) {
            String sobjName = String.valueOf(sObjectType);
            if (sobjName.contains(objectApiName) ) {
                return true;
            }
        }
        return false;
    }

    /**
     * get picklist values for given SObject and Field
     * @return   return picklist values
     */
    public static List<PicklistValue> getPicklistValues(String objectApiName, String fieldApiName){

        List<PicklistValue> pickListValuesList = new List<PicklistValue>();
        
        if(objectExists(objectApiName)) {
            Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult res = convertToObj.getDescribe();

            if(isPicklistField(objectApiName, fieldApiName)) {
                Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(fieldApiName).getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

                for(Schema.PicklistEntry pickListVal : ple){
                    PicklistValue plv = new PicklistValue();
                    plv.label = pickListVal.getLabel();
                    plv.value = pickListVal.getValue();

                    pickListValuesList.add(plv);
                }
            }
        }
        
        return pickListValuesList;
    }

    /**
     * inner class FieldMeta
     */
     @testVisible
    public class FieldMeta {
       @AuraEnabled
       public String objectApiName;
       @AuraEnabled
       public String label;
       @AuraEnabled
       public String apiName;
       @AuraEnabled
       public Boolean isNameField = false;
       @AuraEnabled
       public String type;
       @AuraEnabled
       public String schema;
       @AuraEnabled
       public String describe;
       @AuraEnabled
       public Boolean isEditable;
       @AuraEnabled
       public Boolean isCalculated;
       @AuraEnabled
       public Boolean isUpdateable;
       @AuraEnabled
       public Boolean isCreateable;
       @AuraEnabled
       public Integer digest;
       @AuraEnabled
       public Integer precision;
       @AuraEnabled
       public Integer scale;
       @AuraEnabled
       public Integer length;
    }

    /**
     * Public wrapper class FieldSetProperties to hold field set properties
     */
    @testVisible
    public class FieldSetProperties {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
    }

    /**
     * Public wrapper class for picklist values
     */
    @testVisible
    public class PicklistValue {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }
}