public with sharing class Fleet_NotifyARController {

    public static final String PREFIX = 'FLEETAR:';

    public static final String ACCOUNT_STATUS_CUSTOMER = 'Customer';
    public final static String STATUS_SUCCESS = 'Success';
    public final static String STATUS_ERROR = 'Error';
    //Toast messages
    public static final String TOAST_MESSAGE_AR_ALREADY_NOTIFIED = 'The account has already been submitted to AR for review.';
    public static final String TOAST_MESSAGE_ACCOUNT_ALREADY_CUSTOMER = 'The account status is already set to Customer.';
    public static final String TOAST_MESSAGE_NO_APPLICATION = 'There must be a Fleet Application related to this Account, with at least one child Fleet Application Attachment record.';
    public static final String TOAST_MESSAGE_NO_ATTACHMENT = 'There must be at least one Fleet Application Attachment record. Each Fleet Application Attachment must have a file attached.';
    public static final String TOAST_MESSAGE_ACCOUNT_APP_TYPE_BLANK = 'Please make sure that the account has an Application Type selected.';
    public static final String TOAST_MESSAGE_ACCOUNT_PRIMARY_CONTACT_BLANK = 'Please make sure that the account has a Primary Contact selected.';
    public static final String TOAST_MESSAGE_NO_PRIMARY_APPLICATIONS = 'Please make sure that a Fleet Application is marked as the Primary Application';
    public static final String TOAST_MESSAGE_MULTIPLE_PRIMARY_APPLICATIONS = 'Please make sure that only one Fleet Application is marked as the Primary Application';
    public static final String TOAST_MESSAGE_ONLINE_APP_ALREADY_SUBMITTED = 'Online Applications are submitted to AR department directly from the customer.';
    /**
     * Called when contracts have been created, application uploaded, and user clicks the Notify AR button.
     * Method will Get Account for the Id, set Is_Notify_AR_Application_Received__c = True, set Fleet_AR_App_Sent_Date__c to today, 
     * and set Fleet_Account_Status__c = ACCOUNT_STATUS_SUBMITTED
     * 
     *   DTFS-281 - converted from Contracts to using Fleet_App_Attachment__c and Fleet_App_Attachment__c. 
     */
    @AuraEnabled
    public static string handleNotifyARApplicationReceived(String recordId, String fields, String additionalARComments){
        system.debug(PREFIX+'handleNotifyARApplicationReceived(): ENTRY, accntId = '+ recordId);
        system.debug(PREFIX+'  handleNotifyARApplicationReceived(): additionalARComments = '+ additionalARComments);
        String accntId = recordId;

        //instantiate return object
        ResultWrapper result = new ResultWrapper();
        result.recordId = accntId;

        // deserialize fields from form;
        Account accountFromForm = (Account) JSON.deserialize(fields, Account.class);
        system.debug(PREFIX+'  handleNotifyARApplicationReceived(): accountFromForm = '+ accountFromForm);
        accountFromForm.Id = accntId;

        // validate Account fields from the form, if errors return from method with error Toast message
        result = validateAccountFieldValues(accountFromForm);
        if (result.status == STATUS_ERROR) {
            system.debug(PREFIX+'validateAccountFieldValues(): ERROR - result='+result.status+':'+result.message);
            return JSON.serialize(result);
        }

        // passed validation, now call util method retrieve and update account and Fleet Application records, and post to Chatter
        if (Fleet_NotifyARUtil.notifyARApplicationReceived(accntId, accountFromForm.Fleet_Application_Type__c, accountFromForm.Fleet_Primary_Contact__c, additionalARComments)) {

            result = new ResultWrapper();
            result.status = STATUS_SUCCESS;
            system.debug(PREFIX+'handleNotifyARApplicationReceived():SUCCESS!!!');
            return JSON.serialize(result);     

        } else {
            system.debug(PREFIX+'handleNotifyARApplicationReceived(): ERROR (end of method)');
            result = new ResultWrapper();
            result.status = STATUS_ERROR;
            result.message = 'Something went wrong.';
            return JSON.serialize(result);
        }
    }

    //Validate Account field values set on form
    public static ResultWrapper validateAccountFieldValues(Account accountFromForm) {
        system.debug(PREFIX+'validateAccountFieldValues(): ENTRY accountFromForm:' + accountFromForm);
        ResultWrapper result = new ResultWrapper();
        result.recordId = accountFromForm.Id;

        //make sure account has Fleet_Application_Type__c populated
        if (String.isBlank(accountFromForm.Fleet_Application_Type__c)) {
            result.status = STATUS_ERROR;
            result.message = TOAST_MESSAGE_ACCOUNT_APP_TYPE_BLANK;
            return result;
        }
        
        result.status = STATUS_SUCCESS;
        return result;
    }

    /** Validate that the account is ready to be sent to AR, for example that a 
     * related Contract has been created with application attached
     * 
     * DTFS-281 - converted from Contracts to using Fleet_App_Attachment__c and Fleet_App_Attachment__c. Validation now checks
     * that there is a related Fleet_App_Attachment__c associated with the Account, and a child Fleet_App_Attachment__c containing an attached File.
     * 
     * DTFS-457 - adding logic to only validate presence of child Fleet_App_Attachment and upload file if app format = PDF Forms. Also, this method will 
     * now only validate the primary Fllet Application, based on Is_Primary_Application__c
     */
    @AuraEnabled
    public static string prevalidateAccount(String accountId){

        system.debug(PREFIX+'prevalidateAccount():accountId='+accountId);
        Account accnt = null;
        Boolean hasApplicationFileAttached = false;

        //instantiate return object
        ResultWrapper result = new ResultWrapper();
        result.recordId = accountId;

        //validate that AT department hasn't already been notified about the account application 
        if (accountId != null && accountId <> '') {
            accnt = [SELECT Id, Fleet_Account_Status__c, Fleet_Application_Type__c FROM Account WHERE Id = :accountId];
            system.debug(PREFIX+'     after SOQL Query - Account='+accnt);
        }
        
        if (accnt != null) {
            system.debug(PREFIX+'     after SOQL Query - Account.Fleet_Account_Status__c='+accnt.Fleet_Account_Status__c);

            //make sure the Account.Fleet_Account_Status__c isn't already set to ACCOUNT_STATUS_SUBMITTED nor ACCOUNT_STATUS_CUSTOMER,
            // send error message if it is
            if (accnt.Fleet_Account_Status__c == Fleet_NotifyARUtil.ACCOUNT_STATUS_SUBMITTED || accnt.Fleet_Account_Status__c == ACCOUNT_STATUS_CUSTOMER) {
                system.debug(PREFIX+'prevalidateAccount(): PreValidate ERROR - account status already submitted or customer. accnt.Fleet_Account_Status__c = ' + accnt.Fleet_Account_Status__c);
                result = new ResultWrapper();
                result.status = STATUS_ERROR;
                if (accnt.Fleet_Account_Status__c == Fleet_NotifyARUtil.ACCOUNT_STATUS_SUBMITTED) {
                    result.message = TOAST_MESSAGE_AR_ALREADY_NOTIFIED;
                } else {
                    result.message = TOAST_MESSAGE_ACCOUNT_ALREADY_CUSTOMER;
                }
                system.debug(PREFIX+'prevalidateAccount(): ERROR - result='+result.status+':'+result.message);
                return JSON.serialize(result);
            }
        }

        //Get Fleet Appliations and then validate the primary application 
        List<Fleet_Application__c> apps = [SELECT Id, Name, Application_Type__c, Fleet_Application_Format__c, Is_Primary_Application__c FROM Fleet_Application__c WHERE Parent_Account__c = :accountId];
        Fleet_Application__c primaryApp;

        if (apps != null && apps.size() > 0) {
            system.debug(PREFIX+'     Fleet Applications retrieved:'+apps);

            //loop through the Fleet Applications to find the single primary application
            for (Fleet_Application__c app: apps) {
                system.debug(PREFIX+'     IN LOOP to find primary app, checking app:'+app);

                if (app.Is_Primary_Application__c == true) {

                    //found the primary application, however check that no other app was also marked as primary
                    if (primaryApp == null) {
                        primaryApp = app;
                    } else {
                        // If here, means that there were more than 1 primary application, show toast message to user
                        system.debug(PREFIX+'ERROR! there are more than one primary application. PrimaryApp1:'+primaryApp + '|,   primaryApp2:' + app);
                        result = new ResultWrapper();
                        result.status = STATUS_ERROR;
                        result.message = TOAST_MESSAGE_MULTIPLE_PRIMARY_APPLICATIONS;
                        system.debug(PREFIX+'prevalidateAccount(): ERROR - result='+result.status+':'+result.message);
                        return JSON.serialize(result);
                    }
                }
            }

            //validate the primary application
            if (primaryApp != null) {

                // Validate all Fleet_App_Attachment__c have files attached. Online application might not have any Fleet_App_Attachment__c, which is fine
                hasApplicationFileAttached = doAllAppAttachmentsHaveFileAttached(primaryApp.Id);

                // If here, means that no the app is an online app and can't be sumbited twice
                if(primaryApp.Is_Primary_Application__c == true && primaryApp.Fleet_Application_Format__c == 'Online'){
                    system.debug(PREFIX+'ERROR! This is an online app and already submitted to AR. primaryApp:'+primaryApp);
                    result = new ResultWrapper();
                    result.status = STATUS_ERROR;
                    result.message = TOAST_MESSAGE_ONLINE_APP_ALREADY_SUBMITTED;
                    system.debug(PREFIX+'prevalidateAccount(): ERROR - result='+result.status+':'+result.message);
                    return JSON.serialize(result);
                }
                


            } else {
                // If here, means that no FLeet Application was marked as the primary application
                system.debug(PREFIX+'ERROR! there is NO primary application. primaryApp:'+primaryApp);
                result = new ResultWrapper();
                result.status = STATUS_ERROR;
                result.message = TOAST_MESSAGE_NO_PRIMARY_APPLICATIONS;
                system.debug(PREFIX+'prevalidateAccount(): ERROR - result='+result.status+':'+result.message);
                return JSON.serialize(result);
            }

        } else {
            system.debug(PREFIX+'prevalidateAccount(): ERROR account has no related Fleet_Application__c');
            result = new ResultWrapper();
            result.status = STATUS_ERROR;
            result.message = TOAST_MESSAGE_NO_APPLICATION;
            system.debug(PREFIX+'prevalidateAccount(): ERROR - result='+result.status+':'+result.message);
            return JSON.serialize(result);
        }

        //return error response if there is no "draft" Fleet_Attachment__c with a file attachment
        system.debug(PREFIX+'     hasApplicationFileAttached = '+hasApplicationFileAttached);
        if (!hasApplicationFileAttached) {
            result = new ResultWrapper();
            result.status = STATUS_ERROR;
            result.message = TOAST_MESSAGE_NO_ATTACHMENT;
            system.debug(PREFIX+'prevalidateAccount(): ERROR - result='+result.status+':'+result.message);
            return JSON.serialize(result);
        }

        //if we made it here, then Account is valid for AR Notification
        result = new ResultWrapper();
        result.status = STATUS_SUCCESS;
        system.debug(PREFIX+'prevalidateAccount():SUCCESS!!!');
        return JSON.serialize(result);     
    }

    // get all Fleet_App_Attachment__c for the Fleet App, if there are any, and make sure all Fleet_App_Attachment__c have a file attached
    public static boolean doAllAppAttachmentsHaveFileAttached(Id primaryAppId) {
        system.debug(PREFIX+'doAllAppAttachmentsHaveFileAttached() ENTRY - primaryAppId='+primaryAppId);
        Boolean allAppAttachmentsHaveFiles = true;

        //query any Fleet_App_Attachment__c attachments related to the Fleet_Application__c
        List<Fleet_App_Attachment__c> attachments = [SELECT Id, Attachment_Type__c FROM Fleet_App_Attachment__c WHERE Fleet_Application__c = :primaryAppId];
        system.debug(PREFIX+'     Retrieved Fleet_App_Attachment__c attachments for applcation.Id='+primaryAppId + ', attachments:' + attachments);

        if (attachments != null && attachments.size() > 0) {

            for (Fleet_App_Attachment__c attachment: attachments) {
                system.debug(PREFIX+'     IN LOOP after Fleet_App_Attachment__c SOQL - attachment:'+attachment);
                List<ContentDocumentLink> docs = [SELECT ContentDocumentID, LinkedEntity.Name, ContentDocument.Title FROM   ContentDocumentLink WHERE  LinkedEntityId = :attachment.Id ];
                
                if (docs != null && docs.size() > 0) {
                    //Fleet_App_Attachment__c does have an attachment
                    system.debug(PREFIX+'     IN ContentDocumentLink FILES LOOP - Application Attachment EXISTS!');
                    allAppAttachmentsHaveFiles = true;

                } else {
                    
                    //Fleet_App_Attachment__c does NOT have an attachment
                    system.debug(PREFIX+'     IN ContentDocumentLink FILES LOOP - Application Attachment DOES NOT EXIST!');
                    allAppAttachmentsHaveFiles = false;
                    break;
                }
            }
        } else {
            system.debug(PREFIX+'   Fllet Application has no related Fleet_App_Attachment__c');
        }

        system.debug(PREFIX+'doAllAppAttachmentsHaveFileAttached() EXIT - allAppAttachmentsHaveFiles='+allAppAttachmentsHaveFiles);
        return allAppAttachmentsHaveFiles;
    }

    public class ResultWrapper {
        public string recordId;
        public string message;
        public string status; // 'success' or 'error'
    }
}