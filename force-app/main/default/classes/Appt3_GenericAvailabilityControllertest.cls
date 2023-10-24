@isTest
public class Appt3_GenericAvailabilityControllertest{

    
    @testSetUp
    static void setupData() 
    {         
    Appt_TestUtil.basicAppointment_StoreConfiguration();
    } 
    
 
    @isTest 
    static void getINACtiveApptSlotstest()
    { 
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();
        Test.startTest();
        String result= Appt3_GenericAvailabilityController.getApptSlots('RIP05',currentDate);                       
        Test.stopTest();  
        System.debug('TEstingJSON*********'+result);
        System.assertEquals('INACTIVESTORE',result,'Store is inactive'); 
        
    }
    
     @isTest 
    static void getApptSlotstest()
    { 
        Date currentDate = (Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();
        Test.startTest();
        String result= Appt3_GenericAvailabilityController.getApptSlots('1235',currentDate);                       
        Test.stopTest();  
        System.debug('TEstingJSON*********'+result);
        System.assert(result.contains('"bsfAvailable":2,"backTotalAvailable":12,"backRetailAvailable":8,"backFleetAvailable":4,"backAvailable":true'),'Backoffice total slots available');         
        Appt3_GenericAvailabilityController.ApptSlotsReturnModel testModel = new Appt3_GenericAvailabilityController.ApptSlotsReturnModel(0,'test');
        System.assertEquals(0,testModel.ApptSlotsNumberDays,'should be 0');
        System.assertEquals('test',testModel.scheduleModel,'scheduleModel is test');
        
    }
}