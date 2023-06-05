@isTest
public with sharing class Fleet_Model_InvoiceDetailTest {
    
    @IsTest 
    public static void Fleet_Model_InvoiceDetailTest() {

        Test.startTest();
        Fleet_Model_InvoiceDetail newDetailModel = new Fleet_Model_InvoiceDetail();
        
        Test.stopTest();
        system.debug(newDetailModel);
        System.assert(newDetailModel != null, 'object creation test');
    }
}