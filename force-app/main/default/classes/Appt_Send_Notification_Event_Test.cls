@isTest 
public class Appt_Send_Notification_Event_Test {
    @isTest 
    static void sendNotificationEventTest(){
        List<Notification__c> notis = new List<Notification__c>();
        Contact cont = new Contact();
        cont.LastName = 'Test';
        cont.FirstName = 'Test';
        insert cont;
        for(Integer i = 0; i < 5; i++){
            Notification__c newNoti = new Notification__c();
            newNoti.Notification_Type__c  = 'APPT_SCHEDULED'; 
            newNoti.Communication_Type__c = 'EMAIL'; 
            newNoti.Source__c = 'POS'; 
            //newNoti.Customer_Mobile_Phone__c = ''; 
            //newNoti.Customer_Email__c = ''; 
            //newNoti.Appointment_Date_String__c = ''; 
            //newNoti.Appointment_First__c = '';
            //newNoti.SAP_Store_Id__c = ''; 
            newNoti.Contact__c  = cont.Id; 
            //newNoti.Appointment_Status__c  = ''; 
            //newNoti.Order_Number__c  = ''; 
            notis.add(newNoti);
        }
        insert notis;
        List<Id> notiIds = new List<Id>();
        for(Integer i = 0; i < 5; i++){
            notiIds.add(notis[i].Id);
        }
        
        List<Id> eventIds = Appt_Send_Notification_Event.sendNotificationEvent(notiIds);
        System.assertEquals(5, eventIds.size());
    }
}