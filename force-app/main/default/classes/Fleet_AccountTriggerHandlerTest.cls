/**
 Modified By : Ritika Sharma	
 Modified Date :  3/13/2023
 User Story Number : Salesforce-842.
**/
@isTest
public class Fleet_AccountTriggerHandlerTest {

    @TestSetup
    static void setupData(){
        List<Account> testAcctList = new List<Account> ();

        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Fleet Sales User' ];
        System.debug('number of Profiles: ' + profileList.size());

        List<Fleet_Settings__mdt> fleetSettingList = [SELECT DeveloperName, Value__c FROM Fleet_Settings__mdt];
        System.debug('number of Fleet Settings: ' + fleetSettingList.size()); // visible

        List<RecordType> rtList = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'B2B'];
        System.debug('number of RecordType: ' + rtList.size());

        User testUser = new User (
            Username = 'wstor@ethos.com.dt.fleetdev2',
            LastName = 'Stor',
            FirstName = 'William',
            Email = 'apex+wstorr@ethos.com',
            EmailPreferencesAutoBcc = true,
            EmailPreferencesAutoBccStayInTouch = false,
            EmailPreferencesStayInTouchReminder = true,
            ProfileId = profileList[0].Id,
            Phone = '(602) 123-4567',
            Alias = 'wstr',
            CommunityNickname = 'User15960418108414009002',
            IsActive = true,
            TimeZoneSidKey = 'America/Phoenix',
            LocaleSidKey = 'en_US',
            ReceivesInfoEmails = true,
            ReceivesAdminInfoEmails = true,
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            UserPreferencesActivityRemindersPopup = true,
            UserPreferencesEventRemindersCheckboxDefault = true,
            UserPreferencesTaskRemindersCheckboxDefault = true,
            UserPreferencesDisableLikeEmail = true,
            UserPreferencesSortFeedByComment = true,
            UserPreferencesShowTitleToExternalUsers = true,
            UserPreferencesHideS1BrowserUI = true,
            UserPreferencesPathAssistantCollapsed = true,
            UserPreferencesLightningExperiencePreferred = true,
            UserPreferencesHideSfxWelcomeMat = true,
            DigestFrequency = 'D',
            DefaultGroupNotificationFrequency = 'N',
            Fleet_ECC_Key__c = '09',
            Fleet_Specialist_Assignment_Group__c = '1-50',
            Fleet_Is_Specialist__c = true
        );

        insert testUser;

        Account testAcct1 = new Account (
            Name = 'ENTERPRISE FLEET SVCS',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            ShippingStreet = '9315 OLIVE BLVD',
            ShippingCity = 'SAINT LOUIS',
            ShippingState = 'Missouri',
            ShippingPostalCode = '63132-3211',
            ShippingCountry = 'United States',
            ShippingStateCode = null,
            ShippingCountryCode = 'US',
            Phone = '800-325-8838',
            Fleet_Account_Status__c = 'Customer',
            SAP_Created_Date__c = Date.today(),
            RecordTypeId = rtList[0].Id,
            Fleet_Use_Certificates__c = true,
            Fleet_Specialist__c = testUser.Id,
            Fleet_POS_Notes__c = '**PLEASE FOLLOW ALL OPERATIONAL BEST PRACTICES AND PROCESSES WHEN USING AUTO INTEGRATE**',
            Credit_Limit__c = 999999,
            Accounting_Clerk__c = '04',
            Payment_Type__c = 'AR CHARGE',
            Tax_Classification__c = 'Taxable',
            Payment_Key_Terms__c = 'Due 15th of Following Month',
            PO_Required__c = true,
            Account_Type__c = 'FMC',
            ECC_AutoIntegrate__c = 'Yes',
            ECC_Corporate_Group__c = 'DT FLEET CHARGE ACCOUNTS',
            ECC_Industry_Key__c = 'Fleet Companies',
            ECC_Account_Manager__c = '03',
            ECC_Country__c = 'USA',
            ECC_State__c = 'MO',
            ECC_Account_Company__c = 'FLEET'                        
        );
        testAcctList.add(testAcct1);
        

