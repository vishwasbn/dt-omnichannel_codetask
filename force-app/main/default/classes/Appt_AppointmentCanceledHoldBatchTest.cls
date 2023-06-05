@isTest(SeeAllData=false)
public class Appt_AppointmentCanceledHoldBatchTest 
{
    @testSetup
    static void setupData() {

        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();

        List<WorkOrder> workOrderList = [SELECT Id, CreatedDate FROM WorkOrder];

        System.assertEquals(servAppts[0].ParentRecordId, workOrderList[0].Id, 'Work Order Id does not match Appointment');

        // change the Created time so it passes whenever the test is run
        //    the test will fail in off hours otherwise.
        Datetime currentDatetime = Datetime.now();
        Test.setCreatedDate(workOrderList[0].Id, currentDatetime); // change the date


    } // End of setupData()

    @isTest static void checkNotOverdueApptCancelHold()
    {
        // check setup
        System.debug('checkNotOverdueApptCancelHold start');

        List<ServiceAppointment> servAppts = [SELECT Id, Status, ParentRecordId FROM ServiceAppointment];
        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 1)');

        List<WorkOrder> workOrderList = [SELECT Id, CreatedDate FROM WorkOrder];
        // System.debug('Work Order Created date: ' + workOrderList[0].CreatedDate);
        System.assertEquals(servAppts[0].ParentRecordId, workOrderList[0].Id, 'Work Order Id does not match Appointment');

        // create the Batch process and check that it WON'T change until 20min
        Test.startTest();        
        Appt_AppointmentCanceledHoldBatch batchProcess = new Appt_AppointmentCanceledHoldBatch();

        Id batchId = Database.executeBatch(batchProcess);
        System.debug('batchId' + batchId);
        Test.stopTest();

        servAppts = [SELECT Id, Status FROM ServiceAppointment];

        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 2)');
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, servAppts[0].Status, 'Front Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING);
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, servAppts[1].Status, 'Back Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING);

        System.debug('checkNotOverdueApptCancelHold end');

    } // End of checkNotOverdueApptCancelHold()

    @isTest static void checkOverdueApptCancelHold()
    {
        System.debug('checkOverdueApptCancelHold start');

        List<WorkOrder> workOrderList = [SELECT Id, CreatedDate FROM WorkOrder];

        // set the Work Order to exceed the wait time
        List<Appt_Appointment_Setting__mdt> apptSettingList = [SELECT Id, DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt WHERE DeveloperName = 'Appt_Hold_Cancel_Time_Minutes'];
        System.assertEquals(20, Integer.valueOf(apptSettingList[0].Value__c), 'Custom metadata experation value is wrong');
        Datetime dateUpdate = workOrderList[0].CreatedDate; // start with the current Created Date
        Integer experationPeriod = Integer.valueOf(apptSettingList[0].Value__c);
        experationPeriod += 1; // add one more than the experation period
        experationPeriod *= -1; // negate the period to move the CreatedDate back in time
        dateUpdate = dateUpdate.addMinutes( experationPeriod ); // change the date
        Test.setCreatedDate(workOrderList[0].Id, dateUpdate); // update the date

        Test.startTest();        
        System.debug('Start Schedule Test');

        // Schedule the test job
        Datetime dateNow = system.now();
        // dateNow = dateNow.addDays(1);
        dateNow = dateNow.addSeconds(10);
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String cronExp = dateNow.second() + ' ' + dateNow.minute() + ' ' + dateNow.hour() + ' ' + dateNow.day() + ' ' + dateNow.month() + ' ? ' + dateNow.year();
        System.debug('Chron: ' + cronExp);

        Appt_AppointmentCanceledHoldScheduler scheduleProcess = new Appt_AppointmentCanceledHoldScheduler();
        String jobId = System.schedule('Appt_AppointmentCanceledHoldScheduler',
            cronExp, 
            scheduleProcess);         
        scheduleProcess.execute(null);
        System.debug('jobId' + jobId);

        // Stopping the test will run the job synchronously
        System.debug('End Schedule Test');
        Test.stopTest();

        List<ServiceAppointment> servAppts = [SELECT Id, Status FROM ServiceAppointment];
        System.debug('Service Appointments# ' + servAppts.size());

        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 2)');
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD, servAppts[0].Status, 'Front Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD);
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD, servAppts[1].Status, 'Back Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD);

        System.debug('checkOverdueApptCancelHold end');

    } // End of checkOverdueApptCancelHold()
}