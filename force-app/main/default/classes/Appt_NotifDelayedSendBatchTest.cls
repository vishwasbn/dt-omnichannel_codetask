@isTest
public with sharing class Appt_NotifDelayedSendBatchTest {

    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);
    } 

    @isTest 
    static void Appt_NotificationDelayedSendBatch()
    {         


        WorkOrder myWorkOrder = [SELECT id, SMS_Phone__c FROM WorkOrder LIMIT 1]; 
        myWorkOrder.SMS_Phone__c = '(602) 683-6565';   
        myWorkOrder.Order_Type__c = 'ROPIS';
        myWorkOrder.Hybris_Order_Id__c = '';
        update myWorkOrder;    

        Integer addDays = 1;

        Datetime dt = System.now();
        if(dt.format('EEEE') == 'Saturday'){
            addDays = 3;
        }

        datetime startTime = Datetime.newInstance(
            Date.today().addDays(addDays),
            Time.newInstance(12, 0, 0, 0)
        );
        datetime endTime = Datetime.newInstance(
            Date.today().addDays(addDays),
            Time.newInstance(12, 20, 0, 0)
        );
        ServiceAppointment newAppointment = new ServiceAppointment();
        newAppointment.Status = 'Pending';
        newAppointment.SchedStartTime = startTime;
        newAppointment.SchedEndTime = endTime;
        newAppointment.ParentRecordId = myWorkOrder.id;
        newAppointment.Work_Order__c = myWorkOrder.id;
        newAppointment.Duration = 20;      
        newAppointment.Notification_Appointment__c = true;   
        newAppointment.Date_String__c = '2021-01-02';    
        insert newAppointment;
        System.debug(newAppointment);
        
        Map<id,String> notificaitonMap = new Map<id,String>();
        notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED);
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS, EMAIL');   

        myWorkOrder.Hybris_Order_Id__c = '4564';
        update myWorkOrder; 

        Notification__c testNotification = [SELECT id, Last_Error_Message__c, Initial_PE_SMS_Send_Status__c, Has_Valid_Order_Number__c, Notification_Type__c FROM Notification__c WHERE Service_Appointment__c = :newAppointment.id];
        System.debug(testNotification);      

        System.debug('***********START TEST***************');
        Test.startTest();
        Id batchId = Database.executeBatch(new Appt_NotificationDelayedSendBatch());           
        System.debug('batchId' + batchId);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');

        AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                    FROM AsyncApexJob WHERE ID =: batchId ];
        System.debug(aaj);
        System.assertEquals('Completed', aaj.Status,'Check for job to be completed');     
    }

    @isTest 
    static void Appt_NotificationDelayedSendProcessBatch()
    {         


        WorkOrder myWorkOrder = [SELECT id, SMS_Phone__c FROM WorkOrder LIMIT 1]; 
        myWorkOrder.SMS_Phone__c = '(602) 683-6565';   
        myWorkOrder.Order_Type__c = 'ROPIS';
        myWorkOrder.Hybris_Order_Id__c = '60265456654';
        update myWorkOrder;    

        Integer addDays = 1;

        Datetime dt = System.now();
        if(dt.format('EEEE') == 'Saturday'){
            addDays = 3;
        }

        datetime startTime = Datetime.newInstance(
            Date.today().addDays(addDays),
            Time.newInstance(12, 0, 0, 0)
        );
        datetime endTime = Datetime.newInstance(
            Date.today().addDays(addDays),
            Time.newInstance(12, 20, 0, 0)
        );
        ServiceAppointment newAppointment = new ServiceAppointment();
        newAppointment.Status = 'Pending';
        newAppointment.SchedStartTime = startTime;
        newAppointment.SchedEndTime = endTime;
        newAppointment.ParentRecordId = myWorkOrder.id;
        newAppointment.Work_Order__c = myWorkOrder.id;
        newAppointment.Duration = 20;      
        newAppointment.Notification_Appointment__c = true;   
        newAppointment.Date_String__c = '2021-01-02';    
        insert newAppointment;
        System.debug(newAppointment);
        
        Map<id,String> notificaitonMap = new Map<id,String>();
        notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED);
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS, EMAIL');   

        myWorkOrder.Hybris_Order_Id__c = '4564';
        update myWorkOrder; 

        Notification__c testNotification = [SELECT id, Last_Error_Message__c, Initial_PE_SMS_Send_Status__c, Has_Valid_Order_Number__c, Notification_Type__c FROM Notification__c WHERE Service_Appointment__c = :newAppointment.id];

        testNotification.Initial_PE_SMS_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_INVAILD_ORDER_NUMBER;
        testNotification.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_INVAILD_ORDER_NUMBER;
        update testNotification;

        System.debug(testNotification);      

        System.debug('***********START TEST***************');
        Test.startTest();
        Id batchId = Database.executeBatch(new Appt_NotificationDelayedSendBatch());           
        System.debug('batchId' + batchId);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');

        AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                    FROM AsyncApexJob WHERE ID =: batchId ];
        System.debug(aaj);
        System.assertEquals('Completed', aaj.Status,'Check for job to be completed');     
    }
}