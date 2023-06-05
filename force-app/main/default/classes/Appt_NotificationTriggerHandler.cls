public with sharing class Appt_NotificationTriggerHandler {
    public static String lprefix = 'LOG_Appt_NotificationTriggerHandler:';
    // this funciton handles all the Trigger states
    public static void handle(Map<Id, Notification__c> oldMap, Map<Id, Notification__c> newMap, System.TriggerOperation triggerEvent )
    {

        System.debug(lprefix+'Appt NotificationTriggerHandler  Handler - START');

        switch on triggerEvent 
        {
            
            when BEFORE_UPDATE {
                // handle updates to the response field
                handleResponseActions(oldMap, newMap);
            }
            when else {
                //do nothing 
            }
        }
    
        System.debug(lprefix+'Appt NotificationTriggerHandler Handler - END');
    }

    public static void handleResponseActions(Map<Id, Notification__c> oldMap, Map<Id, Notification__c> newMap){

        List<Notification__c> responseNotifications = new List<Notification__c>();
        // check for changes to the response__c field
        for (Notification__c notif : newMap.values())
        {   
            Notification__c beforeUpdate = oldMap.get(notif.id);
            if(notif.Response__c != beforeUpdate.Response__c){
                responseNotifications.add(notif);
            }
        }

        // if the response field was updated process record
        if(responseNotifications.size() > 0) {
            processUpdates(responseNotifications);
        }

    }

    public static void processUpdates(List<Notification__c> notifications){

        for(Notification__c notif: notifications){

            System.debug(lprefix+' Process Reply - START');

            Boolean validResponseNotification = Appt_ConstantValues.NOTIFICATION_INITIAL_SMS_VALUES.contains(notif.Notification_Type__c);

            // proccess updates based on notification type
            if(validResponseNotification){

                

                if(notif.Notification_Type__c == Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED){

                    if(notif.Response__c == '1') {
                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_LINK_RESCHEDULE;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);

                    } else if (notif.Response__c == '2') {

                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_LINK_CANCEL;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);
                    } else {
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_INVALID_DATA);
                    }

                } else if (notif.Notification_Type__c == Appt_ConstantValues.NOTIFICATION_APPT_RESCHEDULED) {

                    if(notif.Response__c == '1') {

                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_LINK_RESCHEDULE;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);
                    } else if (notif.Response__c == '2') {

                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_LINK_CANCEL;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);
                    } else {
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_INVALID_DATA);
                    }

                } else if (notif.Notification_Type__c == Appt_ConstantValues.NOTIFICATION_APPT_CANCELLED) {

                    if(notif.Response__c == '1') {

                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_LINK_SCHEDULE_NEW;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);
                    } else {
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_INVALID_DATA);
                    } 

                } else if (notif.Notification_Type__c == Appt_ConstantValues.NOTIFICATION_APPT_REMINDER) {

                    if(notif.Response__c == '1') {

                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_LINK_RESCHEDULE;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);
                    } else if (notif.Response__c == '2') {

                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_CONFIRMED;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);
                        
                    } else if (notif.Response__c == '3') {

                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_LINK_CANCEL;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);
                    } else {
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_INVALID_DATA);
                    }

                } else if (notif.Notification_Type__c == Appt_ConstantValues.NOTIFICATION_APPT_NOW) {

                    if(notif.Response__c == '1') {

                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_LINK_RESCHEDULE;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);
                    } else if (notif.Response__c == '2') {

                        notif.Reply_PE_Notification_Type__c = Appt_ConstantValues.NOTIFICATION_APPT_LINK_CANCEL;
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS);
                    } else {
                        notif = processStatusUpdates(notif, Appt_ConstantValues.NOTIFICATION_STATUS_INVALID_DATA);
                    }

                }    
                System.debug(lprefix+' Process Reply - End');
                System.debug(notif);

            }
        }
        
    }

    public static Notification__c processStatusUpdates(Notification__c notification, String status){
        System.debug(lprefix+' processStatusUpdates - Start');
        System.debug(notification.Reply_PE_Send_Status__c);

        // if the notificaiton reply status isn't already invalid data       
        if(status == Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS){
            notification = Appt_NotificationUtil.buildSMSPayload(notification,'reply', notification.Reply_PE_Notification_Type__c);
            if(notification.Reply_PE_Send_Status__c != Appt_ConstantValues.NOTIFICATION_STATUS_INVALID_DATA ) {
                notification.Reply_PE_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_FAILURE;
                notification.Reply_PE_Send_Date__c = Datetime.now();  
            }
            
        } else {
            notification.Reply_PE_Send_Status__c = status;
        }                     

        notification.Response_Status__c = status;
        notification.Response_Date__c = Datetime.now();

        
        System.debug(lprefix+' processStatusUpdates - End');
        System.debug(notification);
        return notification;
    }

    
}