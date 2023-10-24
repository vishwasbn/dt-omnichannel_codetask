@istest
public class Appt_NotificationTriggerHandlerTest {
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();                
    } 

    @isTest static void responseToReScheduledTest()
    {           
        WorkOrder myWorkOrder = [SELECT id, SMS_Phone__c FROM WorkOrder LIMIT 1]; 
        myWorkOrder.SMS_Phone__c = '(602) 683-6565';   
        update myWorkOrder;    
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
        newAppointment.Date_String__c = '2021-01-02';  
        newAppointment.Activity_Type__c = 'Front Room';    
        newAppointment.Start_Time_String__c = '0900'; 
        
        insert newAppointment;
        System.debug(newAppointment);
        
        Map<id,String> notificaitonMap = new Map<id,String>();
        notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_RESCHEDULED);
       
        
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION',  'SMS, EMAIL');
        
        
        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c LIMIT 1];        
        System.debug(testNotification);  
        testNotification.Response__c = '1';
        
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        testNotification.Response__c = '5';
        System.debug('testNotification :: '+ testNotification);
        update testNotification;
        testNotification.Response__c = '1';
        update testNotification;
        testNotification.Response__c = '2';
       
        update testNotification;
        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c validateNotification = [SELECT id, Notification_Type__c, Response_Status__c FROM Notification__c WHERE id = :testNotification.id];   
        System.debug(validateNotification);

        
                     
        System.assertEquals(validateNotification.Response_Status__c, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS, 'Check for notificaiton response status to be success');    
    }

    @isTest static void responseToScheduledTest()
    {           
        WorkOrder myWorkOrder = [SELECT id, SMS_Phone__c FROM WorkOrder LIMIT 1]; 
        myWorkOrder.SMS_Phone__c = '(602) 683-6565';   
        update myWorkOrder;    
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
        newAppointment.Date_String__c = '2021-01-02';  
        newAppointment.Activity_Type__c = 'Front Room';    
        newAppointment.Start_Time_String__c = '0900'; 
        
        insert newAppointment;
        System.debug(newAppointment);
        
        Map<id,String> notificaitonMap = new Map<id,String>();
        notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED);
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS');  
        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c LIMIT 1];        
        System.debug(testNotification);  
        testNotification.Response__c = '1';
        
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        testNotification.Response__c = '5';
        update testNotification;
        testNotification.Response__c = '1';
        update testNotification;
        testNotification.Response__c = '2';
        update testNotification;
        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c validateNotification = [SELECT id, Notification_Type__c, Response_Status__c FROM Notification__c WHERE id = :testNotification.id];   
        System.debug(validateNotification);

        
                     
        System.assertEquals(validateNotification.Response_Status__c, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS, 'Check for notificaiton response status to be success');    
    }


    @isTest static void responseToCanceledTest()
    {           
        WorkOrder myWorkOrder = [SELECT id, SMS_Phone__c FROM WorkOrder LIMIT 1]; 
        myWorkOrder.SMS_Phone__c = '(602) 683-6565';   
        update myWorkOrder;    
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
        newAppointment.Date_String__c = '2021-01-02';  
        newAppointment.Activity_Type__c = 'Front Room';    
        newAppointment.Start_Time_String__c = '0900'; 
        
        insert newAppointment;
        System.debug(newAppointment);
        
        Map<id,String> notificaitonMap = new Map<id,String>();
        notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_CANCELLED);
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS');  
        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c LIMIT 1];        
        System.debug(testNotification);  
        testNotification.Response__c = '1';
        
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        testNotification.Response__c = '5';
        update testNotification;
        testNotification.Response__c = '1';
        update testNotification;
        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c validateNotification = [SELECT id, Notification_Type__c, Response_Status__c FROM Notification__c WHERE id = :testNotification.id];   
        System.debug(validateNotification);

        
                     
        System.assertEquals(validateNotification.Response_Status__c, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS, 'Check for notificaiton response status to be success');    
    }

    @isTest static void responseToReminderTest()
    {           
        WorkOrder myWorkOrder = [SELECT id, SMS_Phone__c FROM WorkOrder LIMIT 1]; 
        myWorkOrder.SMS_Phone__c = '(602) 683-6565';   
        update myWorkOrder;    
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
        newAppointment.Date_String__c = '2021-01-02';  
        newAppointment.Activity_Type__c = 'Front Room';    
        newAppointment.Start_Time_String__c = '0900'; 
        
        insert newAppointment;
        System.debug(newAppointment);
        
        Map<id,String> notificaitonMap = new Map<id,String>();
        notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_REMINDER);
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS');  
        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c LIMIT 1];        
        System.debug(testNotification);  
        testNotification.Response__c = '1';
        
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        testNotification.Response__c = '5';
        update testNotification;
        testNotification.Response__c = '3';
        update testNotification;
        testNotification.Response__c = '1';
        update testNotification;
        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c validateNotification = [SELECT id, Notification_Type__c, Response_Status__c FROM Notification__c WHERE id = :testNotification.id];   
        System.debug(validateNotification);

        
                     
        System.assertEquals(validateNotification.Response_Status__c, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS, 'Check for notificaiton response status to be success');    
    }

    @isTest static void responseToNowTest()
    {   
        //Commenting for SO-891. There is a requirement to stop sending notificaiton for NOTIFICATION_APPT_NOW (for 30 mins.)
        /*        
        WorkOrder myWorkOrder = [SELECT id, SMS_Phone__c FROM WorkOrder LIMIT 1]; 
        myWorkOrder.SMS_Phone__c = '(602) 683-6565';   
        update myWorkOrder;    
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
        newAppointment.Date_String__c = '2021-01-02';  
        newAppointment.Activity_Type__c = 'Front Room';    
        newAppointment.Start_Time_String__c = '0900'; 
        
        insert newAppointment;
        System.debug(newAppointment);
        
        Map<id,String> notificaitonMap = new Map<id,String>();
        notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_NOW);
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS');  
        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c LIMIT 1];        
        System.debug(testNotification);  
        testNotification.Response__c = '1';
        
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        testNotification.Response__c = '5';
        update testNotification;
        testNotification.Response__c = '1';
        update testNotification;
        //testNotification.Response__c = '2';
        //update testNotification;
        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c validateNotification = [SELECT id, Notification_Type__c, Response_Status__c FROM Notification__c WHERE id = :testNotification.id];   
        System.debug(validateNotification);

        
                     
        System.assertEquals(validateNotification.Response_Status__c, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS, 'Check for notificaiton response status to be success');    
    */}
}