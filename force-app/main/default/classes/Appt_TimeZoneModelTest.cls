@isTest
public class Appt_TimeZoneModelTest {
    @isTest static void Appt_TimeZoneModelTest()
    {               
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_TimeZoneModel testModel = new Appt_TimeZoneModel();
        testModel.timeZone = 'test';
        testModel.timeZoneOffset = -1;

        String timeZone = testModel.getTimeZone();
        Integer timeZoneOffset = testModel.getTimeZoneOffset();
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(testModel);
        System.assertEquals(timeZone, 'test');
        System.assertEquals(timeZoneOffset, -1);
       
   
    } 
}