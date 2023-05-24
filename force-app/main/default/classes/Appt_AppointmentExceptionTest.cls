@isTest
public class Appt_AppointmentExceptionTest {

    @isTest static void appointmentExceptionTest()
    {               
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_AppointmentException testException = new Appt_AppointmentException('test exception', 400);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.assertEquals(400, testException.errorCode);
       
   
    } 
}