public without sharing class WebshopBatchCreateActivateBuyerAccount implements Schedulable {

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new WebshopQueueCreateActivateBuyerAccount());
    }

}