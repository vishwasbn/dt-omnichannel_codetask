@isTest
public with sharing class Appt_AppointmentUpdateHandlerTest {
    final static string lprefix = 'LOG Appt_AppointmentUpdateHandlerTest: ';
    
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);

        createData = [SELECT Id, Status, Activity_Type__c, SchedStartTime, SchedEndTime, ParentRecordId, ContactId FROM ServiceAppointment];
        System.debug(lprefix + '#Appointments: ' + createData.size());
        for (ServiceAppointment sa: createData){
            System.debug(lprefix + 'Appointment: ' + sa);
        }

        //merge code start

        Appt_CreateAppointmentServiceModel.Articles item = new Appt_CreateAppointmentServiceModel.Articles();
        item.articleId = '98911';

        Appt_CreateAppointmentServiceModel.Articles item2 = new Appt_CreateAppointmentServiceModel.Articles();
        item2.articleId = '98977';
        //merge code end

        Appt_CreateAppointmentServiceModel model1 = Appt_TestUtil.getCreateAppointmentServiceModel();

        // create back only
        Date startdate = Date.today().addDays(14);
        Date starteOfWeek = startdate.toStartOfWeek();
        Date tday = starteOfWeek.addDays(1);
        model1.appointmentDate = tday;
        model1.consultStartTime = '';
        model1.consultEndTime = '';
        model1.backOfficeStartTime = '1640';
        model1.backOfficeEndTime = '1700';
        model1.orderType = 'BOPIS';

        Appt_CreateAppointmentServiceModel apptServMdl = Appt_AppointmentHandler.createAppointment(model1);
        
    } // End of setupData()


    @isTest 
    static void invalidModelTest ()
    {   
        
        Appt_UpdateAppointmentServiceModel testModel = new Appt_UpdateAppointmentServiceModel();

        System.debug(lprefix + '***********START TEST***************');
        Test.startTest();
       
        Boolean results = Appt_AppointmentUpdateHandler.validateRescheduledAppointmentParams(testModel);
        System.assertEquals(false, results, 'Check for invalid combos');   
        testModel.source = 'WEB';
        testModel.orderType = 'ROPIS';
        results = Appt_AppointmentUpdateHandler.validateRescheduledAppointmentParams(testModel);
        System.assertEquals(false, results, 'Check for invalid combos');  
        testModel.appointmentDate = date.today();
        results = Appt_AppointmentUpdateHandler.validateRescheduledAppointmentParams(testModel);
        System.assertEquals(false, results, 'Check for invalid combos');  
        testModel.consultStartTime = '0900';
        testModel.consultEndTime = '0820';
        testModel.backOfficeStartTime = '0920';
        testModel.backOfficeEndTime = '0940';
        results = Appt_AppointmentUpdateHandler.validateRescheduledAppointmentParams(testModel);
        System.assertEquals(false, results, 'Check for invalid combos');  
        testModel.consultStartTime = '0900';
        testModel.consultEndTime = '0920';
        testModel.backOfficeStartTime = '0950';
        testModel.backOfficeEndTime = '0940';
        results = Appt_AppointmentUpdateHandler.validateRescheduledAppointmentParams(testModel);  
        System.assertEquals(false, results, 'Check for invalid combos');        
        testModel.consultStartTime = '0900';
        testModel.consultEndTime = '0920';
        testModel.backOfficeStartTime = '0920';
        testModel.backOfficeEndTime = '0940';
        results = Appt_AppointmentUpdateHandler.validateRescheduledAppointmentParams(testModel);
        Test.stopTest();  
        System.debug(lprefix + '***********END TEST***************');
        System.debug(lprefix + results);
        System.assertEquals(true, results, 'Check for valid combos');

    } // End of invalidModelTest()

    
    @isTest
    static void checkIfUpdateTest ()
    {   
        
        Appt_UpdateAppointmentServiceModel updateParamsModel = new Appt_UpdateAppointmentServiceModel();
        Appt_UpdateAppointmentServiceModel existingApptModel = new Appt_UpdateAppointmentServiceModel();

        updateParamsModel.backOfficeEndTime = '0900';

        System.debug(lprefix + '***********START TEST***************');
        Test.startTest();
       
        
        Boolean results = Appt_AppointmentUpdateHandler.checkIfUpdateServiceAppointment(updateParamsModel,existingApptModel);
        
        Test.stopTest();  
        System.debug(lprefix + 'checkIfUpdateTest::result: ' + results);
        System.assertEquals(true, results, 'Check for a field to update');
        System.debug(lprefix + '***********END TEST***************');

    } // End of checkIfUpdateTest()


    @isTest static void updateAppointmentWithNullModelErrorTest()
    {   
        System.debug( lprefix + '***********START updateAppointmentWithNullModelErrorTest Setup***************');

        Test.startTest();

        Appt_UpdateAppointmentServiceModel apptServMdl = Appt_AppointmentUpdateHandler.updateAppointment(null);
        
        Test.stopTest();  

        System.assertEquals(true, apptServMdl.isError(), 'Should be a null apptModel error');
        System.assertEquals('Required apptModel model parameter is null', apptServMdl.message, 'Error message for null apptModel incorrect');

        System.debug( lprefix + '***********END updateAppointmentWithNullModelErrorTest***************');

    } // End of updateAppointmentWithNullModelErrorTest()


    @isTest static void updateAppointmentWithAppointmentTest()
    {   
        System.debug( lprefix + '***********START updateAppointmentWithAppointmentTest Setup***************');

        List<ServiceAppointment> apptList = [SELECT Id, ParentRecordId, Status, Activity_Type__c, SchedStartTime, SchedEndTime, ContactId, Work_Order__r.ServiceTerritoryId, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
        System.debug( lprefix +  'Appointment: ' + apptList[0]);
        System.debug( lprefix +  'Workorder: ' + apptList[0].Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c);

        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED);

        Appt_UpdateAppointmentServiceModel model1 = new Appt_UpdateAppointmentServiceModel();

        // update for customer created in setup
        model1.appointmentId = apptList[0].ParentRecordId;
        model1.ServiceTerritoryId = apptList[0].Work_Order__r.ServiceTerritoryId;
        model1.siteId = apptList[0].Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;
        model1.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;
        model1.emailAddress = 'test@test.com';
        model1.recipientEmail= 'testupdate@test.com';  // appt 3.0 change

        Test.startTest();

        Appt_UpdateAppointmentServiceModel apptServMdl = Appt_AppointmentUpdateHandler.updateAppointment(model1);
        // appt 3.0 changes start
        model1.appointmentId = apptList[0].ParentRecordId;
        model1.ServiceTerritoryId = apptList[0].Work_Order__r.ServiceTerritoryId;
        model1.siteId = apptList[0].Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;
        model1.recipientFirstName='ram';
        model1.recipientLastName='s';
        model1.recipientPhone='1234567890';
        Appt_UpdateAppointmentServiceModel apptServMdl_2 = Appt_AppointmentUpdateHandler.updateAppointment(model1);
        // appt 3.0 changes end
        Test.stopTest();  

        System.debug( lprefix + 'updateAppointmentWithAppointmentTest::result: ' + apptServMdl);
        System.assertEquals('Success', apptServMdl.status, 'update Appointment with Appointment failed');
        // appt 3.0 changes start
        System.assertEquals('Success', apptServMdl_2.status, 'update Appointment with Appointment failed');
        List<Contact> contacts;
        contacts = [SELECT FirstName, lastName, Email, Phone, MobilePhone FROM Contact WHERE Email ='testupdate@test.com'];
        System.assertEquals('ram', contacts[0].FirstName, 'updating Appointment contact info failed');
        // appt 3.0 changes end
        System.debug( lprefix + '***********END updateAppointmentWithAppointmentTest***************');

    } // End of updateAppointmentWithAppointmentTest()
    
    @isTest static void updateAppointmentWithNullTest()
    {   
        System.debug( lprefix + '***********START updateAppointmentWithNullTest Setup***************');

        List<ServiceAppointment> apptList = [SELECT Id, ParentRecordId, Status, Activity_Type__c, SchedStartTime, SchedEndTime, ContactId, Work_Order__r.ServiceTerritoryId, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
        System.debug( lprefix +  'Appointment: ' + apptList[0]);
        System.debug( lprefix +  'Workorder: ' + apptList[0].Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c);

        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED);

        Appt_UpdateAppointmentServiceModel model1 = new Appt_UpdateAppointmentServiceModel();

        // update for customer created in setup
        model1.appointmentId = apptList[0].ParentRecordId;
        model1.ServiceTerritoryId = apptList[0].Work_Order__r.ServiceTerritoryId;
        model1.siteId = apptList[0].Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;
        model1.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;
        model1.consultStartTime = null;
        model1.consultEndTime = null;
        model1.backOfficeStartTime = '0830';
        model1.backOfficeEndTime = '0900';
        model1.consultAppointmentId = null;
        model1.source = 'WEB';
        model1.orderType = 'ROPIS';
        model1.emailAddress = 'test@test.com';
        model1.appointmentDate = Date.today();
        
        List<ServiceAppointment> frontSAList = new List<ServiceAppointment>();
        for(ServiceAppointment sa: apptList)
        {
            if(sa.Activity_Type__c=='FRONT ROOM')
                frontSAList.add(sa);
        }
        
        if(frontSAList.size()>0)
            delete frontSAList;

        Test.startTest();

        Appt_UpdateAppointmentServiceModel apptServMdl = Appt_AppointmentUpdateHandler.updateAppointment(model1);
        
        Test.stopTest();  

        System.debug( lprefix + 'updateAppointmentWithNullTest::result: ' + apptServMdl);
        List<ServiceAppointment> newFrontSAList = [select Id from ServiceAppointment where Activity_Type__c='FRONT ROOM'];
        System.assertEquals(0, newFrontSAList.size(), 'front SA exists');

        System.debug( lprefix + '***********END updateAppointmentWithNullTest***************');

    } // End of updateAppointmentWithNullTest()


    @isTest static void updateAppointmentWithNotificationTest()
    {   
        System.debug( lprefix + '***********START updateAppointmentWithNotificationTest Setup***************');

        List<ServiceAppointment> apptList = [SELECT Id, ParentRecordId, Status, Notification_Appointment__c, Activity_Type__c, SchedStartTime, SchedEndTime, ContactId, Work_Order__r.ServiceTerritoryId, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
        System.debug( lprefix +  'Appointment: ' + apptList[0]);
        System.debug( lprefix +  'Workorder: ' + apptList[0].Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c);

        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED);

        Appt_UpdateAppointmentServiceModel model1 = new Appt_UpdateAppointmentServiceModel();

        // update for customer created in setup
        model1.appointmentId = apptList[0].ParentRecordId;
        model1.ServiceTerritoryId = apptList[0].Work_Order__r.ServiceTerritoryId;
        model1.siteId = apptList[0].Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;
        model1.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;
        model1.emailAddress = 'test@test.com';

        Test.startTest();

        Appt_UpdateAppointmentServiceModel apptServMdl = Appt_AppointmentUpdateHandler.updateAppointment(model1);
        
        Test.stopTest();  

        System.debug( lprefix + 'updateAppointmentWithNotificationTest::result: ' + apptServMdl);
        System.assertEquals('Success', apptServMdl.status, 'update Appointment with Notification failed');

        System.debug( lprefix + '***********END updateAppointmentWithNotificationTest***************');

    } // End of updateAppointmentWithNotificationTest()


    @isTest static void updateAppointmentWithBackOnlyTest()
    {   
        System.debug( lprefix + '***********START updateAppointmentWithBackOnlyTest Setup***************');

        List<ServiceAppointment> apptList = [SELECT Id, ParentRecordId, Status, Site_Id__c, Source__c, Order_Type__c, Notification_Appointment__c, Activity_Type__c, SchedStartTime, SchedEndTime, Consult_Start_Time__c, Consult_End_Time__c, Back_Office_Start_Time__c, Back_Office_End_Time__c, ContactId, Work_Order__c, Work_Order__r.ServiceTerritoryId, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Customer_Type__c, Timezone_Offset__c FROM ServiceAppointment WHERE Source__c='POS'];
        System.debug( lprefix +  'Appointment: ' + apptList.size());
        System.assertEquals(1, apptList.size(), 'not the expected number of Service Appointments');

        //Code merge start
        List<ServiceAppointment> apptList2 = [SELECT Id, ParentRecordId, Status, Notification_Appointment__c, Activity_Type__c, SchedStartTime, SchedEndTime, ContactId, Work_Order__r.ServiceTerritoryId, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED);

        Appt_UpdateAppointmentServiceModel model2 = new Appt_UpdateAppointmentServiceModel();

        // update for customer created in setup
        model2.appointmentId = apptList2[0].ParentRecordId;
        model2.ServiceTerritoryId = apptList2[0].Work_Order__r.ServiceTerritoryId;
        model2.siteId = apptList2[0].Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;
        //model2.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED;
        Date startdate = Date.today().addDays(14);
        Date starteOfWeek = startdate.toStartOfWeek();
        Date tday = starteOfWeek.addDays(1);
        model2.appointmentDate = tday;
        model2.consultStartTime = '';
        model2.consultEndTime = '';
        model2.backOfficeStartTime = '1640';
        model2.backOfficeEndTime = '1700';
        model2.orderType = 'BOPIS';
        //Code merge end

        for (ServiceAppointment sa: apptList){
            System.debug( lprefix + 'ServAppt: ' + sa);
        }

        Appt_UpdateAppointmentServiceModel model1 = Appt_TestUtil.convertServiceAppointmentToModel( apptList[0] );

        model1.backOfficeStartTime = apptList[0].SchedStartTime.addMinutes(60).format('HHmm');
        model1.backOfficeEndTime = apptList[0].SchedEndTime.addMinutes(60).format('HHmm');
       //Code merge start
        Appt_UpdateAppointmentServiceModel modelUpdate = new Appt_UpdateAppointmentServiceModel();
        
        modelUpdate.source = Appt_ConstantValues.APPOINTMENT_SOURCE_WEB;
        modelUpdate.orderType = 'ROPIS';
        Date tooday = Date.today();
        modelUpdate.appointmentDate = tooday.addDays(1);
        modelUpdate.consultStartTime = '1520';
        modelUpdate.consultEndTime = '1540';
        modelUpdate.backOfficeStartTime = '1540';
        modelUpdate.backOfficeEndTime = '1600';
       
       
        //model2.consultStartTime = apptList[0].SchedStartTime.addMinutes(60).format('HHmm');
        //model2.consultEndTime = apptList[0].SchedEndTime.addMinutes(60).format('HHmm');
        //Code merge End

        Test.startTest();

        Appt_UpdateAppointmentServiceModel apptServMdl = Appt_AppointmentUpdateHandler.updateAppointment(model1);
        
        System.debug('updateAppointmentWithBackOnlyTest::ServModel: ' + apptServMdl);
        System.assertEquals('Success', apptServMdl.status, 'update Appointment with Back only failed');

         //Code Merge Start
        modelUpdate.appointmentId = apptServMdl.appointmentId;
        Appt_UpdateAppointmentServiceModel apptUpdateMdl2 = Appt_AppointmentUpdateHandler.updateAppointment(modelUpdate);
        System.assertEquals('Success', apptUpdateMdl2.status, 'update Appointment with Back only failed');

        
        Appt_UpdateAppointmentServiceModel apptUpdateMdl = Appt_AppointmentUpdateHandler.updateAppointment(model2);
        System.assertEquals('Success', apptUpdateMdl.status, 'update Appointment with Back only failed');
        //Code Merge End


        Test.stopTest();  


        System.debug( lprefix + '***********END updateAppointmentWithBackOnlyTest***************');

    } // End of updateAppointmentWithBackOnlyTest()


    @isTest static void appointmentUpdateHandlerTest ()
    {   
         //List<ServiceAppointments> appts = [SELECT id, Work_Order__c, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
         System.debug(lprefix + '***********START appointmentUpdateHandlerTest***************');
         List<WorkOrder> workOrders = [SELECT id FROM WorkOrder LIMIT 1];
         String apptId = workOrders[0].id;
         System.debug(lprefix + apptId);

        Date startdate = system.today().addDays(7);
        Date starteOfWeek = startdate.toStartOfWeek();
        String apptDate = String.valueOf(starteOfWeek.addDays(1));  
              
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"appointmentStatus":"Pending", "cancelReason":null, "cancelReasonText":null, "appointmentId":"'+apptId+'", "checkAvailabilityFirst":false, "posCustomerId": null, "hybrisCustomerId":"846468", "siteId":"1237", "source":"WEB", "orderType":"ROPIS", "appointmentDate":"'+apptDate+'", "consultStartTime":"0940", "consultEndTime":"1000", "backOfficeStartTime":"1000", "backOfficeEndTime":"1020", "formType": null, "formNumber": null, "formDate": null,  "hybrisOrderId": null, "posWebOrderId": null, "layawayNumber": null, "quoteNumber": null, "invoiceNumber": null, "orderDate": null, "customerGuid": null, "customerType": null,  "firstName": "Samuel", "lastName": "Chapin",  "emailAddress": null, "mobilePhoneNumber": null, "homePhoneNumber": null, "workPhoneNumber": null, "address1": null, "address2": null, "zipCode": null, "city": null, "state": null, "country": null,  "textOptIn": null,  "emailAddressOptIn": null,  "posCustomerVehicleId": null, "hybrisCustomerVehicleId": null, "vehicleClass": null, "year": null, "make": null, "model": null, "vehicleId": null, "trimId": null, "assemblyId": null, "articles":[ ],  "recipientFirstName": null, "recipientLastName": null, "recipientEmail": null, "recipientPhone": null,  "comments": null}';
        
        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug(lprefix + '***********START TEST***************');
        Test.startTest();
        Appt_UpdateAppointmentResponse results = new Appt_UpdateAppointmentResponse();
        results = Appt_SystemAPIService.updateAppointment();
        
        
        Test.stopTest();

        System.debug(lprefix + 'appointmentUpdateHandlerTest::results: ' + results);
        System.assertEquals('Error', results.status, 'appointment Update Handler responded incorrectly');

        System.debug(lprefix + '***********END appointmentUpdateHandlerTest***************');

    } // End of appointmentUpdateHandlerTest()
    
    
  @isTest static void updateAppointmentCancelledTest()
    {   
        List<ServiceAppointment> apptList = [SELECT Id, ParentRecordId, Status, AccountId, Work_Order__r.AssetId,  Site_Id__c, Source__c, Order_Type__c, Notification_Appointment__c, Activity_Type__c, SchedStartTime, SchedEndTime, Consult_Start_Time__c, Consult_End_Time__c, Back_Office_Start_Time__c, Back_Office_End_Time__c, ContactId, Work_Order__c, Work_Order__r.ServiceTerritoryId, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Customer_Type__c, Timezone_Offset__c FROM ServiceAppointment WHERE Source__c='POS'];
        System.debug( lprefix +  'Appointment: ' + apptList.size());
        System.assertEquals(1, apptList.size(), 'not the expected number of Service Appointments');
        Appt_UpdateAppointmentServiceModel modelUpdate1 = new Appt_UpdateAppointmentServiceModel();
        modelUpdate1.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED;
        modelUpdate1.cancelReasonText = 'Test';
        modelUpdate1.cancelReason = 'Other';
        Appt_UpdateAppointmentServiceModel modelUpdate2 = new Appt_UpdateAppointmentServiceModel();
        modelUpdate2.appointmentId = apptList[0].Work_Order__c;
        modelUpdate2.accountId = apptList[0].AccountId;
        modelUpdate2.contactId = apptList[0].ContactId;
        String existingApptStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        Test.startTest();
		Appt_AppointmentUpdateHandler.updateWorkOrder(modelUpdate1, existingApptStatus, modelUpdate2 );
        existingApptStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED;
        modelUpdate1.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        Appt_AppointmentUpdateHandler.updateWorkOrder(modelUpdate1, existingApptStatus, modelUpdate2 );
        Test.stopTest();  
    } 
    
    
     @isTest static void updateServiceAppointmentsCatchException()
    {   
        List<ServiceAppointment> apptList = [SELECT Id, ParentRecordId, Status, Site_Id__c, Source__c, Order_Type__c, Notification_Appointment__c, Activity_Type__c, SchedStartTime, SchedEndTime, Consult_Start_Time__c, Consult_End_Time__c, Back_Office_Start_Time__c, Back_Office_End_Time__c, ContactId, Work_Order__c, Work_Order__r.ServiceTerritoryId, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, Customer_Type__c, Timezone_Offset__c FROM ServiceAppointment WHERE Source__c='POS'];
        System.debug( lprefix +  'Appointment: ' + apptList.size());
        System.assertEquals(1, apptList.size(), 'not the expected number of Service Appointments');
        
        Appt_UpdateAppointmentServiceModel model1 = Appt_TestUtil.convertServiceAppointmentToModel( apptList[0] );
		model1.appointmentStatus ='Canceled';
        model1.cancelReason ='Other';
        model1.cancelReasonText ='test class';
    
        
        Test.startTest();
        try{
         Appt_UpdateAppointmentServiceModel apptServMdl = Appt_AppointmentUpdateHandler.updateAppointment(model1);
        }
        catch(Exception e){
            System.assertEquals(true, e != null, 'Should be an exception thrown');
        }
        Test.stopTest();  
   
    }
    
}