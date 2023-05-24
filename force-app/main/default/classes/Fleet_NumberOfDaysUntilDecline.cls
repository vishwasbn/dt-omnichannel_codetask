/**
 Created By : Ritika Sharma
 Creatted Dated : 2/16/2023
 Description : This Batch Class is called regularly to get number of days since application has been submitted for AR review.
**/
global class Fleet_NumberOfDaysUntilDecline implements Database.Batchable <sObject>,Database.Stateful,schedulable{
    
    List<Account> fleetlst = new List<Account>();
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String recordType='B2B';
        String query ='Select id, Fleet_Account_Status__c, Fleet_AR_App_Status__c,Fleet_Pending_Additional_Info_Date__c, Fleet_Application_Type__c,Fleet_Days_until_Decline__c,Fleet_Credit_App_Status__c,Fleet_NonCredit_App_Status__c from Account where Fleet_Account_Status__c =\'Pending Additional Information\' and recordtype.name=:recordType order by CreatedDate ASC';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc,List<Account> batch) {
        System.debug('==Batch=='+batch.size());
 
        for(Account acc: batch){
                //acc.Fleet_Account_Status__c ='Pending Additional Information';
            fleetlst.add(acc);
            System.debug('Account List=='+fleetlst);  
          }
         if(fleetlst.size()>0 && fleetlst!= null){
         Fleet_AccountTriggerHandler.countNoOfDays(fleetlst);
         }  
    }
    
    global void finish(Database.BatchableContext bc) {
     //do nothing

    }
    
    public void execute(SchedulableContext sc) {
        Fleet_NumberOfDaysUntilDecline mbtBatch = new Fleet_NumberOfDaysUntilDecline();
        database.executeBatch(mbtBatch);
        
    } 

  
}