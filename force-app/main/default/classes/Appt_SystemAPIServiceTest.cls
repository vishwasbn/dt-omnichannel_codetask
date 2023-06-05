@isTest
public  class Appt_SystemAPIServiceTest {
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);
    } 

    @isTest static void createAppointmentNoApptTest()
    {   
              
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"appointmentStatus": "Pending","posCustomerId": null,"hybrisCustomerId": null,"siteId": "1235","source": "WEB","orderType": "ROPIS","appointmentDate":"2020-03-10","consultStartTime":"1100","consultEndTime":"1120", "backOfficeStartTime":"1120","backOfficeEndTime":"1140","formType": "","formNumber": "546884","formDate": "2021-01-02","hybrisOrderId": "12354581","posWebOrderId": "12354687","layawayNumber": "55489677","quoteNumber": "", "invoiceNumber": "0000256456846", "orderDate": "2020-12-31","customerGuid": "","customerType": "Retail","firstName": "Samuel","lastName": "Chapin","emailAddress": "Samuel.Chapin@gmail.com","mobilePhoneNumber": "6025555555","homePhoneNumber": "6025555555","workPhoneNumber": "6025555555", "address1": "123 Right Here Ln", "address2": "", "zipCode": "85310", "city": "Glendale", "state": "Arizona", "country": "United States", "textOptIn": false, "emailAddressOptIn": false, "posCustomerVehicleId": "WCV00000000025565475", "hybrisCustomerVehicleId": "10382", "vehicleClass": "PAS", "year": "2016", "make": "Ford", "model": "Escape", "vehicleId": "10382", "trimId": "1470", "assemblyId": "C", "articles": [ { "requestType": "Article", "articleId": "000000000000012345", "articleType": "", "articleCount": "2", "articleSize": "", "articleDescription": ""  } ], "recipientFirstName": "Jack", "recipientLastName": "Thomas", "recipientEmail": "jackthomas@none.com", "recipientPhone": "602-555-5555", "comments": "Some comments about the order or appointment"}';
    
        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_CreateAppointmentResponse results = new Appt_CreateAppointmentResponse();
        results = Appt_SystemAPIService.createAppointment();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results);
        System.assertEquals(null, results.appointmentId, 'No appointment should be created');      
    } 

    @isTest static void createAppointmentMakeApptTest()
    {   
        
        System.debug('***********START TEST Setup***************');
            

        Date startdate = system.today().addDays(7);
        Date starteOfWeek = startdate.toStartOfWeek();
        String apptDate = String.valueOf(starteOfWeek.addDays(1));  

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"appointmentStatus": "Pending","posCustomerId": null,"hybrisCustomerId": null,"siteId": "1235","source": "WEB","orderType": "ROPIS","appointmentDate":"'+apptDate+'","consultStartTime":"1100","consultEndTime":"1120", "backOfficeStartTime":"1120","backOfficeEndTime":"1140","formType": "","formNumber": "546884","formDate": "2021-01-02","hybrisOrderId": "12354581","posWebOrderId": "12354687","layawayNumber": "55489677","quoteNumber": "", "invoiceNumber": "0000256456846", "orderDate": "2020-12-31","customerGuid": "","customerType": "Retail","firstName": "Samuel","lastName": "Chapin","emailAddress": "Samuel.Chapin@gmail.com","mobilePhoneNumber": "6025555555","homePhoneNumber": "6025555555","workPhoneNumber": "6025555555", "address1": "123 Right Here Ln", "address2": "", "zipCode": "85310", "city": "Glendale", "state": "Arizona", "country": "United States", "textOptIn": false, "emailAddressOptIn": false, "posCustomerVehicleId": "WCV00000000025565475", "hybrisCustomerVehicleId": "10382", "vehicleClass": "PAS", "year": "2016", "make": "Ford", "model": "Escape", "vehicleId": "10382", "trimId": "1470", "assemblyId": "C", "articles": [ { "requestType": "Article", "articleId": "000000000000012345", "articleType": "", "articleCount": "2", "articleSize": "", "articleDescription": ""  } ], "recipientFirstName": "Jack", "recipientLastName": "Thomas", "recipientEmail": "jackthomas@none.com", "recipientPhone": "602-555-5555", "comments": "Some comments about the order or appointment"}';
    
        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_CreateAppointmentResponse results = new Appt_CreateAppointmentResponse();
        results = Appt_SystemAPIService.createAppointment();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results);
        System.assertEquals('Pending', results.appointmentStatus, 'No appointment should be created');      
    } 
    
    @isTest static void createAppointmentMakeApptExceptionTest()
    {                 

        System.debug('***********START TEST Setup***************');
            

        Date startdate = system.today().addDays(7);
        Date starteOfWeek = startdate.toStartOfWeek();
        String apptDate = String.valueOf(starteOfWeek.addDays(1));  

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"appointmentStatus": "Pending","posCustomerId": null,"hybrisCustomerId": null,"siteId": "1235","source": "WEB","orderType": "ROPIS","appointmentDate":"'+apptDate+'","consultStartTime":"1100","consultEndTime":"1120", "backOfficeStartTime":"1120","backOfficeEndTime":"1140","formType": "","formNumber": "546884","formDate": "2021-01-02","hybrisOrderId": "12354581","posWebOrderId": "12354687","layawayNumber": "55489677","quoteNumber": "", "invoiceNumber": "0000256456846", "orderDate": "2020-12-31","customerGuid": "","customerType": "Retail","firstName": "Samuel","lastName": "Chapin","emailAddress": "Samuel.Chapin@gmail.comjlasdhfosdohfewlahfofhlsdakfoi lasfh lfhs alsdfaoeiwh flwjekaslhg aoghweifheskwgefbawlrgj0aiewhn;ls jhouapwel;gwuihjas;dofu weoqanfl ;sjfopweafn;lsfhaowe;fnlasef","mobilePhoneNumber": "6025555555","homePhoneNumber": "6025555555","workPhoneNumber": "6025555555", "address1": "123 Right Here Ln", "address2": "", "zipCode": "85310", "city": "Glendale", "state": "Arizona", "country": "United States", "textOptIn": false, "emailAddressOptIn": "adsfkjadhsfklhasdkfhsdalkfhdfsakhksdfla", "posCustomerVehicleId": "WCV00000000025565475", "hybrisCustomerVehicleId": "10382", "vehicleClass": "PAS", "year": "2016", "make": "Ford", "model": "Escape", "vehicleId": "10382", "trimId": "1470", "assemblyId": "C", "articles": [ { "requestType": "Article", "articleId": "000000000000012345", "articleType": "", "articleCount": "2", "articleSize": "", "articleDescription": ""  } ], "recipientFirstName": "Jack", "recipientLastName": "Thomas", "recipientEmail": "jackthomas@none.com", "recipientPhone": "602-555-5555", "comments": "Some comments about the order or appointment"}';
    
        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_CreateAppointmentResponse results = new Appt_CreateAppointmentResponse();
        results = Appt_SystemAPIService.createAppointment();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results);
        System.assertEquals(null, results.appointmentStatus, 'No appointment should be created');      
    } 

    @isTest static void createAppointmentMakeApptExceptionTest2()
    {                 

        System.debug('***********START TEST Setup***************');
            

        Date startdate = system.today().addDays(7);
        Date starteOfWeek = startdate.toStartOfWeek();
        String apptDate = String.valueOf(starteOfWeek.addDays(1));  

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"appointmentStatus": "Pending","posCustomerId": null,"hybrisCustomerId": null,"siteId": "1235","source": "WESDGGB","orderType": "ROPISDSFG","appointmentDate":"'+apptDate+'","consultStartTime":"1100","consultEndTime":"1120", "backOfficeStartTime":"1120","backOfficeEndTime":"1140","formType": "","formNumber": "546884","formDate": "2021-01-02","hybrisOrderId": "12354581","posWebOrderId": "12354687","layawayNumber": "55489677","quoteNumber": "", "invoiceNumber": "0000256456846", "orderDate": "2020-12-31","customerGuid": "","customerType": "Retail","firstName": "Samuel","lastName": "Chapin","emailAddress": "Samuel.Chapin@gmail.com","mobilePhoneNumber": "6025555555","homePhoneNumber": "6025555555","workPhoneNumber": "6025555555", "address1": "123 Right Here Ln", "address2": "", "zipCode": "85310", "city": "Glendale", "state": "Arizona", "country": "United States", "textOptIn": false, "emailAddressOptIn": false, "posCustomerVehicleId": "WCV00000000025565475", "hybrisCustomerVehicleId": "10382", "vehicleClass": "PAS", "year": "2016", "make": "Ford", "model": "Escape", "vehicleId": "10382", "trimId": "1470", "assemblyId": "C", "articles": [ { "requestType": "Article", "articleId": "000000000000012345", "articleType": "", "articleCount": "2", "articleSize": "", "articleDescription": ""  } ], "recipientFirstName": "Jack", "recipientLastName": "Thomas", "recipientEmail": "jackthomas@none.com", "recipientPhone": "602-555-5555", "comments": "Some comments about the order or appointment"}';
    
        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_CreateAppointmentResponse results = new Appt_CreateAppointmentResponse();
        results = Appt_SystemAPIService.createAppointment();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results);
        System.assertEquals(null, results.appointmentStatus, 'No appointment should be created');      
    } 

    @isTest static void createAppointmentMakeApptExceptionTest3()
    {                 

        System.debug('***********START TEST Setup***************');
            

        Date startdate = system.today().addDays(200);
        Date starteOfWeek = startdate.toStartOfWeek();
        String apptDate = String.valueOf(starteOfWeek.addDays(1));  

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"appointmentStatus": "Pending","posCustomerId": null,"hybrisCustomerId": null,"siteId": "1235","source": "WEB","orderType": "ROPIS","appointmentDate":"'+apptDate+'","consultStartTime":"1100","consultEndTime":"1120", "backOfficeStartTime":"1120","backOfficeEndTime":"1140","formType": "","formNumber": "546884","formDate": "2021-01-02","hybrisOrderId": "12354581","posWebOrderId": "12354687","layawayNumber": "55489677","quoteNumber": "", "invoiceNumber": "0000256456846", "orderDate": "2020-12-31","customerGuid": "","customerType": "Retail","firstName": "Samuel","lastName": "Chapin","emailAddress": "Samuel.Chapin@gmail.com","mobilePhoneNumber": "6025555555","homePhoneNumber": "6025555555","workPhoneNumber": "6025555555", "address1": "123 Right Here Ln", "address2": "", "zipCode": "85310", "city": "Glendale", "state": "Arizona", "country": "United States", "textOptIn": false, "emailAddressOptIn": false, "posCustomerVehicleId": "WCV00000000025565475", "hybrisCustomerVehicleId": "10382", "vehicleClass": "PAS", "year": "2016", "make": "Ford", "model": "Escape", "vehicleId": "10382", "trimId": "1470", "assemblyId": "C", "articles": [ { "requestType": "Article", "articleId": "000000000000012345", "articleType": "", "articleCount": "2", "articleSize": "", "articleDescription": ""  } ], "recipientFirstName": "Jack", "recipientLastName": "Thomas", "recipientEmail": "jackthomas@none.com", "recipientPhone": "602-555-5555", "comments": "Some comments about the order or appointment"}';
    
        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_CreateAppointmentResponse results = new Appt_CreateAppointmentResponse();
        results = Appt_SystemAPIService.createAppointment();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results);
        System.assertEquals(null, results.appointmentStatus, 'No appointment should be created');      
    } 

    @isTest static void updateAppointmentExceptionTest()
    {   
         //List<ServiceAppointments> appts = [SELECT id, Work_Order__c, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
         System.debug('***********START TEST Setup***************');
              
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"siteId": "1235","startDate": "2021-02-24","endDate": "2021-02-24","orderType": "ROPIS","customerType": "Retail","vehicleClass": "LT","vehicleId": "11645","trimId": "34061","assemblyId": "B","source": "WEB","items": []}';
    
        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_UpdateAppointmentResponse results = new Appt_UpdateAppointmentResponse();
        results = Appt_SystemAPIService.updateAppointment();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results);
        System.assertEquals('Error', results.status, 'Check for bad request error');      
    } 

    @isTest static void updateAppointmentTimeChangeTest()
    {   
         //List<ServiceAppointments> appts = [SELECT id, Work_Order__c, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
         System.debug('***********START TEST Setup***************');
         List<WorkOrder> workOrders = [SELECT id FROM WorkOrder LIMIT 1];
         String apptId = workOrders[0].id;
         System.debug(apptId);

        Date startdate = system.today().addDays(7);
        Date starteOfWeek = startdate.toStartOfWeek();
        String apptDate = String.valueOf(starteOfWeek.addDays(1));  
              
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"appointmentStatus":null, "cancelReason":null, "cancelReasonText":null, "appointmentId":"'+apptId+'", "checkAvailabilityFirst":false, "posCustomerId": null, "hybrisCustomerId":null, "siteId":"1235", "source":"WEB", "orderType":"ROPIS", "appointmentDate":"'+apptDate+'", "consultStartTime":"0940", "consultEndTime":"1000", "backOfficeStartTime":"1000", "backOfficeEndTime":"1020", "formType": null, "formNumber": null, "formDate": null,  "hybrisOrderId": null, "posWebOrderId": null, "layawayNumber": null, "quoteNumber": null, "invoiceNumber": null, "orderDate": null, "customerGuid": null, "customerType": null,  "firstName": "Samuel", "lastName": "Chapin",  "emailAddress": null, "mobilePhoneNumber": null, "homePhoneNumber": null, "workPhoneNumber": null, "address1": null, "address2": null, "zipCode": null, "city": null, "state": null, "country": null,  "textOptIn": null,  "emailAddressOptIn": null,  "posCustomerVehicleId": null, "hybrisCustomerVehicleId": null, "vehicleClass": null, "year": null, "make": null, "model": null, "vehicleId": null, "trimId": null, "assemblyId": null, "articles":[ ],  "recipientFirstName": null, "recipientLastName": null, "recipientEmail": null, "recipientPhone": null,  "comments": null}';
        
        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_UpdateAppointmentResponse results = new Appt_UpdateAppointmentResponse();
        results = Appt_SystemAPIService.updateAppointment();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results);
        System.assertEquals('1000', results.backOfficeStartTime, 'Check for schedule time change');      
    } 

    @isTest static void updateAppointmentTimeChangeExceptionTest()
    {   
         //List<ServiceAppointments> appts = [SELECT id, Work_Order__c, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
         System.debug('***********START TEST Setup***************');
         List<WorkOrder> workOrders = [SELECT id FROM WorkOrder LIMIT 1];
         String apptId = workOrders[0].id;
         System.debug(apptId);

        Date startdate = system.today().addDays(200);
        Date starteOfWeek = startdate.toStartOfWeek();
        String apptDate = String.valueOf(starteOfWeek.addDays(1));  
              
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"appointmentStatus":null, "cancelReason":null, "cancelReasonText":null, "appointmentId":"'+apptId+'", "checkAvailabilityFirst":true, "posCustomerId": null, "hybrisCustomerId":null, "siteId":"1235", "source":"WEB", "orderType":"ROPIS", "appointmentDate":"'+apptDate+'", "consultStartTime":"0940", "consultEndTime":"1000", "backOfficeStartTime":"1000", "backOfficeEndTime":"1020", "formType": null, "formNumber": null, "formDate": null,  "hybrisOrderId": null, "posWebOrderId": null, "layawayNumber": null, "quoteNumber": null, "invoiceNumber": null, "orderDate": null, "customerGuid": null, "customerType": null,  "firstName": "Samuel", "lastName": "Chapin",  "emailAddress": null, "mobilePhoneNumber": null, "homePhoneNumber": null, "workPhoneNumber": null, "address1": null, "address2": null, "zipCode": null, "city": null, "state": null, "country": null,  "textOptIn": null,  "emailAddressOptIn": null,  "posCustomerVehicleId": null, "hybrisCustomerVehicleId": null, "vehicleClass": null, "year": null, "make": null, "model": null, "vehicleId": null, "trimId": null, "assemblyId": null, "articles":[ ],  "recipientFirstName": null, "recipientLastName": null, "recipientEmail": null, "recipientPhone": null,  "comments": null}';

        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_UpdateAppointmentResponse results = new Appt_UpdateAppointmentResponse();
        results = Appt_SystemAPIService.updateAppointment();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results);
        System.assertEquals(null, results.backOfficeStartTime, 'Check for appointment to fail');      
    } 

    @isTest static void updateAppointmentParseExceptionTest()
    {   
         //List<ServiceAppointments> appts = [SELECT id, Work_Order__c, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
         System.debug('***********START TEST Setup***************');
         List<WorkOrder> workOrders = [SELECT id FROM WorkOrder LIMIT 1];
         String apptId = workOrders[0].id;
         System.debug(apptId);

        Date startdate = system.today().addDays(200);
        Date starteOfWeek = startdate.toStartOfWeek();
        String apptDate = String.valueOf(starteOfWeek.addDays(1));  
              
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = 'sgsadfsadfadsfasdgh654979/468@#$';

        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(JSONMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_UpdateAppointmentResponse results = new Appt_UpdateAppointmentResponse();
        results = Appt_SystemAPIService.updateAppointment();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results);
        System.assertEquals(null, results.backOfficeStartTime, 'Check for payload parse exception');      
    } 

    @isTest static void checkForExampleData()
    {  
        System.debug('***********START TEST***************');
        Test.startTest();
        
        String results1 = Appt_SystemAPIServiceHandler.getAvailabilityResponseString();
        String results2 = Appt_SystemAPIServiceHandler.getCreateAppointmentResponseString();
        String results3 = Appt_SystemAPIServiceHandler.getUpdateAppointmentResponseString();
        
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(results1);
        System.assertNotEquals(null, results1 , 'Check for test Availabiltiy String');
        System.assertNotEquals(null, results2 , 'Check for test Create Appointment Response');
        System.assertNotEquals(null, results3 , 'Check for test Update Appointment Response');
    } 
}