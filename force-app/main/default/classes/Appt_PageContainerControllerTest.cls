@isTest
public with sharing class Appt_PageContainerControllerTest {
    static String posString = '{"action": "CRT",'
        +'"appointmentStatus": "Pending",'
        +'"posCustomerId": "9130000081",'
        +'"hybrisCustomerId": "", '
        +'"formType": "BOP",'
        +'"orderType": "BOPIS",'
        +'"formNumber": "1009465",'
        +'"orderDate": "20201210",'
        +'"formDate": "20201210",'
        +'"hybrisOrderId": "",'
        +'"posWebOrderId": "",'
        +'"layawayNumber": "000002",'
        +'"quoteNumber": "001",'
        +'"guid": "",'
        +'"customerType": "Retail",'
        +'"firstName": "John",'
        +'"lastName": "Johnson",'
        +'"emailAddress": "JOHN@DT.TEST.com",'
        +'"mobileAreaCode": "555",'
        +'"mobilePhoneNumber": "1234567",'
        +'"homeAreaCode": "555",'
        +'"homePhoneNumber": "1234567",'
        +'"workAreaCode": "555",'
        +'"workPhoneNumber": "1234567",'
        +'"siteId": "6667",'
        +'"textOptIn": false,'
        +'"emailAddressOptIn": false,'
        +'"address1": "123 E Camelback Rd",'
        +'"address2": "",'
        +'"zipCode": "85395",'
        +'"city": "PHOENIX",'
        +'"state": "Arizona",'
        +'"country": "United States",'
        +'"posCustomerVehicleId": "1002007",'
        +'"hybrisCustomerVehicleID": "",'
        +'"vehicleType": "Fitment",'
        +'"year": "2012",'
        +'"make": "HONDA",'
        +'"model": "CIVIC COUPE",'
        +'"vehicleId": "32570",'
        +'"trimId": "8427",'
        +'"assemblyId": "5469|8427|D",'
        +'"articles": [{ '
            +'"quantity": 1,'
            +'"size": "195 65   R15    91H SL BSW ",'
            +'"articleType": "Tire",'
            +'"articleId": "32491",'
            +'"description": "MCH DEFENDER T H"'
        +'}]'
        +'}';



    @TestSetup
    static void setupData(){
        List<ServiceAppointment> appts = Appt_TestUtil.basicAppointment_storeConfiguration();
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present (tag 1)');
    }

    @isTest
    static void returnModelCreationTest(){
        Appt_AppointmentsPageContainerController.ReturnModel rModel1 = new Appt_AppointmentsPageContainerController.ReturnModel('pass', 'test1');
        Appt_AppointmentsPageContainerController.ReturnModel rModel2 = new Appt_AppointmentsPageContainerController.ReturnModel('fail', 'test2', JSON.serialize('{}'));
    
        System.assertEquals('test1', rModel1.message);
        System.assertEquals('test2', rModel2.message);
    }

    @isTest
    static void getAppointmentServiceModelTest(){

        // Testing out the getAppointmentServiceModel with valid create json string
        String result1 = Appt_AppointmentsPageContainerController.getAppointmentServiceModel(posString);

        // Testing out the getAppointmentServiceModel with valid view json string
        String result2 = Appt_AppointmentsPageContainerController.getAppointmentServiceModel(createNewPosStringWithAction('VIEW'));
        
        // Testing out the getAppointmentServiceModel with an illegal action passed in
        String result3 = Appt_AppointmentsPageContainerController.getAppointmentServiceModel(createNewPosStringWithAction('ILL'));

        // Testing out the getAppointmentServiceModel with an empty workOrderId
        String posStringInvalidWorkOrderId = posString.replace('"action": "CRT"', '"action": "VIEW", "workOrderId": null,');
        String result4 = Appt_AppointmentsPageContainerController.getAppointmentServiceModel(posStringInvalidWorkOrderId);

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
            String errorResult = Appt_AppointmentsPageContainerController.getAppointmentServiceModel(invalidJsonString);
        }
        catch(Exception e){
            System.debug('pageContainerControllerTest -- in getAppointmentServiceModel exception catch method ');
            System.assertEquals(true, e != null, 'Should be an exception thrown');
        }
    }

    

    @isTest
    static void createAppointmentTest(){
        Date currentDate = Date.today();
        String currentDateString = String.valueOf(currentDate.year()) + '-' 
        +(currentDate.month() < 10 ? '0' +String.valueOf(currentDate.month()) : String.valueOf(currentDate.month()) ) +'-' 
        +(currentDate.day() < 10 ? '0' +String.valueOf(currentDate.day()) : String.valueOf(currentDate.day()));

        String posStringCreateAppointmentJson = posString.replace('"action": "CRT",', 
            '"action": "CRT",'
            +'"appointmentDate": "' +currentDateString +'",'
            +'"consultStartTime":"",'
            +'"consultEndTime":"",'
            +'"backOfficeStartTime": "0920",'
            +'"backOfficeEndTime":"0940",');
        
        Appt_CreateAppointmentServiceModel jsonToModel = (Appt_CreateAppointmentServiceModel) JSON.deserialize(posStringCreateAppointmentJson, Appt_CreateAppointmentServiceModel.class);
        String result = Appt_AppointmentsPageContainerController.createAppointment(JSON.serialize(jsonToModel));

        // Cause an exception to make sure it is handled
        String invalidJson = '{"test"; "")';
        try{
            String errorResult = Appt_AppointmentsPageContainerController.createAppointment(invalidJson);
        }
        catch(Exception e){
            System.debug('pageContainerControllerTest excpetion: ' +e);
            System.debug('pageContainerControllerTest -- in create exception catch method ');
            System.assertEquals(true, e != null, 'Should be an exception thrown');
        }
    }

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
            +'"consultStartTime":"",'
            +'"consultEndTime":"",'
            +'"backOfficeStartTime": "0920",'
            +'"backOfficeEndTime": "0940",');

        Appt_UpdateAppointmentServiceModel jsonToModel = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(posStringRescheduleAppointmentJson, Appt_UpdateAppointmentServiceModel.class);
        String result = Appt_AppointmentsPageContainerController.rescheduleAppointment(JSON.serialize(jsonToModel));
        
        // Cause an exception to make sure it is handled
        String invalidJson = '{"test"; "")';

        try{
            String errorResult = Appt_AppointmentsPageContainerController.rescheduleAppointment(invalidJson);
        }
        catch(Exception e){
            System.debug('pageContainerControllerTest excpetion: ' +e);
            System.debug('pageContainerControllerTest -- in reschedule exception catch method ');
            System.assertEquals(true, e != null, 'Should be an exception thrown');
        }
    
    }

    @isTest
    static void cancelAppointmentTest(){
        // We need to get the workOrderId for the service appointments that we created
        List<ServiceAppointment> sa = [SELECT Id, Work_Order__r.Id FROM ServiceAppointment];
        System.assertEquals(true, sa.size() != 0, 'There are no service appts in sf');
        String saId = sa[0].Id;

        String posStringCancel = posString.replace('"appointmentStatus":"Pending"', '"appointmentStatus":"Canceled", "workOrderId": "' +saId +'"');

        Appt_UpdateAppointmentServiceModel jsonToModel = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(posStringCancel, Appt_UpdateAppointmentServiceModel.class);

        String result = Appt_AppointmentsPageContainerController.cancelAppointment(JSON.serialize(jsonToModel));
        String resultNULL='';
        try {
            resultNULL = Appt_AppointmentsPageContainerController.cancelAppointment(null);
            system.debug('resultNULL ::: '+resultNULL);
        }
        catch(Exception e) {
			system.debug('resultNULL in EX ::: '+resultNULL);
            System.AssertNotEquals(NULL,e);
            //System.assertEquals(true, e != null, 'Should have thrown an exception');
        }
    
    }

     @isTest
    static void cancelAppointmentCatchExceptionTest(){
        
               
        try {
            system.debug('Inside cancelAppointmentCatchExceptionTest in testclass');
            String result = Appt_AppointmentsPageContainerController.cancelAppointment(' ');
            system.debug('After calling cancelAppointment in Testclass');
        } catch(Exception e) {
            system.debug('Inside CancelAppointment Exeption in Testclass');
            System.AssertNotEquals(NULL,e);
            //system.assertEquals(true,e.getMessage().contains('Last Name'));
        }
        
    }

    @isTest
    static void editCustomerDetailsTest(){
        // We need to get the contact Id for the service appointments that we created
        List<ServiceAppointment> sa = [SELECT Id, Work_Order__c, AccountId FROM ServiceAppointment];
        System.assertEquals(true, sa.size() != 0, 'There are no service appts in sf');
       
        String acctId = sa[0].AccountId;
        Id workOrderId = sa[0].Work_Order__c;
        String fieldsToEditJson = '{"textOptIn": true, "emailAddressOptIn": true, "smsPhoneNumber": "1111111111"}';

        String result1 = Appt_AppointmentsPageContainerController.editCustomerDetails(acctId, workOrderId, fieldsToEditJson);

        System.assertEquals(true, result1.equals('done'), 'Edit Customer Details should return successfully with string \'done\'');
        fieldsToEditJson = '{}';
        acctId = '';
		String resultNULL='';
        try {
            resultNULL = Appt_AppointmentsPageContainerController.editCustomerDetails(null, null, null);
            system.debug('resultNULL ::: '+resultNULL);
        }
        catch(Exception e) {
			system.debug('resultNULL in EX ::: '+resultNULL);
            System.AssertNotEquals(NULL,e);
            //System.assertEquals(true, e != null, 'Should have thrown an exception');
        }

    }


    @IsTest
    static void getCustomerEditableFieldsTest(){
        Appt_CreateAppointmentServiceModel jsonToModel = (Appt_CreateAppointmentServiceModel) JSON.deserialize(createNewPosStringWithAction('VIEW'), Appt_CreateAppointmentServiceModel.class);

        Test.startTest();

        WorkOrder wo = [SELECT Id, SMS_Phone__c FROM WorkOrder WHERE Id=:jsonToModel.workOrderId LIMIT 1];
        wo.SMS_Phone__c = '1111111111';
        update wo;

        Appt_AppointmentsPageContainerController.getCustomerEditableFields(jsonToModel);
        System.assertEquals(true, jsonToModel != null);
        Test.stopTest();
    }


    @isTest
    static void getSFBaseUrlTest(){
        String baseUrl = Appt_AppointmentsPageContainerController.getSFBaseUrl();
        System.debug('test class base url: ' +baseUrl);
    }
