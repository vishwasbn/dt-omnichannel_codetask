@isTest(seeAllData = false)
public with sharing class Appt_AppointmentArchiveBatchScheduleTest 
{
    final static string LPREFIX = 'LOG Appt_AppointmentArchiveBatchScheduleTest: ';
    
    @TestSetup
    public static void setupTestData(){

        //-- this will setup a store with 27 days of slots
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        System.debug(servAppts);

        // progress Appointment to Scheduled & Confirmed
        servAppts[0].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        servAppts[1].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        // change the appointment time so it passes whenever the test is run
        //    the test will fail in off hours otherwise.
        Datetime currentDatetime = Datetime.now().addDays(-367);
        String dateString = String.valueOf(Date.valueOf(currentDatetime));
        servAppts[0].SchedStartTime = currentDatetime;
        servAppts[0].SchedEndTime = currentDatetime.addMinutes(20);
        servAppts[1].SchedStartTime = currentDatetime.addMinutes(20);
        servAppts[1].SchedEndTime = currentDatetime.addMinutes(40);
        servAppts[0].Date_String__c = dateString;
        servAppts[1].Date_String__c = dateString;
        update servAppts;
    }

    static testMethod void testFindAppointmentsToArchive() {
        List<ServiceAppointment> servAppts = [SELECT Id, Status, SchedStartTime, Date_String__c, ParentRecordId FROM ServiceAppointment];
        System.debug(servAppts);

        Test.startTest();
        Appt_AppointmentArchiveBatchSchedule batch = new Appt_AppointmentArchiveBatchSchedule(1);
        // batch.findAppointmentsToArchive();
        batch.execute(null);
        Test.stopTest();

        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present');

        List<ServiceAppointment> servApptsUpdated = [SELECT Id, Archive_Status__c, Status, SchedStartTime, Date_String__c, ParentRecordId FROM ServiceAppointment];

        // Since this is a synchronous batch process, Find -> Process -> Delete will result in 0 service appointments
        System.assertEquals(0, servApptsUpdated.size(), 'There should not be any serviceAppointments after batch is run.');

    }

    static testMethod void testArchiveBatchSetupSchedule() {
        Test.startTest();

        Appt_AppointmentArchiveBatchSchedule.setupSchedule();

        Test.stopTest();

        List<CronTrigger> cronList = [SELECT Id, CronJobDetail.Name, CronExpression, TimeZoneSidKey, TimesTriggered, NextFireTime, CreatedById FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Appt_AppointmentArchiveBatchTest%' ORDER BY CronJobDetail.Name];

        System.assertEquals(2, cronList.size(), 'incorrect number of Scheduled jobs');

        Integer hourIdx = 1;
        Integer seqIdx = 1;
        for (CronTrigger ct: cronList){
            System.debug( LPREFIX + 'CRON trigger: ' + ct.CronJobDetail.Name);
            String cronStr = ( math.mod(hourIdx, 2) > 0 ) ? '0, 1 * * * ?' : '0, 16 * * * ?';

            String cronName = 'Appt_AppointmentArchiveBatchTest ' + seqIdx + ' at: ' + cronStr;
            System.assertEquals(cronName, ct.CronJobDetail.Name, 'CRON Expression ' + seqIdx + ' is wrong.');
            
            if ( math.mod(hourIdx, 2) == 0 ) ++seqIdx;
            ++hourIdx;
        }
    }
}