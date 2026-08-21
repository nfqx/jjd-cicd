/*
* Created by: Stanley Yin
* Created Date: 06-05-2025
* Purpose: Batch Job to resend activation email after 4 days
*/

public without sharing class BatchResendActivationEmail implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchResendActivationEmail(), 100);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT id, createddate  from user where profile.name = \'Customer Community Plus User\' and isactive = true and lastlogindate = null and createddate = last_n_days:4 and createddate != last_n_days:3');
    }
    
    public void execute(Database.BatchableContext bc, List<User> scope) {
        List<PermissionSetAssignment> psaList = [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'B2BNewWebshop' AND AssigneeId IN : scope];
        List<PermissionSetAssignment> psaNew = new List<PermissionSetAssignment>();
        for(PermissionSetAssignment psa : psaList){
            psaNew.add(new PermissionSetAssignment(PermissionSetId = psa.PermissionSetId, AssigneeId = psa.AssigneeId));
        } 
        delete psaList;
        insert psaNew;
    }

public void finish(Database.BatchableContext bc){ /* DO nothing */ }
}