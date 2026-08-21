/* 
* @author jens.siffermann@youperience.com
* @date 2019-10-29
* @version 1.0.0
*
* @description Unit test MetadataUtil
*/
@isTest
public with sharing class MetadataUtilTest {

    /**
     * test MetadataUtil.getSObjectAPINames()
     */
    @isTest
    public static void testGetSObjectAPINames() {

        Test.startTest();
        List<String> objectApiNames = MetadataUtil.getSObjectAPINames();
        Test.stopTest();

        System.assert(objectApiNames.size() != 0, 'Unexpected number of object types');
    }

    /**
     * test MetadataUtil.getObjectNameFieldApiName()
     */
    @isTest
    public static void testGetObjectNameFieldApiName() {

        Test.startTest();
        String nameField = MetadataUtil.getObjectNameFieldApiName('Account');
        Test.stopTest();

        System.assertEquals('Name', nameField, 'Unexptected API name of Name field');
    }

    /**
     * test MetadataUtil.getObjectNameFieldApiName()
     */
    @isTest
    public static void testGetObjectNameFieldApiNameByDescribe() {

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get('Account');
        Schema.DescribeSObjectResult describe = sObjectType.getDescribe();

        Test.startTest();
        String nameField = MetadataUtil.getObjectNameFieldApiName(describe);
        Test.stopTest();

        System.assertEquals('Name', nameField, 'Unexptected API name of Name field');
    }

    /**
     * test MetadataUtil.getLookupReferenceObjectTypes()
     */
    @isTest
    public static void testGetLookupReferenceObjectTypes() {

        Test.startTest();
        List<String> references = MetadataUtil.getLookupReferenceObjectTypes('Contact', 'AccountId', true);
        Test.stopTest();

        System.assertEquals(1, references.size(), 'Unexpected number of references - should be 1');
        System.assertEquals('Account', references.get(0), 'Unexpected reference - should be Account');
    }

    /**
     * test MetadataUtil.getFieldLabels()
     */
    @isTest
    public static void testGetFieldLabels() {
        Test.startTest();
        Map<String, String> fieldLabelMap = MetadataUtil.getFieldLabels('Account');
        Test.stopTest();

        System.assert(fieldLabelMap.size() != 0, 'Unexpexted number of field labels');
    }

    /**
     * test MetadataUtil.fieldExists()
     */
    @isTest
    public static void testFieldExists() {
        Test.startTest();
        boolean exists = MetadataUtil.fieldExists('Account', 'Name');
        Test.stopTest();

        System.assert(exists, 'Field check unsuccessful');
    }

    /**
     * test MetadataUtil.fieldExists()
     */
    @isTest
    public static void testFieldExistsFail() {
        Test.startTest();
        boolean exists = MetadataUtil.fieldExists('Account', 'does_not_exist');
        Test.stopTest();

        System.assert(exists == false, 'Field check unsuccessful');
    }

    /**
     * test MetadataUtil.getPicklistValues()
     */
    @isTest
    public static void testGetPicklistValues() {
        Test.startTest();
        List<MetadataUtil.PicklistValue> plvs = MetadataUtil.getPicklistValues('Account', 'Type');
        Test.stopTest();

        System.assert(plvs.size() > 0, 'Not able to load picklist values for Account - Type');
    }

    /**
     * test MetadataUtil.isPicklistField()
     */
    @isTest
    public static void testGetPicklistValuesFail() {
         Test.startTest();
        List<MetadataUtil.PicklistValue> plvs = MetadataUtil.getPicklistValues('Account', 'Type_does_not_exist');
        Test.stopTest();

        System.assert(plvs.size() == 0, 'Not able to load picklist values');
    }
}