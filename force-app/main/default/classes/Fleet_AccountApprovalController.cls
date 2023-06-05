public with sharing class Fleet_AccountApprovalController {
    public static String lprefix = 'FLEET_AAC:';
    public final static String APPLICATION_TYPE_CREDIT = 'Credit';
    public final static String APPLICATION_TYPE_NONCREDIT = 'Non-Credit';
    public final static String CREDIT_STATUS_APPROVED = 'Approved';
    public final static String CREDIT_STATUS_DECLINED = 'Declined';

    @AuraEnabled
    public static string getAccount(String Id){
    
        // get account
        List<Account> acctList = [SELECT Id, Name, 
            Fleet_Application_Type__c, 
            Fleet_Credit_App_Status__c, 
            Fleet_NonCredit_App_Status__c,
            ECC_Account_Number__c,
            Fleet_Account_Status__c,
            Fleet_Primary_Contact__c,
            Credit_Reject_Reasons__c,
            Comments_for_Rejection__c
        from Account where Id = :Id];

        Account acct = null;
        if (acctList.size() > 0) acct = acctList[0];

        ResultWrapper result = validateAccount(acct);
        result.recordId = Id;

        if (result.status.equals('Success')) {
            return JSON.serialize(acct);
        } 

        return JSON.serialize(result);
    }

    private static ResultWrapper validateAccount(Account acct) {
        ResultWrapper result = new ResultWrapper();
        if (acct == null) {
            result.message = 'Invalid Account';
            result.status = 'Error';
            return result;
        }
        if (acct.Fleet_Application_Type__c == null) {
            result.message = 'Application Type of Credit or Non-Credit is required';
            result.status = 'Error';
            return result;
        }
        if ((acct.Fleet_Account_Status__c != null && acct.Fleet_Account_Status__c == 'Customer')) {
            result.message = 'This Account has already been approved. Please refresh your browser to retrieve the SAP Account Number.';
            result.status = 'Error';
            return result;
        }
      //Vaneet : Changes 'Closed Won' to 'Closed Won - 100%' (INC1312053)
      //if ([select count() from Opportunity where AccountId = :acct.Id and StageName != 'Closed Won' and StageName != 'Closed Lost' ] < 1) {
      
        
        if ([select count() from Opportunity where AccountId = :acct.Id and (StageName != 'Closed Won' OR StageName!= 'Closed Won - 100%') and (StageName != 'Closed Lost' OR StageName != 'Closed Lost - 0%') ] < 1) {   
            
            result.message = ' There are no open Opportunities to Approve this Account';
            result.status = 'Error';
            return result;
        }
        result.status = 'Success';
        return result;
    }
    
    @AuraEnabled
    public static String approveAccount(String accountId, String modifiedAcctString) {
        if (modifiedAcctString == '' || modifiedAcctString == null || accountId == null) return JSON.serialize(new ResultWrapper(accountId, 'Invalid Account or Account Id', 'Error'));
        
        ResultWrapper result = new ResultWrapper();
        result.recordId = accountId;

        Account modifiedAcct = (Account) JSON.deserialize(modifiedAcctString, Account.class);
        if (modifiedAcct == null) return '';

        //update the account
        Account acctToUpdate = new Account(
            Id=accountId
            ,Fleet_Primary_Contact__c=modifiedAcct.Fleet_Primary_Contact__c
        );

        // email settings
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        if (emailSettings == null) System.debug('FLEET_EMAIL_SETTINGS__C MUST BE CONFIGURED TO SEND EMAILS');


        // handle Rejection statuses and update the Status and Rejection Reasons
        if (modifiedAcct.Fleet_Application_Type__c.equals(APPLICATION_TYPE_CREDIT) && modifiedAcct.Fleet_Credit_App_Status__c.equals(CREDIT_STATUS_DECLINED)) {
            acctToUpdate.Fleet_Credit_App_Status__c = modifiedAcct.Fleet_Credit_App_Status__c;
            acctToUpdate.Credit_Reject_Reasons__c = modifiedAcct.Credit_Reject_Reasons__c;
            acctToUpdate.Comments_for_Rejection__c = modifiedAcct.Comments_for_Rejection__c;
            acctToUpdate.Fleet_AR_App_Status__c = CREDIT_STATUS_DECLINED;
            acctToUpdate.Fleet_Credit_App_Reject_Date__c = Datetime.now();

            System.debug('FLEET: before update for declined, acctToUpdate.Fleet_AR_App_Status__c=' + acctToUpdate.Fleet_AR_App_Status__c + ':' + acctToUpdate);
            update acctToUpdate;

            // send email
            sendCreditAppDeclinedEmail(emailSettings, accountId);

            //build return value
            result.status = 'Success';
            result.message = 'Account Credit Status and Reasons Updated: ' + acctToUpdate.Fleet_Credit_App_Status__c;
            return JSON.serialize(result);

        } else if(modifiedAcct.Fleet_Application_Type__c.equals(APPLICATION_TYPE_NONCREDIT) && modifiedAcct.Fleet_NonCredit_App_Status__c.equals(CREDIT_STATUS_DECLINED)){
            acctToUpdate.Fleet_NonCredit_App_Status__c = modifiedAcct.Fleet_NonCredit_App_Status__c;
            acctToUpdate.Credit_Reject_Reasons__c = modifiedAcct.Credit_Reject_Reasons__c;
            acctToUpdate.Comments_for_Rejection__c = modifiedAcct.Comments_for_Rejection__c;
            acctToUpdate.Fleet_AR_App_Status__c = CREDIT_STATUS_DECLINED;
            acctToUpdate.Fleet_Non_Credit_App_Reject_Date__c = Datetime.now();
            System.debug('FLEET: before update for declined 2, acctToUpdate.Fleet_AR_App_Status__c=' + acctToUpdate.Fleet_AR_App_Status__c + ':' + acctToUpdate);
            update acctToUpdate;
            result.status = 'Success';
            result.message = 'Account Non-Credit Status and Reasons Updated: ' + acctToUpdate.Fleet_NonCredit_App_Status__c;
            return JSON.serialize(result);
        }

        // Handle "Approval" Status
        acctToUpdate.Fleet_Account_Status__c = 'Customer';
        acctToUpdate.Fleet_AR_App_Status__c = CREDIT_STATUS_APPROVED;
        if (modifiedAcct.Fleet_Application_Type__c.equals(APPLICATION_TYPE_CREDIT)) {
            //HANDLE CREDIT
            acctToUpdate.Fleet_Credit_App_Status__c = modifiedAcct.Fleet_Credit_App_Status__c;
            acctToUpdate.Fleet_Credit_App_Approve_Date__c = Datetime.now();
        } else if (modifiedAcct.Fleet_Application_Type__c.equals(APPLICATION_TYPE_NONCREDIT)) {
            //handle non-credit
            acctToUpdate.Fleet_NonCredit_App_Status__c = modifiedAcct.Fleet_NonCredit_App_Status__c;
            acctToUpdate.Fleet_Non_Credit_App_Approve_Date__c = Datetime.now();
        }

        //update the opportunity as part of Approval
      //Vaneet : Changes 'Closed Won' to 'Closed Won - 100%' (INC1312053)
      //List<Opportunity> oppList = [select Id, Name, StageName from Opportunity where AccountId = :accountId and StageName != 'Closed Won' and StageName != 'Closed Lost'  limit 1];
        List<Opportunity> oppList = [select Id, Name, StageName from Opportunity where AccountId = :accountId and (StageName != 'Closed Won' OR StageName!= 'Closed Won - 100%') and (StageName != 'Closed Lost' OR StageName != 'Closed Lost - 0%') limit 1];
        Opportunity oppToUpdate = null;
        if (oppList.size() > 0 && oppList.size() == 1) {
            oppToUpdate = oppList[0];
        }
        if (oppToUpdate == null) {
            result.status = 'Error';
            result.message = 'No Opportunity Found for Approval';
            return JSON.serialize(result);
        }
        //Vaneet : Changes 'Closed Won' to 'Closed Won - 100%' (INC1312053)
        //oppToUpdate.StageName = 'Closed Won';
          oppToUpdate.StageName = 'Closed Won - 100%'; 

        try {
            System.debug('FLEET: before update for approved, acctToUpdate.Fleet_AR_App_Status__c=' + acctToUpdate.Fleet_AR_App_Status__c + ':' + acctToUpdate);
            update acctToUpdate;
            update oppToUpdate;
            System.debug('FLEET: Opp after update: ' + oppToUpdate);
            System.debug('FLEET: Account after update: ' + acctToUpdate);


            result.message = 'Records Successfully updated';
            result.status = 'Success';
            
        } catch (exception e) {
            result.message = 'Error: ' + e.getMessage();
            result.status = 'Error';
        }

        //update the primary Fleet_Application__c record - DTFS-481
        updateFleetApplication(acctToUpdate.Id);

        return JSON.serialize(result);
    }


    // Declines the applicaiton 
    @AuraEnabled
    public static void declineFleetApplication(Id accountId){

        System.debug('------Start Decline-------');


        List<Fleet_Application__c> apps = [SELECT Id, Application_Status__c, Attachment_Status__c 
                                    FROM Fleet_Application__c WHERE Parent_Account__c = :accountId AND Is_Primary_Application__c = true];
        System.debug(lprefix + '    Fleet_Application__c retrieved - apps:' + apps);

        if (apps != null && apps.size() > 0) {
            // Declines the applicaiton
            for (Fleet_Application__c app: apps) {

                if(app.Application_Status__c == 'Submitted'){

                    app.Application_Status__c = Fleet_Values.FLEET_APP_STATUS_DECLINED;              
                    update app;
                    System.debug(lprefix + '    UPDATED fleet application:' + app);
                    
                }

                
            }
        } else {
            System.debug(lprefix + 'WARNING!!! - no Fleet Apps retrieved for account in updateFleetApplication()');
        }
        System.debug(lprefix + 'updateFleetApplication() EXIT');

    }



    public static void updateFleetApplication(Id accountId) {
        System.debug(lprefix + 'updateFleetApplication() ENTRY - accountId = ' + accountId);

        List<Fleet_Application__c> apps = [SELECT Id,   Application_Status__c, Attachment_Status__c 
                                    FROM Fleet_Application__c WHERE Parent_Account__c = :accountId AND Is_Primary_Application__c = true];
        System.debug(lprefix + '    Fleet_Application__c retrieved - apps:' + apps);

        if (apps != null && apps.size() > 0) {
            // Update the status fields on the Application. Since there should only be one, updating inside the loop, but if more than one primary, all will be updated
            for (Fleet_Application__c app: apps) {
                app.Application_Status__c = Fleet_Values.FLEET_APP_STATUS_APPROVED;
                app.Attachment_Status__c = Fleet_Values.FLEET_APP_ATTACHMENT_STATUS_REVIEWED;

                update app;
                System.debug(lprefix + '    UPDATED fleet application:' + app);
            }
        } else {
            System.debug(lprefix + 'WARNING!!! - no Fleet Apps retrieved for account in updateFleetApplication()');
        }
        System.debug(lprefix + 'updateFleetApplication() EXIT');
    }

    private static void sendCreditAppDeclinedEmail(Fleet_Email_Settings__c emailSettings, String accountId) {
        // do not send emails if settings are not configured
        if (emailSettings == null) return;

        //---get credit app declined settings
        String templateNameDT = emailSettings.Fleet_CreditApplicationDeclinedEmail__c;
        String templateNameAT = emailSettings.Fleet_CreditApplicationDeclinedEmail_AT__c;
        String fromAddress = emailSettings.Fleet_CreditAppDeclinedFromEmail__c;
        String bccAddressString = emailSettings.Fleet_CreditAppDeclinedBccEmails__c;
        List<String> bccAddressList = (bccAddressString != null && bccAddressString != '') ? bccAddressString.deletewhitespace().split(',') : new List<String>();
        
        // Add Fleet Agent to this list
        List<Account> acc = [select Fleet_Specialist__r.Email,ShippingPostalcode from Account where Id = :accountId limit 1];
        if (acc.size() > 0 && acc[0].Fleet_Specialist__r != null) {
            bccAddressList.add(acc[0].Fleet_Specialist__r.Email);
        }

        ResultWrapper emailResult;
        if(acc.size() > 0 && ATZipCodes__c.getAll().get(acc[0].ShippingPostalcode) != null){
            emailResult = Fleet_ApplicationEmailController.sendApplicationEmail(templateNameAT, accountId, bccAddressList, fromAddress);
        }else{
            emailResult = Fleet_ApplicationEmailController.sendApplicationEmail(templateNameDT, accountId, bccAddressList, fromAddress);
        }
        
        System.debug(lprefix + 'Send Email Result : ' + emailResult);
    }


    public class ResultWrapper{
        public string recordId;
        public string message;
        public string status; // 'success' or 'error'

        public ResultWrapper() {} 

        public ResultWrapper(String recordId, String message, String status) {
            this.recordId = recordId;
            this.message = message;
            this.status = status;
        }
    }

    
}