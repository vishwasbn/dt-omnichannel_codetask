@isTest
public with sharing class Fleet_Mock_InvoiceAPITest {
    @isTest
    public static void mockInvoiceDetailAPITest(){      

        System.debug('----------Start Test----------');
        Test.startTest();
        //Case returnCase = submitCase(newUser, 'test case description', );
        String result = Fleet_Mock_InvoiceAPI.mockInvoiceDetailAPI();

        System.debug(result);
        
        System.assert(result =='[]', 'checks for sample valid data');

        Test.stopTest();
        System.debug('----------End Test----------');
        
    }

    @isTest
    public static void mockInvoiceSummaryAPITest(){    

        System.debug('----------Start Test----------');
        Test.startTest();
        //Case returnCase = submitCase(newUser, 'test case description', );
        String result = Fleet_Mock_InvoiceAPI.mockInvoiceSummaryAPI();

        System.debug(result);

        System.assert(result.contains('"year":2014,"model":"TAURUS","make":"FORD"') == true, 'checks for sample valid data');

        Test.stopTest();
        System.debug('----------End Test----------');
        
    }

}