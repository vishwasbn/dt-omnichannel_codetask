@isTest
public class Appt_AppointmentMissedBatchTest 
{
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();

        //  Scheduled & Pending already included
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED);
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED);

        // progress Appointment to Scheduled & Confirmed
        servAppts[0].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        servAppts[1].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;
        // change the appointment time so it passes whenever the test is run
        //    the test will fail in off hours otherwise.
        Datetime currentDatetime = Datetime.now();
        servAppts[0].SchedStartTime = currentDatetime;
        servAppts[0].SchedEndTime = currentDatetime.addMinutes(20);
        servAppts[1].SchedStartTime = currentDatetime.addMinutes(20);
        servAppts[1].SchedEndTime = currentDatetime.addMinutes(40);
        update servAppts;

    } // End of setupData()


    @isTest 
    static void checkApptNotMissed()
    {
        // check setup
        System.debug('checkApptNotMissed start');

        List<ServiceAppointment> servAppts = [SELECT Id, Status, SchedStartTime, Appointment_Missed__c, ParentRecordId FROM ServiceAppointment];
        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 1)');
        // System.debug('checkApptNotMissed ' + Datetime.now());
        // System.debug('checkApptNotMissed Appts: ' + servAppts);

        // System.debug('checkApptNotMissed--Before0: '+ servAppts[0]);
        // System.debug('checkApptNotMissed--Before1: '+ servAppts[1]);

        // progress Appointment to Scheduled & Confirmed
        servAppts[0].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        servAppts[1].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;
        // change the appointment time so it passes whenever the test is run
        //    the test will fail in off hours otherwise.
        Datetime currentDatetime = Datetime.now();
        servAppts[0].SchedStartTime = currentDatetime;
        servAppts[0].SchedEndTime = currentDatetime.addMinutes(20);
        servAppts[1].SchedStartTime = currentDatetime.addMinutes(20);
        servAppts[1].SchedEndTime = currentDatetime.addMinutes(40);
        update servAppts;

        List<WorkOrder> workOrderList = [SELECT Id, CreatedDate FROM WorkOrder];
        // System.debug('Work Order Created date: ' + workOrderList[0].CreatedDate);
        System.assertEquals(servAppts[0].ParentRecordId, workOrderList[0].Id, 'Work Order Id does not match Appointment');

        // create the Batch process and check that it WON'T change until 30min
        Test.startTest();        
        Appt_AppointmentMissedBatch batchProcess = new Appt_AppointmentMissedBatch();

        Id batchId = Database.executeBatch(batchProcess);
        System.debug('batchId' + batchId);
        Test.stopTest();

        servAppts = [SELECT Id, Status, SchedStartTime, Appointment_Missed__c FROM ServiceAppointment];

        // System.debug('checkApptNotMissed--AfterTest0: '+ servAppts[0]);
        // System.debug('checkApptNotMissed--AfterTest1: '+ servAppts[1]);
    
        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 2)');
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, servAppts[0].Status, 'Front Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED);
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED, servAppts[1].Status, 'Back Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED);

        System.debug('checkApptNotMissed end');

    } // End of checkApptNotMissed()


    @isTest 
    static void checkApptMissed()
    {
        // check setup
        System.debug('checkApptMissed start');
        
        // get the appointments ordered by starttime to put front first back second
        List<ServiceAppointment> servAppts = [SELECT Id, Status, SchedStartTime FROM ServiceAppointment ORDER BY SchedStartTime];

        // System.debug('checkApptMissed--Before0: '+ servAppts[0]);
        // System.debug('checkApptMissed--Before1: '+ servAppts[1]);

        // progress Appointment to Scheduled & Confirmed
        servAppts[0].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        servAppts[1].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;

        // set the Work Order to exceed the wait time
        List<Appt_Appointment_Setting__mdt> apptSettingList = [SELECT Id, DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt WHERE DeveloperName = 'Appt_Missed_Time_Minutes'];
        System.assertEquals(30, Integer.valueOf(apptSettingList[0].Value__c), 'Custom metadata experation value is wrong');

        Integer apptMissedValue = Integer.valueOf(apptSettingList[0].Value__c);
        apptMissedValue += 21; // add one more than the experation period for the Back start...
        apptMissedValue *= -1; // negate the period to move the SchedStartTime back in time

        // System.debug('checkApptMissed--start offset: ' + apptMissedValue);
        // System.debug('checkApptMissed--Now: ' + Datetime.now());
        Datetime dateUpdate = Datetime.now(); // start with the current current time
        dateUpdate = dateUpdate.addMinutes(apptMissedValue);
        // System.debug('checkApptMissed--new starttime: ' + dateUpdate);
        servAppts[0].SchedStartTime = dateUpdate; // push back the time to cause the failure
        servAppts[0].SchedEndTime = dateUpdate.addMinutes(20);
        servAppts[1].SchedStartTime = dateUpdate.addMinutes(20);
        servAppts[1].SchedEndTime = dateUpdate.addMinutes(40);
        update servAppts;

        servAppts = [SELECT Id, Status, SchedStartTime, Appointment_Missed__c FROM ServiceAppointment];
        // System.debug('checkApptMissed--AfterUpdate0: '+ servAppts[0]);
        // System.debug('checkApptMissed--AfterUpdate1: '+ servAppts[1]);

        Test.startTest();        
        System.debug('Start Schedule Test');

        // Schedule the test job
        Datetime dateNow = system.now();
        // dateNow = dateNow.addDays(1);
        dateNow = dateNow.addSeconds(30);
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String cronExp = dateNow.second() + ' ' + dateNow.minute() + ' ' + dateNow.hour() + ' ' + dateNow.day() + ' ' + dateNow.month() + ' ? ' + dateNow.year();
        System.debug('Chron: ' + cronExp);

        Appt_AppointmentMissedScheduler scheduleProcess = new Appt_AppointmentMissedScheduler();
        String jobId = System.schedule('Appt_AppointmentMissedScheduler',
            cronExp, 
            scheduleProcess);         
        scheduleProcess.execute(null);
        System.debug('jobId: ' + jobId);

        // Stopping the test will run the job synchronously
        System.debug('End Schedule Test');
        Test.stopTest();

        servAppts = [SELECT Id, Status, SchedStartTime, Appointment_Missed__c FROM ServiceAppointment];
        // System.debug('Service Appointments# ' + servAppts.size());
        // System.debug('checkApptMissed: ' + servAppts);

        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 2)');
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED, servAppts[0].Status, 'Front Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED);
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED, servAppts[1].Status, 'Back Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED);

        System.debug('checkApptMissed end');
    }

}