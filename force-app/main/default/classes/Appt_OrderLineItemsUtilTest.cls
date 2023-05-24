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
        
        Test.stopTest();  
        System.debug('***********END TEST***************');     
    }
    
}