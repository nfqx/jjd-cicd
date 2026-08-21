public without sharing class ERPSyncRecursionPrevention {

    // Used only in test context to override the integration username resolved from Custom Metadata,
    // allowing unit tests to inject a known username without deploying ERPIntegrationConfig__mdt records.
    @TestVisible private static String testIntegrationUsername;

    private static final List<ERPFieldConfig> ERP_LAST_SYNC_FIELDS = new List<ERPFieldConfig>{
        new ERPFieldConfig('ERPLastSyncAt__c', Schema.DisplayType.DATETIME)
    };

    // Returns the ids of records whose change originated in the ERP and must therefore NOT be
    // published back to it. Handles both insert (oldRecordsMap == null) and update contexts:
    // on insert there is no previous state to diff against, so a populated ERPLastSyncAt__c is
    // used as the marker of ERP origin. Before this handled insert, every record created by the
    // integration - each address and bank account arriving from SAP, and every record written by
    // an initial data migration - published a platform event straight back to the ERP.
    public static Set<Id> checkERPFieldOnlyUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecordsMap) {
        Set<Id> erpUpdatedRecords = new Set<Id>();

        if (newRecords == null || newRecords.isEmpty()) {
            return erpUpdatedRecords;
        }

        Set<Id> modifierIds = new Set<Id>();
        for (SObject newRecord : newRecords) {
            modifierIds.add((Id) newRecord.get('LastModifiedById'));
        }

        Set<Id> integrationUserIds = getIntegrationUserIds(modifierIds);
        Boolean isInsert = (oldRecordsMap == null);

        for (SObject newRecord : newRecords) {
            Id recordId = newRecord.Id;

            // Applies to insert and update alike: the integration user's own writes must never
            // bounce back to the ERP that produced them.
            if (integrationUserIds.contains((Id) newRecord.get('LastModifiedById'))) {
                erpUpdatedRecords.add(recordId);
                continue;
            }

            if (isInsert) {
                if (hasERPSyncMarker(newRecord)) {
                    erpUpdatedRecords.add(recordId);
                }
                continue;
            }

            SObject oldRecord = oldRecordsMap.get(recordId);

            if (oldRecord == null) {
                continue;
            }

            if (isERPFieldsUpdated(newRecord, oldRecord)) {
                erpUpdatedRecords.add(recordId);
            }
        }

        return erpUpdatedRecords;
    }

    // Insert-context counterpart of isERPFieldsUpdated: with no old record to compare against,
    // the mere presence of a sync timestamp means the record was written by the ERP integration.
    // Records created by users in the UI leave ERPLastSyncAt__c empty.
    private static Boolean hasERPSyncMarker(SObject newRecord) {
        for (ERPFieldConfig fieldConfig : ERP_LAST_SYNC_FIELDS) {
            String fieldName = fieldConfig.fieldName;

            if (!newRecord.getSObjectType().getDescribe().fields.getMap().containsKey(fieldName)) {
                continue;
            }

            if (newRecord.get(fieldName) != null) {
                return true;
            }
        }

        return false;
    }

    private static Set<Id> getIntegrationUserIds(Set<Id> modifierIds) {
        String integrationUsername = testIntegrationUsername != null
            ? testIntegrationUsername
            : getConfiguredUsername();

        if (String.isBlank(integrationUsername) || modifierIds.isEmpty()) {
            return new Set<Id>();
        }

        Set<Id> result = new Set<Id>();
        for (User u : [SELECT Id FROM User WHERE Id IN :modifierIds AND Username = :integrationUsername]) {
            result.add(u.Id);
        }
        return result;
    }

    private static String getConfiguredUsername() {
        ERPIntegrationConfig__mdt config = ERPIntegrationConfig__mdt.getInstance('Default');
        return config != null ? config.IntegrationUsername__c : null;
    }

    private static Boolean isERPFieldsUpdated(SObject newRecord, SObject oldRecord) {
        return isAnyFieldChanged(newRecord, oldRecord, ERP_LAST_SYNC_FIELDS);
    }

    // Typed field-level diff over an explicit field list. Public so that the codebase keeps a
    // single comparison implementation: ERPIntegrationEventPublisher reuses it to decide whether
    // an Account update touched anything the ERP integration actually consumes.
    // Fields absent from the SObject type are skipped rather than failing, so one field list can
    // serve several objects.
    public static Boolean isAnyFieldChanged(SObject newRecord, SObject oldRecord, List<ERPFieldConfig> fieldConfigs) {
        if (newRecord == null || oldRecord == null || fieldConfigs == null) {
            return false;
        }

        Map<String, Schema.SObjectField> fieldMap = newRecord.getSObjectType().getDescribe().fields.getMap();

        for (ERPFieldConfig fieldConfig : fieldConfigs) {
            String fieldName = fieldConfig.fieldName;

            if (!fieldMap.containsKey(fieldName)) {
                continue;
            }

            if (isFieldValueChanged(newRecord.get(fieldName), oldRecord.get(fieldName), fieldConfig.fieldType)) {
                return true;
            }
        }

        return false;
    }

    private static Boolean isFieldValueChanged(Object newValue, Object oldValue, Schema.DisplayType fieldType) {
        if (newValue == null && oldValue == null) {
            return false;
        }
        if (newValue == null || oldValue == null) {
            return true;
        }

        switch on fieldType {
            when DATETIME {
                Datetime newDT = (Datetime) newValue;
                Datetime oldDT = (Datetime) oldValue;
                return newDT != oldDT;
            }
            when PICKLIST, MULTIPICKLIST, STRING, TEXTAREA, EMAIL, PHONE, URL, ENCRYPTEDSTRING {
                String newStr = String.valueOf(newValue);
                String oldStr = String.valueOf(oldValue);
                return newStr != oldStr;
            }
            when else {
                return newValue != oldValue;
            }
        }
    }

    public class ERPFieldConfig {
        public String fieldName;
        public Schema.DisplayType fieldType;

        public ERPFieldConfig(String fieldName, Schema.DisplayType fieldType) {
            this.fieldName = fieldName;
            this.fieldType = fieldType;
        }
    }
}