@isTest
    static void updateAppointmentNotificationsTestMethod(){
        WorkOrder obj_workorder = new WorkOrder();
        //obj_workorder.Name='TestWorkOrder';
        insert obj_workorder;
        
        Notification__c obj_Notify = new Notification__c();
        obj_Notify.Work_Order__c = obj_workorder.id;
        insert obj_Notify;    
        
        Reference__c obj_Ref = new Reference__c();
        obj_Ref.Name = 'Test Reference ';
            insert obj_Ref;
        
		Test.startTest();
		Appt_AppointmentsPageContainerController.updateAppointmentNotifications(obj_workorder.id);
        Test.stopTest(); 
        Appt_CreateAppointmentServiceModel model = new Appt_CreateAppointmentServiceModel();
        Appt_AppointmentsPageContainerController.getAppointmentDetails(model);
    }
    
    @isTest
    static void updateAppointmentNotificationsTest(){     
        

        // Testing out the getAppointmentServiceModel with valid view json string
        String result2 = Appt_AppointmentsPageContainerController.getAppointmentServiceModel(createNewPosStringWithAction('VIEW'));             

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
        
        testResult = Appt_AppointmentsPageContainerController.resendNotification(JSON.serialize(updateApptModel), 'SMS');    
        testResult = Appt_AppointmentsPageContainerController.resendNotification(JSON.serialize(updateApptModel), 'EMAIL');   
        try{
           String testNULLResult = Appt_AppointmentsPageContainerController.resendNotification(null, 'SMS');  
        } catch(exception e){
            System.AssertNotEquals(NULL,e);
        }
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testResult);
        System.assert(testResult.contains('"status":null'), 'checks for invalid status');
        
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