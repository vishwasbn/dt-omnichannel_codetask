/*************************************************************************************************************************** 
Project : Appointment3.0
Purpose :It is the Test class for the Appt3_ApptsPageContainerController
**************************************************************************************************************************** 

Version     Date                     Updated By              TestCoverage         Comments	                                                      	 
1.0       26/12/2022    shubham.upadhyay@discounttire.com         91%        

**************************************************************************************************************************** 
*/
@isTest
public with sharing class Appt3_ApptsPageContainerControllerTest {
    
    static String posString = Appt_TestUtil.createPayload();

    @TestSetup
    static void setupData(){
        
        User pOSUser = Appt_TestUtil.getPosTerminalUser('TestPos' ,'TerminalTestUser'); // new changes
        List<ServiceAppointment> appts = Appt_TestUtil.basicAppointment_storeConfiguration();
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present (tag 1)');
        
    }
    // Testing  the ReturnModel method
    @isTest
    static void returnModelCreationTest(){
        
        user currentUser = [Select id from user where LastName = 'TerminalTestUser'  LIMIT 1 ];
        System.runas(currentUser){
            Test.startTest();
            Appt3_ApptsPageContainerController.ReturnModel rModel1 = new Appt3_ApptsPageContainerController.ReturnModel('pass', 'test1');
            Appt3_ApptsPageContainerController.ReturnModel rModel2 = new Appt3_ApptsPageContainerController.ReturnModel('fail', 'test2', JSON.serialize('{}'));
            Test.stopTest();
            System.assertEquals('test1', rModel1.message);
            System.assertEquals('test2', rModel2.message);
        }
    }

    // Testing out the getAppointmentServiceModel
    @isTest
    static void getAppointmentServiceModelTest(){
        
        Test.startTest();
        // Testing out the getAppointmentServiceModel with valid create json string
        String result1 = Appt3_ApptsPageContainerController.getAppointmentServiceModel(posString);
        
        // Testing out the getAppointmentServiceModel with valid view json string
        String result2 = Appt3_ApptsPageContainerController.getAppointmentServiceModel(createNewPosStringWithAction('VIEW'));
        
        // Testing out the getAppointmentServiceModel with an illegal action passed in
        String result3 = Appt3_ApptsPageContainerController.getAppointmentServiceModel(createNewPosStringWithAction('ILL'));
        
        // Testing out the getAppointmentServiceModel with an empty workOrderId
        String posStringInvalidWorkOrderId = posString.replace('"action": "CRT"', '"action": "VIEW", "workOrderId": null,');
        String result4 = Appt3_ApptsPageContainerController.getAppointmentServiceModel(posStringInvalidWorkOrderId);
        Test.stopTest();  
        
         
        Appt_CreateAppointmentServiceModel createApptModel = (Appt_CreateAppointmentServiceModel) JSON.deserialize(result1, Appt_CreateAppointmentServiceModel.class);
        Appt_UpdateAppointmentServiceModel updateApptModel = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(result2, Appt_UpdateAppointmentServiceModel.class);
        Appt_CreateAppointmentServiceModel exceptionModel = (Appt_CreateAppointmentServiceModel) JSON.deserialize(result3, Appt_CreateAppointmentServiceModel.class);
        Appt_CreateAppointmentServiceModel invalidWorkOrderIdModel = (Appt_CreateAppointmentServiceModel) JSON.deserialize(result4, Appt_CreateAppointmentServiceModel.class);
        
        System.assertEquals('John', createApptModel.firstName, 'First name of returned model does not match json first name');
        System.assertEquals('John', updateApptModel.firstName, 'First name of returned model does not match json first name');  
        System.assertEquals(Appt_ConstantValues.RESPONSE_STATUS_ERROR, exceptionModel.status, 'Exception not thrown when illegal action is inputted');  
        System.assertEquals(Appt_ConstantValues.RESPONSE_STATUS_ERROR, invalidWorkOrderIdModel.status , 'Invalid work order Id exception not thrown');
        

        // Cause an exception to make sure it is handled
        String invalidJsonString = '{"test";"blah"';
        try{
            system.debug('testig invalidJsonString ');
            String errorResult = Appt3_ApptsPageContainerController.getAppointmentServiceModel(invalidJsonString);
        }
        catch(Exception e){
            System.debug('pageContainerControllerTest -- in getAppointmentServiceModel exception catch method ');
            System.assertEquals(true, e != null, 'Should be an exception thrown');
        }
    }

    //Testing the createAppointment method
    @isTest
    static void createAppointmentTest(){
        Date currentDate = Date.today()+1;
        String currentDateString = String.valueOf(currentDate.year()) + '-' 
        +(currentDate.month() < 10 ? '0' +String.valueOf(currentDate.month()) : String.valueOf(currentDate.month()) ) +'-' 
        +(currentDate.day() < 10 ? '0' +String.valueOf(currentDate.day()) : String.valueOf(currentDate.day()));

         String posStringCreateAppointmentJson = posString.replace('"action": "CRT",', 
            '"action": "CRT",'
            +'"appointmentDate": "' +currentDateString +'",'
            +'"consultStartTime": "",'
            +'"consultEndTime": "",'
            +'"selectedSlotStartTime": "1300",'
            +'"selectedSlotEndTime": "1320",'
            +'"backOfficeStartTime": "1300",'
            +'"backOfficeEndTime": "1320",'
            +'"smsPhoneNumber": "1234567891",'
            +'"homePhoneNumber": "1234567891",' 
            +'"workPhoneNumber": "1234567891",'
            +'"mobilePhoneNumber": "1234567891",'
            +'"recipientPhone": "1234567891",'
            +'"isVisionFeature": true,'); 
        posStringCreateAppointmentJson.replace('"appointmentStatus": "Pending",', '"appointmentStatus": "Scheduled",');
        Appt_CreateAppointmentServiceModel jsonToModel = (Appt_CreateAppointmentServiceModel) JSON.deserialize(posStringCreateAppointmentJson, Appt_CreateAppointmentServiceModel.class);
        Test.startTest();
        String result = Appt3_ApptsPageContainerController.createAppointment(JSON.serialize(jsonToModel));
        system.debug('result is' +result);
        System.assert(result.contains('"status":"Success"'), 'Error while creating appointment');
        Test.stopTest();
                    
        // Cause an exception to make sure it is handled
        String invalidJson = '{"test"; "")';
        try{
            String errorResult = Appt3_ApptsPageContainerController.createAppointment(invalidJson);
            system.debug('errorResult' +errorResult);
        }
        catch(Exception e){
            System.debug('pageContainerControllerTest excpetion: ' +e);
            System.debug('pageContainerControllerTest -- in create exception catch method ');
            System.assertEquals(true, e != null, 'Should be an exception thrown');
        }
    }

    // Testing the rescheduleAppointment method
    @isTest
    static void rescheduleAppointmentTest(){
        Date currentDate = Date.today();
        String currentDateString = String.valueOf(currentDate.year()) + '-' 
        +(currentDate.month() < 10 ? '0' +String.valueOf(currentDate.month()) : String.valueOf(currentDate.month()) ) +'-' 
        +(currentDate.day() < 10 ? '0' +String.valueOf(currentDate.day()) : String.valueOf(currentDate.day()));

        List<ServiceAppointment> sa = [SELECT Id, Work_Order__r.Id FROM ServiceAppointment];
        System.assertEquals(true, sa.size() != 0, 'There are no service appts in sf');
        
        String workOrderId = sa[0].Work_Order__r.Id;
        String posStringRescheduleAppointmentJson = posString.replace('"action": "CRT",', 
            '"action": "RES",'
            +'"workOrderId": "' +workOrderId +'",'
            +'"appointmentDate": "' +currentDateString +'",'
            +'"consultStartTime": "",'
            +'"consultEndTime": "",'
            +'"backOfficeStartTime": "0920",'
            +'"backOfficeEndTime": "0940",'
            +'"smsPhoneNumber": "1234567891",'
            +'"homePhoneNumber": "1234567891",' 
            +'"workPhoneNumber": "1234567891",'
            +'"mobilePhoneNumber": "1234567891",'
            +'"recipientPhone": "1234567891",'
            +'"appointmentId": "' +workOrderId +'",');
            
        Appt_UpdateAppointmentServiceModel jsonToModel = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(posStringRescheduleAppointmentJson, Appt_UpdateAppointmentServiceModel.class);
        Test.startTest();
        String result = Appt3_ApptsPageContainerController.rescheduleAppointment(JSON.serialize(jsonToModel));
        system.debug('result is:-'+result);
        System.assert(result.contains('"status":"Success"'), 'Received error while rescheduling appointment');
        Test.stopTest();
        
        // Cause an exception to make sure it is handled
        String invalidJson = '{"test"; "")';
        try{
            String errorResult = Appt3_ApptsPageContainerController.rescheduleAppointment(invalidJson);
        }
        catch(Exception e){
            System.debug('pageContainerControllerTest excpetion: ' +e);
            System.assertEquals(true, e != null, 'Should be an exception thrown');
        }
    }

    // Testing the cancelAppointment method
    @isTest
    static void cancelAppointmentTest(){
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, 'Canceled');  
        // We need to get the workOrderId for the service appointments that we created
        List<ServiceAppointment> sa = [SELECT Id, Work_Order__r.Id FROM ServiceAppointment];
        System.assertEquals(true, sa.size() != 0, 'There are no service appts in sf');
        String saId = sa[0].Id;
        String workOrderId = sa[0].Work_Order__r.Id;
        String posStringCancel = posString.replace('"appointmentStatus": "Pending",', 
            '"appointmentStatus": "Canceled",' 
            +'"workOrderId": "' +workOrderId +'",'
            +'"smsPhoneNumber": "1234567891",'
            +'"homePhoneNumber": "1234567891",' 
            +'"workPhoneNumber": "1234567891",'
            +'"mobilePhoneNumber": "1234567891",'
            +'"recipientPhone": "1234567891",'
            +'"appointmentId": "' +workOrderId +'",'
            +'"cancelReason": "No Show",');
            
        Appt_UpdateAppointmentServiceModel cancelJSONToModel = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(posStringCancel, Appt_UpdateAppointmentServiceModel.class);
        Test.startTest();
        String result = Appt3_ApptsPageContainerController.cancelAppointment(JSON.serialize(cancelJSONToModel));
        system.debug('result is' +result);
        System.assert(result.contains('"status":"Success"'), 'Received error while cancelling appointment');

        Test.stopTest();
        
        // Cause an exception to make sure it is handled
        String invalidJson = '{"test"; "")';
        try{
            String errorResult = Appt3_ApptsPageContainerController.cancelAppointment(invalidJson);
        }
        catch(Exception e){
            System.debug('pageContainerControllerTest -- in cancel exception catch method ' +e);
            System.assertEquals(true, e != null, 'Should be an exception thrown');
        }
    }

    // Testing the editCustomerDetails method
    @isTest
    static void editCustomerDetailsTest(){
        // We need to get the contact Id for the service appointments that we created
        List<ServiceAppointment> sa = [SELECT Id, Work_Order__c, AccountId FROM ServiceAppointment];
        System.assertEquals(true, sa.size() != 0, 'There are no service appts in sf');
       
        String acctId = sa[0].AccountId;
        Id workOrderId = sa[0].Work_Order__c;
        String fieldsToEditJson = '{"textOptIn": true, "emailAddressOptIn": true, "smsPhoneNumber": "1111111111"}';
        
		Test.startTest();
        String result1 = Appt3_ApptsPageContainerController.editCustomerDetails(acctId, fieldsToEditJson);
		Test.stopTest();
        System.assertEquals(true, result1.equals('done'), 'Edit Customer Details should return successfully with string \'done\'');
        fieldsToEditJson = '{}';
        acctId = '';

        try {
            String result2 = Appt3_ApptsPageContainerController.editCustomerDetails(acctId,fieldsToEditJson);
        }
        catch(Exception e) {
            System.assertEquals(true, e != null, 'Should have thrown an exception');
        }
    }

   @isTest
    static void getSFBaseUrlTest(){
        
        String baseUrlAsPerOrg = Appt3_ApptsPageContainerController.getSFBaseUrl();
        Test.startTest();
        String baseUrl = Appt3_ApptsPageContainerController.getSFBaseUrl();
        Test.stopTest();
        system.assertEquals(true, baseUrl.equals(baseUrlAsPerOrg), 'Both Url should be same');    
    }

    // Testing the resendNotification method
    @isTest
    static void updateAppointmentNotificationsTest(){     
        
        // Testing out the getAppointmentServiceModel with valid view json string
        String result2 = Appt3_ApptsPageContainerController.getAppointmentServiceModel(createNewPosStringWithAction('VIEW'));             
        Appt_UpdateAppointmentServiceModel updateApptModel = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(result2, Appt_UpdateAppointmentServiceModel.class);
        
        List<WorkOrder> testWorkOrder = [SELECT id from WorkOrder LIMIT 1];
        ServiceAppointment appt = [SELECT id FROM ServiceAppointment WHERE Work_Order__c = :testWorkOrder[0].id LIMIT 1];
        appt.Notification_Appointment__c = true;

        update appt;

        updateApptModel.workOrderId = testWorkOrder[0].id;
        updateApptModel.appointmentId = testWorkOrder[0].id;
        System.debug(updateApptModel.workOrderId);

        String testResult = '';
        System.debug('***********START TEST***************');
        Test.startTest();
        testResult = Appt3_ApptsPageContainerController.resendNotification(JSON.serialize(updateApptModel), 'SMS');    
        testResult = Appt3_ApptsPageContainerController.resendNotification(JSON.serialize(updateApptModel), 'EMAIL');   
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testResult);
        System.assert(testResult.contains('"status":null'), 'checks for invalid status');
        
    }
   
    //Appt3.0 Test Added for updateAppointmentNotificationException - 12/23/2022 - Start
     @isTest
    static void updateAppointmentNotificationsExceptionTest(){
        Boolean exceptionOccurred = false;
        Test.startTest();
        try{
            Appt3_ApptsPageContainerController.resendNotification('Test', 'SMS');   
        } catch (AuraHandledException exp){
            exceptionOccurred= true;
            System.debug('Exception catched: '+ exp.getMessage());   
        }
        Test.stopTest(); 
        System.assertEquals(true, exceptionOccurred, 'An Exception was not thrown');

    }
    
    @isTest
    static void processVehicleAndCustomerEditableFieldsTest(){
        
        Appt_CreateAppointmentServiceModel model = new Appt_CreateAppointmentServiceModel();
        model.trimId='555501';
        model.mobilePhoneNumber='123456';
        Test.startTest();
        Appt3_ApptsPageContainerController.processVehicleAndCustomerEditableFields(model);
        Test.stopTest();
        System.assertEquals(model.smsPhoneNumber, '123456','Phone number assigned to sms number');   
    }
    
    //Testing the enrichResponseToUI method
    @isTest
    static void enrichResponseToUITest(){
        
        List<ServiceAppointment> sa = [SELECT Id, Work_Order__r.Id FROM ServiceAppointment];
        system.debug('SA val' +sa);
        System.assertEquals(true, sa.size() != 0, 'There are no service appts in sf');
        Workorder workOrderId = new workOrder();
        workOrderId.id=sa[0].Work_Order__r.Id;
        workOrderId.SMS_Phone__c='1234567891';
        update workOrderId;
        system.debug('workOrderId val ' +workOrderId);
        
        String newString = '{"action": "VIEW","workOrderId": "' +workOrderId.id +'"}';
        system.debug('newString is' +newString);
        
        WorkOrderLineItem lineItem = new WorkOrderLineItem(); 
        lineItem.WorkOrderId = workOrderId.id;
       lineItem.WOM_Article_Description__c = 'Description for testing WOLI';
        lineItem.WOM_Article_Number__c = '0000011111' ;
        lineItem.WOM_Article_Quantity__c = 5 ;
        lineItem.WOM_ArticleSize__c = 'Sample Size' ;
        lineItem.Appt3_Article_Type__c = 'Electronics';
        insert lineItem;
        system.debug('lineItem' +lineItem);
        
        Test.startTest();
        String result = Appt3_ApptsPageContainerController.getAppointmentServiceModel(newString);
        Test.stopTest();     
    }
    
     //Testing the updateAlternativePhone method
    @isTest
    static void updateAlternativePhoneTest(){
        
        List<ServiceAppointment> sa = [SELECT Id, Work_Order__r.Id FROM ServiceAppointment];
        System.assertEquals(true, sa.size() != 0, 'There are no service appts in sf');
        String workOrderId = sa[0].Work_Order__r.Id;
        WorkOrder wo = [SELECT id, AccountId,SMS_Phone__c FROM WorkOrder WHERE id = :workOrderId];
        String smsPhoneNumber = wo.SMS_Phone__c;
        Test.startTest();
        String result = Appt3_ApptsPageContainerController.updateAlternativePhone(workOrderId,smsPhoneNumber);
        Test.stopTest();
        system.assertEquals(true, result.equals('done'));
        
         // Cause an exception to make sure it is handled
        String workid = '12345';
        try{
            system.debug('testig invalidWorkorderId ');
            String errorResult = Appt3_ApptsPageContainerController.updateAlternativePhone(workid,'1111');
        }
        catch(Exception e){
            System.debug('pageContainerControllerTest -- in getAppointmentServiceModel exception catch method '+e);
            System.assertEquals(true, e != null, 'Should be an exception thrown');
        }      
    }
    
    // Testing the fetchNotificationsToRender method
    @isTest
    static void fetchNotificationsToRenderTest(){
		
        List<Notification__c> notifications = new List<Notification__c>();
        List<ServiceAppointment> sa = [SELECT Id, Work_Order__r.Id FROM ServiceAppointment];
        
        Notification__c notify1 = new Notification__c();
        notify1.Service_Appointment__c = sa[0].id ;
        notify1.Channels__c = 'EMAIL';
        notify1.Initial_Email_Send_Date__c = Date.valueOf('2022-12-21 00:00:00');
        notify1.Initial_Email_Send_Status__c = 'Pending';
        
        Notification__c notify2 = new Notification__c();
        notify2.Service_Appointment__c = sa[0].id ;
        notify2.Channels__c = 'SMS';
        notify2.Initial_PE_SMS_Send_Date__c = Date.valueOf('2022-12-21 00:00:00');
        notify2.Initial_Email_Send_Status__c = 'Pending';
        notifications.add(notify1);
        notifications.add(notify2);
        
        insert notifications;
        system.debug('notifications' +notifications);
        Appt_CreateAppointmentServiceModel model1 = (Appt_CreateAppointmentServiceModel) JSON.deserialize(posString, Appt_CreateAppointmentServiceModel.class);
        Test.startTest();
        Appt3_ApptsPageContainerController.fetchNotificationsToRender(notifications,model1);
        Test.stopTest();
        system.debug('model1.emailNotificationsSent' +model1.emailNotificationsSent.size());
        system.assertEquals(true,model1.emailNotificationsSent.size()>0);   
    } 
    // Testing out the  recordPayload
    @isTest
    static void recordPayloadTest(){
         Test.startTest();
        Appt3_ApptsPageContainerController.recordPayload(posString,'OMNI');
         Int_Message__c recordPayInt = [SELECT id, Type__c FROM Int_Message__c order by createddate desc limit 1];
          Test.stopTest();
         System.assertEquals('Appt 3.0_OMNI_Payload_Incoming', recordPayInt.Type__c,'Not Matching Type');
    }
    // Test method for getAppointmentDetails
    @isTest
    static void getAppointmentDetailsTest(){
        Appt_CreateAppointmentServiceModel negitiveTestModel= new Appt_CreateAppointmentServiceModel();
        negitiveTestModel.workOrderId=null;
        test.startTest();
        Appt3_ApptsPageContainerController.getAppointmentDetails(negitiveTestModel);
        test.stopTest();
        system.assertEquals(Appt_ConstantValues.RESPONSE_STATUS_ERROR, negitiveTestModel.status);
    }
    
    // UTILITIES
    public static String createNewPosStringWithAction(String action){
        if(action.equalsIgnoreCase('VIEW')){
            // We need to get the workOrderId for the service appointments that we created
            List<ServiceAppointment> sa = [SELECT Id, Work_Order__r.Id FROM ServiceAppointment];
            System.assertEquals(true, sa.size() != 0, 'There are no service appts in sf');

            String workOrderId = sa[0].Work_Order__r.Id;
            // Change action to view and add a workOrderId to it
            return posString.replace('"action": "CRT"', '"action": "VIEW",' +'"workOrderId": "' +workOrderId +'"');
        }
        else {
            // Change action to view and add a workOrderId to it
            return posString.replace('"action": "CRT"', '"action": "' +action +'"');
        }
    }
      
}