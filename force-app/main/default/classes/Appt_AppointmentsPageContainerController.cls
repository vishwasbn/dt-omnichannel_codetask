public without sharing class Appt_AppointmentsPageContainerController {
    public final static string lprefix = 'LOG APPT_PageCC ';

    public class ReturnModel {
        public String status {get; set;}
        public String message {get; set;}
        public String optionalModel {get; set;}

        public ReturnModel(String status, String message){
            this.status = status;
            this.message = message;
        }

        public ReturnModel(String status, String message, String optionalModel){
            this.status = status;
            this.message = message;
            this.optionalModel = optionalModel;
        }
    }

    public class IllegalActionArgumentException extends Exception {}

    
    @AuraEnabled
    public static String getAppointmentServiceModel(String jsonString) {
        System.debug('---ENTER getServiceModel---');

        try {

            // decode the json string (this is a catch all since the payload being passed in encoded from the JXBrowser)
            jsonString = EncodingUtil.urlDecode(jsonString, 'UTF-8');

            // parse incoming JSON String
            Appt_POSAppointmentModel posModel = Appt_POSAppointmentModel.parse(jsonString);
            System.debug(lprefix + ' posModel:' + posModel);
            System.debug(lprefix + ' posModel action: ' +posModel.action);


            // Check if the action is view or create. View will return updateModel, create will return createModel
            if(posModel.action.equalsIgnoreCase('VIEW')){
                Appt_UpdateAppointmentServiceModel serviceModel = posModel.getUpdateAppointmentServiceModel(posModel);

                // Gather customer and vehicle information
                processCustomer(serviceModel);
                processVehicle(serviceModel);
                getCustomerEditableFields(serviceModel);

                // Grab the appointment details if there is a workOrderId, otherwise return an error
                getAppointmentDetails(serviceModel);

                return JSON.serialize(serviceModel);
            }
            else if(posModel.action.equalsIgnoreCase('CRT')){
                Appt_CreateAppointmentServiceModel serviceModel = posModel.getCreateAppointmentServiceModel(posModel);

                // Gather customer and vehicle information
                processCustomer(serviceModel);
                processVehicle(serviceModel);
                getCustomerEditableFields(serviceModel);

                return JSON.serialize(serviceModel);
            }
            else {
                throw new IllegalActionArgumentException('Action \'' +posModel.action +'\' is not a legal argument');
            }

        } catch (exception e) {
            Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();
            System.debug(lprefix + ' error populating Appt_CreateApptServiceModel. Error: ' + e.getMessage());
            serviceModel.status = Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            serviceModel.message = 'System Error: ' + e.getMessage();
            return JSON.serialize(serviceModel);
        }
        
    } // End of getAppointmentServiceModel()
    

    public static void processCustomer(Appt_CreateAppointmentServiceModel model) {
        Appt_AppointmentHandler.getAccount(model);

        System.debug(lprefix +'processCustomer: ' +model);
        // TODO: get account/person/contact Id populated on model so that I can create an Asset for new customers
    }
    

    public static void processVehicle(Appt_CreateAppointmentServiceModel model) {
        // If field is null or empty, display SF values for asset
        // If field is populated, overwrite the data in SF on appointment update
        if(model.workOrderId != null && model.workOrderId != '' && model.workOrderId != 'null'){
            WorkOrder wo = [SELECT Id, Vehicle__r.Vehicle_Make__c, Vehicle__r.Vehicle_Model__c, Vehicle__r.Trim_Name__c, 
            Vehicle__r.Vehicle_Manufacture_Year__c, Vehicle__r.Assembly_Id__c  FROM WorkOrder WHERE id = :model.workOrderId LIMIT 1];

            if(wo != null){
                model.make = (model.make == null || String.isBlank(model.make)) ? wo.Vehicle__r.Vehicle_Make__c : model.make;
                model.model = (model.model == null || String.isBlank(model.model)) ? wo.Vehicle__r.Vehicle_Model__c : model.model;
                model.year = (model.year == null || String.isBlank(model.year)) ? wo.Vehicle__r.Vehicle_Manufacture_Year__c : model.year;
                model.trimDetails = (model.trimName == null || String.isBlank(model.trimName)) ? wo.Vehicle__r.Trim_Name__c : model.trimName;
                model.assemblyDetails = (model.assemblyId == null || String.isBlank(model.assemblyId)) ? wo.Vehicle__r.Assembly_Id__c : model.assemblyId;
            }
            
        } else {   
            model.assemblyDetails = model.assemblyId;  
            model.trimDetails = '';
            List<Reference__c> trimInfo = [SELECT Trim_Name__c from Reference__c WHERE Trim_Id__c = :model.trimId LIMIT 1];
            if(trimInfo.size() > 0){
                if(trimInfo[0].Trim_Name__c != null){
                    model.trimDetails = trimInfo[0].Trim_Name__c;
                } else{
                    model.trimDetails = '';
                }                
            }      
            
        }
    }


    @AuraEnabled
    public static String updateAppointmentNotifications(String wrkOdrId)
    {
        List<Notification__c> notList = [SELECT Id, Work_Order__c, Initial_PE_SMS_Send_Date__c, Initial_PE_SMS_Send_Status__c, Initial_Email_Send_Date__c, Initial_Email_Send_Status__c FROM Notification__c WHERE Work_Order__c =: wrkOdrId ORDER BY LastModifiedDate DESC];

        Datetime smsConfDate = notList[0].Initial_PE_SMS_Send_Date__c == NULL ? null : notList[0].Initial_PE_SMS_Send_Date__c ;
        Datetime emailConfDate =  notList[0].Initial_Email_Send_Date__c == NULL ? null : notList[0].Initial_Email_Send_Date__c;

        Appt_CreateAppointmentServiceModel model = new Appt_CreateAppointmentServiceModel();

        model.smsConfirmationSent = smsConfDate == NULL ? null : Date.newInstance(smsConfDate.year(), smsConfDate.month(), smsConfDate.day());
        model.emailConfirmationSent = emailConfDate == NULL ? null : Date.newInstance(emailConfDate.year(), emailConfDate.month(), emailConfDate.day());

        return ( JSON.serialize(model) );
    } // End of updateAppointmentNotifications()


    public static void getAppointmentDetails(Appt_CreateAppointmentServiceModel model) {
        System.debug(lprefix +' Model workOrderId: ' +model.workOrderId);
        
        if (model.workOrderId == null || model.workOrderId == '') {
            model.message = 'Unable to locate appointment, workOrderId is required. ' + String.valueOf(model.workOrderId);
            model.status = Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            return;
        }
        
        List<WorkOrder> woList = [SELECT ID, SMS_Confirmation_Sent_Date__c, Email_Confirmation_Sent_Date__c, Source__c,
         (SELECT ID, toLabel(Status), Date_String__c, Back_Office_Start_Time__c, Selected_Slot_End_Time_String__c, Selected_Slot_Start_Time_String__c, Back_Office_End_Time__c, Consult_Start_Time__c, Consult_End_Time__c,
         Activity_Type__c FROM ServiceAppointments)
          FROM WorkOrder WHERE ID=:model.workOrderId LIMIT 1];
        System.debug(lprefix +'WOList: ' +woList);


        WorkOrder wo = null;
        if (woList.size() > 0) {
            wo = woList[0];
        } else {
            model.message = 'Invalid work order ID. No Appointment found with workOrderId: ' + String.valueOf(model.workOrderId);
            model.status = Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            return;
        }

        if(wo != null){
            Datetime smsConfDate = wo.SMS_Confirmation_Sent_Date__c == NULL ? null : wo.SMS_Confirmation_Sent_Date__c ;
            Datetime emailConfDate =  wo.Email_Confirmation_Sent_Date__c == NULL ? null : wo.Email_Confirmation_Sent_Date__c;

            model.smsConfirmationSent = smsConfDate == NULL ? null : Date.newInstance(smsConfDate.year(), smsConfDate.month(), smsConfDate.day());
            model.emailConfirmationSent = emailConfDate == NULL ? null : Date.newInstance(emailConfDate.year(), emailConfDate.month(), emailConfDate.day());
            model.appointmentId = wo.Id;
            model.source = wo.Source__c;

            List<ServiceAppointment> appts = wo.ServiceAppointments;
            System.debug(lprefix +' appts: ' +appts);
            if(appts.size() != 0) {
                
                
                for(ServiceAppointment sa: appts){
                    if(sa.Activity_Type__c.equals(Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_BACK)){
                        model.appointmentDate = Date.valueOf(sa.Date_String__c);
                        model.appointmentStatus = sa.Status;
                        model.backOfficeAppointmentId = sa.Id;
                        model.backOfficeStartTime = sa.Back_Office_Start_Time__c;
                        model.backOfficeEndTime = sa.Back_Office_End_Time__c;

                        // only sets these times if they aren't already set
                        if(model.selectedSlotStartTime == null || model.selectedSlotEndTime == null){
                            model.selectedSlotStartTime = sa.Selected_Slot_Start_Time_String__c;
                            model.selectedSlotEndTime = sa.Selected_Slot_End_Time_String__c; 
                        }
                                               
                    }
                    if(sa.Activity_Type__c.equals(Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_FRONT) && !sa.Status.equals(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED) 
                    && !sa.Status.equals(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD)){
                        model.consultAppointmentId = sa.Id;
                        model.consultStartTime = sa.Consult_Start_Time__c;
                        model.consultEndTime = sa.Consult_End_Time__c;    
                        // overwrites the selected time to the console appoiintments time                    
                        //model.selectedSlotStartTime = sa.Selected_Slot_Start_Time_String__c;
                        //model.selectedSlotEndTime = sa.Selected_Slot_End_Time_String__c;                       
                         
                    }
                }
            }
        }
    } // End of getAppointmentDetails()


    public static void getCustomerEditableFields(Appt_CreateAppointmentServiceModel serviceModel){
        System.debug('getCustomerEditableFields(): serviceModel=' +serviceModel);
        System.debug('****START****');
        System.debug(serviceModel.workOrderId);

        // lookup against the work order for the SMS phone number
        if(serviceModel.workOrderId != null && serviceModel.workOrderId != '' && serviceModel.workOrderId != 'null' ){
            
            WorkOrder appt =  [SELECT id, AccountId, SMS_Phone__c FROM WorkOrder WHERE id = :serviceModel.workOrderId];

            
            if(appt != null){
                List<Account> a = [SELECT id, Appt_Email_Opt_In__pc, Appt_SMS_Opt_In__pc FROM Account WHERE Id=:appt.AccountId];
                System.debug('getCustomerEditableFields(), found account on work order: ' +a);
                
                if(a.size() > 0){
                    serviceModel.emailAddressOptIn = serviceModel.emailAddressOptIn == null ? a[0].Appt_Email_Opt_In__pc : serviceModel.emailAddressOptIn;
                    serviceModel.textOptIn = serviceModel.textOptIn == null ? a[0].Appt_SMS_Opt_In__pc : serviceModel.textOptIn;   
                }
                

                if(appt.SMS_Phone__c != null){
                    serviceModel.smsPhoneNumber = appt.SMS_Phone__c;

                    // clear formatting to provide consistent results in the ui
                    serviceModel.smsPhoneNumber = serviceModel.smsPhoneNumber.replace('-','');
                    serviceModel.smsPhoneNumber = serviceModel.smsPhoneNumber.replace('(','');
                    serviceModel.smsPhoneNumber = serviceModel.smsPhoneNumber.replace(')','');
                    serviceModel.smsPhoneNumber = serviceModel.smsPhoneNumber.replace('.','');
                    serviceModel.smsPhoneNumber = serviceModel.smsPhoneNumber.replace(' ','');
                }
            }   
        }
        else {
            serviceModel.smsPhoneNumber = serviceModel.mobilePhoneNumber;
            System.debug(lprefix +' NO CONTACT ID PROVIDED, SKIPPING getCustomerEditableFields()');
        }

        System.debug('serviceModel after retrieving opt in and sms number:' +serviceModel);
    }

    @AuraEnabled
    public static String createAppointment(String model){
        try {
            Appt_CreateAppointmentServiceModel apptModel = (Appt_CreateAppointmentServiceModel) JSON.deserialize(model, Appt_CreateAppointmentServiceModel.class);

            apptModel.appointmentDate = Date.valueOf(apptModel.appointmentDate);
            apptModel.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
            apptModel.source = Appt_ConstantValues.APPOINTMENT_SOURCE_POS;

            System.debug('START**************');

            if(apptModel.smsPhoneNumber != null) {
                apptModel.smsPhoneNumber = apptModel.smsPhoneNumber.replace('null', '');
            }

            if(apptModel.homePhoneNumber != null) {
                apptModel.homePhoneNumber = apptModel.homePhoneNumber.replace('null', '');
            }

            if(apptModel.workPhoneNumber != null) {
                apptModel.workPhoneNumber = apptModel.workPhoneNumber.replace('null', '');
            }

            if(apptModel.mobilePhoneNumber != null) {
                apptModel.mobilePhoneNumber = apptModel.mobilePhoneNumber.replace('null', '');
            }

            if(apptModel.recipientPhone != null) {
                apptModel.recipientPhone = apptModel.recipientPhone.replace('null', '');
            }

            // Check that start/end times match slot start/end times. If so, clear the slot times. Otherwise, it is a custom time
            if(apptModel.backOfficeStartTime.equals(apptModel.selectedSlotStartTime) && apptModel.backOfficeEndTime.equals(apptModel.selectedSlotEndTime)){
                apptModel.selectedSlotStartTime = null;
                apptModel.selectedSlotEndTime = null;
            }
            
            System.debug(lprefix + ' apptModel: ' +apptModel);
            System.debug(lprefix + 'appt model orderDate: ' +apptModel.orderDate);
            System.debug(lprefix + 'appt model formDate: ' + apptModel.formDate);
            System.debug(lprefix + ' User Name: ' +UserInfo.getName());

            Appt_CreateAppointmentServiceModel returnModel = Appt_SystemService.createAppointment(apptModel);

            if(returnModel.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS){
                return JSON.serialize(new ReturnModel('Success', 'Successfully create appointment', JSON.serialize(returnModel)));
            }
            else {
                return JSON.serialize(new ReturnModel('Failed', 'An error occured creating appointment: ' +returnModel.message, JSON.serialize(returnModel)));
            }

        } catch (Exception e) {
            Map<String, Object> errorObj = new Map<String, Object>();
            errorObj.put('lineNumber', e.getLineNumber());
            errorObj.put('message', e.getMessage());
            errorObj.put('exceptionType', e.getTypeName());

            throw new AuraHandledException(JSON.serialize(errorObj));
        }
    }


    @AuraEnabled
    public static String rescheduleAppointment(String model){
        

        try {
            Appt_UpdateAppointmentServiceModel apptModel = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(model, Appt_UpdateAppointmentServiceModel.class);
            apptModel.appointmentDate = Date.valueOf(apptModel.appointmentDate);
            apptModel.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
            apptModel.source = Appt_ConstantValues.APPOINTMENT_SOURCE_POS;
            apptModel.consultStartTime = '';
            apptModel.consultEndTime = '';

            if(apptModel.smsPhoneNumber != null) {
                apptModel.smsPhoneNumber = apptModel.smsPhoneNumber.replace('null', '');
            }

            if(apptModel.homePhoneNumber != null) {
                apptModel.homePhoneNumber = apptModel.homePhoneNumber.replace('null', '');
            }

            if(apptModel.workPhoneNumber != null) {
                apptModel.workPhoneNumber = apptModel.workPhoneNumber.replace('null', '');
            }

            if(apptModel.mobilePhoneNumber != null) {
                apptModel.mobilePhoneNumber = apptModel.mobilePhoneNumber.replace('null', '');
            }

            if(apptModel.recipientPhone != null) {
                apptModel.recipientPhone = apptModel.recipientPhone.replace('null', '');
            }

            System.debug('rescheduleAppointment() selectedSlot check: apptModel.backOfficeStartTime=' +apptModel.backOfficeStartTime + ', apptModel.selectedSlotStartTime='+apptModel.selectedSlotStartTime);
            System.debug('rescheduleAppointment() selectedSlot check: apptModel.backOfficeEndTime=' +apptModel.backOfficeEndTime + ', apptModel.selectedSlotEndTime='+apptModel.selectedSlotEndTime);

            // Check that start/end times match slot start/end times. If so, clear the slot times. Otherwise, it is a custom time
            if(apptModel.backOfficeStartTime.equals(apptModel.selectedSlotStartTime) && apptModel.backOfficeEndTime.equals(apptModel.selectedSlotEndTime)){
                apptModel.selectedSlotStartTime = null;
                apptModel.selectedSlotEndTime = null;
            }

            Appt_UpdateAppointmentServiceModel returnModel = Appt_SystemService.updateAppointment(apptModel);
            System.debug('return model: ' +returnModel);
            if(returnModel.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS){
                return JSON.serialize(new ReturnModel('Success', 'Successfully create appointment', JSON.serialize(returnModel)));
            }
            else {
                return JSON.serialize(new ReturnModel('Failed', 'An error occured creating appointment: ' +returnModel.message, JSON.serialize(returnModel)));
            }

        } catch (Exception e) {
            Map<String, Object> errorObj = new Map<String, Object>();
            errorObj.put('lineNumber', e.getLineNumber());
            errorObj.put('message', e.getMessage());
            errorObj.put('exceptionType', e.getTypeName());

            throw new AuraHandledException(JSON.serialize(errorObj));
        }
    }


    @AuraEnabled
    public static String cancelAppointment(String model){
        Appt_UpdateAppointmentServiceModel apptModel = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(model, Appt_UpdateAppointmentServiceModel.class);
        apptModel.appointmentDate = Date.valueOf(apptModel.appointmentDate);
        apptModel.source = Appt_ConstantValues.APPOINTMENT_SOURCE_POS;

        if(apptModel.smsPhoneNumber != null) {
            apptModel.smsPhoneNumber = apptModel.smsPhoneNumber.replace('null', '');
        }

        if(apptModel.homePhoneNumber != null) {
            apptModel.homePhoneNumber = apptModel.homePhoneNumber.replace('null', '');
        }

        if(apptModel.workPhoneNumber != null) {
            apptModel.workPhoneNumber = apptModel.workPhoneNumber.replace('null', '');
        }

        if(apptModel.mobilePhoneNumber != null) {
            apptModel.mobilePhoneNumber = apptModel.mobilePhoneNumber.replace('null', '');
        }

        if(apptModel.recipientPhone != null) {
            apptModel.recipientPhone = apptModel.recipientPhone.replace('null', '');
        }

        try {
            Appt_UpdateAppointmentServiceModel returnModel = Appt_SystemService.updateAppointment(apptModel);
            
            if(returnModel.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS){
                return JSON.serialize(new ReturnModel('Success', 'Successfully create appointment', JSON.serialize(returnModel)));
            }
            else {
                return JSON.serialize(new ReturnModel('Failed', 'An error occured creating appointment: ' +returnModel.message, JSON.serialize(returnModel)));
            }

        } catch (Exception e) {
            Map<String, Object> errorObj = new Map<String, Object>();
            errorObj.put('lineNumber', e.getLineNumber());
            errorObj.put('message', e.getMessage());
            errorObj.put('exceptionType', e.getTypeName());

            throw new AuraHandledException(JSON.serialize(errorObj));
        }
    }
    

    @AuraEnabled
    public static string editCustomerDetails(String accountId, String workOrderId, String fieldsJson){        
        System.debug(lprefix + workOrderId);

        Map<String,Object> fieldsToMap = (Map<String,Object>)JSON.deserializeUntyped(fieldsJson); // Convert json to map        

        Boolean smsOptIn = (Boolean) fieldsToMap.get('smsOptIn');
        Boolean emailAddressOptIn = (Boolean) fieldsToMap.get('emailAddressOptIn');
        String smsPhoneNumber = (String) fieldsToMap.get('smsPhoneNumber');

        try {
            Account a;
            // if the work order id is passed also updated the appointment SMS number field
            if(workOrderId != null && workOrderId != '' && workOrderId != 'null'){
                WorkOrder updateAppt =  [SELECT id, AccountId FROM WorkOrder WHERE id = :workOrderId];
                updateAppt.SMS_Phone__c = smsPhoneNumber;
                update updateAppt;

                String accId = updateAppt.AccountId;
                a = [SELECT Id, Appt_Email_Opt_In__pc, Appt_SMS_Opt_In__pc FROM Account WHERE Id=:accId LIMIT 1];

                if(a != null){
                    a.Appt_Email_Opt_In__pc = emailAddressOptIn != NULL ? emailAddressOptIn : a.Appt_Email_Opt_In__pc;
                    a.Appt_SMS_Opt_In__pc = smsOptIn != NULL ? smsOptIn : a.Appt_SMS_Opt_In__pc;
                    update a;
                }
            }
            else{
                System.debug(accountId);
                // find the account that the contact is on
                a = [SELECT Id, PersonContactId FROM Account WHERE Id=:accountId];
           
                if(a != NULL){
                    a.Appt_Email_Opt_In__pc = emailAddressOptIn != NULL ? emailAddressOptIn : a.Appt_Email_Opt_In__pc;
                    a.Appt_SMS_Opt_In__pc = smsOptIn != NULL ? smsOptIn : a.Appt_SMS_Opt_In__pc;

                    update a;
                }
            }

            return 'done';

        } catch (Exception e) {
            system.debug(lprefix + 'editCustomerDetails::exception: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String resendNotification(String model, String type){        
        try {
            Appt_CreateAppointmentServiceModel apptModel = (Appt_CreateAppointmentServiceModel) JSON.deserialize(model, Appt_CreateAppointmentServiceModel.class);
            
            System.debug('before notificaitons: ' +apptModel.appointmentId);

            Appt_NotificationUtil.resendNotification(apptModel.appointmentId, type);

            System.debug('check notificaitons: ' +apptModel.appointmentId);

            List<WorkOrder> sentDate = [SELECT id, Email_Confirmation_Sent_Date__c, SMS_Confirmation_Sent_Date__c FROM WorkOrder WHERE id = :apptModel.appointmentId LIMIT 1];

            System.debug('Work Order Notification Dates' + sentDate[0]);
            
            // Set the new confirmation date for the notification to today
            Date today = Date.today();
            if(sentDate.size() > 0){

                if(type.equals('SMS')){

                    if(sentDate[0].SMS_Confirmation_Sent_Date__c != null){
                        apptModel.smsConfirmationSent = Date.newInstance(sentDate[0].SMS_Confirmation_Sent_Date__c.year(), sentDate[0].SMS_Confirmation_Sent_Date__c.month(), sentDate[0].SMS_Confirmation_Sent_Date__c.day());
                    } 
                    
                }
                else {
                    if(sentDate[0].Email_Confirmation_Sent_Date__c != null){
                        apptModel.emailConfirmationSent = Date.newInstance(sentDate[0].Email_Confirmation_Sent_Date__c.year(), sentDate[0].Email_Confirmation_Sent_Date__c.month(), sentDate[0].Email_Confirmation_Sent_Date__c.day());            
                    }
                }

            }
            

            return JSON.serialize(apptModel);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getSFBaseUrl() {

        try {
            String sfdcBaseURL = URL.getOrgDomainUrl().getHost();
            System.debug('Base URL: ' + sfdcBaseURL );
            return sfdcBaseURL;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}