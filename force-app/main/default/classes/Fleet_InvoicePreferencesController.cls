public class Fleet_InvoicePreferencesController {
    public static final String lprefix = 'LOG Fleet_IPC';
    public static final String CASE_STATUS_NEW = 'New';
    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String CHATTER_GROUP = 'AR Notification Chatter Group';
   
    // Get account Id
    @AuraEnabled
    public static String getAccountId(){   

        try{
            User newUser = [SELECT id, accountId FROM USER WHERE id = :UserInfo.getUserId()];
            return newUser.accountId;
        } catch (Exception e) {
             Logger logInstance = Logger.getInstance();
            logInstance.log('Invoice Preferences', 'Fleet_InvoicePreferencesController', e);
            System.debug(e.getStackTraceString());
        }        
        return 'No id found';
    }

    // Find invoice preferences for this account and return them as a map to the LWC
    @AuraEnabled
    public static Map<String, Boolean> handleGetInvoicePreferences(String accountId) {

        // Initialize all preferences as false
        System.debug('Get Invoice Preferences List');
        Map<String, Boolean> preferenceList = new Map<String, Boolean>();
        preferenceList.put('driverName', false);
        preferenceList.put('companyName', false);
        preferenceList.put('streetAddress', false);
        preferenceList.put('city', false);
        preferenceList.put('state', false);
        preferenceList.put('zip', false);
        preferenceList.put('vehicleMake', false);
        preferenceList.put('vehicleYear', false);
        preferenceList.put('vehicleModel', false);
        preferenceList.put('licensePlate', false);
        preferenceList.put('vin', false);
        preferenceList.put('mileage', false);
        preferenceList.put('stockNumber', false);
        preferenceList.put('unitNumber', false);
        preferenceList.put('idJobNumber', false);  
        preferenceList.put('cardExpDate', false);  
        preferenceList.put('licensePlateState', false);  
        preferenceList.put('fleetNumber', false);  
        preferenceList.put('fleetCardNumber', false);  
        preferenceList.put('driversLicense', false);       
        
        try{

            // Get Account ID and account preferences
            User currentUser = [SELECT id, accountId FROM USER WHERE id = :UserInfo.getUserId()];    
            Account accountPreferences = [SELECT Fleet_Invoice_AR_Fields__c FROM ACCOUNT WHERE id = :currentUser.accountId];
            String invoicePrefString = accountPreferences.Fleet_Invoice_AR_Fields__c;

            // Deserialze invoice preferences JSON Object
            Fleet_B2BCustomerModel model = Fleet_B2BCustomerModel.getDeserializedARFields(invoicePrefString);

            // Update Map with selected preferences for this account
            for (Fleet_B2BCustomerModel.InvoiceARRequiredFields iRow : model.invoiceARRequiredFields)
            {
                if(iRow.characteristicValueDescriptioinCAWNT == 'DRIVER NAME'){preferenceList.put('driverName', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'COMPANY NAME'){preferenceList.put('companyName', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'STREET ADDRESS'){preferenceList.put('streetAddress', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'CITY'){preferenceList.put('city', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'STATE'){preferenceList.put('state', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'ZIP'){preferenceList.put('zip', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'VEHICLE MAKE'){preferenceList.put('vehicleMake', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'VEHICLE YEAR'){preferenceList.put('vehicleYear', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'VEHICLE MODEL'){preferenceList.put('vehicleModel', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'LICENSE PLATE #'){preferenceList.put('licensePlate', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'VIN #'){preferenceList.put('vin', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'MILEAGE'){preferenceList.put('mileage', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'STOCK #'){preferenceList.put('stockNumber', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'UNIT #'){preferenceList.put('unitNumber', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'ID/JOB #'){preferenceList.put('idJobNumber', true);}                
                if(iRow.characteristicValueDescriptioinCAWNT == 'CARD EXP DT'){preferenceList.put('cardExpDate', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'LIC PLATE STATE'){preferenceList.put('licensePlateState', true);}                
                if(iRow.characteristicValueDescriptioinCAWNT == 'FLEET #'){preferenceList.put('fleetNumber', true);}                       
                if(iRow.characteristicValueDescriptioinCAWNT == 'FLEET CARD #'){preferenceList.put('fleetCardNumber', true);}
                if(iRow.characteristicValueDescriptioinCAWNT == 'DRIVERS LICENSE'){preferenceList.put('driversLicense', true);}
            }           
        } catch(Exception e){
            Logger logInstance = Logger.getInstance();
            logInstance.log('Invoice Preferences', 'Fleet_InvoicePreferencesController', e);
            System.debug(e.getStackTraceString());
        }     
        // Return account preferences          
        return preferenceList;
    }

    // Create Case 
    @AuraEnabled
    public static String handleInvoicePreferencesChangeRequest(String description, String subject) {        
        System.debug(lprefix + 'HANDLE INVOICE PREFERENCES CHANGE REQUEST');
        String emailMessageType;  
        // get account / contact from current user
        try{

            User currentUser = [SELECT id, ContactId, accountId FROM USER WHERE id = :UserInfo.getUserId()];    
            Account getAcct = [SELECT id, OwnerId, Fleet_Specialist__c,ShippingPostalcode,AT_Customer__c,DT_Customer__c, ECC_Account_Number__c, Name FROM ACCOUNT WHERE id = :currentUser.accountId];
            Contact userContact = [SELECT id, Email FROM Contact WHERE id = :currentUser.ContactId];
            id fleetSpecialistId = getAcct.Fleet_Specialist__c;
            id salesforceAcctId = getAcct.Id;
            String sapId = getAcct.ECC_Account_Number__c;
            String acctName = getAcct.Name;
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

            id arQueueId;
            List<Group> caseQueus = [SELECT id, Name from Group WHERE Type = 'Queue' and Name = 'AR Group Queue'];
            if(caseQueus.size() > 0) {
                arQueueId = caseQueus[0].id;
            }


            Case caseResult = newAction.submitCase(currentUser, description, subject, CASE_STATUS_NEW, CASE_ORIGIN_WEB, arQueueId);
            System.debug('Case Result: '+caseResult);
            id caseId = caseResult.id;

            // create task and chatter notification
            Boolean chatterFlag = true;
            Task returnTask = newAction.createTask((arQueueId != null ? arQueueId : fleetSpecialistId), description, subject, sapId, salesforceAcctId, fleetuser, chatterFlag);

            id arGroupId;
            List<CollaborationGroup> chatterGroups = [SELECT Id, Name from CollaborationGroup ];
            System.debug('chatter group:'+chatterGroups);
            if(chatterGroups.size() > 0) {
                System.debug(chatterGroups[0]);
                arGroupId = chatterGroups[0].id;
            }
            System.debug('AR Group ID---------------' + arGroupId);
            String chatterPostResult = newAction.postToChatter(arGroupId,subject,caseId, '@AR Notification', acctName);
            System.debug(chatterPostResult);

            // email settings
            Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
            if (emailSettings == null) System.debug('FLEET_EMAIL_SETTINGS__C MUST BE CONFIGURED TO SEND EMAILS');
            String returnMessage;
            // Send Email Notificaiton  string messageSubject, String messageType, String toAddress, String templateName, id accountId, String fromAddress, id contactId
            if(getAcct.AT_Customer__c)
                returnMessage = newAction.sendEmailNotificaiton(subject, emailMessageType, userEmail, emailSettings.Fleet_CustomerRqstAcctChangeTemplate_AT__c, caseId, emailSettings.System_To_Reply_Email__c, fleetuser);
            else
                returnMessage = newAction.sendEmailNotificaiton(subject, emailMessageType, userEmail, emailSettings.Fleet_CustomerRqstForAcctChangesTemplate__c, caseId, emailSettings.System_To_Reply_Email__c, fleetuser);
            System.debug('Email Message: ' + returnMessage);         
            
            if (caseResult == null) {
                return 'Probably an error inserting the case or the user doesnt have a valid contact/account Id';
            }
            return 'success';

        }catch(Exception e){
            Logger logInstance = Logger.getInstance();
            logInstance.log('Invoice Preferences', 'Fleet_InvoicePreferencesController', e);
            throw new AuraHandledException('An error occurred while trying to create the preference change request.');            
        }
        
    }   
   
}