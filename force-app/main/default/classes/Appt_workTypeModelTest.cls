@isTest
public class Appt_workTypeModelTest {
    @isTest static void workTypeModelTest()
    {               
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_workTypeModel testModel = new Appt_workTypeModel();
        testModel.OrderType = 'test';


        String orderType = testModel.getOrderType();
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.assertEquals(orderType, 'test');
       
   
    } 
}