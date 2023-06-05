@isTest
public class Appt_Appointments_AuraControllerTest {
    @isTest 
    public static void callOnLoadingTest(){
       Appt_Appointments_AuraController jsonCls = New Appt_Appointments_AuraController();
        Test.startTest();
        Appt_Appointments_AuraController.callOnLoading('{"attributes":{"type":"Int_Message__c"}}');
        Appt_Appointments_AuraController.processJson('{"attributes":{"type":"Int_Message__c"}}');
        Map<String,Object> mapStr = New Map<String,Object>();
        mapStr.put('c__jsonArgs','{"type":"Int_Message__c"}');
        Appt_Appointments_AuraController.getJsonArgs(mapStr);
        Set<String> setStr = New Set<String>{'attributes'};
        Appt_Appointments_AuraController.getFirstKey(setStr);
        Appt_Appointments_AuraController.logInput();
        Appt_Appointments_AuraController.callConstructor();
        Appt_Appointments_AuraController.wrapper obj = New Appt_Appointments_AuraController.wrapper('Test','Test');
        Test.stopTest();
    }
}