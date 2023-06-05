// - Forced to set SeeAllData=true in order to access email templates to test sending application emails,
// -- however other than email templates, all other test data used in this test class is created in this test class
@isTest(SeeAllData=true)
private class Fleet_SendApplicationControllerTest {
    private static void createTestClassData() {
        
        Account acc = new Account(
            Name='Test Account',
            Fleet_Account_Status__c='Prospect'
        );
        insert acc;

        Contact c = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example',
            AccountId = acc.Id
        );
        insert c;
        
        acc.Fleet_Primary_Contact__c = c.Id;
        update acc;

        List<String> oppStagesList = getOppStages();
        String firstOppStage = (oppStagesList.size() > 0) ? oppStagesList[0] : '2. Qualify the Target';

        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            Fleet_Primary_Contact__c = c.Id,
            AccountId=acc.Id,
            CloseDate=System.Today(),
            StageName=firstOppStage,
            Fleet_Reg_Corp_Location__c='Alabama',State__c='Alabama'
        );
        insert opp;


        Fleet_Email_Settings__c settings = Fleet_Email_Settings__c.getOrgDefaults();

        // default email settings
        settings.Fleet_ApplicationReplyToEmail__c = 'ar@discounttire.com';
        settings.Fleet_SenderDisplayName__c = 'Fleet';
        settings.System_To_Reply_Email__c = 'DT_fleet@discounttire.com';
        
        //From Emails - (May need to modify emails based on OWA. From email should match OWA)
        settings.Fleet_CreditAppAcceptFromEmail__c = 'DT_Fleet@discounttire.com.test';
        settings.Credit_App_Accept_From_Email_AT__c = 'AT_Fleet@discounttire.com.test';
        settings.Fleet_CreditAppWelcomeFromEmail__c = 'DT_Fleet@discounttire.com';
        settings.Credit_App_Welcome_From_Email_AT__c = 'AT_Fleet@discounttire.com';
        settings.Fleet_CreditAppDeclinedFromEmail__c = 'gail.baker@discounttire.com';
        settings.Fleet_CashAppWelcomeFromEmail__c = 'DT_Fleet@discounttire.com';
        settings.Cash_App_Welcome_From_Email_AT__c = 'AT_Fleet@discounttire.com';        
        // BCC emails
        settings.Fleet_CreditAppAcceptBccEmails__c = 'AR@discountttire.com';
        settings.Fleet_CreditAppDeclinedBccEmails__c = 'AR@discountttire.com';
        settings.Fleet_CreditAppWelcomeBccEmails__c = 'AR@discountttire.com';
        settings.Fleet_CashAppWelcomeBccEmails__c = 'AR@discountttire.com';
        // CHANGE following CC email to AR_creditapp@discounttire.com for Stage org
        settings.Fleet_Application_AR_CC__c = 'AR_app@discounttire.com'; 
        
        // Email Templates
        settings.Fleet_AccountApplicationReceivedTemplate__c = 'Fleet_Account_Application_received';
        settings.Fleet_Account_Application_Received_AT__c = 'Fleet_Account_Application_Received_AT';
        settings.Fleet_AdditionalCommentsName__c = 'Additional Comments:';
        settings.Fleet_CashApplicationEmailName__c = 'Fleet_Cash_AR_Application_and_Sales_Tax_Exemption_Certificate_s_Email';
        settings.FleetCashApplicationEmailTemplateNameAT__c = 'Fleet_Cash_AR_Application_and_Sales_Tax_Exemption_Certificate_s_Email_AT';            
        settings.Fleet_CashOnlineApplicationEmailName__c = 'Fleet_Online_Non_Credit_Application_Email';
        settings.Fleet_OnlineCashApp_EmailTemplate_AT__c = 'Fleet_Online_Non_Credit_Application_Email_AT';
        settings.Fleet_CommunityAccountInvitationTemplate__c = 'Fleet_Community_Account_Invitation';
        settings.Fleet_CreditApplicationAcceptedEmail__c = 'Fleet_Credit_Application_Accepted';
        settings.Fleet_CreditApplicationAcceptedEmail_AT__c = 'Fleet_Credit_Application_Accepted_AT';
        settings.Fleet_CreditApplicationDeclinedEmail__c = 'Fleet_Credit_Application_Declined';
        settings.Fleet_CreditApplicationDeclinedEmail_AT__c = 'Fleet_Credit_Application_Declined_New_AT';
        settings.Fleet_CreditApplicationEmailName__c = 'Fleet_Credit_AR_Application_and_Sales_Tax_Exemption_Certificate_s_Email';
        settings.FleetCreditAppEmailTemplateName_AT__c = 'Fleet_Cash_AR_Application_and_Sales_Tax_Exemption_Certificate_s_Email_AT';
        settings.Fleet_CreditOnlineApplicationEmailName__c = 'Fleet_Online_Credit_Application_Email';
        settings.FleetOnline_Credit_App_Email_Template_AT__c = 'Fleet_Online_Credit_Application_Email_AT';
        settings.Fleet_CustomerRqstForAcctChangesTemplate__c = 'Fleet_Customer_Request_For_Account_Changes';
        settings.Fleet_CustomerRqstAcctChangeTemplate_AT__c = 'Fleet_Customer_Request_For_Account_Changes_AT';
        settings.Fleet_WelcomeCashAppAcceptedEmail__c = 'Fleet_Welcome_Cash_Application_Accepted';
        settings.Fleet_WelcomeCashAppAcceptedEmail_AT__c = 'Fleet_Welcome_Cash_Application_Accepted_AT';
        settings.Fleet_WelcomeCreditAppAcceptedEmail__c = 'Fleet_Welcome_Credit_Application_Accepted';
		settings.Fleet_WelcomeCreditAppAcceptedEmail_AT__c = 'Fleet_Welcome_Credit_Application_Accepted_AT';
        upsert settings;

        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'testuser', Email='fleetuser@discounttire.test', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = profile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='fleetuser@discounttire.test');
        insert u;

        insertDocumentsFromCustomMetadata();
    }

    public static void insertDocumentsFromCustomMetadata() {
        List<Fleet_ApplicationAttachmentSettings__mdt> attachmentSettingsList = [select 
            Document_Name__c, Id, IsActive__c, State__c 
                from Fleet_ApplicationAttachmentSettings__mdt
                where 
                //State__c IN :selectedStateNames AND 
                IsActive__c = true AND Document_Name__c != null];

        //Set<String> documentUniqueNameSet = new Set<String>();
        for (Fleet_ApplicationAttachmentSettings__mdt attachmentSetting : attachmentSettingsList) {
            //documentUniqueNameSet.add(attachmentSetting.Document_Name__c+'test');
            Document document = new Document();
            document.Body = Blob.valueOf('Some Text');
            document.ContentType = 'application/pdf';
            document.DeveloperName = attachmentSetting.Document_Name__c+'test';
            document.IsPublic = true;
            document.Name = attachmentSetting.State__c;

            List<Folder> folderIds = [select id from folder where name = 'Sales Tax Exemption Certificates'];

            document.FolderId = folderIds.get(0).Id;
            insert document;
        }
        //List<Document> documentList = [select Id from Document where DeveloperName IN :documentUniqueNameSet];
    }

    public static List<String> getOppStages(){
        List<String> pickListValuesList= new List<String>();
         Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
         List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
         for( Schema.PicklistEntry pickListVal : ple){
             pickListValuesList.add(pickListVal.getLabel());
         }     
         return pickListValuesList;
     }
     public static List<String> getOppTaxStates(){
        List<String> pickListValuesList= new List<String>();
         Schema.DescribeFieldResult fieldResult = Opportunity.Tax_Form_State__c.getDescribe();
         List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
         for( Schema.PicklistEntry pickListVal : ple){
             pickListValuesList.add(pickListVal.getLabel());
         }     
         return pickListValuesList;
     }

     static testMethod void testPrevalidateOpportunity() {

        createTestClassData();

        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opportunity'];


        Test.startTest();
        String resultWrapperString = Fleet_SendApplicationController.prevalidateOpportunity(opp.Id);
        Fleet_SendApplicationController.ResultWrapper resultWrapper = (Fleet_SendApplicationController.ResultWrapper) JSON.deserialize(resultWrapperString, Fleet_SendApplicationController.ResultWrapper.Class);
        Test.stopTest();

        System.assertEquals(opp.Id, resultWrapper.recordId);
        System.assertEquals('Success', resultWrapper.status);
    }

    static testMethod void testPrevalidateOpportunityInvalid() {

        createTestClassData();

        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opportunity'];

        Test.startTest();
        String resultWrapperString = Fleet_SendApplicationController.prevalidateOpportunity('');
        Fleet_SendApplicationController.ResultWrapper resultWrapper = (Fleet_SendApplicationController.ResultWrapper) JSON.deserialize(resultWrapperString, Fleet_SendApplicationController.ResultWrapper.Class);
        Test.stopTest();

        System.assertEquals('', resultWrapper.recordId);
        System.assertEquals('Error', resultWrapper.status);
        System.assert(resultWrapper.message.contains('Invalid Opportunity'));
    }

    static testMethod void testPrevalidateOpportunityUserNotOwner() {

        createTestClassData();

        User u = [SELECT Id FROM User where Email = 'fleetuser@discounttire.test'];
        
        Opportunity opp = [SELECT Id, StageName, OwnerId FROM Opportunity WHERE Name = 'Test Opportunity'];
        opp.OwnerId = u.Id;
        update opp;

        Test.startTest();
        String resultWrapperString = Fleet_SendApplicationController.prevalidateOpportunity(opp.Id);
        Fleet_SendApplicationController.ResultWrapper resultWrapper = (Fleet_SendApplicationController.ResultWrapper) JSON.deserialize(resultWrapperString, Fleet_SendApplicationController.ResultWrapper.Class);
        Test.stopTest();

        System.assertEquals(opp.Id, resultWrapper.recordId);
        System.assertEquals('Error', resultWrapper.status);
        System.assert(resultWrapper.message.contains('Only the Opportunity Owner can complete this function'));
    }

    static testMethod void testPrevalidateOpportunityInvalidStage() {

        createTestClassData();

        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opportunity'];
        opp.StageName = 'Closed Won';
        update opp;

        Test.startTest();
        String resultWrapperString = Fleet_SendApplicationController.prevalidateOpportunity(opp.Id);
        Fleet_SendApplicationController.ResultWrapper resultWrapper = (Fleet_SendApplicationController.ResultWrapper) JSON.deserialize(resultWrapperString, Fleet_SendApplicationController.ResultWrapper.Class);
        Test.stopTest();

        System.assertEquals(opp.Id, resultWrapper.recordId);
        //System.assertEquals('Error', resultWrapper.status);
        //System.assert(resultWrapper.message.contains('Opportunity must be any Stage 2-6 to proceed'));
    }

    static testMethod void testSendCustomerApplicationWithoutTaxExemptionForms(){

        createTestClassData();

        Opportunity opp = [SELECT Id, StageName, Fleet_Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity'];
        opp.Application_Type__c = Fleet_Values.FLEET_APPLICATION_TYPE_CREDIT;
        update opp;

        test.startTest();
        
        String resultWrapperString = Fleet_SendApplicationController.sendCustomerApplication(opp.Id, JSON.serialize(opp), Fleet_Values.FLEET_APP_FORMAT_ONLINE);
        Fleet_SendApplicationController.ResultWrapper resultWrapper = (Fleet_SendApplicationController.ResultWrapper) JSON.deserialize(resultWrapperString, Fleet_SendApplicationController.ResultWrapper.Class);
        test.stopTest();
        System.debug('testSendCustomerApplicationWithoutTaxExemptionForms() - send app result wrapper: ' + resultWrapperString);
        System.assert(resultWrapper.status.equals(Fleet_SendApplicationController.STATUS_SUCCESS) || 
            (resultWrapper.status.equals(Fleet_SendApplicationController.STATUS_EXCEPTION) && resultWrapper.message.contains('NO_MASS_MAIL_PERMISSION')));
    }

    static testMethod void testSendCustomerApplicationWithAllTaxExemptionForms(){

        createTestClassData();

        Opportunity opp = [SELECT Id, StageName, Fleet_Primary_Contact__c, Tax_Form_State__c FROM Opportunity WHERE Name = 'Test Opportunity'];
        List<String> oppTaxStatesList = getOppTaxStates();
        String selectedStates = '';
        for (String state : oppTaxStatesList) selectedStates = selectedStates + state + ';';
        opp.Tax_Form_State__c = selectedStates;
        opp.Application_Type__c = Fleet_Values.FLEET_APPLICATION_TYPE_CREDIT;
        update opp;

        test.startTest();
        
        String resultWrapperString = Fleet_SendApplicationController.sendCustomerApplication(opp.Id, JSON.serialize(opp), Fleet_Values.FLEET_APP_FORMAT_PDF);
        Fleet_SendApplicationController.ResultWrapper resultWrapper = (Fleet_SendApplicationController.ResultWrapper) JSON.deserialize(resultWrapperString, Fleet_SendApplicationController.ResultWrapper.Class);
        test.stopTest();
        System.debug('send app result wrapper: ' + resultWrapperString);
        System.assert(resultWrapper.status.equals(Fleet_SendApplicationController.STATUS_SUCCESS) || 
            (resultWrapper.status.equals(Fleet_SendApplicationController.STATUS_EXCEPTION) && resultWrapper.message.contains('NO_MASS_MAIL_PERMISSION')));
    }

    /**static testMethod void testBuildCustomerEmailCredit() {
        Opportunity opp = [SELECT Id, StageName, Fleet_Primary_Contact__c, Tax_Form_State__c, Application_Type__c FROM Opportunity WHERE Name = 'Test Opportunity'];
        opp.Application_Type__c = Fleet_Values.FLEET_APPLICATION_TYPE_CREDIT;
        update opp;
        
        test.startTest();
        Fleet_SendApplicationController.buildAndSendCustomerApplicationEmail(opp, new Fleet_Application__c());
        test.stopTest();

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        String templateName = emailSettings.Fleet_CreditApplicationEmailName__c;
        EmailTemplate template = [select Id, HtmlValue, Body, Subject from EmailTemplate where DeveloperName = :templateName];
        String replyTo = emailSettings.Fleet_ApplicationReplyToEmail__c;
        String senderDisplayName = emailSettings.Fleet_SenderDisplayName__c;

        //System.assertEquals(opp.Id, mail.whatid);
        System.assertNotEquals(null, template);
        //System.assertEquals(template.Id, mail.templateid);
        //System.assertEquals(replyTo, mail.getReplyTo());
        //System.assertEquals(senderDisplayName, mail.getSenderDisplayName());
        //System.assertEquals(opp.Fleet_Primary_Contact__c, mail.targetobjectid);
    }

    static testMethod void testBuildCustomerEmailNonCredit() {
        Opportunity opp = [SELECT Id, StageName, Fleet_Primary_Contact__c, Tax_Form_State__c, Application_Type__c FROM Opportunity WHERE Name = 'Test Opportunity'];
        opp.Application_Type__c = Fleet_Values.FLEET_APPLICATION_TYPE_CASH;
        update opp;
        
        test.startTest();
        Fleet_SendApplicationController.buildAndSendCustomerApplicationEmail(opp, new Fleet_Application__c());
        test.stopTest();

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        String templateName = emailSettings.Fleet_CashApplicationEmailName__c;
        EmailTemplate template = [select Id, HtmlValue, Body, Subject from EmailTemplate where DeveloperName = :templateName];
        String replyTo = emailSettings.Fleet_ApplicationReplyToEmail__c;
        String senderDisplayName = emailSettings.Fleet_SenderDisplayName__c;

        System.assertEquals(opp.Id, mail.whatid);
        System.assertNotEquals(null, template);
        System.assertEquals(template.Id, mail.templateid);
        System.assertEquals(replyTo, mail.getReplyTo());
        System.assertEquals(senderDisplayName, mail.getSenderDisplayName());
        System.assertEquals(opp.Fleet_Primary_Contact__c, mail.targetobjectid);
    }

    static testMethod void testSendEmailToClientInvalid() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        test.startTest();
        Fleet_SendApplicationController.ResultWrapper resultWrapper = Fleet_SendApplicationController.sendEmailToCustomer(mail);
        test.stopTest();

        System.assertEquals(Fleet_SendApplicationController.STATUS_EXCEPTION, resultWrapper.status);
    }

    static testMethod void testAddAttachmentsToEmail() {
        Opportunity opp = [SELECT Id, StageName, Fleet_Primary_Contact__c, Tax_Form_State__c, Application_Type__c FROM Opportunity WHERE Name = 'Test Opportunity'];
        opp.Application_Type__c = Fleet_Values.FLEET_APPLICATION_TYPE_CREDIT;
        List<String> oppTaxStatesList = getOppTaxStates();
        String selectedStates = '';
        for (String state : oppTaxStatesList) selectedStates = selectedStates + state + ';';
        opp.Tax_Form_State__c = selectedStates;
        update opp;
        
        Fleet_SendApplicationController.buildAndSendCustomerApplicationEmail(opp, new Fleet_Application__c());

        test.startTest();
        Messaging.SingleEmailMessage mailWithAttachments = Fleet_SendApplicationController.addAttachmentsToEmail(opp, mail);
        test.stopTest();

        List<Fleet_ApplicationAttachmentSettings__mdt> attachmentSettingsList = [select 
                    Document_Name__c, Id, IsActive__c, State__c 
                from Fleet_ApplicationAttachmentSettings__mdt
                where State__c IN :oppTaxStatesList AND IsActive__c = true AND Document_Name__c != null];

        System.assertEquals(attachmentSettingsList.size(), oppTaxStatesList.size(), 'Fleet_ApplicationAttachmentSettings are not properly configured for all Tax Form States. Update the settings or deactivate unused values.');
        System.assertEquals(oppTaxStatesList.size(), mailWithAttachments.getEntityAttachments().size(), 'Fleet_ApplicationAttachmentSettings are not properly configured with a valid "Document" file. Update the settings or deactivate unsed values.');
    }**/

}