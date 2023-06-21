@isTest
public class Appt_SATriggerHandlerTest {
    
    @testSetUp
    static void setupData() 
    {
        // ---------------- PT changes starts here--------------
        User pOSUser = Appt_TestUtil.getPosTerminalUser('TestPos' ,'TerminalTestUser'); 
        pOSUser.User_Store_Id__c = 'RIP05';  
        update pOSUser;
        
        // ---------------- PT changes ends here--------------
        
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
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
        newAppointment.Site_Id__c ='WYO02';
        
        Test.startTest();
        insert newAppointment;
        Test.stopTest();  
        
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
        newAppointment.Site_Id__c ='WYO02';
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
        newAppointment.Site_Id__c ='WYO02';
        
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
        newAppointment.Site_Id__c ='WYO02';
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
        newAppointment.Site_Id__c ='WYO02';
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
        newAppointment.Site_Id__c ='WYO02';       
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
    
    //Appt 3.0 - start here
     @isTest
    static void testForTimeForOneSlot(){
        user currentUser = [Select id,username ,LastName,User_Store_Id__c from user where LastName = 'TerminalTestUser' LIMIT 1 ];
        Workorder wo = [select id,AccountId from workorder limit 1];        
        Account acc=[select id,SAP_STORE_ID__c from Account where id =: wo.AccountId];
        WorkType orderWorkType=[select id from WorkType limit 1];
        List<Contact> custContacts = [SELECT Id FROM Contact WHERE AccountId =: acc.Id];
        ServiceTerritory servTerr=[select id from ServiceTerritory limit 1];
        FSL__Scheduling_Policy__c schedulePolicy=[select id from FSL__Scheduling_Policy__c limit 1];        
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();     
        system.runAs(currentUser){
        Time apptStartTime = Time.newInstance(11,0,0,0);
        Time apptEndTime = Time.newInstance(11,20,0,0);
        Datetime apptStartDateTime = Datetime.newInstance(currentDate, apptStartTime);
        Datetime apptEndDateTime = Datetime.newInstance(currentDate, apptEndTime);
        Integer localTimeZoneOffset = -7;
        Integer appointmentDuration = 20;
        Appt_ConstantValues.isVisionFeature = true;
                     
        System.debug('***********START TEST NEW***************');
        Test.startTest();
        ServiceAppointment bckServiceAppt = Appt_TestUtil.getServiceAppointment( currentUser.Id, wo.Id, acc.Id, orderWorkType.Id, custContacts[0].Id, servTerr.Id, '1235', apptStartDateTime.addMinutes(20), apptEndDateTime.addMinutes(20), localTimeZoneOffset, appointmentDuration, 'Back Room', schedulePolicy.Id);
        
        List<ServiceAppointment> applist = new List<ServiceAppointment>();
        for(integer i=0;i<5;i++){
            apptStartDateTime = Datetime.newInstance(currentDate+i, apptStartTime);
            apptEndDateTime = Datetime.newInstance(currentDate+i, apptEndTime);
            applist.add(Appt_TestUtil.getServiceAppointment( currentUser.Id, wo.Id, acc.Id, orderWorkType.Id, custContacts[0].Id, servTerr.Id, '1235', apptStartDateTime, apptEndDateTime, localTimeZoneOffset, appointmentDuration, 'Back Room', schedulePolicy.Id));               
        }      
        List<serviceappointment> verificationlist = [select id from serviceappointment where status =: Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING and (id in: applist or id =:bckServiceAppt.Id)];
        Assert.areEqual(verificationlist.size(), 6,'ServiceAppointment');
        //timeslot verification
        List<ServiceAppointment> servAppts = [SELECT Id,Status FROM ServiceAppointment];        
        Integer validateExistingTimeSpotForSlot = [SELECT count() FROM Appt_Time_Spot__c where Service_Appointment__c = :servAppts[1].id];        
        Integer validateNewlyCreatedTimeSpotWithOneSlot = [SELECT count() FROM Appt_Time_Spot__c where Service_Appointment__c = :servAppts[2].id];   
        System.assertEquals(1,validateExistingTimeSpotForSlot,'TimeSpot for one slot created'); // 8.20-8.40 ---This in Test Util
        System.assertEquals(1,validateNewlyCreatedTimeSpotWithOneSlot,'TimeSpot for one slot created'); // 11.20-11.40 --- This is Created in this class
        Test.stopTest();   
        System.debug('***********END TEST***************');
         }     
    }
       
    //Appt3.0 Changes End 
    
    
    //PT changes starts here
    @isTest
    static void createServiceAppointmentPlatformEventsTest(){
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED);
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED);
        system.debug('createServiceAppointmentPlatformEventsTest Starts');
        
