@isTest
public with sharing class Appt_InvocableNotificationUpdateTest {
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();                
    } 

    @isTest 
    static void responseToReScheduledTest()
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
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS');  
        Notification__c testNotification = [SELECT  Id, 
                                                    Work_Order__c, 
                                                    Channels__c,
                                                    Last_Error_Message__c, 
                                                    Initial_PE_SMS_Send_Status__c, 
                                                    Initial_PE_Email_Payload__c,
                                                    Initial_PE_SMS_Payload__c,
                                                    Notification_Type__c, 
                                                    Logs__c,
                                                    Initial_Email_Send_Status__c, 
                                                    Reply_PE_Notification_Type__c,
                                                    Reply_PE_Send_Status__c,
                                                    Reply_PE_Payload__c FROM Notification__c LIMIT 1];        
        
        
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        testNotification = Appt_InvocableNotificationUpdate.updateLogs(testNotification,'EMAIL');
        testNotification = Appt_InvocableNotificationUpdate.updateLogs(testNotification,'SMS-Initial');
        testNotification = Appt_InvocableNotificationUpdate.updateLogs(testNotification,'SMS-Reply');
        testNotification.Logs__c = null;
        testNotification = Appt_InvocableNotificationUpdate.updateLogs(testNotification,'EMAIL');
        testNotification.Logs__c = null;
        testNotification = Appt_InvocableNotificationUpdate.updateLogs(testNotification,'SMS-Initial');
        testNotification.Logs__c = null;
        testNotification = Appt_InvocableNotificationUpdate.updateLogs(testNotification,'SMS-Reply');
        Test.stopTest();  
        System.debug('***********END TEST***************');
        
        System.debug(testNotification.Logs__c);

        System.assert(testNotification.Logs__c.contains('SMS-Reply'), 'Check for log being set');
                     

    }

    @isTest 
    static void updateNotificationStatusTest()
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
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS');  
        Notification__c testNotification = [SELECT  Id, 
                                                    Work_Order__c, 
                                                    Channels__c,
                                                    Last_Error_Message__c, 
                                                    Initial_PE_SMS_Send_Status__c, 
                                                    Initial_PE_Email_Payload__c,
                                                    Initial_PE_SMS_Payload__c,
                                                    Notification_Type__c, 
                                                    Logs__c,
                                                    Initial_Email_Send_Status__c, 
                                                    Reply_PE_Notification_Type__c,
                                                    Reply_PE_Send_Status__c,
                                                    Reply_PE_Payload__c FROM Notification__c LIMIT 1];    
                                                    
        List<id> testIds = new List<id>();
        testIds.add(testNotification.id);               
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_InvocableNotificationUpdate.updateNotificationStatus(testIds);
        Test.stopTest();  
        System.debug('***********END TEST***************');

        Notification__c testNotificationValidation = [SELECT  Id, 
                                                    Work_Order__c, 
                                                    Channels__c,
                                                    Last_Error_Message__c, 
                                                    Initial_PE_SMS_Send_Status__c, 
                                                    Initial_PE_Email_Payload__c,
                                                    Initial_PE_SMS_Payload__c,
                                                    Notification_Type__c, 
                                                    Logs__c,
                                                    Initial_Email_Send_Status__c, 
                                                    Reply_PE_Notification_Type__c,
                                                    Reply_PE_Send_Status__c,
                                                    Reply_PE_Payload__c FROM Notification__c WHERE id = :testNotification.id LIMIT 1];

        System.assert(testNotificationValidation.Initial_PE_SMS_Send_Status__c == Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS, 'Check for send status');
        
        
                     

    }
}