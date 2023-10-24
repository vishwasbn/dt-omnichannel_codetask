@isTest
public without sharing class Appt_InvoiceServiceTest 
{
    // date pass parameter
    @isTest 
    static void invoiceServiceInvalidParamTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();
        
        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetail('','','');
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.status, 'Error', 'Throws error for invalid data');
          
    } 

    @isTest 
    static void invoiceServiceInvalidDateTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();
        
        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetail('1235','156165','08-12-11901');
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.status, 'Error', 'Throws error for invalid date');
          
    } 

    @isTest 
    static void buildRequestReturnErrorTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();
        
        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetail('1235','156165','2020-01-01');
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.message, 'Request for Invoice Detail FAILED', 'Check for fail message for outbound request');
          
    } 

    // type pass parameter
    
    @isTest 
    static void invoiceTypeServiceInvalidParamTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();

        Integer idType = null;
        
        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetail('','',idType);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.status, 'Error', 'Throws error for invalid data');
          
    } 

    @isTest 
    static void invoiceTypeServiceInvalidDateTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();
        
        Integer idType = null;

        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetail('1235','156165',idType);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.status, 'Error', 'Throws error for invalid date');
          
    } 

    @isTest 
    static void buildTypeRequestReturnErrorTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();
        
        Integer idType = 1;

        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetail('1235','156165',idType);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.message, 'Request for Invoice Detail FAILED', 'Check for fail message for outbound request');
          
    } 

    /*    ********************************************************   */

    // BULK date pass parameter
    @isTest 
    static void invoiceServiceInvalidParamBulkTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();

        List<Int_Message__c> intMsgList = new List<Int_Message__c>();
        
        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetailBulk('','','', intMsgList);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.status, 'Error', 'Throws error for invalid data');
          
    } 

    @isTest 
    static void invoiceServiceInvalidDateBulkTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();
        
        List<Int_Message__c> intMsgList = new List<Int_Message__c>();

        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetailBulk('1235','156165','08-12-11901', intMsgList);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.status, 'Error', 'Throws error for invalid date');
          
    } 

    @isTest 
    static void buildRequestReturnErrorBulkTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();
        
        List<Int_Message__c> intMsgList = new List<Int_Message__c>();

        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetailBulk('1235','156165','2020-01-01', intMsgList);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.message, 'Request for Invoice Detail FAILED', 'Check for fail message for outbound request');
          
    } 

    // BULK type pass parameter
    
    @isTest 
    static void invoiceTypeServiceInvalidParamBulkTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();

        Integer idType = null;
        List<Int_Message__c> intMsgList = new List<Int_Message__c>();
        
        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetailBulk('','',idType, intMsgList);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.status, 'Error', 'Throws error for invalid data');
          
    } 

    @isTest 
    static void invoiceTypeServiceInvalidDateBulkTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();
        
        Integer idType = null;
        List<Int_Message__c> intMsgList = new List<Int_Message__c>();

        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetailBulk('1235','156165',idType, intMsgList);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.status, 'Error', 'Throws error for invalid date');
          
    } 

    @isTest 
    static void buildTypeRequestReturnErrorBulkTest()
    {                               
        System.debug('***********START TEST***************');
        Test.startTest();
        
        Integer idType = 1;
        List<Int_Message__c> intMsgList = new List<Int_Message__c>();

        Appt_InvoiceDetailModel testModel = Appt_InvoiceService.getInvoiceDetailBulk('1235','156165',idType, intMsgList);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(testModel.message, 'Request for Invoice Detail FAILED', 'Check for fail message for outbound request');
          
    }
    // mock response
    public class testErorResponseOrderHistoriesHttpCalloutMock implements HttpCalloutMock {
        // Implement this interface method
        public  HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');       
            response.setBody('{\"message\": \"HTTP POST on resource \'https://npapi.discounttire.com/api/dev/orderhistory/prc/v3/orderHistories/orderDetails\' failed: service unavailable (503).\"}');
            response.setStatusCode(503);
            return response; 
        }
    }

    // to check exception handling when we do not receive proper response.
    @isTest
    static void getOrderHistoryDetailsMockExceptionTest(){
        System.debug('***********START TEST***************');
        Test.setMock(HttpCalloutMock.class, new testErorResponseOrderHistoriesHttpCalloutMock()); 
        BaseIntegrationUtil.bearerToken = 'testTokenDT';
        String siteId = '1235';
        String salesOrderId = '12345678';
        String orderType = 'BOPIS';
        
        Test.startTest();
        Appt_InvoiceDetailModel response = Appt_InvoiceService.getOrderHistoryDetails(siteId, salesOrderId, orderType);
        System.debug('ResponeData--->'+ response); 
        System.debug('ResponeData--->'+ response.toString().contains('HTTP POST on resource \'https://npapi.discounttire.com/api/dev/orderhistory/prc/v3/orderHistories/orderDetails\' failed')); 
        Test.stopTest();
        System.assert(response.toString().contains('HTTP POST on resource \'https://npapi.discounttire.com/api/dev/orderhistory/prc/v3/orderHistories/orderDetails\' failed'), 'orderhistory api call failed');
        System.debug('***********END TEST***************');

	}        
}