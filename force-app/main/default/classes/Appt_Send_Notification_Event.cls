/**
 * @description       : 
 * @author            : Jayasurya Chirakala
 * @group             : 
 * @last modified on  : 01-17-2023
 * @last modified by  : Jayasurya Chirakala
**/
public class Appt_Send_Notification_Event {    
    @InvocableMethod(label='Send Platform Notification Event')
    public static List<ID> sendNotificationEvent(List<ID> notificationIds) {
        List<ID> ids = new List<ID>();
        //TO DO: Populate email payload and insert new record to Notification_Event__e
        List<Notification_Event__e> events = new List<Notification_Event__e>();
        List<Notification__c> notifications = [SELECT id, 
                                                        Appointment_First__c, 
                                                        Appointment_Date_String__c, 
                                                        Service_Appointment__c, 
                                                        Customer_Mobile_Phone__c, 
                                                        SMS_Message_Content__c, 
                                                        Notification_Type__c, 
                                                        Communication_Type__c, 
                                                        Appointment_Date_Format__c, 
                                                        Appointment_Time__c, 
                                                        Customer_Name__c,
                                                        Last_Error_Message__c,
                                                        Logs__c,
                                                        Channels__c,
                                                        Source__c,
                                                        Appointment_Status__c,
                                                        SAP_Store_Id__c,
                                                        Store_Id__c,
                                                        Is_AT__c,
                                                        Order_Number__c,
                                                        Order_Type__c,
                                                        API_Callout_Order_Type__c,
                                                        Appt_Order_Date__c,
                                                        Reply_PE_Send_Status__c,
                                                        Customer_Email__c,
                                                        Contact__r.FirstName,
                                                        Contact__r.LastName,
                                                        Work_Order__c,
                                                        Work_Order_Created_Date__c,
                                                        Vehicle_Number__c,
                                                        Vehicle_Information__c,
                                                        Customer_Street__c,
                                                        Customer_City__c,
                                                        Customer_State__c,
                                                        Customer_Zip__c,
                                                        Customer_Country__c,
                                                        Store_Name__c,
                                                        Store_Street__c,
                                                        Store_City__c,
                                                        Store_State__c,
                                                        Store_Zip__c,
                                                        Store_Phone_Number__c,
                                                        Account_Legal_Name__c,
                                                        Fleet_Account_Number__c,
                                                        Order_Date__c,
                                                        Vehicle_Assembly_Id__c,
                                                        Store_DBA_Name__c,
                                                        Email_Template__c,
                                                        Store_Logo__c,
                                                        Store_Google_Maps_address__c,
                                                        Has_Valid_Order_Number__c,
                                                        Valid_Email_Notification__c,
                                                        Order_Items_List__c,
                                                        Appointment_Year__c,
                                                        Order_Date_Format__c,
                                                        Initial_PE_Email_Payload__c,
                                                        Work_Order__r.Order_Type__c,
                                                        Work_Order__r.Order_Date__c,
                                                        Work_Order__r.Alternate_Contact__r.FirstName,
                                                        Work_Order__r.Alternate_Contact__r.LastName, 
                                                        Work_Order__r.Alternate_Contact__r.Phone, 
                                                        Work_Order__r.Alternate_Contact__r.Email
                                               FROM Notification__c
                                               WHERE Id IN :notificationIds];
        for(Notification__c notification : notifications){
            notification = Appt_NotificationUtil.buildEmailPayload(notification);
            Notification_Event__e event = new Notification_Event__e();
            event.emailPayload__c = notification.Initial_PE_Email_Payload__c;
            event.communicationType__c = notification.Communication_Type__c;
            event.notificationChannel__c = 'Email';
            event.notificationId__c = notification.Id;
            event.notificationType__c = notification.Notification_Type__c;
            event.source__c = notification.Source__c;
            System.debug('Appt_Send_Notification_Event: Notification_Event__e = ' +event);
            System.debug('Appt_Send_Notification_Event: emailPayload= ' +event.emailPayload__c);
            events.add(event);
        }

        update notifications;
        
        List<Database.SaveResult> results = EventBus.publish(events);        
        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
                ids.add(sr.getId());
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' +  err.getMessage());
                }
            }
        }
        
        return ids;
    }    
    
}