@IsTest
private class LeadConvertTest {

    @TestSetup
    static void setupTestData() {
        // Insert LeadStatus record with IsConverted = true if none exists (mock if needed)
        // If not possible to insert LeadStatus (standard object), we'll rely on existing data
        
        // Insert LeadConversionMapping__c records for Account and Contact mapping
        List<LeadConversionMapping__c> mappings = new List<LeadConversionMapping__c>{
            new LeadConversionMapping__c(Name = 'test1', SourceFieldName__c = 'Company', TargetFieldName__c = 'Name', TargetObjectName__c = 'Account'),
            new LeadConversionMapping__c(Name = 'test2', SourceFieldName__c = 'FirstName', TargetFieldName__c = 'FirstName', TargetObjectName__c = 'Contact'),
            new LeadConversionMapping__c(Name = 'test3', SourceFieldName__c = 'LastName', TargetFieldName__c = 'LastName', TargetObjectName__c = 'Contact')
        };
        insert mappings;
        
        // Insert Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open - Not Contacted'
        );
        insert testLead;

        // Insert Account
        Account testAccount = new Account(Name = 'Test Company');
        insert testAccount;

        // Insert Contact
        Contact testContact = new Contact(FirstName='Test', LastName='Contact', AccountId=testAccount.Id);
        insert testContact;
    }

    @IsTest
    static void testGetContactAccountRelations() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        List<AccountContactRelation> acrs = LeadConvertController.getContactAccountRelations(c.Id);
        System.assertNotEquals(null, acrs);
    }

    @IsTest
    static void testGetLeadAccountMergeMap() {
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<LeadConvertController.FieldMappingWrapper> results = LeadConvertController.getLeadAccountMergeMap(leadRec.Id, acc.Id);
        System.assertNotEquals(null, results);
    }

    @IsTest
    static void testGetLeadContactMergeMap() {
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        List<LeadConvertController.FieldMappingWrapper> results = LeadConvertController.getLeadContactMergeMap(leadRec.Id, con.Id);
        System.assertNotEquals(null, results);
    }

    @IsTest
    static void testGetPotentialContactDuplicates() {
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        LeadConvertController.SearchResultsWrapper result = LeadConvertController.getPotentialContactDuplicates(leadRec.Id);
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.records);
        System.assertNotEquals(null, result.displayedFields);
    }

    @IsTest
    static void testGetPotentialAccountDuplicates() {
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        LeadConvertController.SearchResultsWrapper result = LeadConvertController.getPotentialAccountDuplicates(leadRec.Id);
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.records);
        System.assertNotEquals(null, result.displayedFields);
    }

    @IsTest
    static void testSoslSearchContact() {
        LeadConvertController.SearchResultsWrapper result = LeadConvertController.soslSearchContact('Test');
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.records);
        System.assertNotEquals(null, result.displayedFields);
    }

    @IsTest
    static void testSoslSearchAccount() {
        LeadConvertController.SearchResultsWrapper result = LeadConvertController.soslSearchAccount('Test');
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.records);
        System.assertNotEquals(null, result.displayedFields);
    }

    @IsTest
    static void testConvertLeadWithExistingAccount() {
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Map<String, String> fieldMap = new Map<String, String>{'Name' => 'Updated Account Name'};
        Test.startTest();
        LeadConvertController.ConvertedLeadWrapper result = LeadConvertController.convertLeadWithExistingAccount(
            leadRec.Id,
            acc.Id,
            fieldMap,
            true,
            'Test Opportunity'
        );
        Test.stopTest();
        System.assert(result != null);
    }

    @IsTest
    static void testConvertLeadWithExistingContact() {
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Map<String, String> fieldMap = new Map<String, String>{'FirstName' => 'Updated'};
        Test.startTest();
        LeadConvertController.ConvertedLeadWrapper result = LeadConvertController.convertLeadWithExistingContact(
            leadRec.Id,
            con.Id,
            acc.Id,
            fieldMap,
            true,
            'Test Opportunity',
            new List<String>()
        );
        Test.stopTest();
        System.assert(result != null);
    }

    @IsTest
    static void testConvertLead() {
        Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        LeadConvertController.ConvertedLeadWrapper result = LeadConvertController.convertLead(leadRec.Id, true, 'Test Opportunity');
        Test.stopTest();
        System.assert(result != null);
    }

    @isTest 
    static void testFieldMappingWrapper(){
        LeadConvertController.FieldMappingWrapper wrapper = new LeadConvertController.FieldMappingWrapper(
            'test', 'test', 'test', 'test', '1', null, 'test', 'test', false, false
        );
        System.assert(wrapper != null);
    }
}