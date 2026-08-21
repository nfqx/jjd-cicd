public without sharing class WebshopQueueCreateActivateBuyerAccount implements Finalizer, Queueable {

    public WebshopQueueCreateActivateBuyerAccount() {}
 
    public static void execute(QueueableContext context){
        List<Account> scope = [SELECT Id, Name FROM Account WHERE CreateOrActivateBuyerAccount__c  = TRUE];
        Map<Id, BuyerAccount> baMap = new Map<Id, BuyerAccount>();
        for(BuyerAccount ba : [SELECT Id, BuyerId FROM BuyerAccount WHERE BuyerId IN : scope]){
            baMap.put(ba.BuyerId, ba);
        }
        List<BuyerAccount> baListUpsert = new List<BuyerAccount>();
        for(Account ac : scope){
            if(!baMap.containsKey(ac.Id)){
                BuyerAccount bacc = new BuyerAccount(
                    BuyerId = ac.Id,
                    Name = ac.Name,
                    isActive = true
                );
                baListUpsert.add(bacc);
            } else {
                BuyerAccount bacc = baMap.get(ac.Id);
                bacc.isActive = true;
                baListUpsert.add(bacc);
            }
        }
        upsert baListUpsert;
        WebshopQueueCreateActivateBuyerAccount f = new WebshopQueueCreateActivateBuyerAccount();
        System.attachFinalizer(f);
    }
  
    public void execute(FinalizerContext ctx) {
        List<Account> acl = [SELECT Id FROM Account WHERE CreateOrActivateBuyerAccount__c  = TRUE];
        for(Account ac : acl){
            ac.CreateOrActivateBuyerAccount__c = false;
        }
        update acl;
    }
}