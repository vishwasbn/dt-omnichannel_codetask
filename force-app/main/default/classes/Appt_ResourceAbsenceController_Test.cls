@isTest
private class Appt_ResourceAbsenceController_Test {
        
    static void setupData() {

        // setup the Account ... Territory ... Resource ... Appoitments... 
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        List<User> userList = [SELECT Id, FirstName, LastName FROM User WHERE FirstName= 'John' AND LastName = 'Smith'];
        List<ServiceTerritory> servTerrList = [SELECT Id, Name FROM ServiceTerritory];
        User resourceUser = Appt_TestUtil.getStandardUser('Bill', 'Johnson');
        ServiceResource servResource = Appt_TestUtil.getServiceResource('Resource Front', userList[0].Id , UserInfo.getUserId(), 'T', 'Front Room');
        ServiceTerritoryMember servTerritoryMember = Appt_TestUtil.getServiceTerritoryMember(servTerrList[0].Id, servResource.Id, 'P', Datetime.now().addMonths(-2));

        // create the testing date
        // it has to match up with Appt_Time_Slots so no sunday
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();

        // create a time period for the Absence... one day
        Datetime startDatetime = Datetime.newInstance(currentDate, Time.newInstance(10,0,0,0));
        Datetime endDatetime = Datetime.newInstance(currentDate, Time.newInstance(12,0,0,0));

        // create first Resource Absence for the second ServiceResource (front)
        ResourceAbsence resAbs = Appt_TestUtil.getResourceAbsence(servResource.Id, startDatetime, endDatetime);

    }

    @isTest
    static void testCreateAbsenceRecords() {
        Appt_ResourceAbsenceController_Test.setupData();
        List<Appt_ResourceAbsenceController.RAToCreateWrapper> raDataList = new List<Appt_ResourceAbsenceController.RAToCreateWrapper>();
        Appt_ResourceAbsenceController.RAToCreateWrapper raData = new Appt_ResourceAbsenceController.RAToCreateWrapper();
        raData.ServiceTeritoryId = '1'; // Add the relevant ServiceTerritory Id here
        raData.Name = [SELECT Id, Name FROM ServiceTerritory][0].Name;
        raData.StoreId = [SELECT Id, Name FROM ServiceTerritory][0].Name;
        raData.StartTime = '11:30:00.000Z';
        raData.EndTime = '18:30:00.000Z';
        raData.StoreDate = '2023-08-03T08:09:56.529Z';
        raDataList.add(raData);


        Test.startTest();
        String requestDataJSON = JSON.serialize(raDataList);
        Appt_ResourceAbsenceController.createAbsenceRecords(requestDataJSON);
        Test.stopTest();

        
        List<ServiceResource> createdServiceResources = [SELECT Id, Name, ResourceType, Type__c, RelatedRecordId, IsActive FROM ServiceResource];
        System.assertEquals(2, createdServiceResources.size()); 

       
        System.assertEquals('Resource Back', createdServiceResources[0].Name);
        System.assertEquals('T', createdServiceResources[0].ResourceType);
        System.assertEquals('Back Room', createdServiceResources[0].Type__c);
        System.assertEquals(true, createdServiceResources[0].IsActive);
    }

    @isTest
    static void testGetAllStores() {
        Appt_ResourceAbsenceController_Test.setupData();
    	//insert operating hours
        List<OperatingHours> opHrs = WOM_TestDataUtility.createOpHours(1,'Test Operating Hours');
        insert opHrs;
        //insert account of record type 'Site'
        List<Account> acct = WOM_TestDataUtility.createAccounts(1,'Test Account','Site');
        acct[0].Store_Id__c='123123';
        insert acct;
        List<ServiceTerritory> servTerr = WOM_TestDataUtility.createServiceTerritory(1,'Test Service Territory',true); 
		insert servTerr;     
        List<ServiceTerritory> serviceList;
        Test.startTest();
        serviceList = Appt_ResourceAbsenceController.getAllStores('', '', 'Test');
        Test.stopTest();
        System.assertEquals(true, serviceList.size() == 1);
    }
    
    @isTest
    static void testGetDateTimeValue() {
        String endTime = '18:30:00.000Z';
        String dateValue = '2023-08-03T08:09:56.529Z';
        DateTime result;
   		Test.startTest();
        result = Appt_ResourceAbsenceController.getDateTimeValue(endTime,dateValue);
        Test.stopTest();
        System.assertNotEquals(result,null);
   }

   @isTest
    static void testGetUserAccountTimezone() {
        // Create a test user with a known timezone
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User']; // Change the profile name as needed
        User testUser = new User(
            Alias = 'testUser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/New_York', // Set the expected timezone here
            UserName = 'testuser@test.com.coedev'
        );
        insert testUser;

        // Set the test context to the created user
        System.runAs(testUser) {
            // Call the AuraEnabled method to get the user's account timezone
            String userTimezone = Appt_ResourceAbsenceController.getUserAccountTimezone();

            // Verify that the user's timezone is as expected
            System.assertEquals('America/New_York', userTimezone);
        }
    }

    @isTest(SeeAllData=true)
    static void getOperatingHourOptions() {
        List<OperatingHours> ohList = [SELECT Id, Name FROM OperatingHours WHERE Type__c ='Store Hours'];
        List<Appt_ResourceAbsenceController.Option> ohOptions= new List<Appt_ResourceAbsenceController.Option>();
        Test.startTest();
        ohOptions = Appt_ResourceAbsenceController.getOperatingHourOptions();
        Test.stopTest();
        System.assertEquals(ohList.size(), ohOptions.size());
    }

    @isTest(SeeAllData=true)
    static void getStoreRegionOptions() {
        OperatingHours opHr = [SELECT Name,id from OperatingHours WHERE Type__c ='Store Hours' LIMIT 1];
        List<AggregateResult> regionList = [SELECT Site_Account__r.Store_Region__c  FROM ServiceTerritory WHERE IsActive = true AND OperatingHours.id = :opHr.Id GROUP BY Site_Account__r.Store_Region__c ];
        List<Appt_ResourceAbsenceController.Option> regionOptions= new List<Appt_ResourceAbsenceController.Option>();
        Test.startTest();
        regionOptions = Appt_ResourceAbsenceController.getSiteRegions(opHr.Id);
        Test.stopTest();
        System.assertEquals(regionList.size(), regionOptions.size());
    }
}