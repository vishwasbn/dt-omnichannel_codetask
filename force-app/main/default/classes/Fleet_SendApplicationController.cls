public with sharing class Fleet_SendApplicationController {
    public static String lprefix = 'FLEET_SENDAPP:';
    public final static String STATUS_SUCCESS = 'Success';
    public final static String STATUS_ERROR = 'Error';
    public final static String STATUS_EXCEPTION = 'Exception';
    public static final String ATTACHMENT_STATUS_DRAFT = 'Draft';
    public static final String ATTACHMENT_TYPE_TAX = 'State Resale Forms';
    public final static String ATTACHMENT_APPLICATION_TYPE_CREDIT = 'Credit Application';
    public final static String ATTACHMENT_APPLICATION_TYPE_CASH = 'Non-Credit Application';
  //Vaneet : Changes 'Closed Won' to 'Closed Won - 100%' and 'Closed Lost' to 'Closed Lost - 0%' (INC1312053)
  //public final static String OPP_STAGE_CLOSED_WON = 'Closed Won';
  //public final static String OPP_STAGE_CLOSED_LOST = 'Closed Lost';
    public final static String OPP_STAGE_CLOSED_WON = 'Closed Won - 100%';
    public final static String OPP_STAGE_CLOSED_LOST = 'Closed Lost - 0%';
    

    @AuraEnabled
    public static String sendCustomerApplication(String recordId, String fields, String applicationFormat){
        System.debug(lprefix+'sendCustomerApplication() ENTRY - recordId=' + recordId + ', applicationFormat=' + applicationFormat);

        // 1. deserialize results;
        Opportunity opp = (Opportunity) JSON.deserialize(fields, Opportunity.class);
        opp.Id = recordId;
        opp.Fleet_Application_Format__c = applicationFormat;

        Opportunity existingOpp = [SELECT Id, OwnerId, StageName, AccountId, Fleet_Application_Format__c, Customer_Type__c, 
                                    Fleet_Primary_Contact__c, Application_Type__c, Fleet_Send_Application_Comments__c 
                                    FROM Opportunity WHERE Id = :recordId];

        // 2. validate opportunity
        ResultWrapper result = validateOpportunity(existingOpp);
        if (result.status == STATUS_ERROR) return JSON.serialize(result);

        // 2a. Retrieve the Account as will be needed later, and will also be updated along with Opportunity - DTFS-441
        Account acnt = [SELECT Id, Name, Fleet_Customer_Type__c, Fleet_Primary_Contact__c, Fleet_Application_Type__c FROM Account WHERE Id = :existingOpp.AccountId];
        System.debug(lprefix+'   retrieved account: ' + acnt);

        // 3. Create Fleet_Application__c object and if necessary Fleet_App_Attachment__c objects (DTFS-345)
        //  If Application Format = PDF Forms, create application and app attachment, before emailing PDF forms in next step. (DTFS-392)
        //  If Application Format = Online, ceate application for online application, before sending email with URL to online application
        Fleet_Application__c app;
        if (applicationFormat == Fleet_Values.FLEET_APP_FORMAT_PDF) {
            System.debug(lprefix+'   Format PDF: Creating Fleet_Application__c application and Fleet_App_Attachment records for accountId= ' + existingOpp.AccountId);
            app = createFleetPDFApplicationAndAttachments(opp, acnt);
        } else {
            System.debug(lprefix+'   Format ONLINE: Creating online Fleet_Application__c application record for accountId= ' + existingOpp.AccountId);
            app = createOnlineFleetApplication(opp, acnt);
        }

        // 4. build and send email (Online or PDF Forms App Email, each email has type for Credit or Non-Credit)
        buildAndSendCustomerApplicationEmail(opp.Id, app.Id);

        // 5. Update Opportunity upon success
        Logger logInstance = Logger.getInstance();
		logInstance.log('Send Application', 'Fleet_SendApplicationController', 'Before Opportunity updated');

        Opportunity oppToUpdate = new Opportunity(
            Id = existingOpp.Id,
            Fleet_Last_Application_Sent_Date__c = System.Today(),
            Fleet_Application_Format__c = applicationFormat,
            Customer_Type__c = opp.Customer_Type__c,
            Fleet_Primary_Contact__c = opp.Fleet_Primary_Contact__c,
            Application_Type__c = opp.Application_Type__c,
            Fleet_Send_Application_Comments__c = opp.Fleet_Send_Application_Comments__c
        );
        
        update opptoUpdate;
        logInstance.log('Send Application', 'Fleet_SendApplicationController', 'After Opportunity updated', JSON.serialize(opptoUpdate));
        System.debug(lprefix+'   Updated Opportunity opptoUpdate:' + opptoUpdate);

        // 6. Update the Account - DTFS-441 - since trigger is supressed, perform the same function, which is to update Account with cooresponding fields from Opportunity
        logInstance.log('Send Application', 'Fleet_SendApplicationController', 'Before Account updated');
        acnt.Fleet_Customer_Type__c = opp.Customer_Type__c;
        acnt.Fleet_Primary_Contact__c = opp.Fleet_Primary_Contact__c;
        acnt.Fleet_Application_Type__c = opp.Application_Type__c;

        update acnt;
        logInstance.log('Send Application', 'Fleet_SendApplicationController', 'After Account updated', JSON.serialize(acnt));
        System.debug(lprefix+'   Updated Account acnt:' + acnt);

        
        result.status=STATUS_SUCCESS;
        result.message='Success';
        result.recordId = recordId;
        
        System.debug(lprefix+'sendCustomerApplication() EXIT - result:' + result);
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static string prevalidateOpportunity(String opportunityId){
        System.debug(lprefix+'prevalidateOpportunity() Entry - opportunityId=' + opportunityId);

        Opportunity opp = null;
        if (opportunityId != null && opportunityId != '') {
            opp = [SELECT Id, Name, StageName, OwnerId, Fleet_Application_Format__c FROM Opportunity WHERE Id = :opportunityId];
        }

        if (opp == null) {
            ResultWrapper result = new ResultWrapper();
            result.recordId = opportunityId;
            result.status = 'Error';
            result.message = 'Invalid Opportunity Id: ' + opportunityId + '. No Opportunity record found.';
            return JSON.serialize(result);
        }

        //validate and then return serialized Opportunity
        System.debug(lprefix+'prevalidateOpportunity() EXIT');
        return JSON.serialize(validateOpportunity(opp));
    }

    public static ResultWrapper validateOpportunity(Opportunity existingOpp) {
        System.debug(lprefix+'validateOpportunity() ENTRY - existingOpp:' + existingOpp);
        ResultWrapper result = new ResultWrapper();
        result.recordId = existingOpp.Id;
        result.appFormat = existingOpp.Fleet_Application_Format__c;

        if (existingOpp.OwnerId == null) { 
            result.status = 'Error';
            result.message = 'There was an error processing this Opportunity - please refresh the page and try again.';
            return result;
        }
        if (UserInfo.getUserId() != existingOpp.OwnerId) {
            result.status = 'Error';
            result.message = 'Only the Opportunity Owner can complete this function.';
            return result;
        }
        if (existingOpp.StageName != null && (existingOpp.StageName.equals(OPP_STAGE_CLOSED_WON) || existingOpp.StageName.equals(OPP_STAGE_CLOSED_LOST))) {
            result.status = 'Error';
            result.message = 'Opportunity must be any Stage 2-6 to proceed.';
            return result;
        }
        
        result.status = 'Success';
        System.debug(lprefix+'validateOpportunity() EXIT - result:' + result);
        return result;
    }

    public static Fleet_Application__c createOnlineFleetApplication(Opportunity opp, Account acnt) {
        System.debug(lprefix+'createOnlineFleetApplication() - acnt:' + acnt + ', opp:'+opp);
        Fleet_Application__c app;

        if (acnt != null) {

            // get Fleet_Application__c depending on application type
            Id appRecordType; 
            if (opp.Application_Type__c == Fleet_Values.FLEET_APPLICATION_TYPE_CREDIT) {
                appRecordType = Schema.SObjectType.Fleet_Application__c.getRecordTypeInfosByName().get(Fleet_Values.APPLICATION_RECORD_TYPE_CREDIT).getRecordTypeId();
            } else {
                appRecordType = Schema.SObjectType.Fleet_Application__c.getRecordTypeInfosByName().get(Fleet_Values.APPLICATION_RECORD_TYPE_NONCREDIT).getRecordTypeId();
            }
            System.debug(lprefix+'  Fleet_Application__c record type Id for app type [' + opp.Application_Type__c + '] is recordTypeId:'+appRecordType);

            if (acnt != null && opp != null) {
                //1. create Fleet Application record
                Logger logInstance = Logger.getInstance();
				logInstance.log('Send Application', 'Fleet_SendApplicationController', 'Before Fleet_Application__c insert');
                app = new Fleet_Application__c(Parent_Account__c = acnt.Id, RecordTypeId = appRecordType);
                app.Application_Type__c = opp.Application_Type__c;
                app.Attachment_Status__c = ATTACHMENT_STATUS_DRAFT;
                app.Name = produceObjectName( 'Fleet_Application__c', acnt.Name, ' - ' + opp.Application_Type__c ); // acnt.Name + ' - ' + opp.Application_Type__c;
                app.Fleet_Application_Format__c = Fleet_Values.FLEET_APP_FORMAT_ONLINE;
                app.Application_GUID__c = createGUID();
                app.Fleet_Online_Application_URL__c = getOnlineApplicationURL(app);

                //set as primary application, a trigger will make sure others are not primary
                app.Is_Primary_Application__c = true;
                
                insert app;
                logInstance.log('Send Application', 'Fleet_SendApplicationController', 'After Fleet_Application__c insert', JSON.serialize(app));
                System.debug(lprefix+'    INSERTED PRIMARY Fleet_Application__c:' + app);

                //save online application URL on Opportunity
                System.debug(lprefix+'    ABOUT TO update Fleet_Online_Application_URL__c:');
                logInstance.log('Send Application', 'Fleet_SendApplicationController', 'Before Opportunity updated');
                Opportunity oppWithUrl = new Opportunity(Id = opp.Id, Fleet_Online_Application_URL__c = app.Fleet_Online_Application_URL__c);
                update oppWithUrl;
                logInstance.log('Send Application', 'Fleet_SendApplicationController', 'after Opportunity updated',JSON.serialize(oppWithUrl));
                System.debug(lprefix+'    updated Fleet_Online_Application_URL__c on Opportunity:' + oppWithUrl);


            }
        }
        System.debug(lprefix+'createOnlineFleetApplication() EXIT -  inserted and returning ONLINE APP Fleet_Application__c record:' + app);
        return app;
    }    

    public static Fleet_Application__c createFleetPDFApplicationAndAttachments(Opportunity opp, Account acnt) {
        System.debug(lprefix+'createFleetPDFApplicationAndAttachments() - acnt:' + acnt + ', opp:'+opp);

        Id appRecordType = Schema.SObjectType.Fleet_Application__c.getRecordTypeInfosByName().get(Fleet_Values.APPLICATION_RECORD_PDF_FORMS).getRecordTypeId();
        Logger logInstance = Logger.getInstance();
        logInstance.log('Send Application', 'Fleet_SendApplicationController', 'Before Fleet_Application__c insert');
        Fleet_Application__c app;

        if (acnt != null && opp != null) {
            //1. create Fleet Application record
            app = new Fleet_Application__c(Parent_Account__c = acnt.Id, RecordTypeId = appRecordType);
            app.Application_Type__c = opp.Application_Type__c;
            app.Attachment_Status__c = ATTACHMENT_STATUS_DRAFT;
            app.Name = produceObjectName( 'Fleet_Application__c', acnt.Name, ' - ' + opp.Application_Type__c ); // acnt.Name + ' - ' + opp.Application_Type__c;
            app.Fleet_Application_Format__c = Fleet_Values.FLEET_APP_FORMAT_PDF;

            //set as primary application, a trigger will make sure others are not primary
            app.Is_Primary_Application__c = true;

            insert app;
            
			logInstance.log('Send Application', 'Fleet_SendApplicationController', 'After Fleet_Application__c insert', JSON.serialize(app));
            System.debug(lprefix+'    inserted PRIMARY Fleet_Application__c:' + app);

            //2. Create Fleet App Attachment for Application, either Credit or non-credit
            logInstance.log('Send Application', 'Fleet_SendApplicationController', 'Before Fleet_App_Attachment__c insert');
            Fleet_App_Attachment__c appAttachment = new Fleet_App_Attachment__c(Fleet_Application__c=app.Id, Parent_Account__c = acnt.Id);
            appAttachment.Name  = produceObjectName( 'Fleet_App_Attachment__c', acnt.Name, ' ' + opp.Application_Type__c + ' Application' ); //  acnt.Name + ' ' + opp.Application_Type__c + ' Application';
            if (opp.Application_Type__c == Fleet_Values.FLEET_APPLICATION_TYPE_CASH) {
                appAttachment.Attachment_Type__c = ATTACHMENT_APPLICATION_TYPE_CASH;
            } else {
                appAttachment.Attachment_Type__c = ATTACHMENT_APPLICATION_TYPE_CREDIT;
            }
            appAttachment.Description__c = 'This Fleet Application Attachment record was created for the ' + appAttachment.Attachment_Type__c + ' to be uploaded within.';
            insert appAttachment;
            logInstance.log('Send Application', 'Fleet_SendApplicationController', 'After Fleet_App_Attachment__c insert', JSON.serialize(appAttachment));
            System.debug(lprefix+'createFleetPDFApplicationAndAttachments() EXIT -  inserted application attachment:' + appAttachment);
        }
        
        System.debug(lprefix+'createFleetPDFApplicationAndAttachments() EXIT -  returning app:' + app);
        return app;
    }

    //DTFS-392 - Standalone method to Build and send 'Online' or 'PDF Forms' Application emails based on Application Format radio button selected by agent.
    @future(callout=true)
    public static void buildAndSendCustomerApplicationEmail(Id oppId, Id appId) {
        System.debug(lprefix+'buildAndSendCustomerApplicationEmail() ENTRY -  oppId=' + oppId + ', appId=' + appId);

        Opportunity opp = [SELECT Id, Name, Application_Type__c,Account.ShippingPostalcode,Account.AT_Customer__c,Account.DT_Customer__c, Fleet_Primary_Contact__c FROM Opportunity WHERE Id = :oppId];
        System.debug(lprefix+'     retrieved opp:' + opp);

        Fleet_Application__c app = [SELECT Id, Name, Fleet_Application_Format__c FROM Fleet_Application__c WHERE Id = :appId];
        System.debug(lprefix+'     retrieved app:' + app);

        // get contact email address from Primary Contact
        Contact c = [select Id, Name, Email from Contact where Id = :opp.Fleet_Primary_Contact__c];
        String toAddress = c.Email; // query email from opp contact
        System.debug(lprefix+'     toAddress = ' + toAddress);

        //---Get email settings
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        System.debug(lprefix+'     emailSettings: ' + emailSettings);

        // get 1 of 4 potential template Name/ Id from custom setting, depending on App Format (Online or PDF Forms) as well as Opp App type (Credit or non-credit)
        String templateNameAT;
        String templateNameDT;
        Map<String,EmailTemplate> mapTemplateList = new Map<String,EmailTemplate>();
        if (app.Fleet_Application_Format__c == Fleet_Values.FLEET_APP_FORMAT_PDF ) {
            if(opp.Account.AT_Customer__c)
              templateNameAT = (opp.Application_Type__c == Fleet_Values.FLEET_APPLICATION_TYPE_CASH) ? emailSettings.FleetCashApplicationEmailTemplateNameAT__c : emailSettings.FleetCreditAppEmailTemplateName_AT__c;
            else
                templateNameDT = (opp.Application_Type__c == Fleet_Values.FLEET_APPLICATION_TYPE_CASH) ? emailSettings.Fleet_CashApplicationEmailName__c : emailSettings.Fleet_CreditApplicationEmailName__c;
        } else {
            if(opp.Account.AT_Customer__c)
              templateNameAT = (opp.Application_Type__c == Fleet_Values.FLEET_APPLICATION_TYPE_CASH) ? emailSettings.Fleet_OnlineCashApp_EmailTemplate_AT__c : emailSettings.FleetOnline_Credit_App_Email_Template_AT__c;
            else
                templateNameDT = (opp.Application_Type__c == Fleet_Values.FLEET_APPLICATION_TYPE_CASH) ? emailSettings.Fleet_CashOnlineApplicationEmailName__c : emailSettings.Fleet_CreditOnlineApplicationEmailName__c;
        }
        System.debug(lprefix+'     Application Format = ' + app.Fleet_Application_Format__c + ', therefore email templateName = ' + templateNameAT+'=='+templateNameDT);
        for(EmailTemplate emailtemplate : [SELECT Id,Name,DeveloperName from EmailTemplate WHERE DeveloperName = :templateNameDT OR DeveloperName = :templateNameAT]){
            mapTemplateList.put(emailtemplate.DeveloperName,emailtemplate);
        }
       // EmailTemplate templateAT = [select Id, HtmlValue, Body, Subject from EmailTemplate where DeveloperName = :templateName];
        if (templateNameAT == null && templateNameDT ==null) throw new AuraHandledException('   WARNING! - Email template not found');

        Id userId = UserInfo.getUserId();
        List<User> userList = [ SELECT Id, Name, Email FROM User WHERE Id =: userId];
        if ((userList == null) || (userList.size() < 1)) throw new AuraHandledException('   WARNING! - User not found');

        String replyTo = userList[0].Email;
        System.debug(lprefix+'     replyTo= ' + replyTo);
        String senderDisplayName = userList[0].Name;
        System.debug(lprefix+'     senderDisplayName= ' + senderDisplayName);
        String ccFleetAREmail = emailSettings.Fleet_Application_AR_CC__c;
        System.debug(lprefix+'     ccFleetAREmail= ' + ccFleetAREmail);


        // get TOADDRESSES
        String[] toAddresses = new String[]{};
        toAddresses.add(toAddress);

        // get CCAdresses
        String[] ccAddresses = new String[]{};
        if (!String.isBlank(ccFleetAREmail)) ccAddresses.add(ccFleetAREmail);



        // Build and send email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setReplyTo(replyTo);
        //mail.setCcAddresses(ccAddresses); //-- commented out for DTFS-737
        mail.setSenderDisplayName(senderDisplayName);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setSaveAsActivity(true);
        mail.setWhatId(opp.Id);
        if(templateNameDT!= null && mapTemplateList.containsKey(templateNameDT))
          mail.setTemplateId(mapTemplateList.get(templateNameDT).Id);
        else if(templateNameAT != null && mapTemplateList.containsKey(templateNameAT))
          mail.setTemplateId(mapTemplateList.get(templateNameAT).Id);
        mail.setTargetObjectId(opp.Fleet_Primary_Contact__c); 

        /*if (app.Fleet_Application_Format__c == Fleet_Values.FLEET_APP_FORMAT_PDF) {
            //only add PDF attachments if app format is 'PDF Forms'
            mail = addAttachmentsToEmail(opp, mail);
        }*/

        // send email
        sendEmailToCustomer(mail);
    }

    /*public static Messaging.SingleEmailMessage addAttachmentsToEmail(Opportunity opp, Messaging.SingleEmailMessage email) {
        System.debug(lprefix+'addAttachmentsToEmail() ENTRY - opp: ' + opp);
        
        //DTFS-392 - User no longer selected Tax State PDFs to attach, instead attach all Tax State Forms to email. 
        //  Setting for the list of Tax Form States is in Fleet Setting (Custom Metadata)
        List<String> selectedStateNames = Fleet_SettingUtil.getSettingValue(Fleet_Values.SETTING_FLEET_TAX_FORM_ATTACHMENT_STATES).split(';');
        System.debug(lprefix+'     list of States with Tax Forms that will be attached to email: ' + selectedStateNames);

        // custom metadata
        List<Fleet_ApplicationAttachmentSettings__mdt> attachmentSettingsList = [select 
                    Document_Name__c, Id, IsActive__c, State__c 
                from Fleet_ApplicationAttachmentSettings__mdt
                where State__c IN :selectedStateNames AND IsActive__c = true AND Document_Name__c != null];
        //System.debug(lprefix+'List of custom metadata records: ' + attachmentSettingsList.size());

        if (attachmentSettingsList.size() > 0 && (attachmentSettingsList.size() != selectedStateNames.size())) System.debug('throw an exception here - mismatch of selected states and custom metadata found');
        
        Set<String> documentUniqueNameSet = new Set<String>();
        for (Fleet_ApplicationAttachmentSettings__mdt attachmentSetting : attachmentSettingsList) {
            documentUniqueNameSet.add(attachmentSetting.Document_Name__c);
            if(Test.isRunningTest()) documentUniqueNameSet.add(attachmentSetting.Document_Name__c+'test'); // add additional names for test code
        }
        //System.debug(lprefix+'Set of Unique Document Names: ' + documentUniqueNameSet);

        
        String[] documentIds = new String[]{};
        for (Document docId : [select Id from Document where DeveloperName IN :documentUniqueNameSet]) {
            documentIds.add(docId.Id);
        }
        //System.debug(lprefix+'Documents found: ' + documentIds.size());
        
        email.setEntityAttachments(documentIds); /// content version
        System.debug(lprefix+'addAttachmentsToEmail() EXIT - email: ' + email);
        return email;
    }*/
    
    public static ResultWrapper sendEmailToCustomer(Messaging.SingleEmailMessage email) {
        System.debug(lprefix+'sendEmailToCustomer() ENTRY - email: ' + email);

        ResultWrapper emailResult = new ResultWrapper();
        try {
            Messaging.SendEmailResult[] result =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug(lprefix+'    Email Result: ' + result.toString());

            if (result.get(0).isSuccess()) {
                emailResult.status = STATUS_SUCCESS;
                emailResult.message = 'Email Successfully Sent!';
                System.debug(lprefix+'    Email Successfully Sent!');
            }
            else {
                emailResult.status = STATUS_ERROR;
                emailResult.message = JSON.serialize(result.get(0).getErrors());
                System.debug(lprefix+'    Email NOT Successfully Sent! - ' + result.get(0).getErrors());
            }

        } catch (exception e) {
            emailResult.status = STATUS_EXCEPTION;
            emailResult.message = e.getMessage();
            Logger logInstance = Logger.getInstance();			
			logInstance.log('Send Application', 'Fleet_SendApplicationController', e);
            System.debug(lprefix+'    EXCEPTION CAUGHT e.getMessage() =  ' + e.getMessage() + ', e:' + e);
            System.debug(lprefix+'       stacktrace:' + e.getStackTraceString());
            
        }
        System.debug(lprefix+'sendEmailToCustomer() EXIT - emailResult:' + emailResult);
        return emailResult;
    }

    //build the URL for online credit or non-credit application with GUID on query string 
    public static String getOnlineApplicationURL(Fleet_Application__c application) {
        System.debug(lprefix+'getOnlineApplicationURL() ENTRY - application: ' + application);
        String url;

        if (application != null && String.isNotBlank(application.Application_Type__c)) {
            
            //build base URL
            url = Fleet_SettingUtil.getSettingValue(Fleet_Values.SETTING_FLEET_COMMUNITY_URL);
            
            System.debug(lprefix+'     building url for Application_Type__c=' + application.Application_Type__c);
            if (application.Application_Type__c == Fleet_Values.FLEET_APPLICATION_TYPE_CREDIT) {
                url += Fleet_Values.FLEET_ONLINE_APP_URL_CREDIT;
            } else {
                url += Fleet_Values.FLEET_ONLINE_APP_URL_NONCREDIT;
            }
            System.debug(lprefix+'     base URL =' + url);
            System.debug(lprefix+'     GUID =' + application.Application_GUID__c);

            //add query string containing GUID param
            url += '?' + Fleet_Values.FLEET_ONLINE_APP_URL_GUID_PARAM + '=' + application.Application_GUID__c;
        }
        System.debug(lprefix+'getOnlineApplicationURL() EXIT - return url with GUID: ' + url);
        return url;
    }

    public static String createGUID() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,16);
        System.debug(lprefix+'createGUID() EXIT with return GUID=' + guid);
        return guid;
    }

    public class ResultWrapper{
        public String recordId;
        public String message;
        public String status; // 'success' or 'error'
        public String appFormat;

        public ResultWrapper() {}
    }


    @AuraEnabled
    public static Account retrieveExistingApplicationsForAccount(Id oppId){

        Account acc = [SELECT Id, Number_of_Fleet_Applications__c, Number_of_Online_Credit_Applications__c, 
        Number_of_Online_Non_Credit_Applications__c, Number_of_PDF_Credit_Applications__C, Number_of_PDF_Non_Credit_Applications__c FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity
        WHERE Id=:oppId) LIMIT 1];

        return acc;
    }

    // This method produces the Fleet Application Name by taking the Account name and truncating off the end
    //    so the suffix will fit in the Name field.  It is also used on the Fleet_App_Attachment__c
    // WARNING: the suffix cannot be greater than half-ish the Name field length
    private static String produceObjectName (String srcObject, String fullPrefix, String suffixString)
    {
        // get the Fleet_Application__c :: Name field length 
        Schema.SObjectType targetObject = Schema.getGlobalDescribe().get(srcObject);
        DescribeSObjectResult objDesc = targetObject.getDescribe();
        DescribeFieldResult fldDesc = objDesc.fields.getMap().get('Name').getDescribe();
        Integer faNameLength = fldDesc.getLength();
        System.debug('Type Length: ' + faNameLength);
        
        // subtract the size of the suffix string from the size of the Name
        System.debug('Suffix: ' + suffixString + ' : ' + suffixString.length());
        Integer prefixSize = faNameLength - suffixString.length();
        // truncate off the end of the Name that won't fit
        String prefixString = fullPrefix.left(prefixSize);
        System.debug('Prefix: ' + prefixString + ' : ' + prefixString.length());
        
        // concatenate the prefix and suffix
        String result = prefixString + suffixString;
        System.debug('Result: ' + result + ' : ' + result.length());
        return result;
    }
    
}