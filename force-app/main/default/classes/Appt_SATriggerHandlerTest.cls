@isTest
public class Appt_SATriggerHandlerTest {
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);
    } 

    @isTest 
    static void createAppointmentMakeApptTest()
    {   
        
        WorkOrder myWorkOrder = [SELECT id FROM WorkOrder LIMIT 1];
        datetime startTime = datetime.now();
        datetime endTime = datetime.now().addMinutes(20);
        ServiceAppointment newAppointment = new ServiceAppointment();
        newAppointment.Status = 'Pending';
        newAppointment.SchedStartTime = startTime;
        newAppointment.SchedEndTime = endTime;
        newAppointment.ParentRecordId = myWorkOrder.id;
        newAppointment.Work_Order__c = myWorkOrder.id;
        newAppointment.Duration = 20;      
        newAppointment.Notification_Appointment__c = true;             
        
        System.debug('***********START TEST***************');
        Test.startTest();
        insert newAppointment;
        System.debug(newAppointment);
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');

        ServiceAppointment validateAppointment = [SELECT id, Status FROM ServiceAppointment WHERE id = :newAppointment.id];       
        System.assertEquals('Pending', validateAppointment.Status , 'No appointment was created with correct status');      
    } 

    @isTest static void updateAppointmentCancelTest()
    {   
        //FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED);
        //FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING);
        FSL.GlobalAPIS.addStatusTransition('Canceled', Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED);
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, 'Canceled');
        
        WorkOrder myWorkOrder = [SELECT id FROM WorkOrder LIMIT 1];
        datetime startTime = datetime.now();
        datetime endTime = datetime.now().addMinutes(20);
        ServiceAppointment newAppointment = new ServiceAppointment();
        newAppointment.Status = 'Scheduled';
        newAppointment.SchedStartTime = startTime;
        newAppointment.SchedEndTime = endTime;
        newAppointment.ParentRecordId = myWorkOrder.id;
        newAppointment.Work_Order__c = myWorkOrder.id;
        newAppointment.Duration = 20;     
        newAppointment.Notification_Appointment__c = false; 
        newAppointment.Date_String__c = '2021-03-11';
        newAppointment.Start_Time_String__c = '0800';
        newAppointment.End_Time_String__c = '0820';
        insert newAppointment;
        newAppointment.Notification_Appointment__c = true; 
        newAppointment.Status = 'Canceled';
        
        System.debug('***********START TEST***************');
        Test.startTest();
        
        update newAppointment;
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(newAppointment);

        ServiceAppointment validateAppointment = [SELECT id, Status FROM ServiceAppointment WHERE id = :newAppointment.id];       
        System.assertEquals('Canceled', validateAppointment.Status , 'Apppointment was Canceled');  
  
    } 

    @isTest static void updateAppointmentRescheduleTest()
    {   
        
        WorkOrder myWorkOrder = [SELECT id FROM WorkOrder LIMIT 1];
        datetime startTime = datetime.now();
        datetime endTime = datetime.now().addMinutes(20);
        datetime startTimeUpdate = datetime.now().addMinutes(20);
        datetime endTimeUpdate = datetime.now().addMinutes(40);
        ServiceAppointment newAppointment = new ServiceAppointment();
        newAppointment.Status = 'Pending';
        newAppointment.SchedStartTime = startTime;
        newAppointment.SchedEndTime = endTime;
        newAppointment.ParentRecordId = myWorkOrder.id;
        newAppointment.Work_Order__c = myWorkOrder.id;
        newAppointment.Duration = 20;
        newAppointment.Notification_Appointment__c = false;     
        
        insert newAppointment;
        newAppointment.Notification_Appointment__c = true; 
        newAppointment.SchedStartTime = startTimeUpdate;
        newAppointment.SchedEndTime = endTimeUpdate;
        newAppointment.Status = 'Pending';
        
        System.debug('***********START TEST***************');
        Test.startTest();
        
        update newAppointment;
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
       
        ServiceAppointment validateAppointment = [SELECT id, Status FROM ServiceAppointment WHERE id = :newAppointment.id];       
        System.assertEquals('Pending', validateAppointment.Status , 'No appointment was created with correct status');    
    } 

    @isTest static void updateAppointmentScheduleTest()
    {   

        FSL.GlobalAPIS.addStatusTransition('Missed', Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING);
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, 'Missed');
        
        WorkOrder myWorkOrder = [SELECT id FROM WorkOrder LIMIT 1];
        datetime startTime = datetime.now();
        datetime endTime = datetime.now().addMinutes(20);
        ServiceAppointment newAppointment = new ServiceAppointment();
        newAppointment.Status = 'Pending';
        newAppointment.SchedStartTime = startTime;
        newAppointment.SchedEndTime = endTime;
        newAppointment.ParentRecordId = myWorkOrder.id;
        newAppointment.Work_Order__c = myWorkOrder.id;
        newAppointment.Duration = 20;
        newAppointment.Notification_Appointment__c = false; 
        insert newAppointment;
        
        newAppointment.Status = 'Missed';
        newAppointment.Notification_Appointment__c = true; 
        
        System.debug('***********START TEST***************');
        Test.startTest();
        
        update newAppointment;
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
       
        ServiceAppointment validateAppointment = [SELECT id, Status FROM ServiceAppointment WHERE id = :newAppointment.id];       
        System.assertEquals('Missed', validateAppointment.Status , 'Appointment was status was udpated');        
    } 

    @isTest static void deleteAppointmentTest()
    {   

        FSL.GlobalAPIS.addStatusTransition('Missed', Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING);
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, 'Missed');
        
        WorkOrder myWorkOrder = [SELECT id FROM WorkOrder LIMIT 1];
        datetime startTime = datetime.now();
        datetime endTime = datetime.now().addMinutes(20);
        ServiceAppointment newAppointment = new ServiceAppointment();
        newAppointment.Status = 'Scheduled';
        newAppointment.SchedStartTime = startTime;
        newAppointment.SchedEndTime = endTime;
        newAppointment.ParentRecordId = myWorkOrder.id;
        newAppointment.Work_Order__c = myWorkOrder.id;
        newAppointment.Duration = 20;
        newAppointment.Notification_Appointment__c = false; 
        insert newAppointment;

        String apptId = newAppointment.Id;
  
        
        System.debug('***********START TEST***************');
        Test.startTest();
        
        delete newAppointment;
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
       
        List<Appt_Time_Spot__c> apptSpot = [SELECT id FROM Appt_Time_Spot__c WHERE Service_Appointment__c = :apptId];       
        System.assertEquals(0, apptSpot.size() , 'Expected Appt_Time_Spot__c to be null since its SA has been deleted');        
    } 

    @isTest static void updateAppointmentRescheduleConfirmedTest()
    {   
        
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED);
        
        WorkOrder myWorkOrder = [SELECT id FROM WorkOrder LIMIT 1];
        datetime startTime = datetime.now();
        datetime endTime = datetime.now().addMinutes(20);
        datetime startTimeUpdate = datetime.now().addMinutes(20);
        datetime endTimeUpdate = datetime.now().addMinutes(40);
        ServiceAppointment newAppointment = new ServiceAppointment();
        newAppointment.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        newAppointment.SchedStartTime = startTime;
        newAppointment.SchedEndTime = endTime;
        newAppointment.ParentRecordId = myWorkOrder.id;
        newAppointment.Work_Order__c = myWorkOrder.id;
        newAppointment.Duration = 20;
        newAppointment.Notification_Appointment__c = false;     
        newAppointment.Start_Time_String__c = '0900';
        newAppointment.End_Time_String__c = '0920';
        
        insert newAppointment;
        newAppointment.Notification_Appointment__c = true; 
        newAppointment.SchedStartTime = startTimeUpdate;
        newAppointment.SchedEndTime = endTimeUpdate;
        newAppointment.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;
        newAppointment.Start_Time_String__c = '0920';
        newAppointment.End_Time_String__c = '0940';
        
        System.debug('***********START TEST***************');
        Test.startTest();
        
        update newAppointment;
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
       
        ServiceAppointment validateAppointment = [SELECT id, Status FROM ServiceAppointment WHERE id = :newAppointment.id];       
        System.assertEquals(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED, validateAppointment.Status , 'Appointment was rescheduled with incorrect Confirmed status');    
    } 
}