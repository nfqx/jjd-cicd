public inherited sharing class LookupSearchResult {

    @AuraEnabled public Id id;
    @AuraEnabled public String sObjectType;
    @AuraEnabled public String icon;
    @AuraEnabled public String title;
    @AuraEnabled public String subtitle;
    @AuraEnabled public Map<String, Object> additionalFieldMap;

    public LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle, Map<String, Object> additionalFieldMap) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
        this.additionalFieldMap = additionalFieldMap;
    }
}