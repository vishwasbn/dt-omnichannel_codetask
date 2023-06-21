public without sharing class Appt_NotificationUtil {
    final static string LPREFIX = 'LOG_Appt_NotificationUtil:';

    // Future method that accepts a map of ids with a notificaiton type
    @future
    public static void createServiceAppointmentNotificaitonsFuture(Map<id,String> recordIds, String communicationTypes, String channels)
    {   
        createServiceAppointmentNotificaitons(recordIds,communicationTypes,channels);
    }

    // Provides the same functionality without using a future call if needed - this proccess will burn 1 query and 3 DML operations
    public static void createServiceAppointmentNotificaitons(Map<id,String> recordIds, String communicationTypes, String channels)
    {   
        System.debug( LPREFIX + 'Appt_NotificationUtil createServiceAppointmentNotificaitons - START');
        Set <id> apptIds = new Set<id>();        
        List<Notification__c> notificaitons = new List<Notification__c>();

        apptIds = recordIds.keySet();        
        List<ServiceAppointment> notifyList = [SELECT 
                                                Work_Order__c, 
                                                Work_Order__r.ContactId, 
                                                Work_Order__r.AccountId, 
                                                Work_Order__r.Alternate_Contact__c,
                                                Work_Order__r.Source__c,
                                                OwnerId, 
                                                id 
                                                FROM ServiceAppointment 
                                                WHERE Work_Order__r.Source__c != 'FILE' AND id IN :apptIds];

        // loop through all appts and create notificaitons if a contact is found
        for(ServiceAppointment appt: notifyList){

            String notifyType = recordIds.get(appt.id);            
            // Create notificaiton for primary contact
            if(appt.Work_Order__r.ContactId != null){
                notificaitons.add(createNotification(appt,notifyType, false, communicationTypes, channels));
            }

            // Create notificaiton for alternate contact
            if(appt.Work_Order__r.Alternate_Contact__c != null){
                notificaitons.add(createNotification(appt,notifyType, true, communicationTypes, channels));
            }           
        }

        System.debug( LPREFIX + ' Before inserting notificaitons');
        System.debug(notificaitons);

        
        

        // Insert Notificaitons
        if(notificaitons.size()>0){
            insert notificaitons; 
            notificaitons = getUpdatedNotificaitonObject(notificaitons);
        
            // updates the notification payload fields
            notificaitons = updateNotificationPayloads(notificaitons);    

            update notificaitons; 
        }
        System.debug(recordIds);

        // Sends a list of notificaitons to have their order information added

        //---TODO.SS should a status be changed here for CO#3

        //---06.09.22.SS - Switch to new SFMC Email System
        Boolean useSFMCEmail = Appt_SettingUtil.getSettingBooleanValue( 'Use_SFMC_Email');

        if (useSFMCEmail)
        {
            System.debug(LPREFIX + 'Using new SFMC Email, no need for this processing');
        }
        else
        {
            Appt_EmailOrderEnrichment.buildQueueableJobs(notificaitons);
        }        

        

        /*
        // capture notification ids
        List <id> idList = new List <id>();
        Set<Id> resultIds = (new Map<Id,Notification__c>(notificaitons)).keySet();
        idList.addAll(resultIds);

        // trigger queuable apex job to load in order information
        if(idList.size() > 0){
            System.enqueueJob(new Appt_EmailOrderEnrichment(idList));
        }*/
        
    }

    // Create a notification
    private static Notification__c createNotification(ServiceAppointment appt, String type, Boolean alternateFlag, String communicationType, String channel){
        System.debug( LPREFIX + 'Appt_NotificationUtil createNotification - START');
        Notification__c newNotificaiton = new Notification__c();
        newNotificaiton.OwnerId = appt.OwnerId;
        newNotificaiton.Notification_Type__c = type;
        newNotificaiton.Service_Appointment__c = appt.id;
        newNotificaiton.Account__c = appt.Work_Order__r.AccountId;
        newNotificaiton.Work_Order__c = appt.Work_Order__c;
        newNotificaiton.Source__c = appt.Work_Order__r.Source__c;
        newNotificaiton.Channels__c = channel;
        newNotificaiton.Communication_Type__c = communicationType;                    
        newNotificaiton.Initial_PE_SMS_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
        if(channel.contains('EMAIL')){
            newNotificaiton.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
            newNotificaiton.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING;
        }  
        if(alternateFlag){
            newNotificaiton.Contact__c = appt.Work_Order__r.Alternate_Contact__c;
            newNotificaiton.Alternate_Contact__c = alternateFlag;
        } else{
            newNotificaiton.Contact__c = appt.Work_Order__r.ContactId;
            newNotificaiton.Alternate_Contact__c = alternateFlag;
        }                
        System.debug( LPREFIX + 'Appt_NotificationUtil createNotification - End');
        return newNotificaiton;
    }

    public static List<Notification__c>  getUpdatedNotificaitonObject(List<Notification__c> notificaitons){  
        System.debug( LPREFIX + 'getUpdatedNotificaitonObject - Start');
        // APPT3-364 - Appt3_Valid_Universal_Order_Id__c added to the SOQL query.
        List<Notification__c> updatedNotificationObjects = [SELECT  id, 
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
                                                                    Logs__c,
                                                                    Last_Error_Message__c,
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
                                                                    Invoice_Status__c,
                                                                    Initial_Email_Send_Status__c,
                                                                    Initial_PE_SMS_Send_Status__c,
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
                                                                    Work_Order__r.Alternate_Contact__r.Email,
                                                            		Appt3_Valid_Universal_Order_Id__c
                                                            FROM Notification__c WHERE id IN :notificaitons];
        System.debug( LPREFIX + 'getUpdatedNotificaitonObject - End');
        System.debug(updatedNotificationObjects);
        return updatedNotificationObjects;
    }

    // updates the notificaiton with event payload information
    public static List<Notification__c>  updateNotificationPayloads(List<Notification__c> notificaitons){  
        System.debug( LPREFIX + 'updateNotificationPayloads- Start');
        System.debug(notificaitons);       

        if(notificaitons.size() > 0){
            for(Notification__c notification: notificaitons){
                
                System.debug(notification);
                buildSMSPayload(notification, 'initial', notification.Notification_Type__c);
                buildEmailPayload(notification);
            }
        }        
        System.debug( LPREFIX + 'updateNotificationPayloads- End');
        return notificaitons;
    }    

    // build out the sms payload for a notificaiton based on informaiton on the notification object passed
    public static Notification__c buildSMSPayload(Notification__c notification, String notificationState, String notificationType){

        System.debug(LPREFIX + ' Start buildSMSPayload');
        System.debug(notification);
        String errorReason = '';
        Boolean initalSMSType = Appt_ConstantValues.NOTIFICATION_INITIAL_SMS_VALUES.contains(notificationType);
        Boolean replySMSType = Appt_ConstantValues.NOTIFICATION_REPLY_SMS_VALUES.contains(notificationType);
        String invalid = Appt_ConstantValues.NOTIFICATION_STATUS_INVALID_DATA;
        Boolean isAt = notification.Is_AT__c;

        try{

            
            Boolean validSMS = true;

            //notification.Initial_PE_SMS_Send_Status__c = invalid;
            
            if(!notification.Channels__c.contains('SMS') && validSMS){
                validSMS = false;    
                errorReason += 'Not a Valid SMS Channel; ';                 
            }

            String smsNumber = notification.Customer_Mobile_Phone__c;

            if(smsNumber != null) {
                // clears out possible formating issues on the phone number
                smsNumber = smsNumber.replace('-','');
                smsNumber = smsNumber.replace('(','');
                smsNumber = smsNumber.replace(')','');
                smsNumber = smsNumber.replace('.','');
                smsNumber = smsNumber.replace(' ','');
            }       
            else {
                smsNumber = '';
            } 

            // Check for a vaild phone numebr
            if(smsNumber.length() == 10 && validSMS){
                smsNumber = smsNumber.substring(0, 3) + '-' + smsNumber.substring(3, 6) + '-' + smsNumber.substring(6, 10);            
            } else {
                validSMS = false;
                errorReason += 'Not a Valid SMS Number; ';  
            }

            // Check for valid notifcaiton type
            Boolean validNotificationType = Appt_ConstantValues.NOTIFICATION_VALID_VALUES.contains(notificationType);
            

            if(!validNotificationType && validSMS) {
                errorReason += 'Not a Valid Notification Type; ';  
                validSMS = false;
            }        
            
            

            // pull in SMS messages from custom settings and build the correct message
            Appt_Notification_SMS_Message__mdt messageSetting = Appt_SettingUtil.getMessageSettingValue(notificationType);                 
            System.debug(notification.Appointment_Time__c);
            System.debug(messageSetting.Message__c);
            System.debug(notification.Appointment_Date_String__c.length());
            System.debug(notification.Appointment_Date_String__c);        

            if(messageSetting.Message__c != null && notification.Appointment_Time__c != null && notification.Appointment_Date_String__c.length() == 10){
                
    
                String message = messageSetting.Message__c;
                String url = messageSetting.Redirect_URL__c;
                if(url == null) {url = '';}
                String appointmentDateTime = notification.Appointment_Date_String__c.substring(5, 7) +'/'+ notification.Appointment_Date_String__c.substring(8, 10) +'/'+ notification.Appointment_Date_String__c.substring(0, 4);
                appointmentDateTime += ' at ' +notification.Appointment_Time__c;
                String appointmentDate = notification.Appointment_Date_String__c.substring(5, 7) +'/'+ notification.Appointment_Date_String__c.substring(8, 10) +'/'+ notification.Appointment_Date_String__c.substring(0, 4);
                String storeName = 'Discount Tire';
                if(isAt){ storeName = 'America\'s Tire'; }

                // complete merge field for store name
                if(message.contains('[STORENAME]')){
                    message = message.replace('[STORENAME]',storeName);
                }

                // complete merge field for date time
                if(message.contains('[DATETIME]')){
                    message = message.replace('[DATETIME]',appointmentDateTime);
                }

                // complete merge field for date time
                if(message.contains('[DATE]')){
                    message = message.replace('[DATE]',appointmentDate);
                }
                
                // replace ['TIME'] with appointment time
                if(message.contains('[TIME]')){
                    message = message.replace('[TIME]', notification.Appointment_Time__c);
                }
                
                // complete merge field for url
                if(message.contains('[URL]')){
                    message = message.replace('[URL]',url);
                }
                
                // get dynamic cancel url
                if(message.contains('[CANCELURL]')){                    
                    url = getCancelUrl(notification.Is_AT__c, notification.Order_Number__c, notification.Appt_Order_Date__c, notification.API_Callout_Order_Type__c, notification.SAP_Store_Id__c);
                    System.debug(url);
                    message = message.replace('[CANCELURL]', url);
                }
                
                // get dynamic reschedule url
                if(message.contains('[RESCHEDULEURL]')){                                   
                    url = getRescheduleUrl(notification.Is_AT__c, notification.Order_Number__c, notification.Appt_Order_Date__c, notification.API_Callout_Order_Type__c, notification.SAP_Store_Id__c);                    
                    System.debug(url);
                    message = message.replace('[RESCHEDULEURL]', url);
                }
                
                // get dynamic new appointment url
                if(message.contains('[NEWAPPOINTMENTURL]')){     
                    
                    url = getNewApptUrl(notification.Is_AT__c, notification.Order_Number__c, notification.Appt_Order_Date__c, notification.API_Callout_Order_Type__c, notification.SAP_Store_Id__c,notification.Work_Order_Type__c);                           
                    System.debug(url);
                    message = message.replace('[NEWAPPOINTMENTURL]',url);
                }
                
                notification.SMS_Message_Content__c = message;

                // build platform event JSON SMS payload
                Appt_NotificationSMSPayload smsPayload = new Appt_NotificationSMSPayload(   smsNumber,
                                                                                            notification.SMS_Message_Content__c,
                                                                                            notificationState,
                                                                                            notificationType,
                                                                                            notification.Appointment_Date_String__c,
                                                                                            notification.Appointment_First__c,
                                                                                            notification.SAP_Store_Id__c,
                                                                                            notification.Work_Order__c,
                                                                                            notification.Customer_Name__c,
                                                                                            url,
                                                                                            notification.Appointment_Status__c);
                                                                                            //'Success',
                                                                                            //'');
                // sets the values if it's an initial payload type                                                                            
                if (initalSMSType) {
                    notification.Initial_PE_SMS_Payload__c = JSON.serializePretty(smsPayload);
                    notification.Initial_PE_SMS_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_FAILURE;
                }

                // sets the values if this is a reply action type - this is set in the trigger before the update is called.
                if (replySMSType){
                    notification.Reply_PE_Payload__c = JSON.serializePretty(smsPayload);
                    notification.Reply_PE_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_FAILURE;
                }
                            

            }else {
                validSMS = false;
                errorReason += 'Required Data is Missing to Send SMS; ';  
            }        

            if(!validSMS) {
                if (initalSMSType) {
                    notification.Initial_PE_SMS_Send_Status__c = invalid;
                } else if (replySMSType){
                    notification.Reply_PE_Send_Status__c = invalid;
                }
                notification.Last_Error_Message__c = notification.Last_Error_Message__c == null ? errorReason : notification.Last_Error_Message__c + errorReason;
            }


        } catch (Exception e){
            if (initalSMSType) {
                notification.Initial_PE_SMS_Send_Status__c = invalid;
                System.debug('error: ' +e.getMessage() +'\nline: ' +e.getLineNumber());
            } else if (replySMSType){
                notification.Reply_PE_Send_Status__c = invalid;
                System.debug('error: ' +e.getMessage() +'\nline: ' +e.getLineNumber());
            }
        }
        System.debug(LPREFIX + ' End buildSMSPayload');
        System.debug(notification.Reply_PE_Send_Status__c);
        System.debug(notification);
        return notification;
    }


    // TO DO: build out the email payload for a notificaiton based on informaiton on the notification object passed    
    public static Notification__c buildEmailPayload(Notification__c notification){
        System.debug(LPREFIX + ' Start buildEmailPayload');
        System.debug(notification);
        String errorReason = '';        
        String invalid = Appt_ConstantValues.NOTIFICATION_STATUS_INVALID_DATA;
        Boolean initalEmailType = Appt_ConstantValues.NOTIFICATION_INITAIL_EMAIL_VALUES.contains(notification.Notification_Type__c);
        try{ 
            // Get the Order type from the Work Order and format it to all caps
            String workOrderType = notification.Work_Order__r.Order_Type__c?.toUppercase();
            if(String.isNotBlank(workOrderType)){
                //APPT3-364 - Added STORE_ORDER conversion
                //workOrderType = (workOrderType == 'SERVICEAPPOINTMENT' ? 'SERVICE_APPOINTMENT' : workOrderType); // Add underscore if it is SERVICEAPPOINTMENT
                switch on workOrderType{
                    when 'SERVICEAPPOINTMENT' {
                        workOrderType = 'SERVICE_APPOINTMENT';
                    }
                    when 'STOREORDER' {
                        workOrderType = 'STORE_ORDER';
                    }                  
                    when else {
                        workOrderType = workOrderType;
                    }
                }
            }

            Appt_NotificationEmailPayload emailPayloadObj = new Appt_NotificationEmailPayload();
            emailPayloadObj.subscriberKey = notification.Work_Order__c;
            emailPayloadObj.emailAddress = notification.Customer_Email__c;
            emailPayloadObj.communicationType = 'A'; // This is 'A' for appointment, add logic for 'O' if there is implementation for Orders in the future
            emailPayloadObj.transactionType = workOrderType;
            emailPayloadObj.orderNumber = notification.Order_Number__c;
            emailPayloadObj.orderCreatedDate = String.valueOf(notification.Work_Order_Created_Date__c.format('yyyy-MM-dd'));
            emailPayloadObj.customerName = notification.Customer_Name__c;
            emailPayloadObj.vehicleId = notification.Vehicle_Number__c;
            emailPayloadObj.vehicleInformation = notification.Vehicle_Information__c;
            emailPayloadObj.streetAddress = notification.Customer_Street__c;
            emailPayloadObj.city = notification.Customer_City__c;
            emailPayloadObj.state = notification.Customer_State__c;
            emailPayloadObj.zipCode = notification.Customer_Zip__c;
            emailPayloadObj.country = notification.Customer_Country__c;
            emailPayloadObj.customerPhone = notification.Customer_Mobile_Phone__c;
            emailPayloadObj.storeId = notification.SAP_Store_Id__c;
            emailPayloadObj.storeName = notification.Store_Name__c;
            emailPayloadObj.storeStreetAddress = notification.Store_Street__c;
            emailPayloadObj.storeCity = notification.Store_City__c;
            emailPayloadObj.storeState = notification.Store_State__c;
            emailPayloadObj.storeZipCode = notification.Store_Zip__c;
            emailPayloadObj.storePhoneNumber = notification.Store_Phone_Number__c;
            emailPayloadObj.appointmentTime = notification.Appointment_Time__c;
            emailPayloadObj.recipientFirstName = notification.Work_Order__r.Alternate_Contact__r.FirstName;
            emailPayloadObj.recipientLastName = notification.Work_Order__r.Alternate_Contact__r.LastName;
            emailPayloadObj.recipientPhone = notification.Work_Order__r.Alternate_Contact__r.Phone;
            emailPayloadObj.recipientEmail = notification.Work_Order__r.Alternate_Contact__r.Email;
            emailPayloadObj.appointmentDate = notification.Appointment_Date_Format__c;
            emailPayloadObj.appointmentStatus = notification.Appointment_Status__c;
            Datetime todaysDate = System.today();
            emailPayloadObj.dateAdded = todaysDate.format('MMM') + ' ' + todaysDate.day() + ',' + todaysDate.year();
            emailPayloadObj.fleetCompanyName = notification.Account_Legal_Name__c;
            emailPayloadObj.fleetAccountNumber = notification.Fleet_Account_Number__c;
            emailPayloadObj.orderCode = notification.Order_Number__c;
            emailPayloadObj.storeCode = notification.Store_Id__c;
            //emailPayloadObj.orderDate = notification.Order_Date_Format__c;
            Date orderDate = notification.Work_Order__r.Order_Date__c;
            emailPayloadObj.orderDate = Datetime.newInstance(orderDate.year(), orderDate.month(),orderDate.day()).format('yyyy-MM-dd');
            emailPayloadObj.clientId = 'DT';

            emailPayloadObj.appointmentId = notification.Service_Appointment__c;
            emailPayloadObj.vehicleAssemblyId = notification.Vehicle_Assembly_Id__c;
            if(notification.Store_DBA_Name__c == 'DISCOUNT TIRE'){
                emailPayloadObj.clientId = 'DT';
            }
            else if(notification.Store_DBA_Name__c == 'DISCOUNT TIRE DIRECT'){
                emailPayloadObj.clientId = 'DTD';
            }
            else if(notification.Store_DBA_Name__c == 'AMERICA\'S TIRE'){
                emailPayloadObj.clientId = 'AT';
            }
            emailPayloadObj.customerKey = 'OrderConfirmationTSDv2';
            //APPT3-364 - Mapping that tells whether this appointment is generated with unviersal SalesOrderId or not
            emailPayloadObj.isUniversalOrderId = notification.Appt3_Valid_Universal_Order_Id__c;
            
            notification.Initial_PE_Email_Payload__c = Appt_NotificationEmailPayload.compose(emailPayloadObj);
            System.debug('@@ Notification: ' + notification.Initial_PE_Email_Payload__c);
            notification.Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
        }catch(Exception e){
            notification.Initial_Email_Send_Status__c = invalid;
            String errorMessage = 'Unexpected error creating Email Payload; '+e.getStackTraceString();

            if(errorMessage.length() > 60){
                errorMessage = errorMessage.substring(0, 60) + '...';
            }

            notification.Last_Error_Message__c = notification.Last_Error_Message__c == null ? errorMessage : notification.Last_Error_Message__c + errorMessage;

        }
        
        System.debug(LPREFIX + ' End buildEmailPayload');
        System.debug(notification);
        return notification;
    }
   
    // This Method is an interface to resend the EMAIL or the SMS Scheduled message
    // default is using the existing Notificaiton object, Plan B is creating a new Notification object
    public static void resendNotification(Id workOrderId, String channel)
    {
        System.debug('Start Appt_NotificationUtil:resendNotification() - workOrder: ' + workOrderId + ' ch: ' + channel);
    
        //---06.09.22.SS - Switch to new SFMC Email System
        Boolean useSFMCEmail = Appt_SettingUtil.getSettingBooleanValue( 'Use_SFMC_Email');

        if ( String.isBlank(workOrderId) ) return;

        List<Notification__c> updateOrderInfo = new List<Notification__c>();

        List<Notification__c> notificaitonList = new List<Notification__c>();

        // get Notification object associate with the Appointment
        // APPT3-364 - Appt3_Valid_Universal_Order_Id__c added to the SOQL query.
        notificaitonList = [SELECT  Id, 
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
                                    Logs__c,
                                    Channels__c,
                                    Source__c,
                                    Last_Error_Message__c,
                                    Appointment_Status__c,
                                    SAP_Store_Id__c,
                                    Is_AT__c,
                                    Order_Number__c,
                                    Order_Type__c,
                                    API_Callout_Order_Type__c,
                                    Appt_Order_Date__c,
                                    Reply_PE_Send_Status__c, 
                                    Initial_Email_Send_Status__c, 
                                    Invoice_Status__c, 
                                    Initial_PE_SMS_Send_Status__c, 
                                    Work_Order__r.AccountId, 
                                    Work_Order__c, 
                                    Work_Order__r.Source__c, 
                                    Work_Order__r.Alternate_Contact__c, 
                                    Work_Order__r.ContactId,
                                    Work_Order__r.Order_Type__c,
                            		Appt3_Valid_Universal_Order_Id__c
                                    FROM Notification__c WHERE Service_Appointment__r.Work_Order__c = :workOrderId AND Service_Appointment__r.Notification_Appointment__c = true AND (Channels__c Like '%EMAIL%' OR Channels__c Like '%SMS%') Order By CreatedDate DESC LIMIT 1];
        System.debug('*****START*****');
        // if there is Notificaiton object - resend it by setting the Status to Pending or failure for SMS
        if ( (notificaitonList != null) && (notificaitonList.size() > 0) ){
            if (channel == 'EMAIL'){
                // sets an override for resend that doesn't care about source
                ServiceAppointment notifyServiceAppointment = [SELECT Id FROM ServiceAppointment WHERE Work_Order__c =:workOrderId AND Notification_Appointment__c = true Limit 1];
                notifyServiceAppointment.Email_Notification_Source_Override__c = true;
                update notifyServiceAppointment;

                System.debug('Appt_NotificationUtil:resendNotification() - Email');
                notificaitonList[0].Initial_Email_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;


                //---06.09.22.SS - Switch to new SFMC Email System
                if (!useSFMCEmail)
                {
                    // added logic to retry getting order information if it wasn't there to start with
                    if(notificaitonList[0].Invoice_Status__c != Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_SUCCESSFUL){
                        notificaitonList[0].Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_PENDING;
                        updateOrderInfo.add(notificaitonList[0]);
                    }
                }
            } else if (channel == 'SMS'){
                System.debug('*****START*****');
                // if notification is an SMS rebuild the payload on resend based on the state of the notification                                                            
                buildSMSPayload(notificaitonList[0], 'initial', notificaitonList[0].Notification_Type__c);                            
                
                System.debug('Appt_NotificationUtil:resendNotification() - SMS');
                notificaitonList[0].Initial_PE_SMS_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_FAILURE;
            }
            update notificaitonList[0];


            

            if (useSFMCEmail)
            {
                System.debug(LPREFIX + 'Using new SFMC Email, no need for this processing');
            }
            else
            {
                if(updateOrderInfo.size() > 0){
                    Appt_EmailOrderEnrichment.buildQueueableJobs(updateOrderInfo);
                }
            }            
        } else {
            Map<id,String> notificaitonMap = new Map<id,String>();
           
            List<ServiceAppointment> saList = [SELECT Id FROM ServiceAppointment WHERE Work_Order__c =:workOrderId AND Notification_Appointment__c = true Limit 1];
            
            if(saList.size() > 0 && saList != null){
                ServiceAppointment sa = saList[0];

                if (channel == 'EMAIL'){
                    
                    sa.Email_Notification_Source_Override__c = true;
                    update sa;
                    notificaitonMap.put(sa.Id, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED);
                    createServiceAppointmentNotificaitons(notificaitonMap,'TRANSACTION', 'EMAIL');   

                }else if (channel == 'SMS'){                    
       
                    notificaitonMap.put(sa.Id, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED);
                    createServiceAppointmentNotificaitons(notificaitonMap,'TRANSACTION', 'SMS');   

                }
                 
            }
            else {
                CalloutException e = new CalloutException();
                e.setMessage('This is a constructed exception!');
                throw e;
            }
                   
            
            System.debug('Stop Appt_NotificationUtil:resendNotification()');
        }
        
    }

    //---Build the reschedule Url
    public static String getRescheduleUrl(Boolean isAt, String orderNumber, Date orderDate, String type, String storeName)
    {   
        System.debug(LPREFIX +' getRescheduleUrl');
        String url;
        url = getBaseURL(isAt) + 'schedule-appointment/installation/initiate?token=' + getToken(orderNumber,type) + '&orderDate=' + getOrderDate(orderDate) + '&storeName=' + storeName + '&requestType=RESCHEDULE&fromEmail=true';
             
        return url;
    }

    //---Build the cancel Url 
    public static String getCancelUrl(Boolean isAt, String orderNumber, Date orderDate, String type, String storeName)
    {
        System.debug(LPREFIX +' getCancelUrl');
        String url;
        
        url = getBaseURL(isAt) + 'schedule-appointment/installation/cancel?token=' + getToken(orderNumber, type) + '&orderDate=' + getOrderDate(orderDate) + '&storeName=' + storeName + '&fromEmail=true';
             
        return url;
    }   
    
    //---Build the new appt Url
    public static String getNewApptUrl(Boolean isAt, String orderNumber, Date orderDate, String type, String storeName, String orderType)
    {

        System.debug(LPREFIX +' getNewApptUrl '+' type '+type+' orderType '+orderType);

        String url;
        if('ServiceAppointment'.equalsIgnoreCase(orderType)) {
            url = getBaseURL(isAt) + 'schedule-appointment'; ///installation/initiate?token=' + getToken(orderNumber, type) + '&orderDate=' + getOrderDate(orderDate) + '&storeName=' + storeName + '';
        } else {
            url = getBaseURL(isAt) + 'schedule-appointment/installation/initiate?token=' + getToken(orderNumber, type) + '&orderDate=' + getOrderDate(orderDate) + '&storeName=' + storeName + '';
        }
        return url;
    } 

    //---builds a token for the url
    public static String getToken(String orderNumber, String type)
    {    
        // Get keys for encryption
        String key = Appt_SettingUtil.getSettingValue('Notification_Encryption_Key');
        String vector = Appt_SettingUtil.getSettingValue('Notification_Initialization_Vector');           
        String tokenType;
        String b64Data = '';

        System.debug('*************LINKS************');
        System.debug(type);

        // determine the order type
        switch on type {
            when 'layawayNumber' {		
                tokenType = '|LAYAWAYNO';
            }	
            when 'hybrisOrderNumber' {		
                tokenType = '|HYBORDRNUM';
            }
            when 'legacyOrderNumber' {		
                tokenType = '|WEBORDER';
            }
            when 'invoiceNumber' {		
                tokenType = '|TRANSNUMBER';
            }
            when 'quoteNumber' {
                	
                tokenType = '|TRANSNUMBER';
                // pad the token type for quote to 20 characters
                orderNumber = orderNumber.leftPad(20, '0');
            }
            when else {		  
                tokenType = '';
            }
        }        
    
        // encrypt the key if all elements are present - if not send the info in clear text
        if(key != null && key != '' && vector != null && vector != ''){
            Blob cryptoKey = Blob.valueOf(key);
            Blob initVector = Blob.valueOf(vector);  
            string b64Key = EncodingUtil.base64Encode(cryptoKey);
            
            Blob data = Blob.valueOf(orderNumber + tokenType);
            
            Blob encryptedData = Crypto.encrypt('AES256', cryptoKey, initVector, data );
            b64Data = EncodingUtil.base64Encode(encryptedData);    
            /*
            System.debug('Encrypted Data: ' + b64Data);
            Blob dataToDecrypt = Crypto.decrypt('AES256', cryptoKey, initVector, encryptedData);
            String clearText = dataToDecrypt.toString();
            System.debug('Original Text decrypted: ' + clearText);*/


        } else {
            b64Data = orderNumber + tokenType;
        }
        
        
        
        
        
        return EncodingUtil.urlEncode(b64Data, 'UTF-8');
    }

    //---Get the correct base url
    public static String getBaseURL(Boolean isAt){
        String atUrl = Appt_SettingUtil.getSettingValue('Email_Hybris_AT_Url');
        String dtUrl = Appt_SettingUtil.getSettingValue('Email_Hybris_DT_Url');

        String baseActionUrl = isAt ? atUrl : dtUrl;
        return baseActionUrl;
    }

    //---Get the order date
    public static String getOrderDate(Date orderDate)
    {
        String orderYear = '' + orderDate.year();
        String orderMonth = '' + orderDate.month();
        String orderDay = '' + orderDate.day();
        String orderDateStr = orderYear.leftPad(4, '0') + '-' + orderMonth.leftPad(2, '0') + '-' + orderDay.leftPad(2, '0');
        return orderDateStr;
    }
}