        user currentUser = [Select id,username ,LastName,User_Store_Id__c from user where LastName = 'TerminalTestUser' LIMIT 1 ];
        Workorder wo = [select id,AccountId from workorder limit 1];
        WorkOrderLineItem woli= new WorkOrderLineItem ();
        Account acc=[select id,SAP_STORE_ID__c from Account where id =: wo.AccountId];
        WorkType orderWorkType=[select id from WorkType limit 1];
        List<Contact> custContacts = [SELECT Id FROM Contact WHERE AccountId =: acc.Id];
        ServiceTerritory servTerr=[select id from ServiceTerritory limit 1];
        FSL__Scheduling_Policy__c schedulePolicy=[select id from FSL__Scheduling_Policy__c limit 1];
        woli.WOM_Article_Number__c='000000000000084838';
        woli.WOM_ArticleSize__c='AIR';
        woli.WOM_Article_Quantity__c=5;
        woli.WOM_Article_Description__c='Test WOLI';
        woli.Appt3_Treadwell__c=TRUE;
        woli.Appt3_Article_Type__c='TEST';
        woli.WorkOrderId=wo.id;
        insert woli;
        
        system.runAs(currentUser){
            Integer localTimeZoneOffset = -7;
            Integer appointmentDuration = 20;
            Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();
            Time apptStartTime = Time.newInstance(8,0,0,0);
            Time apptEndTime = Time.newInstance(8,20,0,0);
            Time starttimestring = Time.newInstance(9, 0, 0, 0);
            Time endtimestring = Time.newInstance(9, 20, 0, 0);
            Datetime apptStartDateTime = Datetime.newInstance(currentDate, apptStartTime);
            Datetime apptEndDateTime = Datetime.newInstance(currentDate, apptEndTime);
            Datetime starttimedate = Datetime.newInstance(currentDate, starttimestring);
            Datetime endtimedate = Datetime.newInstance(currentDate, endtimestring);
            System.debug('***********START TEST***************');
            test.startTest();
            PT_AppointmentEventService.createServiceAppointmentPlatformEvents(null,null,null);
            List<ServiceAppointment> applist = new List<ServiceAppointment>();
            for(integer i=0;i<10;i++){
                apptStartDateTime = Datetime.newInstance(currentDate+i, apptStartTime);
                apptEndDateTime = Datetime.newInstance(currentDate+i, apptEndTime);
                applist.add(Appt_TestUtil.getServiceAppointment( currentUser.Id, wo.Id, acc.Id, orderWorkType.Id, custContacts[0].Id, servTerr.Id, acc.SAP_STORE_ID__c, apptStartDateTime, apptEndDateTime, localTimeZoneOffset, appointmentDuration, 'Front Room', schedulePolicy.Id));               
            }
            List<serviceappointment> verificationlist = [select id from serviceappointment where status =: Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING and id in: applist];
            Assert.areEqual(verificationlist.size(), 10,'No ServiceAppointment created');
            
            for(integer i=0;i<10;i++){
                applist[i].Original_Start_Time_String__c=apptStartDateTime.format('HHmm');
                applist[i].Original_End_Time_String__c=apptEndDateTime.format('HHmm');
                applist[i].Start_Time_String__c = starttimedate.format('HHmm');
                applist[i].End_Time_String__c = endtimedate.format('HHmm');
                applist[i].Status=Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
            }
            Update applist;
            System.debug('apptStartDateTime:-'+apptStartDateTime);
            System.debug('apptEndDateTime:-'+apptEndDateTime);
            System.debug('starttimedate:-'+starttimedate);
            System.debug('endtimedate:-'+endtimedate);
            system.debug('Start apptStartDateTime :- '+apptStartDateTime.format('HHmm'));
            system.debug('apptEndDateTime :- '+apptEndDateTime.format('HHmm'));
            system.debug('starttimedate :- '+starttimedate.format('HHmm'));
            system.debug('endtimedate :- '+endtimedate.format('HHmm'));
            verificationlist = [select id,Original_Start_Time_String__c,Start_Time_String__c,Appointment_Rescheduled__c from serviceappointment where Appointment_Rescheduled__c = true and id in: applist];
            
            System.debug('verificationlist:-'+verificationlist);
            Assert.areEqual(10, verificationlist.size());
            
            for(integer i=0;i<10;i++){
                applist[i].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED;
            }
            Update applist;
            verificationlist = [select id,Appointment_Rescheduled__c,status from serviceappointment where status =:Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED and id in: applist];
            Assert.areEqual(10, verificationlist.size());
            
            test.stopTest();
            System.debug('***********STOP TEST***************');
        }
        system.debug('createServiceAppointmentPlatformEventsTest ENDS');
    }
    
}