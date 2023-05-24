@isTest(SeeAllData=false)
public class Appt_AppointmentReminderBatchTest 
{
    final static string LPREFIX = 'LOG Appt_AppointmentReminderBatchTest: ';
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();

        //  Scheduled & Pending already included
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED);

        // progress Appointment to Scheduled & Confirmed
        servAppts[0].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        servAppts[1].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;
        // change the appointment time so it passes whenever the test is run
        //    the test will fail in off hours otherwise.
        Datetime tomorrowDatetime = Datetime.now().addDays(1);

        //tomorrowDatetime = Datetime.newInstanceGMT(tomorrowDateTime.yearGmt(), tomorrowDatetime.monthGmt(), tomorrowDatetime.dayGmt(), 16, 00, 00); // 9am MST

        servAppts[0].SchedStartTime = tomorrowDatetime;
        servAppts[0].SchedEndTime = tomorrowDatetime.addMinutes(20);
       
        servAppts[1].SchedStartTime = tomorrowDatetime.addMinutes(20);
        servAppts[1].SchedEndTime = tomorrowDatetime.addMinutes(40);

        for (ServiceAppointment sa: servAppts)
        {
            sa.Notification_Appointment__c = true;    
        }

        update servAppts;

    } // End of setupData()

    @isTest 
    static void checkConfirmedScheduled()
    {
        System.debug(LPREFIX + 'checkConfirmedScheduled start');

        List<ServiceAppointment> servApptList = [SELECT Id, ServiceTerritoryId, Work_Order__c, Timezone_Offset__c, Activity_Type__c, Consult_Start_Time__c, Back_Office_Start_Time__c, SchedStartTime, Reminder_Notification_Sent__c FROM ServiceAppointment WHERE Reminder_Notification_Sent__c = false AND ( Status = 'Scheduled' OR Status = 'Confirmed' ) AND Notification_Appointment__c = true  ORDER BY Timezone_Offset__c DESC ];

        System.debug(LPREFIX + 'Appointments ready for Reminder: ' + servApptList.size());

        for (ServiceAppointment sa: servApptList){
            System.debug(LPREFIX + 'Appointment: ' + sa);
        }

        Test.startTest();        
        System.debug(LPREFIX + 'Start Schedule Test');

        // Schedule the test job
        Datetime dateNow = system.now();
        // dateNow = dateNow.addDays(1);
        dateNow = dateNow.addSeconds(10);
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String cronExp = dateNow.second() + ' ' + dateNow.minute() + ' ' + dateNow.hour() + ' ' + dateNow.day() + ' ' + dateNow.month() + ' ? ' + dateNow.year();
        System.debug(LPREFIX + 'Chron: ' + cronExp);

        Appt_AppointmentReminderScheduler scheduleProcess = new Appt_AppointmentReminderScheduler();
        String jobId = System.schedule('Appt_AppointmentReminderScheduler',
            cronExp, 
            scheduleProcess);
        System.debug('jobId: ' + jobId);
        scheduleProcess.execute(null);

        // Stopping the test will run the job synchronously
        System.debug(LPREFIX + 'End Schedule Test');
        Test.stopTest();

        List<Notification__c> noteList = [SELECT Id, Initial_Email_Send_Status__c, Alternate_Contact__c, Channels__c, Communication_Type__c, Email_Template__c, Notification_Type__c  FROM Notification__c WHERE Notification_Type__c='APPT_REMINDER'];

        for (Notification__c note: noteList){
            System.debug(LPREFIX + 'Notification__c: ' + note);
        }
        System.assertEquals(2, noteList.size(), 'the number of Notificaiton objects is not correct');

        System.debug(LPREFIX + 'checkConfirmedScheduled end');
    }

    @isTest 
    static void checkScheduleSetup()
    {
        Id currentUser = UserInfo.getUserId();

        Test.startTest();        

        Appt_AppointmentReminderScheduler.setupSchedule();

        Test.stopTest();

        List<CronTrigger> cronList = [SELECT Id, CronJobDetail.Name, CronExpression, TimeZoneSidKey, TimesTriggered, NextFireTime, CreatedById FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Appt_AppointmentReminderSchedulerTest%'];

        System.debug( LPREFIX + 'CRON List: ' + cronList.size());
        String cronExp = '0 0 <hour> ? * SUN-FRI *';
        
        System.debug( LPREFIX + 'CRON trigger: ' + cronList[0].CronJobDetail.Name + ' CRON: ' + cronList[0].CronExpression);
        String cronStrDST = cronExp.replace( '<hour>', '4-10' );
        String cronStrNoDST = cronExp.replace( '<hour>', '3-9' );

        String cronNameDST = 'Appt_AppointmentReminderSchedulerTest 7 at: ' + cronStrDST;
        String cronNameNoDST = 'Appt_AppointmentReminderSchedulerTest 7 at: ' + cronStrNoDST;

        Boolean checkCronMatch = cronList[0].CronJobDetail.Name.equals(cronNameDST) || cronList[0].CronJobDetail.Name.equals(cronNameNoDST);
        System.assertEquals(checkCronMatch, true, 'CRON Expression is wrong.');
    }

}