@isTest
private class Appt_ResourceAbsenceController_Test {
        @testSetup
    static void setupData() {

        // setup the Account ... Territory ... Resource ... Appoitments... 
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 1)');

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
    
        List<Appt_ResourceAbsenceController.RequestData> testData = new List<Appt_ResourceAbsenceController.RequestData>();
        Appt_ResourceAbsenceController.RequestData testData1 = new Appt_ResourceAbsenceController.RequestData();
        testData1.ServiceTeritoryId = '1'; // Add the relevant ServiceTerritory Id here
        testData1.Name = [SELECT Id, Name FROM ServiceTerritory][0].Name;
        testData1.StoreId = [SELECT Id, Name FROM ServiceTerritory][0].Name;
        testData1.StartTime = '11:30:00.000Z';
        testData1.EndTime = '18:30:00.000Z';
        testData1.StoreDate = '2023-08-03T08:09:56.529Z';
        testData.add(testData1);


        Test.startTest();
        String requestDataJSON = JSON.serialize(testData);
        Appt_ResourceAbsenceController.createAbsenceRecords(requestDataJSON);
        Test.stopTest();

        
        List<ServiceResource> createdServiceResources = [SELECT Id, Name, ResourceType, Type__c, RelatedRecordId, IsActive FROM ServiceResource];
        System.assertEquals(2, createdServiceResources.size()); 

       
        System.assertEquals('Resource Back', createdServiceResources[0].Name);
        System.assertEquals('T', createdServiceResources[0].ResourceType);
        System.assertEquals('Back Room', createdServiceResources[0].Type__c);
       // System.assertEquals('0056g000007o1VOAAY', createdServiceResources[0].RelatedRecordId);
        System.assertEquals(true, createdServiceResources[0].IsActive);
        
        createdServiceResources = [SELECT Id, Name, ResourceType, Type__c, RelatedRecordId, IsActive FROM ServiceResource];
    }
    @isTest
    static void testGetAllStores() {
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
        serviceList = Appt_ResourceAbsenceController.getAllStores('Test');
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
}