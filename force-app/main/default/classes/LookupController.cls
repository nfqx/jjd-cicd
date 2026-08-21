public without sharing class LookupController {
    private final static Integer MAX_RESULTS = 100;
    private final static String LAST_VIEWED_DATE_FIELD = 'LastViewedDate';
    private final static String NAME_FIELD = 'Name';

    /**
     * Search related records
     * @param  objectApiName        SObject Api name
     * @param  lookupApiName        Lookup field Api name
     * @param  searchTerm           Search term
     * @param  limitToObjectTypes   Limit search to object types
     * @param  selectedIds          excluded selected Ids
     * @param  lookupFilters        lookup filter
     * @return                 List<LookupSearchResult> list of records
     */
    @AuraEnabled(Cacheable=false)
    public static List<LookupSearchResult> search(String parentObjectApiName, String lookupApiName, String searchTerm, List<String> limitToObjectTypes,  List<String> selectedIds, List<LookupFilter> lookupFilters, List<String> additionalFields, String displayField) {
        // get lookup field meta data
        List<String> referenceObjectTypes = MetadataUtil.getLookupReferenceObjectTypes(parentObjectApiName, lookupApiName, true);

        // remove unnecessary object types
        if(limitToObjectTypes != null && limitToObjectTypes.size() > 0) {
            for(Integer i = (referenceObjectTypes.size() -1); i >= 0; i--) {
                String objectType = referenceObjectTypes.get(i);

                if(limitToObjectTypes.contains(objectType) == false) {
                    referenceObjectTypes.remove(i);
                }
            }
        }
        return searchWithReferenceObjectTypes(referenceObjectTypes, searchTerm, limitToObjectTypes, selectedIds, lookupFilters, additionalFields, new List<String>(), new List<String>(), displayField);
    }
    /**
     * Search related records
     * @param  objectApiName        SObject Api name
     * @param  lookupApiName        Lookup field Api name
     * @param  searchTerm           Search term
     * @param  limitToObjectTypes   Limit search to object types
     * @param  selectedIds          excluded selected Ids
     * @param  lookupFilters        lookup filter
     * @return                 List<LookupSearchResult> list of records
     */
    @AuraEnabled(Cacheable=false)
    public static List<LookupSearchResult> searchWithIds(String parentObjectApiName, String lookupApiName, String searchTerm, List<String> limitToObjectTypes,  List<String> selectedIds, List<LookupFilter> lookupFilters, List<String> additionalFields, List<String> listIds, List<String> listIdsExclude, String displayField) {
        // get lookup field meta data
        List<String> referenceObjectTypes = MetadataUtil.getLookupReferenceObjectTypes(parentObjectApiName, lookupApiName, true);

        // remove unnecessary object types
        if(limitToObjectTypes != null && limitToObjectTypes.size() > 0) {
            for(Integer i = (referenceObjectTypes.size() -1); i >= 0; i--) {
                String objectType = referenceObjectTypes.get(i);

                if(limitToObjectTypes.contains(objectType) == false) {
                    referenceObjectTypes.remove(i);
                }
            }
        }
        return searchWithReferenceObjectTypes(referenceObjectTypes, searchTerm, limitToObjectTypes, selectedIds, lookupFilters, additionalFields, listIds, listIdsExclude, displayField);
    }


    @AuraEnabled(Cacheable=false)
    public static List<LookupSearchResult> searchWithReferenceObjectTypes(List<String> referenceObjectTypes, String searchTerm, List<String> limitToObjectTypes,  List<String> selectedIds, List<LookupFilter> lookupFilters, List<String> additionalFields, List<String> listIds, List<String> listIdsExclude, String displayField)
    {
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Prepare query paramters
        searchTerm += '*';

        // build sosl query
        String sosl = 'FIND \'' + searchTerm + '\' IN ALL FIELDS RETURNING ';

        Map<String, String> objectNameFieldMap = new Map<String, String>();

        // build sosl for each reference object
        String[] objectSosls = new String[]{};
        for(String reference : referenceObjectTypes) {
            String objectSosl = reference + '(Id';

            // name field of object type
            String nameField = MetadataUtil.getObjectNameFieldApiName(reference);

            objectNameFieldMap.put(reference, nameField);

            if(nameField != null) {
                objectSosl += ', ' +  nameField;
            }

            if(additionalFields != null && additionalFields.size() > 0){
                for(String additionalField : additionalFields){
                    objectSosl += ', ' +  additionalField;
                }
            }
            if(String.isNotBlank(displayField)){
                objectSosl += ', ' +  displayField;
            }

            if(selectedIds != null && selectedIds.size() > 0) {
                objectSosl += ' WHERE Id NOT IN :selectedIds AND ';
            }

            if(lookupFilters != null && lookupFilters.size() > 0) {
                if(selectedIds == null || selectedIds.size() == 0) {
                    objectSosl += ' WHERE ';
                }
                for(LookupFilter lookupFilter : lookupFilters) {
                    if(lookupFilter.objectType == reference) {
                        objectSosl += lookupFilter.filter + ' AND ';
                    }
                }
            }

            if(!listIdsExclude.isEmpty()){
                objectSosl += ' Id NOT IN :listIdsExclude AND ';
            }

            if(!listIds.isEmpty()){
                objectSosl += ' Id IN :listIds AND ';
            }
            objectSosl = objectSosl.removeEnd('AND ');
            objectSosl += ')';
            objectSosls.add(objectSosl);
        }

        sosl += String.join(objectSosls, ', ') + ' LIMIT ' + MAX_RESULTS;
        System.debug(sosl);
        // execute search
        Search.SearchResults searchResults = Search.find(sosl);

        // get search result for each object type
        for(String reference : referenceObjectTypes) {
            List<Search.SearchResult> objectResult = searchResults.get(reference);

            // Prepare results

            String icon = 'standard:search';
            if(reference.indexOf('__c') == -1) {
                // in case of standard object use object standard icon
                icon = 'standard:' + reference.toLowerCase();
            }

            for (Search.SearchResult searchResult : objectResult) {
                SObject sobj = searchResult.getSObject();
                String nameField = objectNameFieldMap.get(reference);
                String title =  String.isNotBlank(displayField) ? (String) sobj.get(displayField) : (String) sobj.get(nameField);
                String subtitle = '';
                Map<String, Object> additionalFieldMap = new Map<String, Object>();
                if(additionalFields != null && additionalFields.size() > 0){
                    Integer index = 0;
                    for(String additionalField : additionalFields){
                        Object value = sobj.get(additionalField) != null ? sobj.get(additionalField) : '';
                        if(index == 0){
                            subtitle += (String.valueOf(value) + ' - ');
                        }
                        additionalFieldMap.put(additionalField, value);
                        index++;
                    }
                    subtitle = subtitle.removeEnd(' - ');
                } else {
                    subtitle = sobj.getSObjectType().getDescribe().getLabel();
                }
                

                results.add(new LookupSearchResult(sobj.Id, reference, icon, title, subtitle, additionalFieldMap));
            }
        }

        return results;
    }

    /**
     * Query lookup record
     * @param  lookupApiName   Lookup field API name
     * @param  recordId        Record Id of related record
     * @return                 LookupRecordResult
     */
    @AuraEnabled(Cacheable=false)
    public static LookupController.LookupRecordResult lookupDetail(String lookupApiName, Id recordId) {
        if(recordId == null) {
            throw new AuraHandledException('MISSING_RECORD_ID');
        }

        // target object type bases on recordId
        Schema.DescribeSObjectResult targetDescribe = recordId.getSobjectType().getDescribe();
        String targetObjectType = targetDescribe.getName();

        LookupController.LookupRecordResult result = new LookupController.LookupRecordResult();
        result.objectType = targetObjectType;

        if(!String.isBlank(targetObjectType) && recordId != null) {
            String queryFields = 'Id';

            String nameField = MetadataUtil.getObjectNameFieldApiName(targetDescribe);
            if(String.isNotBlank(nameField)) {
                queryFields += ', ' + nameField;
            }
            // get related record details
            String query = 'SELECT ' + queryFields + ' FROM ' + targetObjectType + ' WHERE Id =\'' + recordId + '\'';
            SObject obj = Database.query(query);

            result.record = obj;
        }
        
        return result;
    }

    /**
     * check if a field exist in SObject
     * @param  objectApiName SObject API name
     * @param  fieldApiName  Field API name
     * @return               true if field exists and is accessible
     */
    /*private static boolean fieldExists(String objectApiName, String fieldApiName) {
        SObject so = Schema.getGlobalDescribe().get(objectApiName).newSObject();
        return so.getSObjectType().getDescribe().fields.getMap().containsKey(fieldApiName);
    }*/

    /**
     * inner class LookupRecordResult
     */
    @testVisible
    public class LookupRecordResult {
        @AuraEnabled
        public String objectType;
        @AuraEnabled
        public SObject record;
    }

    @testVisible
    public class LookupFilter {
        @AuraEnabled
        public String objectType {get; set;}
        @AuraEnabled
        public String filter {get; set;} 
    }

    @AuraEnabled(cacheable=false)
    public static List<sObject> lookUp(String searchTerm, String objectName, String filters, String recordId, String fields) {

        Integer limitNum = 20;

        String finalQuery = 'SELECT ' + fields + ' FROM ' + objectName;

        if(String.isBlank(recordId)){
            if(String.isNotBlank(searchTerm)){
                finalQuery += ' WHERE Name Like  \'%' + searchTerm + '%\' ';
            }
            
            if(String.isNotBlank(filters)){
                finalQuery += String.isNotBlank(searchTerm) ? ' AND ' : ' WHERE ';
                finalQuery += filters;
            }
        }else{
            finalQuery += ' WHERE Id =  \'' + recordId + '\'';
        }

        finalQuery+= ' LIMIT ' + limitNum;

        System.debug('Final Query::::' + finalQuery);

        List<sObject> lookUpList = database.query(finalQuery);

        return lookUpList;  
    }
}