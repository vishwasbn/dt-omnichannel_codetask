public with sharing class Appt_InvocableNotificationUpdate 
{
    @InvocableMethod
    public static void updateNotificationStatus(List<Id> nRecords) 
    {
        System.debug('Appt_InvocableNotificationUpdate Start');
        System.debug('noteRecordIds: ' + nRecords);
        Boolean emailSend = false;
        Boolean smsSend = false;
        Set<Id> nRecIdsSet = new Set<Id>(nRecords);
        List<Notification__c> nRecs = [SELECT   Id, 
                                                Work_Order__c, 
                                                Channels__c,
                                                Last_Error_Message__c, 
                                                Initial_PE_SMS_Send_Status__c, 
                                                Initial_PE_Email_Payload__c,
                                                Initial_PE_SMS_Payload__c,
                                                Notification_Type__c, 
                                                Logs__c,
                                                Initial_Email_Send_Status__c, 
                                                Reply_PE_Notification_Type__c,
                                                Reply_PE_Send_Status__c,
                                                Reply_PE_Payload__c
                                        FROM Notification__c WHERE Id IN: nRecIdsSet ];


        
        if ((nRecs != null) && (nRecs.size() > 0))
        {
            Datetime currentDt = Datetime.now();
            Set<Id> wrkOdrSetSMS = new Set<Id>();
            Set<Id> wrkOdrSetEMail = new Set<Id>();
            List<WorkOrder> wokOrdList =  new List<WorkOrder>();

            Map<Id, Notification__c> noteByWrkOdr = new Map<Id, Notification__c>();
            for (Notification__c rec: nRecs)
            {
                
                noteByWrkOdr.put(rec.Work_Order__c, rec);
                // update the correct fields for emails
                if ( rec.Channels__c.contains('EMAIL') && rec.Initial_Email_Send_Status__c == Appt_ConstantValues.NOTIFICATION_STATUS_PENDING) {
                    System.debug('Passed email conditional check: Email Send Status = ' +rec.Initial_Email_Send_Status__c);
                    emailSend = true;
                    rec.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS;
                    rec.Initial_Email_Send_Date__c = currentDt;
                    rec = updateLogs(rec, 'EMAIL');
                    wrkOdrSetEMail.add(rec.Work_Order__c);
                    System.debug('initial email');
                    System.debug('EmailworkOrders: ' + wrkOdrSetEMail);      
                }

                // update the correct status and log for initial sms 
                if ( rec.Channels__c.contains('SMS') && Appt_ConstantValues.NOTIFICATION_INITIAL_SMS_VALUES.contains(rec.Notification_Type__c) && rec.Initial_PE_SMS_Send_Status__c == Appt_ConstantValues.NOTIFICATION_STATUS_FAILURE) {
                    smsSend = true;
                    rec.Initial_PE_SMS_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS; 
                    rec.Initial_PE_SMS_Send_Date__c = currentDt;
                    rec = updateLogs(rec, 'SMS-Initial');     
                    wrkOdrSetSMS.add(rec.Work_Order__c);
                    System.debug('initial sms');
                    System.debug('SMSworkOrders: ' + wrkOdrSetSMS);                
                }

                // update the correct status and log for replies
                if ( rec.Channels__c.contains('SMS') && Appt_ConstantValues.NOTIFICATION_REPLY_SMS_VALUES.contains(rec.Reply_PE_Notification_Type__c) && rec.Reply_PE_Send_Status__c == Appt_ConstantValues.NOTIFICATION_STATUS_FAILURE) {
                    smsSend = true;
                    rec.Reply_PE_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_SUCCESS; 
                    rec.Reply_PE_Send_Date__c = currentDt;
                    rec = updateLogs(rec, 'SMS-Reply');     
                    wrkOdrSetSMS.add(rec.Work_Order__c);    
                    System.debug('reply sms');
                    System.debug('SMSworkOrders: ' + wrkOdrSetSMS);          
                }               
            

            }
            
            System.debug('Update Work Orders');
            System.debug('workOrders: ' + wokOrdList);

            update nRecs;
            // Updates the send message date if the message was sent correctly
            if(wrkOdrSetEMail.size() > 0 || wrkOdrSetSMS.size() > 0){
                for (WorkOrder wo: [SELECT Id, SMS_Confirmation_Sent_Date__c, Email_Confirmation_Sent_Date__c FROM WorkOrder WHERE Id IN: wrkOdrSetEMail OR Id IN :wrkOdrSetSMS])
                {
                    if ( noteByWrkOdr.get(wo.Id).Channels__c.contains('EMAIL') && emailSend && wrkOdrSetEMail.contains(wo.Id)) {
                        wo.Email_Confirmation_Sent_Date__c = currentDt;
                    }

                    if ( noteByWrkOdr.get(wo.Id).Channels__c.contains('SMS') && smsSend && wrkOdrSetSMS.contains(wo.Id)) {
                        wo.SMS_Confirmation_Sent_Date__c = currentDt;
                    }

                    wokOrdList.add(wo);
                }                
            }
            
            if(wokOrdList.size() > 0 ){
                System.debug('Update Work Orders');
                System.debug('workOrders: ' + wokOrdList);
                update wokOrdList;
            }

        }
        
    }


    // process to write to the logs if an email or SMS was sent out
    public static Notification__c updateLogs(Notification__c notification, String type){
        
        // Set error if one is on the notification record
        String lastError;
        if(notification.Last_Error_Message__c == null){
            lastError = '';
        } else{
            lastError = 'Last Error: ' + notification.Last_Error_Message__c +'\n';
        }
        // Log emails sents
        if(type == 'EMAIL'){
            System.debug('Adding email send to log for notification: ' +notification);
            if(notification.Logs__c != null){
                notification.Logs__c = notification.Logs__c+ '\n\n' + 
                'Type: ' +type+'\n' +
                lastError +
                notification.Notification_Type__c + ' - ' + 
                Datetime.now() +'\n' + 'Log: Email Send attempted';
            } else {
                notification.Logs__c = 'Type: ' +type+'\n' +
                lastError +
                notification.Notification_Type__c + ' - ' + 
                Datetime.now() +'\n' + 'Log: Email Send attempted';
            }

        }

        // log inital sms
        if(type == 'SMS-Initial'){
            System.debug('Adding sms initial send to log for notification: ' +notification);
            if(notification.Logs__c != null){
                notification.Logs__c = notification.Logs__c+ '\n\n' + 
                'Type: ' +type+'\n' +
                lastError +
                notification.Notification_Type__c + ' - ' + 
                Datetime.now() +'\n' + 'Log: ' + notification.Initial_PE_SMS_Payload__c;
            } else {
                notification.Logs__c = 'Type: ' +type+'\n' +
                lastError +
                notification.Notification_Type__c + ' - ' + 
                Datetime.now() +'\n' + 'Log: ' + notification.Initial_PE_SMS_Payload__c;
            }

        }

        // log reply sms
        if(type == 'SMS-Reply'){
            System.debug('Adding sms reply send to log for notification: ' +notification);
            if(notification.Logs__c != null){
                notification.Logs__c = notification.Logs__c+ '\n\n' + 
                'Type: ' +type+'\n' +
                lastError +
                notification.Reply_PE_Notification_Type__c + ' - ' + 
                Datetime.now() +'\n' + 'Log: ' + notification.Reply_PE_Payload__c;
            } else {
                notification.Logs__c = 'Type: ' +type+'\n' +
                lastError +
                notification.Reply_PE_Notification_Type__c + ' - ' + 
                Datetime.now() +'\n' + 'Log: ' + notification.Reply_PE_Payload__c;
            }

        }        

        return notification;
    }
}