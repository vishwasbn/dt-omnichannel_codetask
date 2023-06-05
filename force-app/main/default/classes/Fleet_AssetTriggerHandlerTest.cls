@isTest
public class Fleet_AssetTriggerHandlerTest
{

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
        insert testAcctList;
    }

    static testmethod void test1()
    {
        List<Account> acctList = [SELECT Id, Name, ECC_Account_Number__c, Invoice_Copy_Sent__c, Fleet_Specialist__c, Fleet_Public_Notes__c, Fleet_Private_Notes__c FROM Account];
        Account selAccount = acctList[0];

        Id vehicleRT = Schema.Sobjecttype.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();

        Test.startTest();

        Asset newAsset = new Asset();
        newAsset.AccountId = selAccount.Id;
        newAsset.Name = 'Test';
        newAsset.Vehicle_Type_Other__c = 'Commercial';
        insert newAsset;

        Asset newAsset2 = new Asset();
        newAsset2.AccountId = selAccount.Id;
        newAsset2.Name = 'Test';
        insert newAsset2;

        newAsset2.Vehicle_Type_Other__c = 'Commercial';
        update newAsset2;

        List<Asset> checkList = [SELECT Id, Name, Vehicle_Number__c FROM Asset];
    
        Test.stopTest();
    }
}