@isTest(SeeAllData=false)
public class Appt_ResourceAbsenceBatchTest {
    @testSetup
    static void setupData(){
        
        // setup the Account ... Territory ... Resource ... Appoitments... 
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 1)');
        
        List<User> userList = [SELECT Id, FirstName, LastName FROM User WHERE FirstName= 'John' AND LastName = 'Smith'];
        
        List<ServiceTerritory> servTerrList = [SELECT Id, Name FROM ServiceTerritory];
        
        User resourceUser = Appt_TestUtil.getStandardUser('Bill', 'Johnson');
        
        ServiceResource servResource = Appt_TestUtil.getServiceResource('Resource Front', userList[0].Id , resourceUser.Id, 'T', 'Front Room');
        
        ServiceTerritoryMember servTerritoryMember = Appt_TestUtil.getServiceTerritoryMember(servTerrList[0].Id, servResource.Id, 'P', Datetime.now().addMonths(-2));
        
        // create the testing date
        // it has to match up with Appt_Time_Slots so no sunday
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();
        
        // create a time period for the Absence... one day
        Datetime startDatetime = Datetime.newInstance(currentDate, Time.newInstance(10,0,0,0));
        Datetime endDatetime = Datetime.newInstance(currentDate, Time.newInstance(12,0,0,0));
        
        // create first Resource Absence for the second ServiceResource (front)
        ResourceAbsence resAbs = Appt_TestUtil.getResourceAbsence(servResource.Id, startDatetime, endDatetime);
        
        Map<String, Integer> tsFrontBackMap = new Map<String, Integer> ();
        List<Appt_Time_Slot__c> atsList = checkApptTimeSlots('setupData-complete', currentDate, currentDate, tsFrontBackMap);
        
    }
    @isTest 
    static void testServiceAppointments(){
        StoreHolidays__c storeHolidays = new StoreHolidays__c(
            name = 'christmas',
            Active__c = true,
            End__c = system.now()+1, 
            Start__c = system.now() 
            
        );
        insert storeHolidays;
        
        Test.startTest();
        Appt_ResourceAbsenceBatch obj = new Appt_ResourceAbsenceBatch();
        DataBase.executeBatch(obj); 
        
        StoreHolidays__c storeHolidays1 = new StoreHolidays__c(
            name = 'New year',
            Active__c = true,
            End__c = system.now()+2, 
            Start__c = system.now()+1 
            
        );
        insert storeHolidays1;
        DataBase.executeBatch(obj); 
        Test.stopTest();
    }
    @isTest 
    static void testServiceAppointmentsTwoDays(){
        List<StoreHolidays__c> sotreHolidayList = new List<StoreHolidays__c>();
        StoreHolidays__c storeHolidayFull = new StoreHolidays__c(
            name = 'christmas',
            Active__c = true,
            Start__c = system.now() ,
            End__c = system.now()+1 
         );
        sotreHolidayList.add(storeHolidayFull);
        StoreHolidays__c storeHolidayPartial = new StoreHolidays__c(
            name = 'christmasEve',
            Active__c = true,
            Start__c = ((system.now()-1)+(10/24)), 
            End__c = ((system.now())-(15/24)) 
            );
        sotreHolidayList.add(storeHolidayPartial);
        insert sotreHolidayList;
        
        Test.startTest();
        Appt_ResourceAbsenceBatch obj = new Appt_ResourceAbsenceBatch();
        DataBase.executeBatch(obj); 
        Test.stopTest();
    }
    @isTest 
    static void testServiceAppointmentsWithTimeZone(){
        Profile pf= [Select Id from profile where Name='Standard User']; 
        
        String orgId=UserInfo.getOrganizationId(); 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+dateString+RandomId; 

        User uu=new User(
            firstname = 'ABC', 
            lastName = 'XYZ', 
            email = uniqueName + '@test' + orgId + '.org', 
            Username = uniqueName + '@test' + orgId + '.org', 
            EmailEncodingKey = 'ISO-8859-1', 
            Alias = uniqueName.substring(18, 23), 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            ProfileId = pf.Id
        ); 
        insert uu;
        StoreHolidays__c storeHolidays = new StoreHolidays__c(
            name = 'christmas',
            Active__c = true,
            End__c = system.now()+1, 
            Start__c = system.now() 
        );
        insert storeHolidays;
        system.runAs(uu){
            Test.startTest();
            Appt_ResourceAbsenceBatch obj = new Appt_ResourceAbsenceBatch();
            DataBase.executeBatch(obj); 
            Test.stopTest();
        }
    }
    static List<Appt_Time_Slot__c> checkApptTimeSlots(String label, Date currentDate, Date currentNextDate, Map<String, Integer> tsFrontBackMap)
    {
        List<Appt_Time_Slot__c> atsList = [SELECT Id, Name, isBackUnavailable__c, Service_Territory__c, Date__c, Start_Time__c, End_Time__c, IsFrontUnavailable__c, Type__c FROM Appt_Time_Slot__c WHERE ( Date__c >=: currentDate AND Date__c <=: currentNextDate ) order by Start_Time__c ];
        System.debug(label + '::Appt_Time_Slot__c: ' + atsList.size());
        
        Integer isBackUnavailableCNT = 0;
        Integer isFrontUnavailableCNT = 0;
        for (Appt_Time_Slot__c ats: atsList){
            if (ats.isBackUnavailable__c) {
                ++isBackUnavailableCNT;
                if (ats.Type__c == 'Front Room') System.debug(label + '::Back flag lost');
            }
            if (ats.IsFrontUnavailable__c) {
                ++isFrontUnavailableCNT;
                if (ats.Type__c == 'Back Room') System.debug(label + '::Front flag lost');
            }
        }
        System.debug(label + '::Back cnt: ' + isBackUnavailableCNT);
        System.debug(label + '::Front cnt: ' + isFrontUnavailableCNT);
        
        tsFrontBackMap.put('Front', isFrontUnavailableCNT);
        tsFrontBackMap.put('Back', isBackUnavailableCNT);
        
        return atsList;
    }
}