        // Type = Credit ... 56%
        // Type = Non-Credit ... 70%
        //  without 56%

        Account testAcct2 = new Account (
            Name = 'Sams Solutions'
        );
        testAcctList.add(testAcct2);
        //testAcctList.add(testAct);       
        insert testAcctList;
    }
	
    static testmethod void test1()
    {
        Fleet_AccountTriggerHandler fATH = new Fleet_AccountTriggerHandler();
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Fleet Sales User' ];
        
        List<Fleet_Settings__mdt> fleetSettingList = [SELECT DeveloperName, Value__c FROM Fleet_Settings__mdt];
        
        List<RecordType> rtList = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'B2B'];
        
        User testUser = new User (
            Username = 'test@ethos.com.dt.fleetdev2',
            LastName = 'testLN',
            FirstName = 'testFN',
            Email = 'test+wstorr@ethos.com',
            EmailPreferencesAutoBcc = true,
            EmailPreferencesAutoBccStayInTouch = false,
            EmailPreferencesStayInTouchReminder = true,
            ProfileId = profileList[0].Id,
            Phone = '(602) 123-4567',
            Alias = 'wstr',
            CommunityNickname = 'User15960418108414009004',
            IsActive = true,
            TimeZoneSidKey = 'America/Phoenix',
            LocaleSidKey = 'en_US',
            ReceivesInfoEmails = true,
            ReceivesAdminInfoEmails = true,
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            UserPreferencesActivityRemindersPopup = true,
            UserPreferencesEventRemindersCheckboxDefault = true,
            UserPreferencesTaskRemindersCheckboxDefault = true,
            UserPreferencesDisableLikeEmail = true,
            UserPreferencesSortFeedByComment = true,
            UserPreferencesShowTitleToExternalUsers = true,
            UserPreferencesHideS1BrowserUI = true,
            UserPreferencesPathAssistantCollapsed = true,
            UserPreferencesLightningExperiencePreferred = true,
            UserPreferencesHideSfxWelcomeMat = true,
            DigestFrequency = 'D',
            DefaultGroupNotificationFrequency = 'N',
            Fleet_ECC_Key__c = '09',
            Fleet_Specialist_Assignment_Group__c = '1-50',
            Fleet_Is_Specialist__c = true
        );

        insert testUser;

        Account testAcct = new Account (
            Name = 'ENTERPRISE FLEET SVCS test',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            ShippingStreet = '9315 OLIVE BLVD',
            ShippingCity = 'SAINT LOUIS',
            ShippingState = 'Missouri',
            ShippingPostalCode = '63132-3211',
            ShippingCountry = 'United States',
            ShippingStateCode = null,
            ShippingCountryCode = 'US',
            Phone = '800-325-8838',
            Fleet_Account_Status__c = 'Customer',
            SAP_Created_Date__c = Date.today(),
            RecordTypeId = rtList[0].Id,
            Fleet_Use_Certificates__c = true,
            Fleet_Specialist__c = testUser.Id,
            Fleet_POS_Notes__c = '**PLEASE FOLLOW ALL OPERATIONAL BEST PRACTICES AND PROCESSES WHEN USING AUTO INTEGRATE**',
            Credit_Limit__c = 999999,
            Accounting_Clerk__c = '04',
            Payment_Type__c = 'AR CHARGE',
            Tax_Classification__c = 'Taxable',
            Payment_Key_Terms__c = 'Due 15th of Following Month',
            PO_Required__c = true,
            Account_Type__c = 'FMC',
            ECC_AutoIntegrate__c = 'Yes',
            ECC_Corporate_Group__c = 'DT FLEET CHARGE ACCOUNTS',
            ECC_Industry_Key__c = 'Fleet Companies',
            ECC_Account_Manager__c = '03',
            ECC_Country__c = 'USA',
            ECC_State__c = 'MO',
            ECC_Account_Company__c = 'FLEET'                        
        );
        
        insert testAcct;
        Contact objCon = New Contact();
		objCon.LastName = 'Test';
		objCon.Email = 'test@test.com';
		objCon.AccountId =   testAcct.Id;
        Insert objCon;
		List<Account> acctList = [select Id, Name, Fleet_Use_Certificates__c,Fleet_Primary_Contact__c, Invoice_Copy_Sent__c, Fleet_Specialist__c, Fleet_Public_Notes__c, Fleet_AR_App_Status__c, ECC_Account_Number__c, Fleet_Private_Notes__c, Fleet_Application_Type__c,Phone,Phone_Extension__c from Account where id= :testAcct.id];
        acctList[0].Fleet_Use_Certificates__c = false;
        acctList[0].ECC_Account_Number__c = '29894';
        acctList[0].Fleet_Application_Type__c = 'Non-Credit';
        acctList[0].Fleet_Primary_Contact__c = objCon.Id;
        acctList[0].Fleet_Public_Notes__c = 'Public Note #1 Test  Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test';
    
        //List<Account> acctList = [SELECT Id, Name, ECC_Account_Number__c, Invoice_Copy_Sent__c,Fleet_Use_Certificates__c, Fleet_Specialist__c, Fleet_AR_App_Status__c, Fleet_Application_Type__c, Fleet_Public_Notes__c, Fleet_Private_Notes__c FROM Account];

        // after update only 
        // Fleet_AccountTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType);
  
                
		Test.startTest();
        //acclist1.add(testAct);
        update acctList[0];
        Test.stopTest();
        


        // orphan method, so I called it here
        Fleet_AccountTriggerHandler.sendOutboundForAccountECCSynch( acctList[0] );

        List<Int_Message__c> msgList = [SELECT Id, OwnerId, IsDeleted, Name, Object_Type__c, Payload__c, RecordId__c, Submitted_Date__c, Status__c, Type__c, URL__c, Age_In_Minutes__c FROM Int_Message__c];
        System.debug('number of Messages: ' + msgList.size());

        for(Int_Message__c msg:  msgList) {
            System.debug('msg: ' + msg);
            System.debug('message type: ' + msg.Type__c);
            //System.assertEquals('ECC_OUTBOUND_ACCOUNT', msg.Type__c, 'Message type is incorrect');
            System.debug('message RecordId: ' + msg.RecordId__c);
            //System.assertEquals(acctList[0].Id, msg.RecordId__c, 'Account Id incorrect');
        }
        //System.assertEquals(2, msgList.size(), 'Incorrect number of emails sent out');
		
        Fleet_AccountTriggerHandler.updatePublicNotes(acctList);
     }
     
    @isTest
    public static void checkForNonCreditCommunityUsersTest(){
        Fleet_AccountTriggerHandler fATH = new Fleet_AccountTriggerHandler();
        List<RecordType> rtList = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'B2B'];
        list<account> acclist2 = new list<account>();
        DateTime dT = system.now();
        Date todayDate = date.newinstance(dT.year(), dT.month(), dT.day());
        // added as part of SF-842
        Account acct = new Account(
        	  Name = 'ENTERPRISE FLEET',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            ShippingStreet = '9315 OLIVE BLVD',
            ShippingCity = 'SAINT LOUIS',
            ShippingState = 'Missouri',
            ShippingPostalCode = '63132-3211',
            ShippingCountry = 'United States',
            ShippingStateCode = null,
            ShippingCountryCode = 'US',
            Phone = '800-325-8838',
            Fleet_Account_Status__c = 'Pending Additional Information',
            Fleet_AR_App_Status__c ='Pending Additional Information',
            Fleet_Application_Type__c = 'Credit',
            Fleet_Pending_Additional_Info_Date__c= todayDate,
            RecordTypeId = rtList[0].Id
        );       
        insert acct;
          Account acctt = new Account(
        	Name = 'ENTERPRISE FLEET SVCS',            
            RecordTypeId = rtList[0].Id,            
            Fleet_Application_Type__c = 'Non-Credit'
        );       
        insert acctt;
      
        list<account> acclist1 = new list<account>();
        Account testAct = new Account (
            Name = 'ENTERPRISE FLEET',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            ShippingStreet = '9315 OLIVE BLVD',
            ShippingCity = 'SAINT LOUIS',
            ShippingState = 'Missouri',
            ShippingPostalCode = '63132-3211',
            ShippingCountry = 'United States',
            ShippingStateCode = null,
            ShippingCountryCode = 'US',
            Phone = '800-325-8838',
            Fleet_Account_Status__c = 'Pending Additional Information',
            Fleet_AR_App_Status__c ='Pending Additional Information',
            Fleet_Application_Type__c = 'Non-Credit',
            Fleet_Pending_Additional_Info_Date__c= todayDate,
            RecordTypeId = rtList[0].Id
           );
        
         insert testAct;
         testAct.Fleet_Days_Until_Decline__c=8;
         update testAct;
        //acclist1.add(testAct);
        acclist1 = [Select id, Fleet_Account_Status__c, Fleet_AR_App_Status__c,Fleet_Pending_Additional_Info_Date__c, Fleet_Application_Type__c,Fleet_Days_until_Decline__c,Fleet_Credit_App_Status__c,Fleet_NonCredit_App_Status__c from Account where Fleet_AR_App_Status__c ='Pending Additional Information' and  id= :testAct.id];
        acclist2 = [Select id, Fleet_Account_Status__c, Fleet_AR_App_Status__c,Fleet_Pending_Additional_Info_Date__c, Fleet_Application_Type__c,Fleet_Days_until_Decline__c,Fleet_Credit_App_Status__c,Fleet_NonCredit_App_Status__c from Account where Fleet_AR_App_Status__c ='Pending Additional Information' and  id= :acct.id];
             
    //Test.startTest();
        
        //Test.stopTest();
        Map<id, Account> oldMap = new Map<id, Account>();     
        oldMap.put(acctt.id, acctt);
        
        Test.startTest();
        update accList1[0];
        update accList2[0];
        Fleet_AccountTriggerHandler.checkForNonCreditCommunityUsers(oldMap, oldMap);
       // Fleet_AccountTriggerHandler.handle(oldMap, oldMap, System.TriggerOperation.BEFORE_INSERT);
        Fleet_AccountTriggerHandler.handle(New List<Account>{acct},oldMap, oldMap, System.TriggerOperation.BEFORE_INSERT);
        Fleet_AccountTriggerHandler.countNoOfDays(acclist1);
        Fleet_AccountTriggerHandler.countNoOfDays(acclist2);
        Fleet_AccountTriggerHandler.handleDeclinedAccounts(acclist1);
        Test.stopTest();
                
    }

    @isTest
    public static void sendOutboundForAccountECCSynchTest(){
        Fleet_AccountTriggerHandler fATH = new Fleet_AccountTriggerHandler();
        List<Account> acctList = [SELECT Id, Name, ECC_Account_Number__c, Invoice_Copy_Sent__c,Fleet_Use_Certificates__c, Fleet_Specialist__c,Fleet_Application_Type__c, Fleet_Public_Notes__c, Fleet_Private_Notes__c,Phone,Phone_Extension__c FROM Account];
   		 Test.startTest();
        Fleet_AccountTriggerHandler.sendOutboundForAccountECCSynch(acctList[0]);
        //Fleet_AccountTriggerHandler.countNoOfDays(acctList);
         Test.stopTest();  
    }
    
    @isTest
    public static void processContactCommunityUsersTest(){
        Fleet_AccountTriggerHandler fATH = new Fleet_AccountTriggerHandler();
        List<RecordType> rtList = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'B2B'];
        
        Account acct = new Account(
        	Name = 'ENTERPRISE FLEET SVCS',            
            RecordTypeId = rtList[0].Id,            
            Fleet_Application_Type__c = 'Non-Credit'
            
        );       
        insert acct;
        Map<id, Account> oldMap = new Map<id, Account>();  
        Set<id> sendEmailAccountIdList = new Set<id>();
        sendEmailAccountIdList.add(acct.id);
        oldMap.put(acct.id, acct);
        
         Test.startTest();
        Fleet_AccountEmailUtil.updateApprovalEmailSentFlag(sendEmailAccountIdList);
        Fleet_AccountTriggerHandler.processContactCommunityUsers(oldMap, oldMap, sendEmailAccountIdList);
        Test.stopTest(); 
        
        
    }
        
    
}