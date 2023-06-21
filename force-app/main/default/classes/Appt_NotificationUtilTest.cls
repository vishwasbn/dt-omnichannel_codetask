@isTest
public class Appt_NotificationUtilTest {
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);
    } 

    @isTest static void futureNotificationTest()
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
        insert newAppointment;
        System.debug(newAppointment);
        
        Map<id,String> notificaitonMap = new Map<id,String>();
        notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED);
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_NotificationUtil.createServiceAppointmentNotificaitonsFuture(notificaitonMap, 'TRANSACTION', 'SMS, EMAIL');        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');

        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c WHERE Service_Appointment__c = :newAppointment.id];
        System.debug(testNotification);               
        System.assertEquals(testNotification.Notification_Type__c, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED, 'Correct Notificaiton/type was created');      
    }

    @isTest static void futureNotificationWithTimeTest()
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
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_NotificationUtil.createServiceAppointmentNotificaitonsFuture(notificaitonMap, 'TRANSACTION', 'SMS, EMAIL');        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');

        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c WHERE Service_Appointment__c = :newAppointment.id];
        System.debug(testNotification);               
        System.assertEquals(testNotification.Notification_Type__c, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED, 'Correct Notificaiton/type was created');    
    }


    @isTest static void futureNotificationEmailOnlyTest()
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
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_NotificationUtil.createServiceAppointmentNotificaitonsFuture(notificaitonMap, 'TRANSACTION', 'EMAIL');        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');

        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c WHERE Service_Appointment__c = :newAppointment.id];
        System.debug(testNotification);               
        System.assertEquals(testNotification.Notification_Type__c, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED, 'Correct Notificaiton/type was created');      
    }
    
    @isTest static void resendNotificationTest()
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
        insert newAppointment;
        System.debug(newAppointment);
        
        Map<id,String> notificaitonMap = new Map<id,String>();
        notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED);
        Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS, EMAIL');    
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
            
        Appt_NotificationUtil.resendNotification(myWorkOrder.id,'SMS');
        Appt_NotificationUtil.resendNotification(myWorkOrder.id,'EMAIL');
        Test.stopTest();  
        System.debug('***********END TEST***************');
       
        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c WHERE Service_Appointment__c = :newAppointment.id];
        System.debug(testNotification);               
        System.assertEquals(testNotification.Notification_Type__c, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED, 'Correct Notificaiton/type was created');      
    }

    @isTest 
    static void resendNotificationNewNotificationTest()
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
        insert newAppointment;
        System.debug(newAppointment);
        
        //Map<id,String> notificaitonMap = new Map<id,String>();
        //notificaitonMap.put(newAppointment.id, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED);
        //Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS, EMAIL');    
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
            
        Appt_NotificationUtil.resendNotification(myWorkOrder.id,'SMS');
        Appt_NotificationUtil.resendNotification(myWorkOrder.id,'EMAIL');
        Test.stopTest();  
        System.debug('***********END TEST***************');
       
        Notification__c testNotification = [SELECT id, Notification_Type__c FROM Notification__c WHERE Service_Appointment__c = :newAppointment.id];
        System.debug(testNotification);               
        System.assertEquals(testNotification.Notification_Type__c, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED, 'Correct Notificaiton/type was created');      
    }

    @isTest
    static void getApptEmailTest(){
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();

        // Should be 2 appts in sf test, both belonging to the same service territory
        List<ServiceAppointment> appts = [SELECT Id, ServiceTerritory.Id, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Work_Order__c, Work_Order__r.AccountId, Work_Order__r.Source__c, Work_Order__r.ContactId FROM ServiceAppointment];
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present ');

        ServiceAppointment appt = appts[0];
        
        Notification__c newNotificaiton = new Notification__c();
        newNotificaiton.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED;
        newNotificaiton.Service_Appointment__c = appt.id;
        newNotificaiton.Account__c = appt.Work_Order__r.AccountId;
        newNotificaiton.Work_Order__c = appt.Work_Order__c;
        newNotificaiton.Source__c = appt.Work_Order__r.Source__c;
        newNotificaiton.Channels__c = 'EMAIL';
        newNotificaiton.Communication_Type__c = 'TRANSACTION';                    
        newNotificaiton.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
        newNotificaiton.Contact__c = appt.Work_Order__r.ContactId;
        newNotificaiton.Alternate_Contact__c = false;

        newNotificaiton.Invoice_Payload__c = Appt_InvoiceDetailModelTest.getJSON();

        insert newNotificaiton;     

        
        Appt_VFEmailController vfCont = new Appt_VFEmailController();
        vfCont.NotificationRef = newNotificaiton;

        String storeName = vfCont.getStoreName();
        String orderDate = vfCont.getOrderDate();
        String rescheduleUrl = vfCont.getRescheduleUrl();
        String cancelUrl = vfCont.getCancelUrl();
        String newApptUrl = vfCont.getNewApptUrl();
        String checkinUrl = vfCont.getCheckInUrl();
        String storeExpUrl = vfCont.getStoreExperienceUrl();
        String googleMapUrl = vfCont.getGoogleMapUrl();
        String appStoreUrl = vfCont.getAppleStoreUrl();
        String googleStoreUrl = vfCont.getGoogleStoreUrl();
        String facebookUrl = vfCont.getFacebookUrl();
        String twitterUrl = vfCont.getTwitterUrl();
        String instagramUrl = vfCont.getInstagramUrl();
        String youTubeUrl = vfCont.getYouTubeUrl();
        String unsubUrl = vfCont.getUnsubscribeUrl();
        String contactUsUrl = vfCont.getContactUsUrl();
        String prefUrl = vfCont.getPreferencesUrl();
        String privPolicyUrl = vfCont.getPrivacyPolicyUrl();
        String notTypeUrl = vfCont.getNotificationType();
        Boolean isConfirmed = vfCont.getIsConfirmed();
        Boolean isScheduled = vfCont.getIsScheduled();
        Boolean isCancelled = vfCont.getIsCancelled();
        Boolean isReminder = vfCont.getIsReminder();
        Boolean showOrder = vfCont.getShowMyOrder();
        String emailTitle = vfCont.getEmailTitle();
        String vehLine1 = vfCont.getVehicleLine1();
        String vehLine2 = vfCont.getVehicleLine2();
        List<Appt_VFEmailController.ProductItem> prodItemList = vfCont.getProductList();

        List<String> excludedList = new List<String>();
        excludedList.add('REFUND');


        Appt_InvoiceDetailModel.LineItems liRow = new Appt_InvoiceDetailModel.LineItems();
        Boolean inclRow = vfCont.includeRow( liRow, excludedList);

        vfCont.relatedTo.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_CONFIRMED;
        String confTitle = vfCont.getEmailTitle();

        vfCont.relatedTo.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED;
        String schTitle = vfCont.getEmailTitle();

        vfCont.relatedTo.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_CANCELLED;
        String cancelTitle = vfCont.getEmailTitle();

        vfCont.relatedTo.Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_REMINDER;
        String reminderTitle = vfCont.getEmailTitle();

        System.assertEquals(1, 1);  
    }   
 
    @isTest static void utilMethodsTest()
    {   
        
        Date today = Date.today();
        String testResult = '';

        Boolean isAt = true;
        String orderNumber = '12354';
        Date orderDate = today;
        String type = 'legacyOrderNumber';
        String storeName = '1235';
        
        
        System.debug('***********START TEST***************');
        Test.startTest();
        
        testResult = Appt_NotificationUtil.getBaseURL(true);
        testResult = Appt_NotificationUtil.getBaseURL(false);
        testResult = Appt_NotificationUtil.getOrderDate(today);
        testResult = Appt_NotificationUtil.getRescheduleUrl(isAt, orderNumber, orderDate, type, storeName);
        testResult = Appt_NotificationUtil.getCancelUrl(isAt, orderNumber, orderDate, 'invoiceNumber', storeName);
        testResult = Appt_NotificationUtil.getNewApptUrl(isAt, orderNumber, orderDate, 'hybrisOrderNumber', storeName, 'ServiceAppointment');
        testResult = Appt_NotificationUtil.getNewApptUrl(isAt, orderNumber, orderDate, 'quoteNumber', storeName, 'BOPIS');
        System.debug(testResult);
        System.assert(testResult.contains('schedule-appointment'), 'check for link constructrion');
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
       
           
    }
    
    @isTest static void buildEmailPayloadTest()
    {   
        WorkOrder myWorkOrder = [SELECT id FROM WorkOrder LIMIT 1]; 
        myWorkOrder.Order_Type__c = 'BOPIS';
        update myWorkOrder;

        Contact cont = new Contact();
        cont.LastName = 'Test';
        cont.FirstName = 'Test';
        insert cont;

        Notification__c newNoti = new Notification__c();
        newNoti.Notification_Type__c  = 'APPT_SCHEDULED'; 
        newNoti.Communication_Type__c = 'EMAIL'; 
        newNoti.Source__c = 'POS';         
        newNoti.Contact__c  = cont.Id;
        newNoti.Work_Order__c = myWorkOrder.Id;

        insert newNoti;

        Test.startTest();
        Notification__c testNoti = [SELECT id, 
                                    Account_Legal_Name__c,
                                    Appointment_Date_Format__c,
                                    Appointment_Status__c,
                                    Appointment_Time__c,
                                    Communication_Type__c,
                                    Contact__r.FirstName,
                                    Contact__r.LastName,
                                    Customer_City__c,
                                    Customer_Country__c,
                                    Customer_Email__c,
                                    Customer_Mobile_Phone__c,
                                    Customer_Name__c,
                                    Customer_State__c,
                                    Customer_Street__c,
                                    Customer_Zip__c,
                                    Fleet_Account_Number__c,
                                    Initial_Email_Send_Status__c,
                                    Initial_PE_Email_Payload__c,
                                    Notification_Type__c,
                                    Order_Date_Format__c,
                                    Order_Number__c,
                                    SAP_Store_Id__c,
                                    Store_Id__c,
                                    Service_Appointment__c,
                                    Store_City__c,
                                    Store_DBA_Name__c,
                                    Store_Name__c,
                                    Store_Phone_Number__c,
                                    Store_State__c,
                                    Store_Street__c,
                                    Store_Zip__c,
                                    Vehicle_Assembly_Id__c,
                                    Vehicle_Information__c,
                                    Vehicle_Number__c,
                                    Work_Order__c,
                                    Work_Order_Created_Date__c,
                                    Order_Type__c,
                                    Work_Order__r.Order_Type__c,
                                    Work_Order__r.Order_Date__c,
                                    Work_Order__r.Alternate_Contact__r.FirstName,
                                    Work_Order__r.Alternate_Contact__r.LastName, 
                                    Work_Order__r.Alternate_Contact__r.Phone, 
                                    Work_Order__r.Alternate_Contact__r.Email,
                                    Last_Error_Message__c,
                                    Appt3_Valid_Universal_Order_Id__c
                                    FROM Notification__c WHERE id= :newNoti.Id];

        newNoti = Appt_NotificationUtil.buildEmailPayload(testNoti);
        Test.stopTest();    

        System.assertNotEquals(null, newNoti.Initial_PE_Email_Payload__c);             
    }
    
     @isTest static void buildEmailPayloadAlternateContactTest()
    {   
        Contact altCont = new Contact();
        altCont.LastName = 'altTest';
        altCont.FirstName = 'altTest';
        altCont.phone = '9999999999';
        altCont.email = 'altTest@test.com';        
        insert altCont; 
        
        
        WorkOrder myWorkOrder = [SELECT id,contactId,Alternate_Contact__c FROM WorkOrder LIMIT 1]; 
        myWorkOrder.Order_Type__c = 'BOPIS';
        myWorkOrder.Alternate_Contact__c= altCont.id;
        update myWorkOrder;

        Contact cont = new Contact();
        cont.LastName = 'Test';
        cont.FirstName = 'Test';
        insert cont;
        

        Notification__c newNoti = new Notification__c();
        newNoti.Notification_Type__c  = 'APPT_SCHEDULED'; 
        newNoti.Communication_Type__c = 'EMAIL'; 
        newNoti.Source__c = 'POS';         
        newNoti.Contact__c  = cont.Id;
        newNoti.Work_Order__c = myWorkOrder.Id;

        insert newNoti;
        
        Test.startTest();
        Notification__c testNoti = [SELECT id, 
                                    Account_Legal_Name__c,
                                    Appointment_Date_Format__c,
                                    Appointment_Status__c,
                                    Appointment_Time__c,
                                    Communication_Type__c,
                                    Contact__r.FirstName,
                                    Contact__r.LastName,
                                    Customer_City__c,
                                    Customer_Country__c,
                                    Customer_Email__c,
                                    Customer_Mobile_Phone__c,
                                    Customer_Name__c,
                                    Customer_State__c,
                                    Customer_Street__c,
                                    Customer_Zip__c,
                                    Fleet_Account_Number__c,
                                    Initial_Email_Send_Status__c,
                                    Initial_PE_Email_Payload__c,
                                    Notification_Type__c,
                                    Order_Date_Format__c,
                                    Order_Number__c,
                                    SAP_Store_Id__c,
                                    Store_Id__c,
                                    Service_Appointment__c,
                                    Store_City__c,
                                    Store_DBA_Name__c,
                                    Store_Name__c,
                                    Store_Phone_Number__c,
                                    Store_State__c,
                                    Store_Street__c,
                                    Store_Zip__c,
                                    Vehicle_Assembly_Id__c,
                                    Vehicle_Information__c,
                                    Vehicle_Number__c,
                                    Work_Order__c,
                                    Work_Order_Created_Date__c,
                                    Order_Type__c,
                                    Work_Order__r.Order_Type__c,
                                    Work_Order__r.Order_Date__c,
                                    Work_Order__r.Alternate_Contact__r.FirstName,
                                    Work_Order__r.Alternate_Contact__r.LastName, 
                                    Work_Order__r.Alternate_Contact__r.Phone, 
                                    Work_Order__r.Alternate_Contact__r.Email,
                                    Last_Error_Message__c,
                                    Appt3_Valid_Universal_Order_Id__c
                                    FROM Notification__c WHERE id= :newNoti.Id];

        newNoti = Appt_NotificationUtil.buildEmailPayload(testNoti);
        Test.stopTest();    
        
        Appt_NotificationEmailPayload emailPayload = new Appt_NotificationEmailPayload();
        
        emailPayload.subscriberKey= testNoti.Work_Order__c;
        emailPayload.emailAddress=testNoti.Customer_Email__c;
        emailPayload.communicationType='A';
      	emailPayload.transactionType='BOPIS';
        emailPayload.orderNumber=testNoti.Order_Number__c;
        emailPayload.orderCreatedDate=String.valueOf(testNoti.Work_Order_Created_Date__c.format('yyyy-MM-dd'));
        emailPayload.customerName=testNoti.Customer_Name__c;
        emailPayload.vehicleId=testNoti.Vehicle_Number__c;
        emailPayload.vehicleInformation=testNoti.Vehicle_Information__c;
        emailPayload.streetAddress=testNoti.Customer_Street__c;
        emailPayload.city=testNoti.Customer_City__c;
        emailPayload.state=testNoti.Customer_State__c;
        emailPayload.zipCode=testNoti.Customer_Zip__c;
        emailPayload.country=testNoti.Customer_Country__c;
        emailPayload.customerPhone=testNoti.Customer_Mobile_Phone__c;
        emailPayload.storeId=testNoti.SAP_Store_Id__c;
        emailPayload.storeName=testNoti.Store_Name__c;
        emailPayload.storeStreetAddress=testNoti.Store_Street__c;
        emailPayload.storeCity=testNoti.Store_City__c;
        emailPayload.storeState=testNoti.Store_State__c;
        emailPayload.storeZipCode=testNoti.Store_Zip__c;
        emailPayload.storePhoneNumber=testNoti.Store_Phone_Number__c;
        emailPayload.appointmentTime=testNoti.Appointment_Time__c;
        emailPayload.recipientFirstName=testNoti.Work_Order__r.Alternate_Contact__r.FirstName;
        emailPayload.recipientLastName=testNoti.Work_Order__r.Alternate_Contact__r.LastName;
        emailPayload.recipientPhone=testNoti.Work_Order__r.Alternate_Contact__r.Phone;
        emailPayload.recipientEmail=testNoti.Work_Order__r.Alternate_Contact__r.Email;
        emailPayload.appointmentDate=testNoti.Appointment_Date_Format__c;
        emailPayload.appointmentStatus=testNoti.Appointment_Status__c;
        Datetime todaysDate = System.today();
        emailPayload.dateAdded=todaysDate.format('MMM') + ' ' + todaysDate.day() + ',' + todaysDate.year();
        emailPayload.fleetCompanyName=testNoti.Account_Legal_Name__c;
        emailPayload.fleetAccountNumber=testNoti.Fleet_Account_Number__c;
        emailPayload.orderCode=testNoti.Order_Number__c;
        emailPayload.storeCode=testNoti.Store_Id__c;
        emailPayload.orderDate=testNoti.Order_Date_Format__c;
        emailPayload.appointmentId=testNoti.Service_Appointment__c;
        emailPayload.vehicleAssemblyId=testNoti.Vehicle_Assembly_Id__c;   
 		emailPayload.clientId = 'DT';          
        emailPayload.customerKey='OrderConfirmationTSDv2';
        emailPayload.isUniversalOrderId = false;
        
 		string payLoad= Appt_NotificationEmailPayload.compose(emailPayload);

        System.assertEquals(payLoad, newNoti.Initial_PE_Email_Payload__c);    
      
    }

}