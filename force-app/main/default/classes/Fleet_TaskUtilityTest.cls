@isTest (seeAllData = false)
private class Fleet_TaskUtilityTest {

    @TestSetup
    static void createTestClassData() {
        User testUser1 = new User();
        testUser1.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Fleet Sales User'].Id;
        testUser1.FirstName = 'firstName';
        testUser1.LastName = 'lastName';
        testUser1.Email = 'test1@test.com';
        testUser1.Username = 'test1@test.com' + System.currentTimeMillis();
        testUser1.CompanyName = 'TEST';
        testUser1.Title = 'title';
        testUser1.Alias = 'ali11';
        testUser1.TimeZoneSidKey = 'America/Los_Angeles';
        testUser1.EmailEncodingKey = 'UTF-8';
        testUser1.LanguageLocaleKey = 'en_US';
        testUser1.LocaleSidKey = 'en_US';
        testUser1.Fleet_Is_Specialist__c=true;

        insert testUser1;
       // [SELECT id, Active__c, End__c,Name, Start__c  FROM  WHERE Active__c = true AND Start__c >= TODAY])
        StoreHolidays__c california = new StoreHolidays__c();
        california.Active__c = true;
        california.Name = 'California';
        california.Start__c=system.now().adddays(2);
        insert california;
        StoreHolidays__c california1 = new StoreHolidays__c();
        california1.Active__c = true;
        california1.Name = 'California';
        california1.Start__c=system.now().adddays(1);
        insert california1;
        StoreHolidays__c california2 = new StoreHolidays__c();
        california2.Active__c = true;
        california2.Name = 'California';
        california2.Start__c=system.now();
        insert california2;

    }
  static testMethod void testTaskUtility() {
        system.debug('testTriggerHandler() ENTRY -----------');
        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        list<id> acclist = new list<id>();
        User firstUser = [SELECT Id FROM User WHERE Alias = 'ali11'];
        system.debug('   firstUser='+firstUser);
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
            RecordTypeId = b2bRT,
            Fleet_Specialist__c= firstUser.id
                                
        );
        insert testAcct1 ;
        acclist.add(testacct1.id);
           
        test.startTest();
        //Fleet_TaskUtility.handleaccount(acclist);
        for(integer i=0; i<6 ; i++)
        {
          Fleet_TaskUtility.checktodayday(i);
          Fleet_TaskUtility.handleaccount(acclist);
         }
        test.stopTest();
         
    }
}