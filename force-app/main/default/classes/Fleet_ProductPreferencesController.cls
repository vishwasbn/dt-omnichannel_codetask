public with sharing class Fleet_ProductPreferencesController {
    public static final String lprefix = 'LOG Fleet_IPC';
    public static final String CASE_STATUS_NEW = 'New';
    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String CHATTER_GROUP = 'AR Notification Chatter Group';
    
    // Get Account Id Method
    @AuraEnabled
    public static String getAccountId(){           

        try{
            User newUser = [SELECT id, accountId FROM USER WHERE id = :UserInfo.getUserId()];
            return newUser.accountId;
        } catch (Exception e) {
            System.debug(e.getStackTraceString());
        }        

        return 'No Id Found';
    }
    // Get public notes
    @AuraEnabled
    public static String handleGetPublicNotes() {

        // Sets default notes
        String publicNotes = 'No notes were found...';

        // pull in public notes from the account
        try{
            User currentUser = [SELECT id, ContactId, accountId FROM USER WHERE id = :UserInfo.getUserId()];    
            Account getAcct = [SELECT id, Fleet_Public_Notes__c FROM ACCOUNT WHERE id = :currentUser.accountId];
            publicNotes = getAcct.Fleet_Public_Notes__c;
        } catch (Exception e){
            System.debug(e.getStackTraceString());
        }

        return publicNotes;       
        
    }

    // Create Case 
    @AuraEnabled
    public static String handleProductPreferencesChangeRequest(String description, String subject) {        
        String status;  
        String emailMessageType = 'Product preference change request';     
        System.debug('description: ' + description);
        System.debug('subject: '+subject);

        try{
            
            User currentUser = [SELECT id, ContactId, accountId FROM USER WHERE id = :UserInfo.getUserId()];    
            Account getAcct = [SELECT id, OwnerId, Owner.Name, Fleet_Specialist__c, Fleet_Specialist__r.Name, ECC_Account_Number__c, Name FROM ACCOUNT WHERE id = :currentUser.accountId];
            Contact userContact = [SELECT id, Email FROM Contact WHERE id = :currentUser.ContactId];
            id fleetSpecialistId = getAcct.Fleet_Specialist__c;
            String fleetSpecialistName = getAcct.Fleet_Specialist__r.Name;
            id salesforceAcctId = getAcct.Id;
            String acctName = getAcct.Name;
            String sapId = getAcct.ECC_Account_Number__c;
            String userEmail = userContact.Email;
            id fleetuser = currentUser.ContactId;
            if(fleetSpecialistId == null){
                fleetSpecialistId = getAcct.OwnerId;
                fleetSpecialistName = getAcct.Owner.Name;
            }

            if(subject == 'ProductPreferenceChange'){
                subject = 'Product Preference Change Request';
            }

            // Check for errors with the user
            if (currentUser == null) throw new AuraHandledException('Invalid User');
            else if (currentUser.ContactId == null) throw new AuraHandledException('No Contact Record exists for the user: ' + currentUser.Name + '('+currentUser.Id+')');
            else if (currentUser.AccountId == null) throw new AuraHandledException('No Account Record exists for the user: ' + currentUser.Name + '('+currentUser.Id+')');
            

            System.debug(subject);
            System.debug(description);

            // Create object that can create a case and assign it to a user the fleet user does not have access to
            Fleet_CreateActionWithoutSharing newAction = new Fleet_CreateActionWithoutSharing(); 

            Case caseResult = new Case();
            
            if(!Test.isRunningTest())
                caseResult = newAction.submitCase(currentUser, description, subject, CASE_STATUS_NEW, CASE_ORIGIN_WEB, fleetSpecialistId);
            
            id caseId = caseResult.id;

            // create task
            Boolean chatterFlag = true;
            Task returnTask = newAction.createTask(fleetSpecialistId, description, subject, sapId, salesforceAcctId, fleetuser, chatterFlag);
            
            // create chatter post to Fleet Specialist regarding new case
            String chatterPostResult = newAction.postToChatter(fleetSpecialistId,subject,caseId, fleetSpecialistName, acctName);
            
            // email settings
            Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
            if (emailSettings == null) System.debug('FLEET_EMAIL_SETTINGS__C MUST BE CONFIGURED TO SEND EMAILS');

            // Send Email Notificaiton  string messageSubject, String messageType, String toAddress, String templateName, id accountId, String fromAddress, id contactId
            String returnMessage = newAction.sendEmailNotificaiton(subject, emailMessageType, userEmail, emailSettings.Fleet_CustomerRqstForAcctChangesTemplate__c, caseId, emailSettings.System_To_Reply_Email__c, fleetuser);
            
            // Throw error if task was not created successfully
            if (returnTask.Id == null) {
                throw new AuraHandledException('Product preference change request was not made successfully.');
            }
        } catch (DmlException e){
            // Throw error if task was not created successfully
            System.debug(e.getStackTraceString());
            throw new AuraHandledException('Product preference change request was not made successfully.');
        }
        return 'success';
    }      
}