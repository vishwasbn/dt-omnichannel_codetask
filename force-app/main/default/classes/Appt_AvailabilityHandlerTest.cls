@isTest
public with sharing class Appt_AvailabilityHandlerTest {
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

        
        



    }*/

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
}