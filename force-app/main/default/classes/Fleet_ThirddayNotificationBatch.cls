/***********************************************************************************************************************************
Name      : Fleet_InactivityEmail
Usage     : Batch Class to send 3rd day notification email to customer.
Date      : 4/17/2023
CreatedBy : Rohith V

************************************************************************************************************************************/ 
public class Fleet_ThirddayNotificationBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {
    
    // To Query the list of accounts that meet specific criteria for sending the third-day notification email.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String logPrefix = 'Fleet_ThirddayNotificationBatch.start() - ';
        System.debug(logPrefix + 'Started.');

        return Database.getQueryLocator([SELECT Id, Owner.Email, Fleet_Pending_Additional_Info_Date__c, Fleet_Days_Until_Decline__c, Fleet_Application_Third_Day_Notification__c,Fleet_Primary_Contact__c FROM Account WHERE Fleet_Pending_Additional_Info_Date__c != null AND Fleet_Days_Until_Decline__c = 3 AND Fleet_Application_Third_Day_Notification__c = false]);
    }
    
    // Process the list of accounts returned by the query and send the third-day notification email to each account's primary contact.
    public void execute(Database.BatchableContext bc, List<Account> accScope) {
        String logPrefix = 'Fleet_ThirddayNotificationBatch.execute() - ';
        System.debug(logPrefix + 'Started.');

        if (!accScope.isEmpty()) {
            Fleet_AccountEmailUtil.sendThirdDayNotificationEmails(accScope);
        } else {
            System.debug(logPrefix + 'No accounts found that meet criteria for declined accounts.');
        }
    }

    public void finish(Database.BatchableContext bc) {
        //do nothing
    }
    
    // Schedule the batch job
    public void execute(SchedulableContext sc) {
        Fleet_ThirddayNotificationBatch batch = new Fleet_ThirddayNotificationBatch();
        Database.executeBatch(batch);
    }
}