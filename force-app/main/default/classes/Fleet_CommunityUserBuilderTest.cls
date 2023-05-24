@isTest
public class Fleet_CommunityUserBuilderTest {

    @TestSetup
    static void setupData()
    {
        List<Account> testAcctList = new List<Account> ();
        List<User> testUserList = new List<User>();

        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Fleet Sales User' ];
        System.debug('number of Profiles: ' + profileList.size());

        List<Fleet_Settings__mdt> fleetSettingList = [SELECT DeveloperName, Value__c FROM Fleet_Settings__mdt];
        System.debug('number of Fleet Settings: ' + fleetSettingList.size()); // visible

        List<RecordType> rtList = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'B2B'];
        System.debug('number of RecordType: ' + rtList.size());

        Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();

        System.debug('setupData Starting');

        User testUser = new User (
            Username = 'william.stor@gmail.com',
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

        testUserList.add(testUser);

        User testUser2 = new User(
            ProfileId = profileList[0].Id,
            FirstName = 'Bob',
            LastName = 'Barker',
            Email = 'Bob.Barkder@gmail.com',
            Username = 'Bob.Barkder@gmail.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            );

        testUserList.add(testUser2);

        User testUser3 = new User(
            ProfileId = profileList[0].Id,
            FirstName = 'Bob',
            LastName = 'Barker',
            Email = 'Bob.Barkder@gmail.com',
            Username = 'Bob.Barkder@gmail.com.dt2',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            );

        testUserList.add(testUser3);

        insert testUserList;

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

        List<Contact> contList = new List<Contact> ();
        
        Contact cont = new Contact();
        cont.AccountId = testAcct1.Id;
        cont.RecordTypeId = b2bRT;
        cont.FirstName = 'John';
        cont.LastName = 'Smith';
        cont.Email='john.smith@gmail.com';
        // good contact

        contList.add(cont);    

        cont = new Contact();
        cont.AccountId = testAcct1.Id;
        cont.RecordTypeId = b2bRT;
        cont.FirstName = 'William';
        cont.LastName = 'Stor';
        cont.Email='william.stor@gmail.com';
        // conflicts with existing user
    
        contList.add(cont);  
        
        cont = new Contact();
        cont.AccountId = testAcct1.Id;
        cont.RecordTypeId = b2bRT;
        cont.FirstName = 'Bob';
        cont.LastName = 'Barker';
        cont.Email='Bob.Barkder@gmail.com';
        // conflicts with existing user higher in the sequence
    
        contList.add(cont);    

        insert contList;

        System.debug('setupData Ending');
    }


    static testmethod void testDuplicateUsernames()
    {
        System.debug('testDuplicateUsernames Starting');

        // List<User> uList =  [SELECT Id, ContactId, Username, FirstName, LastName, Email, Phone FROM User ];

        // System.debug('User list: ' + uList.size());

        // List<Account> acctList = [SELECT Id, Name FROM Account];
 
        // System.debug('Account List: ' + acctList.size());
        
        Map<Id, Contact> contMap = new Map<Id, Contact> ( [SELECT Id, Email, FirstName, LastName, Phone, MobilePhone FROM Contact] );

        System.debug('Contact List: ' + contMap.size());

        Fleet_CommunityUserBuilder.convertContactToCommunityUser(contMap.keySet(), false);
        
        List<User> uAfterList =  [SELECT Id, ContactId, Username, FirstName, LastName, Email, Phone FROM User ORDER BY CreatedDate DESC, Username ASC LIMIT 3 ];
        System.debug('uAfterList[0]'+uAfterList[0].Username);
        System.debug('uAfterList[1]'+uAfterList[1].Username);
        System.debug('uAfterList[2]'+uAfterList[2].Username);
        System.assertEquals('bob.barkder@gmail.com.dt3', uAfterList[0].Username, 'Username with existing sequenced version failed');
        System.debug('testDuplicateUsernames Ending');
    }
}