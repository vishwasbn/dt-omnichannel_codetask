public with sharing class Fleet_SubmitSupportRequestController {
    public static final String lprefix = 'LOG Fleet_IPC';
    public static final String CASE_STATUS_NEW = 'New';
    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String CHATTER_GROUP = 'AR Notification Chatter Group';
    public static final String EMAIL_TEMPLATE_NAME = 'Communities_Preference_change_request';
    public static final String FROM_EMAIL= 'AR@discounttire.com';
       
    // Create Case 
    @AuraEnabled
    public static String handleSupportRequest(String description, String subject) {        
        System.debug(lprefix + 'HANDLE SUPPORT REQUEST');
        String emailMessageType;  
        // get account / contact from current user
        try{

            User currentUser = [SELECT id, ContactId, accountId FROM USER WHERE id = :UserInfo.getUserId()];    
            Account getAcct = [SELECT id, OwnerId, Fleet_Specialist__c, ECC_Account_Number__c FROM ACCOUNT WHERE id = :currentUser.accountId];
            Contact userContact = [SELECT id, Email FROM Contact WHERE id = :currentUser.ContactId];
            id fleetSpecialistId = getAcct.Fleet_Specialist__c;
            id salesforceAcctId = getAcct.Id;
            String sapId = getAcct.ECC_Account_Number__c;
            String userEmail = userContact.Email;
            id fleetuser = currentUser.ContactId;
            if(fleetSpecialistId == null){
                fleetSpecialistId = getAcct.OwnerId;
            }

            if(subject == 'InvoicesPreferenceChange'){
                subject = 'Invoices Preference Changee Request';
            }

            // Check for errors with the user
            if (currentUser == null) throw new AuraHandledException('Invalid User');
            else if (currentUser.ContactId == null) throw new AuraHandledException('No Contact Record exists for the user: ' + currentUser.Name + '('+currentUser.Id+')');
            else if (currentUser.AccountId == null) throw new AuraHandledException('No Account Record exists for the user: ' + currentUser.Name + '('+currentUser.Id+')');
            
            System.debug(subject);
            System.debug(description);

            // Create object that can create a case and assign it to a user the fleet user does not have access to
            Fleet_CreateActionWithoutSharing newAction = new Fleet_CreateActionWithoutSharing(); 

            Case caseResult = newAction.submitCase(currentUser, description, subject, CASE_STATUS_NEW, CASE_ORIGIN_WEB, fleetSpecialistId);
            System.debug('Case Result: '+caseResult);
            id caseId = caseResult.id;

            // create task
            Boolean chatterFlag = true;
            Task returnTask = newAction.createTask(fleetSpecialistId, description, subject, sapId, salesforceAcctId, fleetuser, chatterFlag);
                    
            // Send Email Notificaiton  string messageSubject, String messageType, String toAddress, String templateName, id accountId, String fromAddress, id contactId
            String returnMessage = newAction.sendEmailNotificaiton(subject, emailMessageType, userEmail, EMAIL_TEMPLATE_NAME, caseId, FROM_EMAIL, fleetuser);
            System.debug('Email Message: ' + returnMessage);         
            
            if (caseResult == null) {
                return 'Probably an error inserting the case or the user doesnt have a valid contact/account Id';
            }
            return 'success';

        }catch(Exception e){
            throw new AuraHandledException('An error occurred while trying to create the support request.');            
        }
        
    }  
}