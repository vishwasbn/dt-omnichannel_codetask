/***********************************************************************************************************************************
Name      : Fleet_InactivityEmail
Usage     : Batch Class to send inactivity email to customer.
Date      : March 2023
CreatedBy : Rohith V

#2 
Modified By : Rohith V	
Modified Date :  04/27/2023
User Story Number : Salesforce-1176.

************************************************************************************************************************************/ 

global class Fleet_InactivityEmail implements Database.Batchable<sObject>, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Define the query to select B2B Accounts with Fleet Inactivity Notification Enabled.
        String inactivityDays = System.Label.Inactivity_Days;
        
        //Updated the Query to exclude the closed accounts. SF-1176
         
		String query = 'SELECT Id, Name, Fleet_Last_Invoice_Date__c, Fleet_Last_Invoice_Tender_Amount__c, AT_Customer__c, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Fleet_Inactivity_Notification_Date__c, Fleet_Inactivity_Notification_Enabled__c ' +
        'FROM Account ' +
        'WHERE Fleet_Inactivity_Notification_Enabled__c = true ' +
        'AND Fleet_Primary_Contact__r.Email !=null ' +    
        'AND (Fleet_Inactivity_Notification_Date__c = null OR Fleet_Inactivity_Notification_Date__c < LAST_N_DAYS:' + inactivityDays + ') ' +
        'AND (Fleet_Last_Invoice_Date__c = null OR Fleet_Last_Invoice_Date__c <= LAST_N_DAYS:' + inactivityDays + ')'+
        'AND  Fleet_Account_Status__c != \'Closed\'';   
       

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> accScope) {
        // Send inactivity email to the updated accounts
        Fleet_AccountEmailUtil.sendInactivityEmail(accScope);
        system.debug('Accounts in Scope' +accScope);
    }

    global void finish(Database.BatchableContext BC) {

    }

    global void execute(SchedulableContext sc) {
        // Execute the batch job
        Integer batchSize = Integer.valueOf(System.Label.Inactivity_Email_Limit);
        Database.executeBatch(this, batchSize);
    }
}