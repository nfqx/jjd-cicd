/**
* Scheduler for WebshopActiveCustomerCheckBatch
* @author: Stanley Yin (stanley.yin@nfq-x.com), Dec 17, 2023
*
*/

public without sharing class WebshopActiveCustomerCheckScheduler Implements Schedulable{
    public static void execute(SchedulableContext sc){
        scheduleJob();
    }
    
    public static void scheduleJob(){
        Database.executeBatch(new WebshopActiveCustomerCheckBatch(), 100);
    }
}