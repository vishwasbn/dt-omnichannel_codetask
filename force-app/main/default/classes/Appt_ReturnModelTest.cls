@isTest
public with sharing class Appt_ReturnModelTest {
    @isTest static void returnModelTest ()
    {               
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_ReturnModel testClass = new Appt_ReturnModel ();
        testClass.setError('400', 'bad request');        
        testClass.isError();


        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.assertEquals(testClass.isError(), true);
       
   
    } 
}