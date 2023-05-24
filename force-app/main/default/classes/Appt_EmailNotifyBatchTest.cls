@isTest(seeAllData = false)
public class Appt_EmailNotifyBatchTest 
{
    @testSetup
    static void setupData() {
        // setup the Account ... Territory ... Resource ... Appoitments... 
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 1)');
    }    

    @isTest
    static void getApptEmailHybrisTest(){

        // Should be 2 appts in sf test, both belonging to the same service territory
        List<ServiceAppointment> appts = [SELECT Id, ServiceTerritory.Id, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Work_Order__c, Work_Order__r.AccountId, Work_Order__r.Source__c, Work_Order__r.ContactId FROM ServiceAppointment];
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present ');

        ServiceAppointment appt = appts[0];

        System.debug(appt);

        WorkOrder testOrder = [SELECT id FROM WorkOrder WHERE id = :appt.Work_Order__c];
        testOrder.Source__c = 'POS';
        testOrder.Order_Type__c = 'ROPIS';
        testOrder.SMS_Phone__c = '5555555555';

        update testOrder;

        System.debug('***********START TEST***************');
        Test.startTest();
        
        Notification__c newNotificaiton = new Notification__c();
        newNotificaiton.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_REMINDER;
        newNotificaiton.Service_Appointment__c = appt.id;
        newNotificaiton.Account__c = appt.Work_Order__r.AccountId;
        newNotificaiton.Work_Order__c = appt.Work_Order__c;
        newNotificaiton.Source__c = appt.Work_Order__r.Source__c;
        newNotificaiton.Channels__c = 'EMAIL';
        newNotificaiton.Communication_Type__c = 'TRANSACTION';                    
        newNotificaiton.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
        newNotificaiton.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING;
        newNotificaiton.Contact__c = appt.Work_Order__r.ContactId;
        newNotificaiton.Alternate_Contact__c = false;

        //newNotificaiton.Invoice_Payload__c = Appt_InvoiceDetailModelTest.getJSON();

        insert newNotificaiton;     

        System.debug(newNotificaiton);
        
        Id batchId = Database.executeBatch(new Appt_EmailNotifyBatch() );
        System.debug('batchId' + batchId);

        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c testNotify = [SELECT id,Invoice_Status__c, Invoice_Payload__c, Last_Error_Message__c, Valid_Email_Notification__c, Initial_Email_Send_Status__c, Initial_PE_SMS_Send_Status__c  FROM Notification__c WHERE id = :newNotificaiton.id];
        System.debug(testNotify.Invoice_Payload__c);

        System.assert(testNotify.Invoice_Payload__c == null, 'Check for payload');

        //System.assertEquals(testNotify.Invoice_Status__c, Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_ERROR);  
    }

    @isTest
    static void getApptEmailPOSTest(){

        // Should be 2 appts in sf test, both belonging to the same service territory
        List<ServiceAppointment> appts = [SELECT Id, ServiceTerritory.Id, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Work_Order__c, Work_Order__r.AccountId, Work_Order__r.Source__c, Work_Order__r.ContactId FROM ServiceAppointment];
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present ');

        ServiceAppointment appt = appts[0];

        System.debug(appt);

        WorkOrder testOrder = [SELECT id FROM WorkOrder WHERE id = :appt.Work_Order__c];
        testOrder.Source__c = 'POS';
        testOrder.Hybris_Order_Id__c = null;
        testOrder.POS_Web_Order_Id__c = '56546';
        testOrder.SMS_Phone__c = '5555555555';

        update testOrder;

        System.debug('***********START TEST***************');
        Test.startTest();
        
        Notification__c newNotificaiton = new Notification__c();
        newNotificaiton.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_REMINDER;
        newNotificaiton.Service_Appointment__c = appt.id;
        newNotificaiton.Account__c = appt.Work_Order__r.AccountId;
        newNotificaiton.Work_Order__c = appt.Work_Order__c;
        newNotificaiton.Source__c = appt.Work_Order__r.Source__c;
        newNotificaiton.Channels__c = 'EMAIL';
        newNotificaiton.Communication_Type__c = 'TRANSACTION';                    
        newNotificaiton.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
        newNotificaiton.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING;
        newNotificaiton.Contact__c = appt.Work_Order__r.ContactId;
        newNotificaiton.Alternate_Contact__c = false;

        //newNotificaiton.Invoice_Payload__c = Appt_InvoiceDetailModelTest.getJSON();

        insert newNotificaiton;     

        System.debug(newNotificaiton);

        Id batchId = Database.executeBatch(new Appt_EmailNotifyBatch() );
        System.debug('batchId' + batchId);

        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c testNotify = [SELECT id,Invoice_Status__c, Invoice_Payload__c, Last_Error_Message__c, Valid_Email_Notification__c, Initial_Email_Send_Status__c, Initial_PE_SMS_Send_Status__c  FROM Notification__c WHERE id = :newNotificaiton.id];
        System.debug(testNotify.Invoice_Payload__c);

        System.assert(testNotify.Invoice_Payload__c == null, 'Check for payload');

        //System.assertEquals(testNotify.Invoice_Status__c, Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_ERROR);    
        //System.assertEquals(Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_ERROR, testNotify.Invoice_Status__c, 'Expecting ' +Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING+' but got Invoice_Status__c='+ testNotify.Invoice_Status__c);    
    }

    @isTest
    static void getApptEmailLayawayTest(){

        // Should be 2 appts in sf test, both belonging to the same service territory
        List<ServiceAppointment> appts = [SELECT Id, ServiceTerritory.Id, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Work_Order__c, Work_Order__r.AccountId, Work_Order__r.Source__c, Work_Order__r.ContactId FROM ServiceAppointment];
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present ');

        ServiceAppointment appt = appts[0];

        System.debug(appt);

        WorkOrder testOrder = [SELECT id FROM WorkOrder WHERE id = :appt.Work_Order__c];
        testOrder.Source__c = 'POS';
        testOrder.Hybris_Order_Id__c = null;
        testOrder.POS_Web_Order_Id__c = null;
        testOrder.Layaway_Number__c = '56546';
        testOrder.SMS_Phone__c = '5555555555';
        testOrder.Order_Type__c = 'Layaway';

        update testOrder;

        System.debug('***********START TEST***************');
        Test.startTest();
        
        Notification__c newNotificaiton = new Notification__c();
        newNotificaiton.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_REMINDER;
        newNotificaiton.Service_Appointment__c = appt.id;
        newNotificaiton.Account__c = appt.Work_Order__r.AccountId;
        newNotificaiton.Work_Order__c = appt.Work_Order__c;
        newNotificaiton.Source__c = appt.Work_Order__r.Source__c;
        newNotificaiton.Channels__c = 'EMAIL';
        newNotificaiton.Communication_Type__c = 'TRANSACTION';                    
        newNotificaiton.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
        newNotificaiton.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING;
        newNotificaiton.Contact__c = appt.Work_Order__r.ContactId;
        newNotificaiton.Alternate_Contact__c = false;

        //newNotificaiton.Invoice_Payload__c = Appt_InvoiceDetailModelTest.getJSON();

        insert newNotificaiton;     

        System.debug(newNotificaiton);

        Id batchId = Database.executeBatch(new Appt_EmailNotifyBatch() );
        System.debug('batchId' + batchId);

        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c testNotify = [SELECT id,Invoice_Status__c, Invoice_Payload__c, Last_Error_Message__c, Valid_Email_Notification__c, Initial_Email_Send_Status__c, Initial_PE_SMS_Send_Status__c  FROM Notification__c WHERE id = :newNotificaiton.id];
        System.debug(testNotify.Invoice_Payload__c);

        System.assert(testNotify.Invoice_Payload__c == null, 'Check for payload');

        //System.assertEquals(testNotify.Invoice_Status__c, Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_ERROR);  
        //System.assertEquals(Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING, testNotify.Invoice_Status__c, 'Expecting ' +Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING+' but got Invoice_Status__c='+ testNotify.Invoice_Status__c);    
    }

    @isTest
    static void getApptEmailQuoteTest(){

        // Should be 2 appts in sf test, both belonging to the same service territory
        List<ServiceAppointment> appts = [SELECT Id, ServiceTerritory.Id, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Work_Order__c, Work_Order__r.AccountId, Work_Order__r.Source__c, Work_Order__r.ContactId FROM ServiceAppointment];
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present ');

        ServiceAppointment appt = appts[0];

        System.debug(appt);

        WorkOrder testOrder = [SELECT id FROM WorkOrder WHERE id = :appt.Work_Order__c];
        testOrder.Source__c = 'POS';
        testOrder.Hybris_Order_Id__c = null;
        testOrder.POS_Web_Order_Id__c = null;
        testOrder.Layaway_Number__c = null;
        testOrder.Quote_Number__c = '65465';
        testOrder.Invoice_Number__c = null;
        testOrder.SMS_Phone__c = '5555555555';
        testOrder.Order_Type__c = 'Quote';

        update testOrder;

        System.debug('***********START TEST***************');
        Test.startTest();
        
        Notification__c newNotificaiton = new Notification__c();
        newNotificaiton.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_REMINDER;
        newNotificaiton.Service_Appointment__c = appt.id;
        newNotificaiton.Account__c = appt.Work_Order__r.AccountId;
        newNotificaiton.Work_Order__c = appt.Work_Order__c;
        newNotificaiton.Source__c = appt.Work_Order__r.Source__c;
        newNotificaiton.Channels__c = 'EMAIL';
        newNotificaiton.Communication_Type__c = 'TRANSACTION';                    
        newNotificaiton.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
        newNotificaiton.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING;
        newNotificaiton.Contact__c = appt.Work_Order__r.ContactId;
        newNotificaiton.Alternate_Contact__c = false;

        //newNotificaiton.Invoice_Payload__c = Appt_InvoiceDetailModelTest.getJSON();

        insert newNotificaiton;     

        System.debug(newNotificaiton);

        Id batchId = Database.executeBatch(new Appt_EmailNotifyBatch() );
        System.debug('batchId' + batchId);

        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c testNotify = [SELECT id,Invoice_Status__c, Invoice_Payload__c, Last_Error_Message__c, Valid_Email_Notification__c, Initial_Email_Send_Status__c, Initial_PE_SMS_Send_Status__c  FROM Notification__c WHERE id = :newNotificaiton.id];
        System.debug(testNotify.Invoice_Payload__c);

        System.assert(testNotify.Invoice_Payload__c == null, 'Check for payload');

        //System.assertEquals(testNotify.Invoice_Status__c, Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_ERROR);   
        //System.assertEquals(Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING, testNotify.Invoice_Status__c, 'Expecting ' +Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING+' but got Invoice_Status__c='+ testNotify.Invoice_Status__c);    
    }

    @isTest
    static void getApptEmailInvoiceTest(){

        // Should be 2 appts in sf test, both belonging to the same service territory
        List<ServiceAppointment> appts = [SELECT Id, ServiceTerritory.Id, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Work_Order__c, Work_Order__r.AccountId, Work_Order__r.Source__c, Work_Order__r.ContactId FROM ServiceAppointment];
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present ');

        ServiceAppointment appt = appts[0];

        System.debug(appt);

        WorkOrder testOrder = [SELECT id FROM WorkOrder WHERE id = :appt.Work_Order__c];
        testOrder.Source__c = 'POS';
        testOrder.Hybris_Order_Id__c = null;
        testOrder.POS_Web_Order_Id__c = null;
        testOrder.Layaway_Number__c = null;
        testOrder.Quote_Number__c = null;
        testOrder.Invoice_Number__c = '54654464';
        testOrder.SMS_Phone__c = '5555555555';
        testOrder.Order_Type__c = 'Invoice';

        update testOrder;

        System.debug('***********START TEST***************');
        Test.startTest();
        
        Notification__c newNotificaiton = new Notification__c();
        newNotificaiton.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_REMINDER;
        newNotificaiton.Service_Appointment__c = appt.id;
        newNotificaiton.Account__c = appt.Work_Order__r.AccountId;
        newNotificaiton.Work_Order__c = appt.Work_Order__c;
        newNotificaiton.Source__c = appt.Work_Order__r.Source__c;
        newNotificaiton.Channels__c = 'EMAIL';
        newNotificaiton.Communication_Type__c = 'TRANSACTION';                    
        newNotificaiton.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
        newNotificaiton.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING;
        newNotificaiton.Contact__c = appt.Work_Order__r.ContactId;
        newNotificaiton.Alternate_Contact__c = false;

        //newNotificaiton.Invoice_Payload__c = Appt_InvoiceDetailModelTest.getJSON();

        insert newNotificaiton;     

        System.debug(newNotificaiton);

        Id batchId = Database.executeBatch(new Appt_EmailNotifyBatch() );
        System.debug('batchId' + batchId);

        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c testNotify = [SELECT id,Invoice_Status__c, Invoice_Payload__c, Last_Error_Message__c, Valid_Email_Notification__c, Initial_Email_Send_Status__c, Initial_PE_SMS_Send_Status__c  FROM Notification__c WHERE id = :newNotificaiton.id];
        System.debug(testNotify.Invoice_Payload__c);

        System.assert(testNotify.Invoice_Payload__c == null, 'Check for payload');

        //System.assertEquals(Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING, testNotify.Invoice_Status__c, 'Expecting ' +Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING+' but got Invoice_Status__c='+ testNotify.Invoice_Status__c);    
    }

    @isTest
    static void setupScheduleTest(){
       
    
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_EmailNotifyBatchScheduler.setupSchedule();
        Test.stopTest();  
        System.debug('***********END TEST***************');

        CronTrigger ct =  [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger ORDER BY CreatedDate DESC LIMIT 1];
        System.debug(ct.CronJobDetail.Name);
        System.assert(ct.CronJobDetail.Name.contains('Appt_EmailNotifyBatchTest'),'check for job to be created');

    }

}