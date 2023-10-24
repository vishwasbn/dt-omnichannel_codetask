/******************************************************************************************************
* Project : Appointment 3.0
*******************************************************************************************************
* Business Owner : Discount Tire
* Purpose        : This is main controller class that drives Appt 3.0 functionality - Create/Reschedule/Cancel
* Business Logic : 
*******************************************************************************************************
* Test Class:     Appt3_ApptsPageContainerControllerTest
*
* Dependencies (Other) : N/A
*
*******************************************************************************************************
* Version   Date          Updated By                        Test          Target        Comments
*                                                           Coverage      Release
*
* 1.0      11/14/2022     sindhur.borusu@discounttire.com    91%          FY23-June   
*****************************************************************************************/

/**
 * @description This is main controller class that drives Appt 3.0 functionality - Create/Reschedule/Cancel.
 */
public without sharing class Appt3_ApptsPageContainerController {
    
    public final static string LPREFIX = 'LOG APPT3_PageCC ';
    public static WorkOrder wo;
    /**
     * @description This class contains the structure in which data is sent from controller.
     */
    public class ReturnModel {
        /**
         * @description getter setter for status.
        */
        public String status {get; set;}
        /**
         * @description getter setter for message
         */
        public String message {get; set;}
        /**
         * @description getter setter for optionalModel
         */
        public String optionalModel {get; set;} 
        
        /**
         * @description constructor with two parameters for class ReturnModel
         * @param status
         * @param message
         */
        public ReturnModel(String status, String message){
            this.status = status;
            this.message = message;
        }
        
        /**
         * @description constructor with three parameters for class ReturnModel
         * @param status
         * @param message
         * @param optionalModel
         */
        public ReturnModel(String status, String message, String optionalModel){
            this.status = status;
            this.message = message;
            this.optionalModel = optionalModel;
        }
    }
    
    /**
     * @description This method is called during the load of Appointment Page Container component. The raw paylaod from calling applications will be parsed into model class
     * @param jsonString
     * @return a string which contains serviceModel based on action received.
     */
    @AuraEnabled
    public static String getAppointmentServiceModel(String jsonString) {
        System.debug(LPREFIX + '---ENTER getServiceModel---');
        
        try {
            
            //decode the json string (this is a catch all since the payload being passed in encoded from the JXBrowser)
            //jsonString = EncodingUtil.urlDecode(jsonString, 'UTF-8');
            
            //parse incoming JSON String
            Appt3_POSAppointmentModel posModel = Appt3_POSAppointmentModel.parse(jsonString);
            System.debug(LPREFIX + ' posModel:' + posModel);
            System.debug(LPREFIX + ' posModel action: ' +posModel.action);
            
            //Check if the action is view or create. View will return updateModel, create will return createModel
            if(posModel.action.equalsIgnoreCase('VIEW')){
                Appt_UpdateAppointmentServiceModel serviceModel;
                //when calling applications send only workorderid, enrich the response payload to be rendered on VIEW screen.
                if (posModel.siteId != null) {
                    serviceModel = posModel.getUpdateAppointmentServiceModel(posModel);
                    
                } else {
                    serviceModel = new Appt_UpdateAppointmentServiceModel();
                    serviceModel.workOrderId = posModel.workOrderId;
                }
                processVehicleAndCustomerEditableFields(serviceModel);
                //Grab the appointment details if there is a workOrderId, otherwise return an error
                getAppointmentDetails(serviceModel);
                return JSON.serialize(serviceModel);
            }
            else if(posModel.action.equalsIgnoreCase('CRT')){
                Appt_CreateAppointmentServiceModel serviceModel = posModel.getCreateAppointmentServiceModel(posModel);
                System.debug('Service Model is ' +serviceModel);
                processVehicleAndCustomerEditableFields(serviceModel);
                System.debug('Service Model is ' +JSON.serialize(serviceModel));
                return JSON.serialize(serviceModel);
            }
            else {
                throw new AuraHandledException('Action \'' +posModel.action +'\' is not a legal argument');
            }
        } catch (exception e) {
            logExceptions(e, Appt3_ApptsPageContainerController.class.getName(), 'Appointments 3.0');
            Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();
            serviceModel.status = Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            serviceModel.message = 'System Error: ' + e.getMessage();
            return JSON.serialize(serviceModel);
        }
        
    }
    /**
     * @description This method contains logic to feed the return model with data from multiple objects in the database.
     * @param model
     */  
    public static void processVehicleAndCustomerEditableFields(Appt_CreateAppointmentServiceModel model) {
        System.debug(LPREFIX + '---processVehicleAndCustomerEditableFields---'+model);
        /* If workorderid is available in the payload, then fetch all data related to the work order in a single query for further processing. Typically, the if part will be
         executed during the load of VIEW appointment screen */
    
        if(model.workOrderId != null && model.workOrderId != '' && model.workOrderId != 'null'){
            wo = [SELECT Id, Vehicle__r.Vehicle_Make__c, Vehicle__r.Vehicle_Model__c,Vehicle__r.Appt3_Vehicle_Image_URL__c,Vehicle__r.Trim_Name__c,
                  SMS_Confirmation_Sent_Date__c,Email_Confirmation_Sent_Date__c, Source__c,Order_Type__c,WorkOrderNumber,Appt3_Sales_Order_Id__c,
                  Appointment_Comments__c,Appt3_UnPaid__c, Account.Appt_Customer_Type__c,Vehicle__r.Vehicle_Manufacture_Year__c, Vehicle__r.Assembly_Id__c, 
                  Account.PersonContactId, Account.FirstName,Account.MiddleName, AccountId, SMS_Phone__c,Vehicle__r.Appt3_Fitment_Lift_Id__c,
                  Vehicle__r.Appt3_Front_Tire_Size__c,Vehicle__r.Appt3_Front_Tire_Diameter__c, Vehicle__r.Appt3_Rear_Tire_Diameter__c,
                  Vehicle__r.Appt3_Rear_Tire_Size__c,Vehicle__r.Appt3_Assembly_Type__c,Vehicle__r.Appt3_Color__c, Vehicle__r.Vehicle_License_Plate__c,
                  Vehicle__r.Appt3_Type_Of_Vehicle__c,Vehicle__r.Appt3_Generic_Vehicle_Category__c,Vehicle__r.Appt3_Generic_Vehicle_SubCategory__c,
                  Vehicle__r.Appt3_Customer_Vehicle_Id__c,Vehicle__r.Trim_Id__c, Account.Appt_Email_Opt_In__pc, Account.Appt_SMS_Opt_In__pc, 
                  Account.Appt3_Company_Name__c,Account.Appt3_Company_Name2__c, Account.LastName,Account.Suffix,Account.Email__c,
                  Account.Appt3_Fleet_Number__c,Account.Appt3_Customer_Id__c, Account.Appt3_My_Account__c, Account.Appt3_Private_Label_Cardholder__c, 
                  Account.Appt3_Military__c, Account.Appt3_AAA_Membership__c, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c,Account.ShippingStreet,
                  Account.ShippingPostalCode, Account.ShippingCity,Account.ShippingState, Account.ShippingCountry,Account.PersonMobilePhone,
                  Account.PersonHomePhone, Account.Phone, Order_Date__c, Hybris_Order_Id__c, Invoice_Number__c, Quote_Number__c, Layaway_Number__c, POS_Web_Order_Id__c,
                  (SELECT ID, toLabel(Status), Date_String__c, Back_Office_Start_Time__c, Selected_Slot_End_Time_String__c, 
                   Selected_Slot_Start_Time_String__c, Back_Office_End_Time__c, Consult_Start_Time__c, Consult_End_Time__c, Activity_Type__c 
                   FROM ServiceAppointments),
                  (SELECT Channels__c, Initial_Email_Send_Status__c, Initial_Email_Send_Date__c, Initial_PE_SMS_Send_Date__c, Initial_PE_SMS_Send_Status__c 
                   FROM Notifications__r WHERE Initial_Email_Send_Status__c = 'Success' OR Initial_PE_SMS_Send_Status__c = 'Success')
                  FROM WorkOrder WHERE Id = :model.workOrderId LIMIT 1];
            if(wo != null) {
                //Vehicle data processing for UI
                model.make = (model.make == null || String.isBlank(model.make)) ? wo.Vehicle__r.Vehicle_Make__c : model.make;
                model.model = (model.model == null || String.isBlank(model.model)) ? wo.Vehicle__r.Vehicle_Model__c : model.model;
                model.year = (model.year == null || String.isBlank(model.year)) ? wo.Vehicle__r.Vehicle_Manufacture_Year__c : model.year;
                //trimDetails attribute renders trim name on the screen. POS payload sends trimId.
                model.trimDetails = (model.trimName == null || String.isBlank(model.trimName)) ? wo.Vehicle__r.Trim_Name__c : model.trimName;
                model.assemblyDetails = (model.assemblyId == null || String.isBlank(model.assemblyId)) ? wo.Vehicle__r.Assembly_Id__c : model.assemblyId;
                //Customer editable fields processing for UI
                if(wo.AccountId != null) {
                    model.emailAddressOptIn = wo.Account.Appt_Email_Opt_In__pc;
                    model.textOptIn = wo.Account.Appt_SMS_Opt_In__pc; 
                    model.accountId = wo.AccountId;
                    model.contactId = wo.Account.PersonContactId;                    
                }
                if (wo.SMS_Phone__c != null) {
                    model.smsPhoneNumber = wo.SMS_Phone__c;
                }
                //when calling applications send only workorderid, enrich the response payload to be rendered on VIEW screen.
                if (model.siteId == null) {
                    enrichResponseToUI(model);
                }
            }
            
        } else {   
            model.assemblyDetails = model.assemblyId;  
            //trimDetails attribute renders trim name on the UI. POS payload sends trimId only.
            model.trimDetails = '';
            List<Reference__c> trimInfo = [SELECT Trim_Name__c from Reference__c WHERE Trim_Id__c = :model.trimId LIMIT 1];
            if(!trimInfo.isEmpty()){
                if(trimInfo[0].Trim_Name__c != null) {
                    model.trimDetails = trimInfo[0].Trim_Name__c;
                } else{
                    model.trimDetails = '';
                }                
            }
            model.smsPhoneNumber = model.mobilePhoneNumber;
        }
    }
    
    /**
     * @description This gets the existing service appointment details to be rendered on the VIEW appopintment screen.
     * @param model
     */
    public static void getAppointmentDetails(Appt_CreateAppointmentServiceModel model) {
        System.debug(LPREFIX +'---getAppointmentDetailS---' +model);
        
        if (model.workOrderId == null || model.workOrderId == '') {
            model.message = System.Label.Appt3_WorkOrderId_Required + ' '+ String.valueOf(model.workOrderId);
            model.status = Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            return;
        }
        
        if (wo == null) {
            model.message = System.Label.Appt3_No_Appointment_found_with_workOrderId + ' ' + String.valueOf(model.workOrderId);
            model.status = Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            return;
        }
       
        List<Notification__c> notifications = wo.Notifications__r;
        if(notifications.size() != 0) { 
            fetchNotificationsToRender(notifications, model);
        }
        
        model.appointmentId = wo.Id;
        model.source = wo.Source__c;
        
        List<ServiceAppointment> appts = wo.ServiceAppointments;
        System.debug(LPREFIX +' appts: ' +appts);
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
                   }
            }
        }
    }
    /**
     * @description This method gets called when the terminal user confirms creation of an appointment.
     * @param model
     * @return a string which contains success or failure response and returnmodel.
     */
    @AuraEnabled
    public static String createAppointment(String model){
        System.debug(LPREFIX + '--- createAppointment ---'+model);
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
            if(apptModel.backOfficeStartTime != null && 
               apptModel.backOfficeEndTime != null && 
               apptModel.backOfficeStartTime.equals(apptModel.selectedSlotStartTime) && 
               apptModel.backOfficeEndTime.equals(apptModel.selectedSlotEndTime)){
                   apptModel.selectedSlotStartTime = null;
                   apptModel.selectedSlotEndTime = null;
               }
            
            System.debug(LPREFIX + ' apptModel: ' +apptModel);
            System.debug(LPREFIX + 'appt model orderDate: ' +apptModel.orderDate);
            System.debug(LPREFIX + 'appt model formDate: ' + apptModel.formDate);
            System.debug(LPREFIX + ' User Name: ' +UserInfo.getName());
            
            Appt_CreateAppointmentServiceModel returnModel = Appt_SystemService.createAppointment(apptModel);
            
            if(returnModel.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS){
                return JSON.serialize(new ReturnModel('Success', 'Successfully create appointment', JSON.serialize(returnModel)));
            }
            else {
                return JSON.serialize(new ReturnModel('Failed', 'An error occured creating appointment: ' +returnModel.message, JSON.serialize(returnModel)));
            }    
        } catch (Exception e) {
            logExceptions(e, Appt3_ApptsPageContainerController.class.getName(), 'Appointments 3.0');            
            Map<String, Object> errorObj = buildUIErrorMessage(e);
            throw new AuraHandledException(JSON.serialize(errorObj));
        }
    }
    
    /**
     * @description This method gets called when the terminal user confirms reschedule of an appointment.
     * @param model
     * @return a string which contains success or failure response and returnmodel.
     */
    @AuraEnabled
    public static String rescheduleAppointment(String model){
        System.debug(LPREFIX + '--- rescheduleAppointment---'+model);
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
            System.debug('requestmodel' +apptModel);
            Appt_UpdateAppointmentServiceModel returnModel = Appt_SystemService.updateAppointment(apptModel);
            System.debug('return model: ' +returnModel);
            if(returnModel.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS){
                return JSON.serialize(new ReturnModel('Success', 'Successfully create appointment', JSON.serialize(returnModel)));
            }
            else {
                return JSON.serialize(new ReturnModel('Failed', 'An error occured creating appointment: ' +returnModel.message, JSON.serialize(returnModel)));
            }
            
        } catch (Exception e) {
            logExceptions(e, Appt3_ApptsPageContainerController.class.getName(), 'Appointments 3.0');            
            Map<String, Object> errorObj = buildUIErrorMessage(e);         
            throw new AuraHandledException(JSON.serialize(errorObj));
        }
    }
    
    /**
     * @description This method gets called when the terminal user cancels an appointment.
     * @param model
     * @return a string which contains success or failure response and returnmodel.
     */
    @AuraEnabled
    public static String cancelAppointment(String model){
        System.debug(LPREFIX + '---cancelAppointment---'+model);
        try {
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
            
            Appt_UpdateAppointmentServiceModel returnModel = Appt_SystemService.updateAppointment(apptModel);
            
            if(returnModel.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS){
                return JSON.serialize(new ReturnModel('Success', 'Successfully create appointment', JSON.serialize(returnModel)));
            }
            else {
                return JSON.serialize(new ReturnModel('Failed', 'An error occured creating appointment: ' +returnModel.message, JSON.serialize(returnModel)));
            }
            
        } catch (Exception e) {
            logExceptions(e, Appt3_ApptsPageContainerController.class.getName(), 'Appointments 3.0');            
            Map<String, Object> errorObj = buildUIErrorMessage(e);             
            throw new AuraHandledException(JSON.serialize(errorObj));
        }
    }
    /**
     * @description This method sets the EMAIL and SMS opt in fields on Account based on customer's preference.
     * @param accountId
     * @param fieldsJson
     * @return a string 'done' after updation.
     */
    @AuraEnabled
    public static string editCustomerDetails(String accountId, String fieldsJson){        
        System.debug(LPREFIX + '---editCustomerDetails---'+accountId+'-fieldsJson-'+fieldsJson);
        Map<String,Object> fieldsToMap = (Map<String,Object>)JSON.deserializeUntyped(fieldsJson); // Convert json to map        
        Boolean smsOptIn = (Boolean) fieldsToMap.get('smsOptIn');
        Boolean emailAddressOptIn = (Boolean) fieldsToMap.get('emailAddressOptIn');
        try {
            Account a;
            System.debug(accountId);
            a = [SELECT Id, PersonContactId, Appt_Email_Opt_In__pc, Appt_SMS_Opt_In__pc FROM Account WHERE Id=:accountId];
            
            if(a != NULL){
                a.Appt_Email_Opt_In__pc = emailAddressOptIn != NULL ? emailAddressOptIn : a.Appt_Email_Opt_In__pc;
                a.Appt_SMS_Opt_In__pc = smsOptIn != NULL ? smsOptIn : a.Appt_SMS_Opt_In__pc;
                
                update a;
            }
            return 'done';
            
        } catch (Exception e) {
            logExceptions(e, Appt3_ApptsPageContainerController.class.getName(), 'Appointments 3.0');            
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description This method resends the notifications when terminal user clicks 'Resend' on View Appointment screen.
     * @param model
     * @param type
     * @return string 
     */
    @AuraEnabled
    public static String resendNotification(String model, String type){ 
        System.debug(LPREFIX + '---resendNotification---'+model+'-type-'+type);
        try {
            Appt_CreateAppointmentServiceModel apptModel = (Appt_CreateAppointmentServiceModel) JSON.deserialize(model, Appt_CreateAppointmentServiceModel.class);            
            Appt_NotificationUtil.resendNotification(apptModel.appointmentId, type);
            List<Notification__c> notifications = [SELECT Channels__c, Initial_Email_Send_Status__c, Initial_Email_Send_Date__c, Initial_PE_SMS_Send_Date__c, 
                                                   Initial_PE_SMS_Send_Status__c FROM Notification__c 
                                                   WHERE Work_Order__c = :apptModel.appointmentId AND 
                                                   (Initial_Email_Send_Status__c = 'Success' OR Initial_PE_SMS_Send_Status__c = 'Success')];
            System.debug('Notifications query result - '+notifications);
            if(notifications.size() != 0) {
                fetchNotificationsToRender(notifications, apptModel);
            }
            
            return JSON.serialize(apptModel);
           
        } catch (Exception e) {
            logExceptions(e, Appt3_ApptsPageContainerController.class.getName(), 'Appointments 3.0');  
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description This contains logic to fetch the latest 3 email/sms communications sent to the customer using Notification object.
     * @param notifications
     * @param model
     */
    public static void fetchNotificationsToRender(List<Notification__c> notifications, Appt_CreateAppointmentServiceModel model) {
        System.debug(LPREFIX + '---fetchNotificationsToRender---'+notifications+'-Model-'+model);             
        model.emailNotificationsSent = new List<String>();
        model.smsNotificationsSent = new List<String>();
        for(Notification__c ns: notifications){
                if(ns.Channels__c.contains('EMAIL') && ns.Initial_Email_Send_Date__c != null ){
                model.emailNotificationsSent.add(ns.Initial_Email_Send_Date__c.format('MM/dd/yyyy @ h:mm a', UserInfo.getTimeZone().getID()));
            }
                if(ns.Channels__c.contains('SMS') && ns.Initial_PE_SMS_Send_Date__c != null ){
                model.smsNotificationsSent.add(ns.Initial_PE_SMS_Send_Date__c.format('MM/dd/yyyy @ h:mm a', UserInfo.getTimeZone().getID()));
            }
            
        }
        
        model.emailNotificationsSent.sort();
        model.smsNotificationsSent.sort();
        System.debug('Email ->'+model.emailNotificationsSent);
        System.debug('SMS ->'+model.smsNotificationsSent);  
    }
    
    /**
     * @description This method returns the host name of the current instance URL.
     * @return a string containing BaseURL.
     */
    @AuraEnabled
    public static string getSFBaseUrl() {
        System.debug(LPREFIX + '---getSFBaseUrl---');
        try {
            String sfdcBaseURL = URL.getOrgDomainUrl().getHost();
            System.debug('Base URL: ' + sfdcBaseURL );
            return sfdcBaseURL;
        } catch (Exception e) {
            logExceptions(e, Appt3_ApptsPageContainerController.class.getName(), 'Appointments 3.0');             
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description This method updates the SMS Phone field on WorkOrder when terminal user updates the Alternative contact on View Appointment Screen.
     * @param workOrderId
     * @param smsPhoneNumber 
     * @return a string 'done' after updation.
     */
    @AuraEnabled
    public static string updateAlternativePhone(String workOrderId, String smsPhoneNumber) {
        System.debug(LPREFIX + '-workOrderId-'+workOrderId+'-smsPhoneNumber-'+smsPhoneNumber);
        try {
            if(workOrderId != null && workOrderId != '' && workOrderId != 'null'){
                WorkOrder updateAppt =  [SELECT id, AccountId FROM WorkOrder WHERE id = :workOrderId];
                updateAppt.SMS_Phone__c = smsPhoneNumber;
                update updateAppt;
            }
            return 'done';
        } catch (Exception e) {
            logExceptions(e, Appt3_ApptsPageContainerController.class.getName(), 'Appointments 3.0');             
            throw new AuraHandledException(e.getMessage());            
        }
    }    
    
    /**
     * @description This method records the request payload from calling applications to Int_Message__c object.
     * @param jsonString
     * @param channel 
     */
    @AuraEnabled
    public static void recordPayload(String jsonString, String channel) {
        try {
            channel = !String.isBlank(channel) ? channel : 'Entry Point';
            Int_Message__c intMsg = new Int_Message__c(Type__c = 'Appt 3.0_'+channel+'_Payload_Incoming', Payload__c = jsonString);
            insert intMsg;
        } catch (Exception e) {
            logExceptions(e, Appt3_ApptsPageContainerController.class.getName(), 'Appointments 3.0');             
            throw new AuraHandledException(e.getMessage());            
        }
    }
    
    /**
     * @description This method enriches the response sent to UI when only workOrderId is received in the request from calling applications.
     * @param serviceModel 
     */
    public static void enrichResponseToUI(Appt_CreateAppointmentServiceModel serviceModel) {
        List<Appt_InvoiceDetailModel.LineItems> lineItems = new List<Appt_InvoiceDetailModel.LineItems>();
        String lineItemsString;
        serviceModel.firstName = wo.Account.FirstName;
        serviceModel.lastName = wo.Account.LastName;
        serviceModel.middleInitial = wo.Account.MiddleName;
        serviceModel.suffix = wo.Account.Suffix;
        serviceModel.emailAddress = wo.Account.Email__c;
        serviceModel.companyName = wo.Account.Appt3_Company_Name__c;
        serviceModel.companyName2 = wo.Account.Appt3_Company_Name2__c;
        serviceModel.fleetNumber = wo.Account.Appt3_Fleet_Number__c;         
        serviceModel.siteId = wo.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;
        serviceModel.address1 = wo.Account.ShippingStreet;
        serviceModel.zipCode = wo.Account.ShippingPostalCode;
        serviceModel.city = wo.Account.ShippingCity;
        serviceModel.state = wo.Account.ShippingState;
        serviceModel.country = wo.Account.ShippingCountry;
        serviceModel.showMyAccount = wo.Account.Appt3_My_Account__c;
        serviceModel.showAAAMember = wo.Account.Appt3_AAA_Membership__c ;
        serviceModel.showDTCC = wo.Account.Appt3_Private_Label_Cardholder__c;
        serviceModel.showMilitary = wo.Account.Appt3_Military__c;
        serviceModel.mobilePhoneNumber = wo.Account.PersonMobilePhone;
        serviceModel.homePhoneNumber = wo.Account.PersonHomePhone;
        serviceModel.workPhoneNumber = wo.Account.Phone;
        serviceModel.customerId = wo.Account.Appt3_Customer_Id__c;
        serviceModel.year = wo.Vehicle__r.Vehicle_Manufacture_Year__c;
        serviceModel.make = wo.Vehicle__r.Vehicle_Make__c;
        serviceModel.model = wo.Vehicle__r.Vehicle_Model__c;
        serviceModel.imageURL = wo.Vehicle__r.Appt3_Vehicle_Image_URL__c;
        serviceModel.trimId = wo.Vehicle__r.Trim_Id__c;
        serviceModel.assemblyId = wo.Vehicle__r.Assembly_Id__c;
        serviceModel.fitmentLiftId = wo.Vehicle__r.Appt3_Fitment_Lift_Id__c;
        serviceModel.frontTireSize = wo.Vehicle__r.Appt3_Front_Tire_Size__c;
        serviceModel.rearTireSize = wo.Vehicle__r.Appt3_Rear_Tire_Size__c;
        serviceModel.frontTireDiameter = wo.Vehicle__r.Appt3_Front_Tire_Diameter__c;
        serviceModel.rearTireDiameter = wo.Vehicle__r.Appt3_Rear_Tire_Diameter__c;        
        serviceModel.assemblyType = wo.Vehicle__r.Appt3_Assembly_Type__c;
        serviceModel.color = (wo.Vehicle__r.Appt3_Color__c==null || String.isBlank(wo.Vehicle__r.Appt3_Color__c)) ? 'N/A' : wo.Vehicle__r.Appt3_Color__c;
        serviceModel.licensePlate = (wo.Vehicle__r.Vehicle_License_Plate__c==null || String.isBlank(wo.Vehicle__r.Vehicle_License_Plate__c)) ? 'N/A' : wo.Vehicle__r.Vehicle_License_Plate__c;
        serviceModel.vehicleType = wo.Vehicle__r.Appt3_Type_Of_Vehicle__c;
        serviceModel.genericVehicleCategory = wo.Vehicle__r.Appt3_Generic_Vehicle_Category__c;
        serviceModel.genericVehicleSubCategory = wo.Vehicle__r.Appt3_Generic_Vehicle_SubCategory__c;
        serviceModel.customerVehicleId = wo.Vehicle__r.Appt3_Customer_Vehicle_Id__c;
        serviceModel.source = wo.Source__c;
        serviceModel.orderType = wo.Order_Type__c; 
        serviceModel.orderDate = wo.Order_Date__c != null ? String.valueOf(wo.Order_Date__c) : '';
        serviceModel.customerType = wo.Account.Appt_Customer_Type__c;
        serviceModel.salesOrderId = wo.Appt3_Sales_Order_Id__c;
        serviceModel.comments = wo.Appointment_Comments__c;
        serviceModel.unPaid = wo.Appt3_UnPaid__c;  
        serviceModel.hybrisOrderId = wo.Hybris_Order_Id__c;
        serviceModel.posWebOrderId = wo.POS_Web_Order_Id__c;
        serviceModel.invoiceNumber = wo.Invoice_Number__c;
        serviceModel.quoteNumber = wo.Quote_Number__c;
        serviceModel.layawayNumber = wo.Layaway_Number__c;
        serviceModel.isVisionFeature = true;
        // CAR Order Histories call to fetch order data
        lineItemsString = Appt3_AppointmentListPageController.getOrderData(JSON.serialize(serviceModel));
        lineItems = (List<Appt_InvoiceDetailModel.LineItems>) JSON.deserialize(lineItemsString, List<Appt_InvoiceDetailModel.LineItems>.class);
        if (lineItems != null && lineItems.size() > 0) {
            serviceModel.articles = new List<Appt_CreateAppointmentServiceModel.Articles>();
            for (Appt_InvoiceDetailModel.LineItems lineItem : lineItems) {
                Appt_CreateAppointmentServiceModel.Articles a = new Appt_CreateAppointmentServiceModel.Articles();
                a.articleId = lineItem.articleNumber;
                a.articleSize = lineItem.storeSize;
                a.articleDescription = lineItem.storeDescription;
                a.articleType = lineItem.articleType;
                a.articleCount = String.valueOf(Integer.valueOf(lineItem.retailQuantity));
                serviceModel.articles.add(a);
            }
        }   
    }

    /**
     * @description This method executes when an exception occurs, builds the error message to be rendered on UI.
     * @param e 
     * @return errorObj
     */
    public static Map<String, Object> buildUIErrorMessage(Exception e){
        Map<String, Object> errorObj = new Map<String, Object>();
        errorObj.put('lineNumber', e.getLineNumber());
        errorObj.put('message', e.getMessage());
        errorObj.put('exceptionType', e.getTypeName()); 
        return errorObj;   
    }    
    
    /**
     * @description This method executes when an exception occurs, creates a LOG record with erorr details.
     * @param e
     * @param className 
     * @param feature 
     */
    public static void logExceptions(Exception e, String className, String feature) {
        Logger logInstance = Logger.getInstance();
        logInstance.log(feature, className , e);   
    }    

}