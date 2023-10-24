@isTest
public with sharing class Appt_OrderLineItemsUtilTest {    

    @isTest 
    static void futureNotificationTest()
    {                          
        System.debug('***********START TEST***************');
        Test.startTest();

        String testResult = Appt_OrderLineItemsUtil.getLineItemDescriptionByType('ZTIR');
        System.debug(testResult);
        System.assert(testResult != null, 'check for a vaild return value');
        //testResult = Appt_OrderLineItemsUtil.getLineItemDescriptionByArticleNumnber(80222);
        //System.debug(testResult);
        //System.assert(testResult != null, 'check for a vaild return value');
        testResult = Appt_OrderLineItemsUtil.getLineItemDescriptionByType('ZTIRs');
        System.debug(testResult);
        System.assertEquals(null, testResult, 'check for invalid article type');
        testResult = Appt_OrderLineItemsUtil.getLineItemDescriptionByArticleNumnber(8022654645645565464562215.0);  
        System.debug(testResult);      
        System.assertEquals(null, testResult, 'check for invalid article number');

        List<Appt_InvoiceDetailModel.LineItems> lineItems = new List<Appt_InvoiceDetailModel.LineItems>();
        Appt_InvoiceDetailModel.LineItems item = new Appt_InvoiceDetailModel.LineItems();
            item.articleType = 'ln.item.articleType';
            item.articleNumber = 'ln.item.articleNumber';
            item.retailQuantity = 23;
            item.onHandStockQuantity = 2;
            item.storeSize = 'ln.item.storeSize';
            item.storeDescription = 'ln.item.storeDescription';
            item.actualUnit_price = 12;
            item.fet = 23;
            item.totalSalesAmount = 147;
            item.vehicleMake = 'ln.item.vehicleMake';
            item.vehicleModel = 'ln.item.vehicleModel';
            item.vehicleYear = '2011';
            item.mileage = '24';
            item.poNumber = '22';
           // item.discounts = '20'; 
        lineItems.ADD(item);
        Appt_OrderLineItemsUtil.sortList(lineItems);
        Test.stopTest();  
        System.debug('***********END TEST***************');     
    }
    
}