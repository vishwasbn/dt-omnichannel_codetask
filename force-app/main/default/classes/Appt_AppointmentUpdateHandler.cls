public without sharing class Appt_AppointmentUpdateHandler {
    
    public static final String lprefix = 'Appt_ApptUpdateH: ';


    //Update an existing appointment, including customer and vehicle. This method is used to CANCEL an appointment as well.
    public static Appt_UpdateAppointmentServiceModel updateAppointment(Appt_UpdateAppointmentServiceModel updateParamsModel){
 
        System.debug('create database savepoint for rollback');
        Savepoint sp = Database.setSavepoint();
        
        //if apptModel param is null return with an error
        if ( updateParamsModel == null ) {
            updateParamsModel = new Appt_UpdateAppointmentServiceModel();
            updateParamsModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'Required apptModel model parameter is null');
            return updateParamsModel;
        }

        // 0. Validate the parameters in the model. If not valid, return model which will contain error codes and message
        if (validateModelParams(updateParamsModel) == false) return updateParamsModel;
        System.debug(lprefix+'updateAppointment() ENTRY - updateParamsModel.appointmentId='+updateParamsModel.appointmentId+', updateParamsModel.appointmentStatus='+updateParamsModel.appointmentStatus);
        System.debug(lprefix+'   custom times modal check: updateParamsModel.selectedSlotStartTime='+updateParamsModel.selectedSlotStartTime + ', updateParamsModel.selectedSlotStartTime=' + updateParamsModel.selectedSlotEndTime);  //DEBUG
        
        // model to hold record field values that are to be updated. Will be return object as well.
        Appt_UpdateAppointmentServiceModel toUpdateModel = new Appt_UpdateAppointmentServiceModel();
        toUpdateModel.appointmentId = updateParamsModel.appointmentId;

        //Retrieve the Work Order and child service appointments
        Appt_UpdateAppointmentServiceModel existingApptModel = getAppointmentRecords(updateParamsModel);
        if (existingApptModel != null && existingApptModel.isError()) {
            //return error because couldn't retrieve the Work Order and Service Appointment records
            toUpdateModel.setError(existingApptModel.statusCode,existingApptModel.message);
            return toUpdateModel;
        }

        toUpdateModel.consultAppointmentId = existingApptModel.consultAppointmentId;
        toUpdateModel.backOfficeAppointmentId = existingApptModel.backOfficeAppointmentId;
        toUpdateModel.contactId = existingApptModel.contactId;
        toUpdateModel.schedulingPolicyId = existingApptModel.schedulingPolicyId;
        toUpdateModel.workOrderId = existingApptModel.workOrderId;
        toUpdateModel.assetId = existingApptModel.assetId;
        toUpdateModel.accountId = existingApptModel.accountId;
        toUpdateModel.alternateContactId = existingApptModel.alternateContactId;
        //--before setting siteId, make sure the siteId in params is same on existing appointment. Since you can't change site, throw error if different
        // siteId cannot be changed
        if (!String.isBlank(updateParamsModel.siteId) && updateParamsModel.siteId != existingApptModel.siteId) {
            toUpdateModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'The siteId parameter is not equal to the siteId of the existing appointment');
            return toUpdateModel;
        } else {
            toUpdateModel.siteId = existingApptModel.siteId;
            updateParamsModel.siteId = existingApptModel.siteId;
        }
        System.debug('existingApptModel.orderType ::' +existingApptModel.orderType);
        System.debug('updateParamsModel.orderType ::' +updateParamsModel.orderType);
        //if Order Type and Source weren't populated in params, then use existing
        if (String.isBlank(updateParamsModel.source)) updateParamsModel.source = existingApptModel.source;
        //POS doesnot have Order Type of SA, so resetting to SA.
        if(('ServiceAppointment'.equalsIgnoreCase(existingApptModel.orderType)) && ('POS'.equalsIgnoreCase(updateParamsModel.source))
                && ('ROPIS'.equalsIgnoreCase(updateParamsModel.orderType))) {
            updateParamsModel.orderType = existingApptModel.orderType;
        } else {
            if (String.isBlank(updateParamsModel.orderType)) updateParamsModel.orderType = existingApptModel.orderType;
        }
        if (String.isBlank(updateParamsModel.customerType)) updateParamsModel.customerType = existingApptModel.customerType;

        // Validate siteId and fields that cannot change in existing appointment
        if (validateParamsAgainstExistingAppt(updateParamsModel, existingApptModel) == false)  return updateParamsModel;

        // if this is re-schedule, meaning date and/or times changed, then validate the new data and time params
        if (didDateOrTimeChange(existingApptModel, updateParamsModel)) {
            if (validateRescheduledAppointmentParams(updateParamsModel) == false) return updateParamsModel;
        }

        try {
            // Update account
            // LIMIT NOTE - 1 DML Update
            updateCustomer(updateParamsModel, existingApptModel.accountId, toUpdateModel);

            // Update alternate contact with recipient field
            // LIMIT NOTE - 1 SOQL and 1 DML Update
            updateAlternateContact(updateParamsModel, toUpdateModel);

            // Update Vehicle
            // LIMIT NOTE - 1 SOQL and 1 DML Update
            //if (isVehicleUpdated(updateParamsModel)) updateVehicle(updateParamsModel, toUpdateModel);
            //System.debug(lprefix+'     toUpdateModel:'+toUpdateModel);

            // pass vehicle information to the 
            toUpdateModel.year = updateParamsModel.year;
            toUpdateModel.make = updateParamsModel.make;
            toUpdateModel.model = updateParamsModel.model;
            toUpdateModel.posCustomerVehicleId = updateParamsModel.posCustomerVehicleId;
            toUpdateModel.hybrisCustomerVehicleId = updateParamsModel.hybrisCustomerVehicleId;
            toUpdateModel.assemblyId = updateParamsModel.assemblyId;
            toUpdateModel.vehicleId = updateParamsModel.vehicleId;
            toUpdateModel.trimId = updateParamsModel.trimId;
            toUpdateModel.vehicleClass = updateParamsModel.vehicleClass;

            toUpdateModel = Appt_AppointmentDataProcessUtil.processVehicleData(toUpdateModel);

            //update Work Order
            // LIMIT NOTE - 1 DML Update
            updateWorkOrder(updateParamsModel, existingApptModel.appointmentStatus, toUpdateModel);
            
            //update ServiceAppointments only if SA param fields are populated and different then existing SA
            // LIMIT NOTE - 1 DML Update
            if (checkIfUpdateServiceAppointment(updateParamsModel, existingApptModel)) {            
                updateServiceAppointments(updateParamsModel, toUpdateModel, existingApptModel);
            }

        } catch (Exception e) {
            System.debug('Exception caught, rolling back DB updates. e:'+e);
            Database.rollback(sp);
            throw e;
        }

        //-- update toUpdateModel for the response
        updateResponse(toUpdateModel, updateParamsModel, existingApptModel);

        System.debug(lprefix+'updateAppointment() EXIT - returnModel:'+toUpdateModel);
        return toUpdateModel;
    }


    private static void updateResponse(Appt_UpdateAppointmentServiceModel toUpdateModel, Appt_UpdateAppointmentServiceModel updateParamsModel, Appt_UpdateAppointmentServiceModel existingApptModel) {
        //set model status to SUCCESS and populte fields in the response
        toUpdateModel.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;
        toUpdateModel.appointmentStatus = !String.isBlank(updateParamsModel.appointmentStatus) ? updateParamsModel.appointmentStatus : existingApptModel.appointmentStatus;
        toUpdateModel.siteId = !String.isBlank(updateParamsModel.siteId) ? updateParamsModel.siteId : existingApptModel.siteId;
        toUpdateModel.appointmentDate = updateParamsModel.appointmentDate != null ? updateParamsModel.appointmentDate : existingApptModel.appointmentDate;
        toUpdateModel.hybrisOrderId = !String.isBlank(updateParamsModel.hybrisOrderId) ? updateParamsModel.hybrisOrderId : existingApptModel.hybrisOrderId;

        if (String.isBlank(toUpdateModel.consultStartTime)) toUpdateModel.consultStartTime = existingApptModel.consultStartTime;
        if (String.isBlank(toUpdateModel.consultEndTime)) toUpdateModel.consultEndTime = existingApptModel.consultEndTime;
        if (String.isBlank(toUpdateModel.consultDuration)) toUpdateModel.consultDuration = existingApptModel.consultDuration;
        if (String.isBlank(toUpdateModel.backOfficeStartTime)) toUpdateModel.backOfficeStartTime = existingApptModel.backOfficeStartTime;
        if (String.isBlank(toUpdateModel.backOfficeEndTime)) toUpdateModel.backOfficeEndTime = existingApptModel.backOfficeEndTime;
        if (String.isBlank(toUpdateModel.backOfficeDuration)) toUpdateModel.backOfficeDuration = existingApptModel.backOfficeDuration;
    }


    // validate important parameters on model and if errors found, set error code and message on model and return FALSE
    public static Boolean validateModelParams(Appt_UpdateAppointmentServiceModel apptModel) {

        if (String.isBlank(apptModel.appointmentId)) {
            apptModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'Required appointmentId parameter is blank or null, appointmentId='+apptModel.appointmentId);
            return false;
        }

        //if here, then parameters passed validation
        return true;
    }

    //validate params fields that can't change in existing
    public static Boolean validateParamsAgainstExistingAppt(Appt_UpdateAppointmentServiceModel updateParamsModel, Appt_UpdateAppointmentServiceModel existingApptModel) {

        //Cannot downgrade from status Scheduled, Confirmed, etc... to Pending
        if (!String.isBlank(updateParamsModel.appointmentStatus) && 
            updateParamsModel.appointmentStatus == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING && 
            existingApptModel.appointmentStatus != Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING) {
                updateParamsModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'A previously scheduled appointment cannot be downgraded to status Pending');
                return false;
        }

        // cannot update a cancelled appointment to be Scheduled
        if (!String.isBlank(updateParamsModel.appointmentStatus) && 
            (updateParamsModel.appointmentStatus == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED || updateParamsModel.appointmentStatus == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED) && 
            (existingApptModel.appointmentStatus == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED || existingApptModel.appointmentStatus == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD)) {
                updateParamsModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'A previously cancelled appointment cannot be reset to Scheduled or Confirmed');
                return false;
        }

        //if here, then parameters passed validation
        return true;
    }


    // This validation method is only called if this is a rescheduled appointment. If so validate the date and time params for reschedules appt
    public static Boolean validateRescheduledAppointmentParams(Appt_UpdateAppointmentServiceModel updateParamsModel) {

        if (String.isBlank(updateParamsModel.source) || String.isBlank(updateParamsModel.orderType)) {
            updateParamsModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'Source or OrderType parameter is blank or null. They are required for Re-scheduling of an appointment.');
            return false;
        }

        if (updateParamsModel.appointmentDate == null || updateParamsModel.appointmentDate < Date.today()) {
            updateParamsModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'appointmentDate must be greater than or equal to today');
            return false;
        }

        if ( (String.isBlank(updateParamsModel.consultStartTime) || String.isBlank(updateParamsModel.consultEndTime)) && (String.isBlank(updateParamsModel.backOfficeStartTime) || String.isBlank(updateParamsModel.backOfficeEndTime)) ) {
            updateParamsModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'It is required that either consultStartTime and consultEndTime or backOfficeStartTime and backOfficeEndTime are properly populated');
            return false;
        }
        
        if (!String.isBlank(updateParamsModel.consultStartTime) && !String.isBlank(updateParamsModel.consultEndTime) && updateParamsModel.consultEndTime <= updateParamsModel.consultStartTime) {
            updateParamsModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'consultEndTime must be greater than consultStartTime');
            return false;
        }

        if (!String.isBlank(updateParamsModel.backOfficeStartTime) && !String.isBlank(updateParamsModel.backOfficeEndTime) && updateParamsModel.backOfficeEndTime <= updateParamsModel.backOfficeStartTime) {
            updateParamsModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'backOfficeEndTime must be greater than backOfficeStartTime');
            return false;
        }

        //if here, then parameters passed validation
        return true;
    }


    private static void updateCustomer(Appt_UpdateAppointmentServiceModel updateParamsModel, String existingApptAccountId, Appt_UpdateAppointmentServiceModel toUpdateModel) {
        System.debug(lprefix+'updateCustomer() ENTRY - existingApptAccountId='+ existingApptAccountId +', hybrisCustomerId='+updateParamsModel.hybrisCustomerId+', posCustomerId='+updateParamsModel.posCustomerId+', GUID='+updateParamsModel.customerGuid);

        toUpdateModel.source = updateParamsModel.source;
        toUpdateModel.posCustomerId = updateParamsModel.posCustomerId;
        toUpdateModel.hybrisCustomerId = updateParamsModel.hybrisCustomerId;
        toUpdateModel.customerGuid = updateParamsModel.customerGuid;
        toUpdateModel.firstName = updateParamsModel.firstName;
        toUpdateModel.lastName = updateParamsModel.lastName;
        toUpdateModel.emailAddress = updateParamsModel.emailAddress;
        toUpdateModel.homePhoneNumber = updateParamsModel.homePhoneNumber;
        toUpdateModel.mobilePhoneNumber = updateParamsModel.mobilePhoneNumber;
        toUpdateModel.workPhoneNumber = updateParamsModel.workPhoneNumber;
        toUpdateModel.address1 = updateParamsModel.address1;
        toUpdateModel.city = updateParamsModel.city;
        toUpdateModel.state = updateParamsModel.state;
        toUpdateModel.zipCode = updateParamsModel.zipCode;
        toUpdateModel.country = updateParamsModel.country;
        toUpdateModel.customerType = updateParamsModel.customerType;
        toUpdateModel.emailAddressOptIn = updateParamsModel.emailAddressOptIn;
        toUpdateModel.textOptIn = updateParamsModel.textOptIn;

        toUpdateModel = Appt_AppointmentDataProcessUtil.processAccountData(toUpdateModel);
    }

    

    public static void updateAlternateContact(Appt_UpdateAppointmentServiceModel updateParamsModel, Appt_UpdateAppointmentServiceModel toUpdateModel){
        System.debug(lprefix+'updateAlternateContact() Entry - updateParamsModel.recipientLastName='+updateParamsModel.recipientLastName + ', updateParamsModel.recipientEmail='+ updateParamsModel.recipientEmail);
        Id altCustomerRecordTypeId =  Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('B2C_Alternate').getRecordTypeId();
        Contact contct;
        List<Contact> contacts;

        // Search for Contact by email.  email required to search for contact
        if (!String.isBlank(updateParamsModel.recipientEmail) ) {

            contacts = [SELECT FirstName, lastName, Email, Phone, MobilePhone FROM Contact 
                                    WHERE Email = :updateParamsModel.recipientEmail];
        }

        //-- If 1 contact queried, use it. If more than 1 contact found don't use and instead insert new contact in later code below
        if (contacts != null && contacts.size() == 1) {
            contct = contacts.get(0);
            System.debug(lprefix+'     found Alternate Contact:'+contct);
        }

        if (contct != null) {
            // Update any non-null recipient fields except for Email
            if (updateParamsModel.recipientFirstName != null) contct.FirstName = updateParamsModel.recipientFirstName;
            if (updateParamsModel.recipientLastName != null) contct.LastName = updateParamsModel.recipientLastName;
            if (updateParamsModel.recipientPhone != null) contct.Phone = updateParamsModel.recipientPhone;

            System.debug(lprefix+'     about to update existing Alternate Contact:'+contct);
            update contct;
            System.debug(lprefix+'     successfully updated Alternate Contact Id='+contct.Id);

        } else {

                contct = new Contact(RecordTypeId = altCustomerRecordTypeId);
                contct.FirstName = updateParamsModel.recipientFirstName;
                //-- last name cannot be null
                contct.LastName = !String.isBlank(updateParamsModel.recipientLastName) ? updateParamsModel.recipientLastName : 'Not Provided';
                contct.Email = updateParamsModel.recipientEmail;
                contct.Phone = updateParamsModel.recipientPhone;

                System.debug(lprefix+'     about to save newly created Alternate Contact:'+contct);
                insert contct;
                System.debug(lprefix+'     successfully saved Alternate Contact Id:'+contct.Id);
        }

        if (contct != null) toUpdateModel.alternateContactId = contct.Id;

        System.debug(lprefix+'updateAlternateContact() EXIT');
    }


    public static void updateWorkOrder(Appt_UpdateAppointmentServiceModel updateParamsModel, String existingApptStatus, Appt_UpdateAppointmentServiceModel toUpdateModel) {
        System.debug(lprefix+'updateWorkOrder() ENTRY - appointmentId='+toUpdateModel.appointmentId);

        //-- There is a timing issue with PersonAccounts where immediately after inserting a new PersonAcount, the PersonContactId might not yet be populated on the Account record.
        //-- If toUpdateModel.contactId=null, we have to query the account here to get the PersonContactId - DTA-355
        if (String.isBlank(toUpdateModel.contactId)) {
            toUpdateModel.contactId = Appt_AppointmentDataProcessUtil.getPersonContactId(toUpdateModel.accountId);
            System.debug(lprefix+'PersonContactId=null, but after re-query PersonContactId=:'+toUpdateModel.contactId);
        }


        WorkOrder updateWO = new WorkOrder(Id = toUpdateModel.appointmentId);
        updateWO.AccountId = toUpdateModel.accountId;
        updateWO.ContactId = toUpdateModel.contactId;
        updateWO.Vehicle__c = toUpdateModel.assetId;

        // check if status has changed, and if so set on Work Order
        System.debug(lprefix+'     updateParamsModel.status='+updateParamsModel.appointmentStatus+', existingApptStatus='+existingApptStatus);
        if (!String.isBlank(updateParamsModel.appointmentStatus) && updateParamsModel.appointmentStatus != existingApptStatus) {
            System.debug(lprefix+'     STATUS CHANGE, from:'+existingApptStatus+'  TO:'+updateParamsModel.appointmentStatus);

            //handled CANCELED
            if (updateParamsModel.appointmentStatus == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED) {
                updateWO.Cancel_Reason__c = updateParamsModel.cancelReasonText;
                updateWO.Cancel_Reason_Code__c = updateParamsModel.cancelReason;
            }
        }

        if (updateParamsModel.frontroomWorkTypeId != null) updateWO.WorkTypeId = updateParamsModel.frontroomWorkTypeId;
        if (updateParamsModel.backroomWorkTypeId != null) updateWO.WorkTypeId = updateParamsModel.backroomWorkTypeId;
        if (updateParamsModel.source != null) updateWO.Source__c = updateParamsModel.source;
        if (updateParamsModel.comments != null) updateWO.Appointment_Comments__c = updateParamsModel.comments;
        if (updateParamsModel.orderType != null) updateWO.Order_Type__c = updateParamsModel.orderType;
        if (updateParamsModel.formType != null) updateWO.Form_Type__c = updateParamsModel.formType;
        if (updateParamsModel.formNumber != null) updateWO.Form_Number__c = updateParamsModel.formNumber;
        if (updateParamsModel.formDate != null) updateWO.Form_Date__c = Date.valueOf(updateParamsModel.formDate);
        if (updateParamsModel.hybrisOrderId != null) updateWO.Hybris_Order_Id__c = updateParamsModel.hybrisOrderId;
        if (updateParamsModel.posWebOrderId != null) updateWO.POS_Web_Order_Id__c = updateParamsModel.posWebOrderId;
        if (updateParamsModel.layawayNumber != null) updateWO.Layaway_Number__c = updateParamsModel.layawayNumber;
        if (updateParamsModel.quoteNumber != null) updateWO.Quote_Number__c = updateParamsModel.quoteNumber;
        if (updateParamsModel.invoiceNumber != null) updateWO.Invoice_Number__c = updateParamsModel.invoiceNumber;
        if (updateParamsModel.orderDate != null) updateWO.Order_Date__c = Date.valueOf(updateParamsModel.orderDate);
        if (updateParamsModel.alternateContactId != null) updateWO.Alternate_Contact__c = updateParamsModel.alternateContactId;
        //-- use smsPhoneNumber if populated, otherwise use mobile phone in WO SMS field (if  populated)
        if (!String.isBlank(updateParamsModel.smsPhoneNumber)) updateWO.SMS_Phone__c = updateParamsModel.smsPhoneNumber;
        else if (!String.isBlank(updateParamsModel.mobilePhoneNumber)) updateWO.SMS_Phone__c = updateParamsModel.mobilePhoneNumber;

        System.debug(lprefix+'     about to update existing WorkOrder:'+updateWO);
        update updateWO;
        System.debug(lprefix+'     successfully update existing WorkOrder:'+updateWO);
    }

    public static Boolean checkIfUpdateServiceAppointment(Appt_UpdateAppointmentServiceModel updateParamsModel, Appt_UpdateAppointmentServiceModel existingApptModel) {
        System.debug(lprefix+'checkIfUpdateServiceAppointment() ENTRY. existingModel: ' +existingApptModel);
        if (updateParamsModel.appointmentDate != null && updateParamsModel.appointmentDate != existingApptModel.appointmentDate) return true;
        if (updateParamsModel.appointmentStatus != null && updateParamsModel.appointmentStatus != existingApptModel.appointmentStatus) return true;
        if (updateParamsModel.source != null && updateParamsModel.source != existingApptModel.source) return true;
        if (updateParamsModel.orderType != null && updateParamsModel.orderType != existingApptModel.orderType) return true;
        if (updateParamsModel.consultStartTime != null && updateParamsModel.consultStartTime != existingApptModel.consultStartTime) return true;
        if (updateParamsModel.consultEndTime != null && updateParamsModel.consultEndTime != existingApptModel.consultEndTime) return true;
        if (updateParamsModel.backOfficeStartTime != null && updateParamsModel.backOfficeStartTime != existingApptModel.backOfficeStartTime) return true;
        if (updateParamsModel.backOfficeEndTime != null && updateParamsModel.backOfficeEndTime != existingApptModel.backOfficeEndTime) return true;

        System.debug(lprefix+'checkIfUpdateServiceAppointment() EXIT - returning FALSE');
        return false;
    }


    //update ServiceAppointment records
    public static void updateServiceAppointments(Appt_UpdateAppointmentServiceModel updateParamsModel, Appt_UpdateAppointmentServiceModel toUpdateModel, Appt_UpdateAppointmentServiceModel existingApptModel) {
        System.debug(lprefix+'updateServiceAppointments() ENTRY - NEW appointmentStatus='+updateParamsModel.appointmentStatus);
        System.debug(lprefix+'updateServiceAppointments() toUpdateModel.consultAppointmentId='+toUpdateModel.consultAppointmentId+', toUpdateModel.backOfficeAppointmentId='+toUpdateModel.backOfficeAppointmentId);

        //--  1. caluclate work types and durations needed for the rescheduled appointment
        Appt_workTypeModel wrkTypModel = Appt_AvailabilityHandler.calculateWorkType(updateParamsModel.spawnGetAvailabilityServiceModel(false));
        if (wrkTypModel != null && wrkTypModel.isError()) {
            // throw exception we can't reschedule if we can't calculate the work type and duration
            throw new Appt_AppointmentException(wrkTypModel.message, Integer.valueOf(wrkTypModel.statusCode));
        }
        
        //-- 2.  get ServiceAppointment objects, which could be new if update source or ordertype change the work type
        ServiceAppointment fsa;
        ServiceAppointment bsa;
        Boolean frontIsNew = false;
        Boolean backIsNew = false;
        Boolean setBackToNotification = false;

        if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH || wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT) {
            if (!String.isBlank(toUpdateModel.consultAppointmentId)) {
                fsa = new ServiceAppointment(Id = toUpdateModel.consultAppointmentId);
                 // Set lower priority to check for double booking a slot
                fsa.FSL__Schedule_over_lower_priority_appointment__c = true;
                fsa.Priority__c = 1;
            } else {
                fsa = new ServiceAppointment(ParentRecordId = toUpdateModel.workOrderId);
                fsa.Work_Order__c = toUpdateModel.workOrderId;
                 // Set lower priority to check for double booking a slot
                fsa.FSL__Schedule_over_lower_priority_appointment__c = true;
                fsa.Priority__c = 1;
                frontIsNew = true;
            }

        } else if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK && !String.isBlank(toUpdateModel.consultAppointmentId)) {
            
            //This is situation where there was a Front Room appointment but was rescheduled to Back room only, so set existing front room appointment to Canceled and update immediately
            fsa = new ServiceAppointment(Id = toUpdateModel.consultAppointmentId);
            fsa.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED;  //--DTA-406 set to SERVICE_APPOINTMENT_STATUS_CANCELED
            System.debug(lprefix+'     about to DELETE RESCHEDULED TO BACK ONLY FRONT serviceappointment:'+fsa);
            delete fsa;

            // set the back office appointment to the notificaction appointment since the fron't office one is deleted
            setBackToNotification = true;            
            System.debug(lprefix+'     SUCCESSFULLY DELETE RESCHEDULED TO BACK ONLY FRONT serviceappointmentId='+fsa.Id); 

            // Set the existingAppt model's consultStart and consultEnd times back to blank
            existingApptModel.consultStartTime = '';
            existingApptModel.consultEndTime = '';
        }

        if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH || wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK) {
            if (!String.isBlank(toUpdateModel.backOfficeAppointmentId)) {
                bsa = new ServiceAppointment(Id = toUpdateModel.backOfficeAppointmentId);
                 // Set lower priority to check for double booking a slot
                bsa.FSL__Schedule_over_lower_priority_appointment__c = true;
                bsa.Priority__c = 1;
            } else {
                bsa = new ServiceAppointment(ParentRecordId = toUpdateModel.workOrderId);
                bsa.Work_Order__c = toUpdateModel.workOrderId;
                 // Set lower priority to check for double booking a slot
                bsa.FSL__Schedule_over_lower_priority_appointment__c = true;
                bsa.Priority__c = 1;
                backIsNew = true;
            }
        }

        //-- 3. check if this is a RESCHEDULED appointment
        Boolean isRescheduled = didDateOrTimeChange(existingApptModel, updateParamsModel);

        //-- 4. handle Rescheduling of appointment date and/or time
        if (isRescheduled || frontIsNew) {

            //-- Get timezone offset for store on appointment date. If appointment
            //LIMIT NOTE: 1 SOQL query
            Integer offset;
            if (updateParamsModel.appointmentDate != null) {
                offset = Appt_AppointmentUtil.getTimeZoneOffset(updateParamsModel.siteId, updateParamsModel.appointmentDate);
            } else {
                offset = Appt_AppointmentUtil.getTimeZoneOffset(updateParamsModel.siteId);
            }
            updateParamsModel.timeZoneOffset = offset;

            System.debug(lprefix +'updateParamsModel: ' +updateParamsModel);
            System.debug(lprefix +'offset: ' +offset);
            System.debug(lprefix +'updateParamsModel.timeZoneOffset: ' +updateParamsModel.timeZoneOffset);
            System.debug(lprefix +'updateParamsModel.checkAvailabilityFirst: ' +updateParamsModel.checkAvailabilityFirst);
            if (updateParamsModel.timeZoneOffset == null || updateParamsModel.timeZoneOffset == 0) {
                // throw exception, causing rollback,  because we couldn't get timezoneoffset, probably because service territory couldn't be found for the siteId
                throw new Appt_AppointmentException('Unable to retrieve the ServiceTerritory as well as timezone offset with siteId='+updateParamsModel.siteId, Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_NOT_FOUND));
            }

            //  if inbound param checkAvailabilityFirst= true, check if rescheduled appointment slot is still available, if it is not throw exception
            if (updateParamsModel.checkAvailabilityFirst != null && updateParamsModel.checkAvailabilityFirst) {
                if (!Appt_AvailabilityHandler.checkAvailability(updateParamsModel.spawnGetAvailabilityServiceModel(true), wrkTypModel)) {
                    throw new Appt_AppointmentException('The rescheduled appointment slot is notavailable', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_NOT_AVAILABLE));
                }
            }

            //---- FRONT ROOM SERVICE APPOINTMENT update date and time fields-----------------
            if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH || wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT) {

                // construct DateTime for ConsultStartTime and ConsultEndTime in GMT
                Datetime startDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(updateParamsModel.appointmentDate), updateParamsModel.consultStartTime, updateParamsModel.timeZoneOffset);
                Datetime endDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(updateParamsModel.appointmentDate), updateParamsModel.consultEndTime, updateParamsModel.timeZoneOffset);

                // update date and time fields on FRONT APPOINTMENT
                fsa.Activity_Type__c = Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_FRONT;
                fsa.EarliestStartTime = startDateTime;
                fsa.SchedStartTime = startDateTime;
                fsa.DueDate = endDateTime;
                fsa.SchedEndTime = endDateTime;
                fsa.Duration = Appt_AppointmentUtil.minutesBetweenDatetimes(startDateTime, endDateTime);
                fsa.Start_Time_String__c = updateParamsModel.consultStartTime;
                fsa.End_Time_String__c = updateParamsModel.consultEndTime;  
            }

            //---- BACK ROOM SERVICE APPOINTMENT update date and time fields-----------------
            if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH || wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK) {

                // construct DateTime for ConsultStartTime and ConsultEndTime in GMT
                Datetime startDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(updateParamsModel.appointmentDate), updateParamsModel.backOfficeStartTime, updateParamsModel.timeZoneOffset);
                Datetime endDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(updateParamsModel.appointmentDate), updateParamsModel.backOfficeEndTime, updateParamsModel.timeZoneOffset);

                // update date and time fields on BACK APPOINTMENT
                bsa.Activity_Type__c = Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_BACK;
                bsa.EarliestStartTime = startDateTime;
                bsa.SchedStartTime = startDateTime;
                bsa.DueDate = endDateTime;
                bsa.SchedEndTime = endDateTime;
                bsa.Duration = Appt_AppointmentUtil.minutesBetweenDatetimes(startDateTime, endDateTime);
                bsa.Start_Time_String__c = updateParamsModel.backOfficeStartTime;
                bsa.End_Time_String__c = updateParamsModel.backOfficeEndTime;
            }
        }

        //--List for bulk save of ServiceAppointments
        List<ServiceAppointment> saList = new List<ServiceAppointment>();

        //-- 4. setup Update or Insert the FRONT ServiceAppointment, putting FRONT ServiceAppointment on list for bulk save later, if there is one
        if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH || wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT) {
            
            //-- only update FRONT ROOM ServiceAppointment if it is NOT already canceled or canceled hold
            if (String.isBlank(existingApptModel.frontApptStatus) || (!String.isBlank(existingApptModel.frontApptStatus) 
                && existingApptModel.frontApptStatus != Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED && existingApptModel.frontApptStatus != Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD)) {

                if (!String.isBlank(updateParamsModel.appointmentStatus)) fsa.Status = updateParamsModel.appointmentStatus;
                populateServiceAppointmentFields(fsa, updateParamsModel);
                    
                    
				Boolean shouldAddFrontSA = true;
                if (frontIsNew) {

                    // set the front office appointment as the notification appointment the back office isn't already set as the notification appointment
                    if(fsa.Notification_Appointment__c  == false && bsa.Notification_Appointment__c == false ){
                        fsa.Notification_Appointment__c = true;
                    }
                    
                    //AEC-111
                    if( String.isBlank(toUpdateModel.consultStartTime) && 
                        String.isBlank(toUpdateModel.consultEndTime))
                        {
                            //If Front SA is not there on the existing Work Order + consultStart & consultEnd is blank/null in the UPDATE APPOINTMENT API call,
                            //Do not try to create Front SA as it will result in an exception.
                            shouldAddFrontSA = false;
                        }
                    //AEC-111
                }

                //-- put ServiceAppointment on list for bulk insert later
                if(shouldAddFrontSA)
                {
                    saList.add(fsa);
                }

            } else {

                //Since not updating the canceled front appt, Update response model from existing model
                toUpdateModel.consultStartTime = existingApptModel.consultStartTime;
                toUpdateModel.consultEndTime = existingApptModel.consultEndTime;  
                toUpdateModel.consultDuration = existingApptModel.consultDuration;
                toUpdateModel.consultAppointmentId = existingApptModel.consultAppointmentId;
            }
        }

        //Update or Insert the BACK ServiceAppointment
        if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH || wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK) {
            
            if (!String.isBlank(updateParamsModel.appointmentStatus)) bsa.Status = updateParamsModel.appointmentStatus;
            populateServiceAppointmentFields(bsa, updateParamsModel);

            if (backIsNew) {

                // set the back office appointment as the notification appointment the front office isn't already set as the notification appointment
                if(fsa.Notification_Appointment__c  == false && bsa.Notification_Appointment__c == false ){
                    bsa.Notification_Appointment__c = true;
                }

            } else {

                // set the back office appointment as the notification appointment the front office isn't already set as the notification appointment
                if (setBackToNotification) {
                    bsa.Notification_Appointment__c = true;
                }
            }

            //-- put ServiceAppointment on list for bulk insert later
            saList.add(bsa);

        }


        //-- Upset of List of ServiceAppointments. Using Upsert because SAs could be new (requiring insert) or existing (requiring update)
        try {
            System.debug(lprefix+'     about to UPSERT List of ServiceAppointments with '+ saList.size() +' items:'+saList);
            upsert saList;
            System.debug(lprefix+'     SUCCESSFULLY UPSERTed List of serviceappointmentId='+saList);
        } catch(Exception e) {
            System.debug(lprefix+'     EXCEPTION, SECOND about to UPSERT List of serviceappointment. Exception:'+e);
            upsert saList;
            System.debug(lprefix+'     SUCCESSFULLY UPSERT SECOND ATTEMPT List of serviceappointmentId='+saList);
        }

        //Update response model
        toUpdateModel.consultStartTime = updateParamsModel.consultStartTime;
        toUpdateModel.consultEndTime = updateParamsModel.consultEndTime;  
        if (fsa != null) toUpdateModel.consultDuration = String.valueOf(fsa.Duration);
        if (fsa != null) toUpdateModel.consultAppointmentId = fsa.Id;
        toUpdateModel.backOfficeStartTime = updateParamsModel.backOfficeStartTime;
        toUpdateModel.backOfficeEndTime = updateParamsModel.backOfficeEndTime;
        if (bsa != null) toUpdateModel.backOfficeDuration = String.valueOf(bsa.Duration);
        if (bsa != null) toUpdateModel.backOfficeAppointmentId = bsa.Id;

        System.debug(lprefix+'updateServiceAppointments() EXIT - consultAppointmentId='+toUpdateModel.consultAppointmentId + ', backOfficeAppointmentId=' + toUpdateModel.backOfficeAppointmentId);
    }


    //populate common serviceappointment fields
    private static void populateServiceAppointmentFields(ServiceAppointment sa, Appt_UpdateAppointmentServiceModel updateParamsModel) {

        if (updateParamsModel.siteId != null) sa.Site_Id__c = updateParamsModel.siteId;
        if (updateParamsModel.customerType != null) sa.Customer_Type__c = updateParamsModel.customerType;
        if (updateParamsModel.source != null) sa.Source__c = updateParamsModel.source;
        if (updateParamsModel.orderType != null) sa.Order_Type__c = updateParamsModel.orderType;
        if (updateParamsModel.appointmentDate != null) sa.Date_String__c = String.valueOf(updateParamsModel.appointmentDate);
        if (updateParamsModel.timeZoneOffset != null) sa.Timezone_Offset__c = updateParamsModel.timeZoneOffset;
        sa.FSL__Schedule_over_lower_priority_appointment__c = true;

        //if populated, set start/end times of originally selected appt slot on appointment record (originally selected appt slot from POS Custom Times Modal - DTA-503)
        System.debug(lprefix+'populateServiceAppointmentFields()  - updateParamsModel.selectedSlotStartTime='+updateParamsModel.selectedSlotStartTime + ', updateParamsModel.selectedSlotStartTime=' + updateParamsModel.selectedSlotEndTime);  //DEBUG

        if (!String.isBlank(updateParamsModel.selectedSlotStartTime) && updateParamsModel.selectedSlotStartTime.trim().length() == 4) sa.Selected_Slot_Start_Time_String__c = updateParamsModel.selectedSlotStartTime.trim();
        else sa.Selected_Slot_Start_Time_String__c = null;
        
        if (!String.isBlank(updateParamsModel.selectedSlotEndTime) && updateParamsModel.selectedSlotEndTime.trim().length() == 4) sa.Selected_Slot_End_Time_String__c = updateParamsModel.selectedSlotEndTime.trim();
        else sa.Selected_Slot_End_Time_String__c = null;

        System.debug(lprefix+'populateServiceAppointmentFields()  - sa.Selected_Slot_Start_Time_String__c='+sa.Selected_Slot_Start_Time_String__c + ', sa.Selected_Slot_End_Time_String__c=' + sa.Selected_Slot_End_Time_String__c);  //DEBUG
    }


    private static Boolean didDateOrTimeChange(Appt_UpdateAppointmentServiceModel existingModel, Appt_UpdateAppointmentServiceModel updateParamsModel) {
        Boolean returnBool = false;
        System.debug(lprefix+'didDateOrTimeChange() ENTRY- updateParamsModel.appointmentDate='+updateParamsModel.appointmentDate+', consultStartTime='+updateParamsModel.consultStartTime+', backOfficeStartTime='+updateParamsModel.backOfficeStartTime);
        System.debug(lprefix+'didDateOrTimeChange() - existingModel.appointmentDate='+existingModel.appointmentDate+', consultStartTime='+existingModel.consultStartTime+', backOfficeStartTime='+existingModel.backOfficeStartTime);

        if (updateParamsModel.appointmentDate != null && !updateParamsModel.appointmentDate.isSameDay(existingModel.appointmentDate)) {
            returnBool = true;
        }
        else if (!String.isBlank(updateParamsModel.consultStartTime) && !String.isBlank(existingModel.consultStartTime) && updateParamsModel.consultStartTime != existingModel.consultStartTime) {
            returnBool = true;
        } 
        else if (!String.isBlank(updateParamsModel.consultEndTime) && !String.isBlank(existingModel.consultEndTime) && updateParamsModel.consultEndTime != existingModel.consultEndTime) {
            returnBool = true;
        }
        else if (!String.isBlank(updateParamsModel.backOfficeStartTime) && updateParamsModel.backOfficeStartTime != existingModel.backOfficeStartTime) {
            returnBool = true;
        }
        else if (!String.isBlank(updateParamsModel.backOfficeEndTime) && updateParamsModel.backOfficeEndTime != existingModel.backOfficeEndTime) {
            returnBool = true;
        }

        System.debug(lprefix+'didDateOrTimeChange() EXIT - returnBool='+returnBool);
        return returnBool;
    }


    private static Appt_UpdateAppointmentServiceModel getAppointmentRecords(Appt_UpdateAppointmentServiceModel apptModel){
        System.debug(lprefix+'getAppointmentRecords() ENTRY - apptModel:'+apptModel);

        Appt_UpdateAppointmentServiceModel returnModel = new Appt_UpdateAppointmentServiceModel();

        List<ServiceAppointment> appts = [SELECT id, Status, Activity_Type__c, SchedStartTime, SchedEndTime, Start_Time_String__c, End_Time_String__c, Date_String__c, 
            Work_Order__r.Status, Duration, Work_Order__c, WorkType.DurationInMinutes, Work_Order__r.AccountId, Work_Order__r.ContactId, Work_Order__r.Account.PersonContactId, Work_Order__r.Source__c,  
            Work_Order__r.Appointment_Comments__c, Work_Order__r.Order_Type__c, Work_Order__r.Form_Type__c, Work_Order__r.Form_Number__c, Work_Order__r.Form_Date__c, 
            Work_Order__r.Hybris_Order_Id__c, Work_Order__r.POS_Web_Order_Id__c, Work_Order__r.Layaway_Number__c, Work_Order__r.Quote_Number__c, Work_Order__r.Invoice_Number__c, 
            Work_Order__r.Order_Date__c, Work_Order__r.Vehicle__c, Work_Order__r.Vehicle__r.POS_Customer_Vehicle_Id__c, Work_Order__r.Vehicle__r.Hybris_Customer_Vehicle_Id__c, 
            Work_Order__r.Vehicle__r.Vehicle_Manufacture_Year__c,  Work_Order__r.Vehicle__r.Vehicle_Make__c, Work_Order__r.Vehicle__r.Vehicle_Model__c, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, 
            Work_Order__r.Vehicle__r.Assembly_Id__c, Work_Order__r.Vehicle__r.Vehicle_Id__c, Work_Order__r.Vehicle__r.Trim_Id__c, Work_Order__r.Account.POS_Customer_Id__c, 
            Work_Order__r.Account.Hybris_Customer_Id__c, Work_Order__r.Account.GUID__c, Work_Order__r.Cancel_Reason__c, Account.PersonContactId, FSL__Scheduling_Policy_Used__c, Notification_Appointment__c 
            FROM ServiceAppointment WHERE Work_Order__r.Id = :apptModel.appointmentId ORDER BY Activity_Type__c DESC];
        System.debug(lprefix+'       Retrieved Service Appointment/Work Order records:'+appts);

        if (appts != null && appts.size() > 0) {

            System.debug(lprefix+'       asset id:'+appts.get(0).Work_Order__r.Vehicle__c);

            returnModel.appointmentId = apptModel.appointmentId;
            returnModel.appointmentStatus = appts.get(0).Status;
            returnModel.workOrderId = appts.get(0).Work_Order__c;
            returnModel.accountId = appts.get(0).Work_Order__r.AccountId;
            returnModel.contactId = !String.isBlank(appts.get(0).Work_Order__r.ContactId) ? appts.get(0).Work_Order__r.ContactId : appts.get(0).Work_Order__r.Account.PersonContactId;
            returnModel.appointmentDate = Date.valueOf(appts.get(0).Date_String__c);
            returnModel.source = appts.get(0).Work_Order__r.Source__c;
            returnModel.comments = appts.get(0).Work_Order__r.Appointment_Comments__c;
            returnModel.orderType = appts.get(0).Work_Order__r.Order_Type__c;
            returnModel.formType = appts.get(0).Work_Order__r.Form_Type__c;
            returnModel.formNumber = appts.get(0).Work_Order__r.Form_Number__c;
            returnModel.formDate = String.valueOf(appts.get(0).Work_Order__r.Form_Date__c);
            returnModel.hybrisOrderId = appts.get(0).Work_Order__r.Hybris_Order_Id__c;
            returnModel.posWebOrderId = appts.get(0).Work_Order__r.POS_Web_Order_Id__c;
            returnModel.layawayNumber = appts.get(0).Work_Order__r.Layaway_Number__c;
            returnModel.quoteNumber = appts.get(0).Work_Order__r.Quote_Number__c;
            returnModel.invoiceNumber = appts.get(0).Work_Order__r.Invoice_Number__c;
            returnModel.orderDate = String.valueOf(appts.get(0).Work_Order__r.Order_Date__c);
            returnModel.assetId = appts.get(0).Work_Order__r.Vehicle__c;
            returnModel.schedulingPolicyId = appts.get(0).FSL__Scheduling_Policy_Used__c;
            returnModel.siteId =  appts.get(0).Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;
            returnModel.hybrisCustomerId = appts.get(0).Work_Order__r.Account.Hybris_Customer_Id__c;
            returnModel.posCustomerId = appts.get(0).Work_Order__r.Account.POS_Customer_Id__c;
            returnModel.customerGuid = appts.get(0).Work_Order__r.Account.GUID__c;

            
            for(ServiceAppointment sa: appts) {
                
                if (sa.Activity_Type__c == Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_FRONT) {

                    //Front Room appointment fields
                    returnModel.consultAppointmentId = sa.id;
                    returnModel.consultStartTime = String.valueOf(sa.Start_Time_String__c);
                    returnModel.consultEndTime = String.valueOf(sa.End_Time_String__c);
                    if (sa.Duration != null) returnModel.consultDuration = String.valueOf(sa.Duration.intValue());

                    returnModel.frontApptStatus = sa.Status;
                    

                } else if (sa.Activity_Type__c == Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_BACK) {

                    //Back Room appointment fields
                    returnModel.backOfficeAppointmentId = sa.id;
                    returnModel.backOfficeStartTime = String.valueOf(sa.Start_Time_String__c);
                    returnModel.backOfficeEndTime = String.valueOf(sa.End_Time_String__c);
                    if (sa.Duration != null) returnModel.backOfficeDuration = String.valueOf(sa.Duration.intValue());

                    //-- If a Back Room service appointment exists, then always use it for returnModel.appointmentStatus
                    returnModel.appointmentStatus = sa.Status;
                }
            }
        } else {
            returnModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_NOT_FOUND, 'unable to retrieve WorkOrder and related ServiceAppointment records with appointmentId='+apptModel.appointmentId);
            return returnModel;
        }


        System.debug(lprefix+'getAppointmentRecords() EXIT - returnModel:'+returnModel);
        return returnModel;
    }
}