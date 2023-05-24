@isTest
public class Appt_SystemAPIAvailabilityServiceTest {
    @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);
    } 

    @isTest static void Appt_SiteAvailabilityErrorTest()
    {   
              
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"siteId": "1235","startDate": "2021-02-24","endDate": "2021-02-24","orderType": "ROPIS","customerType": "Retail","vehicleClass": "LT","vehicleId": "11645","trimId": "34061","assemblyId": "B","source": "WEB","items": []}';
    
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
        System.assertEquals('Error', results.status, 'Check for error');      
    } 

    @isTest static void Appt_SiteAvailabilitySuccessTest()
    {
               
        String startDateString = String.valueOf(system.today());
        String endDateString = String.valueOf(system.today().addDays(2));

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"siteId": "1235","startDate": "'+startDateString+'","endDate": "'+endDateString+'","orderType": "ROPIS","customerType": "Retail","vehicleClass": "LT","vehicleId": "11645","trimId": "34061","assemblyId": "B","source": "WEB","items": []}';
    
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

    @isTest static void Appt_SiteAvailabilityInvalidJSONExceptionTest()
    {       
 
        String startDateString = String.valueOf(system.today());
        String endDateString = String.valueOf(system.today().addDays(2));

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = 'sdfgdf-***-/+46!##%%';
    
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
        System.assertEquals('Error', results.status, 'Check for error');      
    } 

    @isTest static void Appt_SiteAvailabilityNoAvailabilityTest()
    {   
               
        String startDateString = String.valueOf(system.today().addDays(199));
        String endDateString = String.valueOf(system.today().addDays(200));

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String JSONMsg = '{"siteId": "1235","startDate": "'+startDateString+'","endDate": "'+endDateString+'","orderType": "ROPIS","customerType": "Retail","vehicleClass": "LT","vehicleId": "11645","trimId": "34061","assemblyId": "B","source": "WEB","items": []}';
    
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
        System.debug('****END TEST****');
        System.debug(results.message);
        System.assertEquals('No Availability for this site.', results.message, 'Check for no availability ');       
    } 

}