public without sharing class AbandonedCartCheckoutDeleteBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc){
        Integer hrBack = Integer.valueOf(System.Label.AbandonedCartCheckoutDeleteHours);
        Datetime hrsBack = Datetime.now().addHours(hrBack * -1);
        return Database.getQueryLocator('SELECT Id, CreatedById FROM WebCart WHERE Status = \'Checkout\' AND LastModifiedDate < = : hrsBack');
    }

    public void execute(Database.BatchableContext bc,  List<WebCart> scope){
        delete scope;
    }
  
    public void finish(Database.BatchableContext BC){ 
        // do nothing
    }
}