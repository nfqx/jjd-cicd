public with sharing class OrderSimulationController {
    public static ReturnWrapper sendToOrderSimulation(String body, ERPIntegrationSettings__mdt cfg) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(('callout:ERP_API_NEW') + (cfg.EndpointPath__c ?? ''));
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() >= 300){
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String errorMessage = data.containsKey('error') ? (String)data.get('error') : 'Unknown Error';
            ErrorLogging__c el = new ErrorLogging__c(
                ProcessName__c = 'Order Simulation',
                Error__c = errorMessage
            );
            insert el;
            return new ReturnWrapper(false, el.Id, errorMessage, null);
        }
        
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return new ReturnWrapper(true, null, null, data);
    }

    public class ReturnWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorLogId;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Map<String, Object> data;
        public ReturnWrapper(Boolean isSuccess, String errorLogId, String errorMessage, Map<String, Object> data){
            this.isSuccess = isSuccess;
            this.errorLogId = errorLogId;
            this.errorMessage = errorMessage;
            this.data = data;
        }
    }
}