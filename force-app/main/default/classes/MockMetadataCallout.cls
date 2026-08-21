@isTest
global class MockMetadataCallout implements WebServiceMock {
    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {

        // Create a fake LeadConvertSettings record
        MetadataService.LeadConvertSettings leadConvertSetting = new MetadataService.LeadConvertSettings();

        // Create ObjectMapping list with one mapping
        MetadataService.ObjectMapping objMapping = new MetadataService.ObjectMapping();
        objMapping.inputObject = 'Lead';
        objMapping.outputObject = 'Contact';

        // Create mappingFields list
        MetadataService.ObjectMappingField field1 = new MetadataService.ObjectMappingField();
        field1.inputField = 'Lead.Email';
        field1.outputField = 'Contact.Email';

        MetadataService.ObjectMappingField field2 = new MetadataService.ObjectMappingField();
        field2.inputField = 'Lead.Phone';
        field2.outputField = 'Contact.Phone';

        objMapping.mappingFields = new List<MetadataService.ObjectMappingField>{field1, field2};

        // Assign objectMapping list
        leadConvertSetting.objectMapping = new List<MetadataService.ObjectMapping>{objMapping};

        // Create the response result object and add records
        MetadataService.ReadLeadConvertSettingsResult result = new MetadataService.ReadLeadConvertSettingsResult();
        result.records = new List<MetadataService.LeadConvertSettings>{leadConvertSetting};

        MetadataService.readLeadConvertSettingsResponse_element responseElement = new MetadataService.readLeadConvertSettingsResponse_element();
        responseElement.result = result;

        // Put the result in the response map so the callout returns it
        response.put('response_x', responseElement);
    }
}