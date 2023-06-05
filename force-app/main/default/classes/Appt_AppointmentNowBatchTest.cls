@isTest(SeeAllData=false)
public class Appt_AppointmentNowBatchTest 
{
    final static string LPREFIX = 'LOG Appt_AppointmentNowBatchTest: ';

    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();

        Set<Id> apptIds = new Set<Id> {servAppts[0].Id, servAppts[1].Id};

        servAppts = [SELECT Id, Status, SchedStartTime, SchedEndTime, ParentRecordId, ContactId FROM ServiceAppointment WHERE Id IN: apptIds];

        Set<Id> cntctIds = new Set<Id> {servAppts[0].ContactId, servAppts[1].ContactId};

        Map<Id, Contact> cntctMap = new Map<Id, Contact>( [SELECT Id, MobilePhone FROM Contact WHERE Id IN: cntctIds] );
        System.debug( LPREFIX + 'contactCount: ' + cntctMap.size());

        //  Scheduled & Pending already included
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED);

        // progress Appointment to Scheduled & Confirmed
        servAppts[0].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        servAppts[1].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;
        // change the appointment time so it passes whenever the test is run
        //    the test will fail in off hours otherwise.
        Datetime currentDatetime = Datetime.now();
        // currentDatetime = Datetime.newInstanceGMT(currentDatetime.yearGmt(), currentDatetime.monthGmt(), currentDatetime.dayGmt(), 19, 00, 00); // 2pm MDT

        servAppts[0].SchedStartTime = currentDatetime;
        servAppts[0].SchedEndTime = currentDatetime.addMinutes(20);
       
        servAppts[1].SchedStartTime = currentDatetime.addMinutes(20);
        servAppts[1].SchedEndTime = currentDatetime.addMinutes(40);



        for (ServiceAppointment sa: servAppts)
        {
            sa.Notification_Appointment__c = true;
            cntctMap.get(sa.ContactId).MobilePhone = '(602) 555-5555';  
            // System.debug( LPREFIX + 'Setup Appointment: ' + sa);
        }

        // System.debug( LPREFIX + 'Contact: ' + cntctMap);

        update servAppts;
        update cntctMap.values();

    } // End of setupData()

    @isTest 
    static void checkConfirmedScheduled()
    {
        System.debug( LPREFIX + 'checkConfirmedScheduled start');

        List<ServiceAppointment> servApptList = [SELECT Id, ServiceTerritoryId, Work_Order__c, Timezone_Offset__c, Activity_Type__c, Consult_Start_Time__c, Back_Office_Start_Time__c, SchedStartTime, Now_Notification_Sent__c FROM ServiceAppointment WHERE Now_Notification_Sent__c = false AND ( Status = 'Scheduled' OR Status = 'Confirmed' ) AND Notification_Appointment__c = true ];

        System.debug( LPREFIX + 'Appointments ready for NOW Notification: ' + servApptList.size());

        // debug Appointment list
        // for (ServiceAppointment sa: servApptList){
        //     System.debug( LPREFIX + 'Appointment: ' + sa);
        // }

        Test.startTest();        
        System.debug( LPREFIX + 'Start Schedule Test');

        // Schedule the test job
        Datetime dateNow = system.now();
        // dateNow = dateNow.addDays(1);
        dateNow = dateNow.addSeconds(10);
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String cronExp = dateNow.second() + ' ' + dateNow.minute() + ' ' + dateNow.hour() + ' ' + dateNow.day() + ' ' + dateNow.month() + ' ? ' + dateNow.year();
        System.debug( LPREFIX + 'Chron: ' + cronExp);

        Appt_AppointmentNowScheduler scheduleProcess = new Appt_AppointmentNowScheduler();
        String jobId = System.schedule('Appt_AppointmentNowScheduler',
            cronExp, 
            scheduleProcess);
        System.debug( 'jobId: ' + jobId);
        scheduleProcess.execute(null);

        // Stopping the test will run the job synchronously
        System.debug( LPREFIX + 'End Schedule Test');
        Test.stopTest();

        List<Notification__c> noteList = [SELECT Id, Initial_Email_Send_Status__c, Initial_PE_SMS_Send_Status__c, Alternate_Contact__c, Channels__c, Communication_Type__c, Email_Template__c, Notification_Type__c,  Service_Appointment__c  FROM Notification__c WHERE Notification_Type__c='APPT_NOW'];

        Set<Id> noteApptIds = new Set<Id>();
        for (Notification__c note: noteList){
            System.debug( LPREFIX + 'Notification__c: ' + note);
            noteApptIds.add(note.Service_Appointment__c);
        }
        System.assertEquals(2, noteList.size(), 'the number of Notificaiton objects is not correct');

        servApptList = [SELECT Id, ServiceTerritoryId, Work_Order__c, Timezone_Offset__c, Activity_Type__c, Consult_Start_Time__c, Back_Office_Start_Time__c, SchedStartTime, Now_Notification_Sent__c FROM ServiceAppointment WHERE Id IN: noteApptIds ];

        for (ServiceAppointment appt: servApptList){
            // System.debug( LPREFIX + 'ServiceAppointment: ' + appt);
            System.assertEquals(true, appt.Now_Notification_Sent__c, 'Appt - Now Notificaiton Sent false');
        }

        System.debug( LPREFIX + 'checkConfirmedScheduled end');
    }

    @isTest 
    static void checkScheduleSetup()
    {
        Id currentUser = UserInfo.getUserId();

        Test.startTest();        

        Appt_AppointmentNowScheduler.setupSchedule();

        Test.stopTest();

        List<CronTrigger> cronList = [SELECT Id, CronJobDetail.Name, CronExpression, TimeZoneSidKey, TimesTriggered, NextFireTime, CreatedById FROM CronTrigger WHERE CreatedById =: currentUser AND TimesTriggered = 0 ORDER BY CronExpression];

        System.debug( LPREFIX + 'CRON List: ' + cronList.size());
        String cronExp = '0 <minutes> 5-21 ? * MON-SAT *';
        Integer cronMinutes = 0;
        for (CronTrigger ct: cronList){
            // System.debug( LPREFIX + 'CRON trigger: ' + ct);
            String cronStr = cronExp.replace( '<minutes>', cronMinutes.format() );
            String cronName = 'Appt_AppointmentNowScheduler ' + cronMinutes + ' at: ' + cronStr;
            System.assertEquals(cronName, ct.CronJobDetail.Name, 'CRON Expression ' + cronMinutes + ' minutes is wrong.');
            cronMinutes += 15;
        }
    }
}