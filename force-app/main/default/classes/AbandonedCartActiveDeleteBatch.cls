public without sharing class AbandonedCartActiveDeleteBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc){
        Integer dayBack = Integer.valueOf(System.Label.AbandonedCartActiveDeleteDays);
        Datetime daysBack = Datetime.now().addDays(dayBack * -1);
        return Database.getQueryLocator('SELECT Id, CreatedById FROM WebCart WHERE Status = \'Active\' AND LastModifiedDate < = : daysBack');
    }

    public void execute(Database.BatchableContext bc,  List<WebCart> scope){
        delete scope;
    }
  
    public void finish(Database.BatchableContext BC){ 
        // do nothing
    }
}