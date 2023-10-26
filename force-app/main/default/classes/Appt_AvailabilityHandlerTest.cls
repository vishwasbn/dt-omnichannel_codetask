@isTest
public with sharing class  Appt_AvailabilityHandlerTest {
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
       //System.debug(createData);
    } 

    @isTest static void errorsTest()
    {     
        
        Appt_GetAvailabilityServiceModel modelE1 = new Appt_GetAvailabilityServiceModel();
        modelE1.siteId = '9999';
        modelE1.startDate = Date.today();
        modelE1.endDate = Date.today().addDays(3);
        modelE1.orderType = 'ROPIS';
        modelE1.customerType = 'Retail';
        modelE1.source = 'WEB';
        

        Appt_GetAvailabilityServiceModel modelE2 = new Appt_GetAvailabilityServiceModel();
        modelE2.siteId = '1235';
        modelE2.startDate = Date.today();
        modelE2.endDate = Date.today().addDays(3);
        modelE2.orderType = 'ROPIS';
        modelE2.customerType = 'Retail';
        modelE2.source = 'XYZ';

        Appt_GetAvailabilityServiceModel modelE3 = new Appt_GetAvailabilityServiceModel();
        modelE3.siteId = '1235';
        modelE3.startDate = Date.today();
        modelE3.endDate = Date.today().addDays(3);
        modelE3.orderType = 'ROPE';
        modelE3.customerType = 'Retail';
        modelE3.source = 'POS';
   
        
        System.debug('***********START TEST***************');
        Test.startTest();

        Appt_SiteAvailabilityModel modelAOut1 = Appt_SystemService.getSiteAvailability(modelE1);

        System.debug('modelE1:'+modelE1);
        System.debug('modelAOut1:'+modelAOut1);
        
        
        Appt_SiteAvailabilityModel modelAOut2 = Appt_SystemService.getSiteAvailability(modelE2);

        System.debug('modelE2:'+modelE2);
        System.debug('modelAOut2:'+modelAOut2);
        

        Appt_SiteAvailabilityModel modelAOut3 = Appt_SystemService.getSiteAvailability(modelE3);

        System.debug('modelE3:'+modelE3);
        System.debug('modelAOut3:'+modelAOut3);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');

        System.assert((modelAOut1.status != null && modelAOut1.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR), 'Expecting model status to be Error. modelOut.status='+modelAOut1.status);
        System.assert((modelAOut2.status != null && modelAOut2.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR), 'Expecting model status to be Error. modelOut.status='+modelAOut2.status);
        System.assert((modelAOut3.status != null && modelAOut3.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR), 'Expecting model status to be Error. modelOut.status='+modelAOut3.status);


        //System.assertEquals(400, testException.errorCode);
       
    } 

   /*
    @isTest static void calculateAvailableTimesTest() {

        Appt_GetAvailabilityServiceModel.Items item = new Appt_GetAvailabilityServiceModel.Items();
        item.articleId = '98911';

        Appt_GetAvailabilityServiceModel.Items item2 = new Appt_GetAvailabilityServiceModel.Items();
        item2.articleId = '98977';

        List<Appt_GetAvailabilityServiceModel.Items> itemss = new List<Appt_GetAvailabilityServiceModel.Items>();
        itemss.add(item);
        itemss.add(item2);

        Appt_GetAvailabilityServiceModel modelA = new Appt_GetAvailabilityServiceModel();
        modelA.siteId = '1235';
        modelA.startDate = Date.today();
        modelA.endDate = Date.today().addDays(3);
        modelA.orderType = 'ROPIS';
        modelA.customerType = 'Retail';
        modelA.source = 'WEB';
        modelA.items = itemss;

        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_SiteAvailabilityModel modelAOut = Appt_SystemService.getSiteAvailability(modelA);

        System.debug('modelA:'+modelA);
        System.debug('modelAOut:'+modelAOut);
        System.assert((modelAOut.status != null && modelAOut.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS), 'Expecting model status to be Success. modelOut.status='+modelAOut.status);
        System.assert((modelAOut.days != null && modelAOut.days.size() > 0), 'Expecting days List to be populated with more than 1 day. modelOut.days:'+modelAOut.days); 

        Appt_GetAvailabilityServiceModel checkAvailWeb = new Appt_GetAvailabilityServiceModel();
        checkAvailWeb.siteId = '1235';
        checkAvailWeb.orderType = 'ROPIS';
        checkAvailWeb.customerType = 'Retail';
        checkAvailWeb.source = 'WEB';
        checkAvailWeb.availabilityOnly = true;
        checkAvailWeb.appointmentDate = Date.valueOf(modelAOut.days.get(0).scheduleDate);
        Integer conStart = (Integer.valueOf(modelAOut.days.get(0).timeSlots.get(0).consultStartTime)) - 200;
        checkAvailWeb.consultStartTime = conStart.format().remove(',');
        Integer conEnd = (Integer.valueOf(modelAOut.days.get(0).timeSlots.get(0).consultEndTime)) - 200;
        checkAvailWeb.consultEndTime = conEnd.format().remove(',');
        Integer backStart = (Integer.valueOf(modelAOut.days.get(0).timeSlots.get(0).backOfficeStartTime)) - 200;
        checkAvailWeb.backOfficeStartTime = backStart.format().remove(',');
        Integer backEnd = (Integer.valueOf(modelAOut.days.get(0).timeSlots.get(0).backOfficeEndTime)) - 200;
        checkAvailWeb.backOfficeEndTime = backEnd.format().remove(',');
        System.debug('checkAvailWeb:'+checkAvailWeb);

        Boolean isAvailWeb = Appt_SystemService.checkAvailability(checkAvailWeb);
        System.debug('isAvailWeb:'+isAvailWeb);

        Appt_GetAvailabilityServiceModel checkAvailPos = new Appt_GetAvailabilityServiceModel();
        checkAvailPos.siteId = '1235';
        checkAvailPos.orderType = 'ROPIS';
        checkAvailPos.customerType = 'Retail';
        checkAvailPos.source = 'POS';
        checkAvailPos.availabilityOnly = true;
        checkAvailPos.appointmentDate = Date.valueOf(modelAOut.days.get(0).scheduleDate);
        checkAvailPos.consultStartTime = conStart.format().remove(',');
        checkAvailPos.consultEndTime = conEnd.format().remove(',');
        checkAvailPos.backOfficeStartTime = backStart.format().remove(',');
        checkAvailPos.backOfficeEndTime = backEnd.format().remove(',');
        System.debug('checkAvailPos:'+checkAvailPos);
        
        Boolean isAvailPos = Appt_SystemService.checkAvailability(checkAvailPos);
        System.debug('isAvailPos:'+isAvailPos);

        
        Test.stopTest();  
        System.debug('***********END TEST***************');

        
        
        
        //System.assert((modelAOut.status != null && modelAOut.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS), 'Expecting model status to be Success. modelOut.status='+modelAOut.status);
       // System.assert((modelAOut.days != null && modelAOut.days.size() > 0), 'Expecting days List to be populated with more than 1 day. modelOut.days:'+modelAOut.days); 

        
        



    }
  */

    @isTest static void workTypeArticlesTest() {  
        
        String startDateString = String.valueOf(system.today());
        String endDateString = String.valueOf(system.today().addDays(10));

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"siteId": "1235","startDate": "'+startDateString+'","endDate": "'+endDateString+'","orderType": "ServiceAppointment","customerType": "Retail","vehicleClass": "LT","vehicleId": "11645","trimId": "34061","assemblyId": "B","source": "WEB","items": []}';
    
        req.requestURI = '/services/apexrest/AppointmentAvailabilityService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        Appt_SiteAvailabilityResponse results = new Appt_SiteAvailabilityResponse();
        results = Appt_SystemAPIAvailabilityService.getAvailability();
        System.debug(results);
        
        Test.stopTest();    
        System.assertEquals('Success', results.status, 'Check for sucess');  

    }

    @isTest static void workTypeArticlesFleetTest() {  
        
        String startDateString = String.valueOf(system.today());
        String endDateString = String.valueOf(system.today().addDays(10));

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"siteId": "1235","startDate": "'+startDateString+'","endDate": "'+endDateString+'","orderType": "ServiceAppointment","customerType": "Fleet","vehicleClass": "LT","vehicleId": "11645","trimId": "34061","assemblyId": "B","source": "WEB","items": []}';
    
        req.requestURI = '/services/apexrest/AppointmentAvailabilityService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        Appt_SiteAvailabilityResponse results = new Appt_SiteAvailabilityResponse();
        results = Appt_SystemAPIAvailabilityService.getAvailability();
        System.debug(results);
        
        Test.stopTest();    
        System.assertEquals('Success', results.status, 'Check for sucess');  

    }

    @isTest static void workTypeArticlesPOSFleetTest() {  
        
        String startDateString = String.valueOf(system.today());
        String endDateString = String.valueOf(system.today().addDays(10));

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"siteId": "1235","startDate": "'+startDateString+'","endDate": "'+endDateString+'","orderType": "ServiceAppointment","customerType": "Fleet","vehicleClass": "LT","vehicleId": "11645","trimId": "34061","assemblyId": "B","source": "WEB","items": []}';
    
        req.requestURI = '/services/apexrest/AppointmentAvailabilityService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        Appt_SiteAvailabilityResponse results = new Appt_SiteAvailabilityResponse();
        results = Appt_SystemAPIAvailabilityService.getAvailability();
        System.debug(results);
        
        Test.stopTest();    
        System.assertEquals('Success', results.status, 'Check for sucess');  

    }
    
    @isTest static void calculateAvailableTimesForBothSlotsTest(){
        Appt_GetAvailabilityServiceModel availModel = new Appt_GetAvailabilityServiceModel();
        availModel.siteId='1235';
        availModel.startDate = Date.today().addDays(1);
        availModel.endDate = Date.today().addDays(1);
        availModel.orderType='ServiceAppointment';
        availModel.source='WEB';
        availModel.consultStartTime ='1500';
        availModel.consultEndTime ='1520';
        availModel.backOfficeStartTime ='1520';
        availModel.backOfficeEndTime ='1540'; 
		Appt_GetAvailabilityServiceModel.Items article = new Appt_GetAvailabilityServiceModel.Items();
        article.articleId = '84802';
        List<Appt_GetAvailabilityServiceModel.Items> articles = new List<Appt_GetAvailabilityServiceModel.Items>();
        articles.add(article); 
        availModel.items = articles;
        Test.startTest();        
        Appt_SiteAvailabilityModel returnModel = Appt_AvailabilityHandler.calculateAvailableTimes(availModel);            
        Test.stopTest();
        system.debug('@@@@'+returnModel);
        Assert.areEqual(Appt_ConstantValues.RESPONSE_STATUS_SUCCESS, returnModel.status);
        Assert.isNotNull(returnModel.days);
        Assert.isNotNull(returnModel.daysMap);
        Assert.isNotNull(returnModel.timeZone);
    }
    
    @isTest static void calculateAvailableTimesForPOSBackSlotsTest(){
        Appt_GetAvailabilityServiceModel availModel = new Appt_GetAvailabilityServiceModel();
        availModel.siteId='1235';
        availModel.startDate = Date.today();
        availModel.endDate = Date.today();
        availModel.orderType='Layaway';
        availModel.source='POS';
        availModel.backOfficeStartTime ='1520';
        availModel.backOfficeEndTime ='1540'; 
        Test.startTest();        
        Appt_SiteAvailabilityModel returnModel = Appt_AvailabilityHandler.calculateAvailableTimes(availModel);            
        Test.stopTest();
        Assert.areEqual(Appt_ConstantValues.RESPONSE_STATUS_SUCCESS, returnModel.status);
        Assert.isNotNull(returnModel.days);
        Assert.isNotNull(returnModel.daysMap);
        Assert.isNotNull(returnModel.timeZone);
    }
    
    //Apt 3 start
     @isTest static void getSlotsFromStartToEndTimeTest() {  
        
        Appt_ConstantValues.isVisionFeature = true;
        DateTime startDate= DateTime.newInstance(2023,01,06,15,15,0);
        DateTime endDate = startDate.addMinutes(30);
        Test.startTest();
         
         List<Appt_Time_Slot__c> slotsWithVisionTrue = Appt_AvailabilityHandler.getSlotsFromStartToEndTime('Back Room', 'WYO01', Date.newInstance(2023, 01, 06), startDate , endDate);
         
         System.debug('Slots for vision flag true'+slotsWithVisionTrue.size());
         
          Appt_ConstantValues.isVisionFeature = false;
         
         List<Appt_Time_Slot__c> slotsVisionFalse = Appt_AvailabilityHandler.getSlotsFromStartToEndTime('Back Room', 'WYO01', Date.newInstance(2023, 01, 06), startDate , endDate);
         
         System.debug('Slots for vision flag false'+slotsVisionFalse.size());
        
        Test.stopTest();    
        // System.assertEquals('Success', results.status, 'Check for sucess');  

    }
     //Appt 3.0 Started Added test for WorkType  - Date - 12/29/2022
    @IsTest
    static void calculateWorkTypeTestForMissingModel(){
        Test.startTest();        
        Appt_workTypeModel model = Appt_AvailabilityHandler.calculateWorkType(null);            
        Test.stopTest();
        Assert.isTrue(model.isError(), 'Appt_workTypeModel has error message');
    }
    @IsTest
    static void calculateWorkTypeTestForVisionFeature(){
        Appt_GetAvailabilityServiceModel availModel = new Appt_GetAvailabilityServiceModel();
        availModel.orderType='ROPIS';
        availModel.source='POS';
        availModel.consultStartTime ='0830';
        availModel.consultEndTime ='0845';
        availModel.isVisionFeature= true;               
        Test.startTest();        
        Appt_workTypeModel model = Appt_AvailabilityHandler.calculateWorkType(availModel);            
        Test.stopTest();
        Assert.areEqual(Appt_ConstantValues.WORK_TYPE_TYPE_BACK, model.type, 'Type for vision Feature');
    }
    //Appt 3.0 End Added test for WorkType  - Date - 12/29/2022

    @IsTest
    static void validateModelParamsTest(){
        Appt_GetAvailabilityServiceModel availModel = new Appt_GetAvailabilityServiceModel();
        Test.startTest();        
        Assert.isFalse(Appt_AvailabilityHandler.validateModelParams(availModel), 'False for empty siteId on availability Model');
        availModel.siteId='1222';
        Assert.isFalse(Appt_AvailabilityHandler.validateModelParams(availModel), 'False for empty startDate, endDate on availability Model');
        Test.stopTest();
    }    
    @IsTest
    static void checkAvailabilityTestForExceptionScenario(){
        Appt_GetAvailabilityServiceModel availModel = new Appt_GetAvailabilityServiceModel();
        availModel.appointmentDate=Date.newInstance(2022,12,10);       
        
        Appt_workTypeModel wrkTypModel = new Appt_workTypeModel();
        wrkTypModel.type = Appt_ConstantValues.WORK_TYPE_TYPE_FRONT;
        Test.startTest();   
        
        try{
            availModel.siteId='323232';
            Appt_AvailabilityHandler.checkAvailability(availModel,wrkTypModel);
            Assert.fail('Expected exception');
        } catch( Appt_AppointmentException e){
            Assert.isTrue(e.getmessage().contains('BAD REQUEST - could not retrieve timeZoneOffset'), 'timezoneOffset missing');            
        }
        
        try{
            availModel.timeZoneOffset=1;
            Appt_AvailabilityHandler.checkAvailability(availModel,wrkTypModel);
            Assert.fail('Expected exception');
        } catch( Appt_AppointmentException e){
            Assert.isTrue(e.getmessage().contains('BAD REQUEST - consultStartTime'), 'consultStartTime missing');            
        }
        
        
        try{
            availModel.consultStartTime ='0830';
            Appt_AvailabilityHandler.checkAvailability(availModel,wrkTypModel);
            Assert.fail('Expected exception');
        } catch( Appt_AppointmentException e){
            Assert.isTrue(e.getmessage().contains('BAD REQUEST - Appointment start time'), 'Appointment start time in past');            
        }
        Test.stopTest();
    }
    
    @IsTest
    static void getAvailabilitySlotsTestInCutOffTime(){
        
        DateTime startDate= DateTime.newInstance(2023,01,06,15,15,0);
        
        Appt_Time_Slot__c slotFront = new Appt_Time_Slot__c();
        slotFront.Type__c = Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT;
        slotFront.Start_Time__c = DateTime.newInstance(2023,01,05,09,30,0);       
        
        List<Appt_Time_Slot__c> frontSlots = new List<Appt_Time_Slot__c>();
        frontSlots.add(slotFront);
        
        Appt_Time_Slot__c slotBack = new Appt_Time_Slot__c();
        slotBack.Type__c = Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK;
        slotBack.Start_Time__c = DateTime.newInstance(2023,01,05,09,30,0);  
        
        List<Appt_Time_Slot__c> backSlots = new List<Appt_Time_Slot__c>();
        backSlots.add(slotBack);
        
        //Appt_AppointmentUtil.isInWebCutoffTime(slot.Start_Time__c);
        Test.startTest();
        List<Appt_Time_Slot__c> slotsFoundForBackend = Appt_AvailabilityHandler.getAvailableSlots(backSlots,'B','S','F',startDate,2,new Appt_SiteAvailabilityModel());
        Assert.isTrue(slotsFoundForBackend.isEmpty(),'Empty slots received.');
        List<Appt_Time_Slot__c> slotsFoundForFront = Appt_AvailabilityHandler.getAvailableSlots(frontSlots,'F','S','F',startDate,2,new Appt_SiteAvailabilityModel());
        Assert.isTrue(slotsFoundForFront.isEmpty(),'Empty slots received.');
        List<Appt_Time_Slot__c> slotsFoundForFrontFleetR = Appt_AvailabilityHandler.getAvailableSlots(frontSlots,'F','S','R',startDate,2,new Appt_SiteAvailabilityModel());        
        Assert.isTrue(slotsFoundForFrontFleetR.isEmpty(),'Empty slots received.');
        
        Test.stopTest();
    }
    
    @IsTest
    static void getAvailabilitySlotsTestOutOfCutOffTime(){
        
        DateTime startDate= DateTime.newInstance(2023,01,06,15,15,0);
        
        Appt_Time_Slot__c slotFront = new Appt_Time_Slot__c();
        slotFront.Type__c = Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT;
        slotFront.Start_Time__c = DateTime.now().addDays(2);    
        
        List<Appt_Time_Slot__c> frontSlots = new List<Appt_Time_Slot__c>();
        frontSlots.add(slotFront);
        
        Appt_Time_Slot__c slotBack = new Appt_Time_Slot__c();
        slotBack.Type__c = Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK;
        slotBack.Start_Time__c =  DateTime.now().addDays(2);     
        
        List<Appt_Time_Slot__c> backSlots = new List<Appt_Time_Slot__c>(); 
        backSlots.add(slotBack);        
        
        Test.startTest();
        List<Appt_Time_Slot__c> slotsFoundForBackendR = Appt_AvailabilityHandler.getAvailableSlots(backSlots,'B','S','R',startDate,2,new Appt_SiteAvailabilityModel());
        Assert.isTrue(slotsFoundForBackendR.isEmpty(),'Empty slots received.');
        List<Appt_Time_Slot__c> slotsFoundForBackend = Appt_AvailabilityHandler.getAvailableSlots(backSlots,'B','S','F',startDate,2,new Appt_SiteAvailabilityModel());
        Assert.isTrue(slotsFoundForBackend.isEmpty(),'Empty slots received.');
        List<Appt_Time_Slot__c> slotsFoundForFront = Appt_AvailabilityHandler.getAvailableSlots(frontSlots,'F','S','F',startDate,2,new Appt_SiteAvailabilityModel());
        Assert.isTrue(slotsFoundForFront.isEmpty(),'Empty slots received.');
        List<Appt_Time_Slot__c> slotsFoundForFrontFleetR = Appt_AvailabilityHandler.getAvailableSlots(frontSlots,'F','S','R',startDate,2,new Appt_SiteAvailabilityModel());
        Assert.isTrue(slotsFoundForFrontFleetR.isEmpty(),'Empty slots received.');     
        try{
            Appt_AvailabilityHandler.getAvailableSlots(frontSlots,'F','S','X',startDate,2,new Appt_SiteAvailabilityModel());
            Assert.fail('Exception steps, should go in catch.');
        } catch(Appt_AppointmentException e){
            Assert.isTrue(e.getMessage().contains('System Error - Unable to check slot availability'), 'No matching field, exception occured');
         
        }
        
        Test.stopTest();
    } 
    //Appt3.0 test coverage END  
}