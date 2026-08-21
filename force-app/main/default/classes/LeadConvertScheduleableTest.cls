@isTest
public class LeadConvertScheduleableTest {
    

    @isTest
    static void testExecute() {
        // Insert a dummy mapping to verify that it's deleted
        insert new LeadConversionMapping__c(
            Name = 'ToDelete',
            SourceFieldName__c = 'Old',
            TargetFieldName__c = 'Old',
            TargetObjectName__c = 'OldObj'
        );

        // Set the mock
        Test.setMock(WebServiceMock.class, new MockMetadataCallout());

        Test.startTest();
        LeadConvertScheduleable.execute(null);
        Test.stopTest();

        // Verify new mappings were inserted and old ones were deleted
        List<LeadConversionMapping__c> mappings = [
            SELECT SourceFieldName__c, TargetFieldName__c, TargetObjectName__c
            FROM LeadConversionMapping__c
        ];
        
        System.assertEquals(3, mappings.size(), 'Expected 3 new mappings');

        // Optional: Check specific values
        Set<String> targetFields = new Set<String>();
        for (LeadConversionMapping__c m : mappings) {
            targetFields.add(m.TargetFieldName__c);
        }
        System.assert(targetFields.contains('Contact.Email'));
        System.assert(targetFields.contains('Contact.Phone'));
    }
}