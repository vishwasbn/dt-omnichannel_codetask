@isTest(SeeAllData=false)
public class Appt_TestEmailVFControllerTest {

    @testSetup
    static void setupData() {

        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();

    } // End of setupData()

    @isTest static void testingMethod()
    {    
        List<ServiceAppointment> servAppts = [SELECT Id, Status, SchedStartTime, Date_String__c, ParentRecordId FROM ServiceAppointment];
        System.assertEquals(2, servAppts.size(), 'unexpected number of appointments');

        servAppts[0].Notification_Appointment__c = true;
        servAppts[0].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        update servAppts[0];

        List<Notification__c> noteList = [SELECT Id, Initial_Email_Send_Status__c, Initial_PE_SMS_Send_Status__c, Alternate_Contact__c, Channels__c, Communication_Type__c, Email_Template__c, Notification_Type__c,  Service_Appointment__c  FROM Notification__c];
        System.debug('Notificaion Size: ' + noteList.size());    
        System.debug('Notificaion: ' + noteList);  

        ApexPages.StandardController sc = new ApexPages.StandardController(noteList[0]);

        Appt_TestEmailVFController vfObj = new Appt_TestEmailVFController(sc);

        System.debug('relatedTo: ' + vfObj.relatedTo);
        system.assert( ( vfObj.relatedTo != null ), 'Notificaiton record missing');
    }
}