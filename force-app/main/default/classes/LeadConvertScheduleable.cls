/*
* Created by: Stanley Yin
* Created Date: 06-02-2024
* Purpose: Schedulable Class for B2BProductPriceCalculator Processing
*/

public class LeadConvertScheduleable implements Database.Batchable<SObject>,Database.AllowsCallouts,Schedulable{
    public static void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadConvertScheduleable(), 1);
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        if(!Test.isRunningTest()){ delete [SELECT Id FROM LeadConversionMapping__c WHERE Manual__c = FALSE]; }  
        Id userId = UserInfo.getUserId();
        return Database.getQueryLocator('SELECT Id FROM User WHERE Id = : userID LIMIT 1');
    }
    public void execute(Database.BatchableContext bc,  List<User> scope){
        List<LeadConversionMapping__c> mappingsToInsert = new List<LeadConversionMapping__c>();
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        service.CallOptions = new MetadataService.CallOptions_element();
        service.timeout_x = 120000;

        List<MetadataService.LeadConvertSettings> leadConvertSettings = (List<MetadataService.LeadConvertSettings>) service.readMetadata('LeadConvertSettings', new List<String>{'LeadConvertSettings'}).getRecords();
        Integer i = 0;
        for (MetadataService.LeadConvertSettings leadConvertSetting : leadConvertSettings) {
            for (MetadataService.ObjectMapping objectMapping : leadConvertSetting.objectMapping) {
                for (MetadataService.ObjectMappingField fieldMapping : objectMapping.mappingFields) {
                    mappingsToInsert.add(new LeadConversionMapping__c(
                        Name = String.valueOf(i),
                        SourceFieldName__c = fieldMapping.inputField,
                        TargetFieldName__c = fieldMapping.outputField,
                        TargetObjectName__c = objectMapping.outputObject
                    ));
                    i++;
                }
            }
        }
        Database.insert(mappingsToInsert, false);
    }
    public void finish(Database.BatchableContext BC){ 
        // do nothing
    }
}