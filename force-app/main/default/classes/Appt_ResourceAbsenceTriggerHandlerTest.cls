@isTest(SeeAllData=false)
public class Appt_ResourceAbsenceTriggerHandlerTest 
{
    @testSetup
    static void setupData() {

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
    static void insertResourceAbsenceForOneDay()
    {
        System.debug('insertResourceAbsenceForOneDay start');

        // get the resources
        List<ServiceResource> servResourceList = [SELECT Id, Name, RelatedRecordId, ResourceType, Description, IsActive, LocationId, ServiceCrewId, AccountId, Type__c FROM ServiceResource];
        System.assertEquals(2, servResourceList.size(), 'There is not 2 Service Resource present');

        // create the testing date
        // it has to match up with Appt_Time_Slots so no sunday
        Date currentDate = (  Integer.valueOf( Datetime.now().format('u') ) > 5 ) ? Date.today().addDays(2) : Date.today();

        // get all the time slots for "Today".  There is no reason to filter by territory, there is only one
        // List<Appt_Time_Slot__c> atsList = getApptTimeSlots('insertResourceAbsence', currentDate, currentDate, 0, 6);
        Map<String, Integer> tsFrontBackMap = new Map<String, Integer> ();
        List<Appt_Time_Slot__c> atsList = checkApptTimeSlots('insertResourceAbsence-Pre', currentDate, currentDate, tsFrontBackMap);

        // create a time period for the Absence... one day
        Datetime startDatetime = Datetime.newInstance(currentDate, Time.newInstance(8,0,0,0));
        Datetime endDatetime = Datetime.newInstance(currentDate, Time.newInstance(18,0,0,0));

        Test.startTest();        
        // create the second Resource Absence for the first ServiceResource (back)
        ResourceAbsence rscAbs = Appt_TestUtil.getResourceAbsence(servResourceList[0].Id, startDatetime, endDatetime);
        rscAbs.Street = 'Test';
        update rscAbs;
        delete rscAbs;
        Test.stopTest();

        atsList = getApptTimeSlots('insertResourceAbsence', currentDate, currentDate, 30, tsFrontBackMap.get('Front'));

        System.debug('insertResourceAbsenceForOneDay end');

    } // End of insertResourceAbsenceForOneDay()


    @isTest 
    static void updateResourceAbsenceForOneDay()
    {
        System.debug('updateResourceAbsenceForOneDay start');

        // get the resources
        List<ServiceResource> servResourceList = [SELECT Id, Name, RelatedRecordId, ResourceType, Description, IsActive, LocationId, ServiceCrewId, AccountId, Type__c FROM ServiceResource];
        System.assertEquals(2, servResourceList.size(), 'There is not 2 Service Resource present');

        // create the testing dates for today; avoid saturday (saturday less than 8) & sunday
        Date currentDate = (  Integer.valueOf( Datetime.now().format('u') ) > 5 ) ? Date.today().addDays(2) : Date.today();
        Date currentNextDate = ( Integer.valueOf( Datetime.now().format('u') ) > 5 ) ? Date.today().addDays(2) : Date.today();

        // get all the time slots for "Days".  There is no reason to filter by territory, there is only one
        // List<Appt_Time_Slot__c> atsList = getApptTimeSlots('updateResourceAbsence', currentDate, currentNextDate, 0, 6);
        Map<String, Integer> tsFrontBackMap = new Map<String, Integer> ();
        List<Appt_Time_Slot__c> atsList = checkApptTimeSlots('updateResourceAbsenceForOneDay-Pre', currentDate, currentNextDate, tsFrontBackMap);

        // create a new start time... two hours earlier
        Datetime startDatetime = Datetime.newInstance(currentDate, Time.newInstance(8,0,0,0));

        Datetime startDateNexttime = Datetime.newInstance(currentNextDate, Time.newInstance(8,0,0,0));
        Datetime endDateNexttime = Datetime.newInstance(currentNextDate, Time.newInstance(18,0,0,0));
        System.debug('updateResourceAbsenceForOneDay::startDate: ' + startDatetime);
        System.debug('updateResourceAbsenceForOneDay::startDate: ' + startDateNexttime);
        System.debug('updateResourceAbsenceForOneDay::endDate: ' + endDateNexttime);

        // create ResouceAbsence for Back resource
        ResourceAbsence rscAbs = Appt_TestUtil.getResourceAbsence(servResourceList[0].Id, startDateNexttime, endDateNexttime);

        List<ResourceAbsence> rscAbsList = [SELECT Id, AbsenceNumber, RecordTypeId, ResourceId, Type, Description, Start, End FROM ResourceAbsence];
        System.assertEquals(2, rscAbsList.size(), 'Number of ResourceAbsence records is wrong');
        rscAbsList[0].Start = startDatetime;
        rscAbsList[1].Start = startDateNexttime.addHours(2);

        Test.startTest();        
        // update the front & back Resource Absence
        update  rscAbsList;
        
        Test.stopTest();

        atsList = getApptTimeSlots('updateResourceAbsence', currentDate, currentDate, 30, (18 + tsFrontBackMap.get('Front')) );

        System.debug('updateResourceAbsenceForOneDay start');

    } // End of updateResourceAbsenceForOneDay()


    @isTest 
    static void deleteResourceAbsence()
    {
        System.debug('deleteResourceAbsence start');

        // create the testing date
        Integer dayOfWeek = Integer.valueOf( Datetime.now().format('u') );
        Date currentDate = ( dayOfWeek == 5 ) ? Date.today().addDays(3) : ( dayOfWeek >= 6 ) ? Date.today().addDays(2) : Date.today();
        System.debug('deleteResourceAbsence::currentDate: ' + currentDate);

        // get the resources
        List<ServiceResource> servResourceList = [SELECT Id, Name, RelatedRecordId, ResourceType, Description, IsActive, LocationId, ServiceCrewId, AccountId, Type__c FROM ServiceResource];
        System.assertEquals(2, servResourceList.size(), 'There is not 2 Service Resource present');

        // create a time period for the Absence... two day
        Datetime startDatetime = Datetime.newInstance(currentDate, Time.newInstance(8,0,0,0));
        Datetime endDatetime = Datetime.newInstance(currentDate.addDays(1), Time.newInstance(18,0,0,0));
        System.debug('deleteResourceAbsence::startDate: ' + startDatetime);
        System.debug('deleteResourceAbsence::endDate: ' + endDatetime);

        // get all the time slots for "Period".  There is no reason to filter by territory, there is only one
        // List<Appt_Time_Slot__c> atsList = getApptTimeSlots('deleteResourceAbsence', startDatetime.date(), endDatetime.date(), 0, 0);
        Map<String, Integer> tsFrontBackMap = new Map<String, Integer> ();
        List<Appt_Time_Slot__c> atsList = checkApptTimeSlots('deleteResourceAbsence-Pre', startDatetime.date(), endDatetime.date(), tsFrontBackMap);
        // System.debug('deleteResourceAbsence::tsFrontBackMap: ' + tsFrontBackMap);

        // create resource absence for the back again...
        ResourceAbsence resAbs = Appt_TestUtil.getResourceAbsence(servResourceList[0].Id, startDatetime, endDatetime);

        atsList = getApptTimeSlots('deleteResourceAbsence-add', startDatetime.date(), endDatetime.date(), 60, tsFrontBackMap.get('Front'));

        Test.startTest();        
        // delete Resource Absence
        delete  resAbs;
        
        Test.stopTest();

        atsList = getApptTimeSlots('deleteResourceAbsence-delete', startDatetime.date(), endDatetime.date(), 0, tsFrontBackMap.get('Front'));

        System.debug('deleteResourceAbsence end');
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

    static List<Appt_Time_Slot__c> getApptTimeSlots(String label, Date currentDate, Date currentNextDate, Integer backCount, Integer frontCount)
    {
        Map<String, Integer> tsFrontBackMap = new Map<String, Integer> ();

        List<Appt_Time_Slot__c> atsList = checkApptTimeSlots(label, currentDate, currentNextDate, tsFrontBackMap);
        return atsList;
    }

}