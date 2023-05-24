public with sharing class Appt_SystemAPIServiceHandler {

    public final static string lprefix = 'LOG APPT_API_HANDLER: ';
    
    public static Boolean validateGetAvailabilityResponse(Appt_SiteAvailabilityResponse response, Int_Message__c intMsg, Integer statusCode) {
        
        // Response is null - invalid return value from Service layer. Set Error message if null is returned
        if (response == null) {
            if (intMsg.Salesforce_Error__c == null) setSFError(intMsg,'getAvailability', '\n Invalid response from getAvailability(). Response Value: ' + response, statusCode);
            return false;
        }

        // error already set on Error Status
        if (intMsg.Status__c == Int_Values.STATUS_ERROR) {
            return false;
        }

        // Valid error response returned
        if (response.status != Appt_ConstantValues.RESPONSE_STATUS_SUCCESS) {
            String responseMessage = (response.message != null) ? response.message : 'Unhandled Error Message';
            setSFError(intMsg, 'getAvailability', responseMessage, statusCode);
            return false;
        }

        // Validation passed, set Int Message to TRUE
        intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;
        return true;
    }

    public static Boolean validateCreateAppointmentResponse(Appt_CreateAppointmentResponse response, Int_Message__c intMsg, Integer statusCode) {
        
        // Response is null - invalid return value from Service layer, check if error needs to be set
        if (response == null) {
            if (intMsg.Salesforce_Error__c == null) setSFError(intMsg,'createIncomingAppointment', '\n Invalid responsen from createAppointment(). Response Value: ' + response, statusCode);
            return false;
        }

        // error already set on Error Status
        if (intMsg.Status__c == Int_Values.STATUS_ERROR) {
            return false;
        }

        // Valid error response returned
        if (response.status != Appt_ConstantValues.RESPONSE_STATUS_SUCCESS) {
            String responseMessage = (response.message != null) ? response.message : 'Unhandled Error Message';
            setSFError(intMsg, 'createIncomingAppointment', responseMessage, statusCode);
            return false;
        }

        // Validation passed, set Int Message to TRUE
        intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;
        return true;
    }

    public static Boolean validateUpdateAppointmentResponse(Appt_UpdateAppointmentResponse response, Int_Message__c intMsg, Integer statusCode) {
        
        // Response is null - invalid return value from Service layer, probably an exception thrown
        if (response == null) {
            if (intMsg.Salesforce_Error__c == null) setSFError(intMsg,'updateIncomingAppointment', '\n Invalid response from updateAppointment(). \n Response Value: ' + response, statusCode);
            return false;
        }

        if (intMsg.Status__c == Int_Values.STATUS_ERROR) {
            return false;
        }
        
        // Valid error response returned
        if (response.status != Appt_ConstantValues.RESPONSE_STATUS_SUCCESS) {
            String responseMessage = (response.message != null) ? response.message : 'Unhandled Error Message';
            setSFError(intMsg, 'updateIncomingAppointment', responseMessage, statusCode);
            return false;
        }

        // Validation passed, set Int Message to TRUE
        intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;
        return true;
    }

    //---Sets respone status code and invalid codes are set to 500
    public static void setStatusCode(Integer statusCode) {
        //System.debug(lprefix + 'enter setStatusCode: ' + statusCode);
        if (statusCode == null) return;

        if (statusCode == 428) {
            RestContext.response.statusCode = 500;
        } else {
            RestContext.response.statusCode = statusCode;
        }
    }
    
    //---Set that there was a Salesforce Error
    public static void setSFError(Int_Message__c intMsg, String codeLocation, String error, Integer statusCode)
    {
        intMsg.Status__c = Int_Values.STATUS_ERROR;
        
        // set SF error without overwriting any previous errors
        if (intMsg.Salesforce_Error__c == null || intMsg.Salesforce_Error__c == '') {
            intMsg.Salesforce_Error__c = codeLocation + ':' + error + ' \n Status Code: ' + String.valueOf(statusCode);
        } else {
            intMsg.Salesforce_Error__c = intMsg.Salesforce_Error__c + '\n' + codeLocation + ':' + error + ' \n Status Code: ' + String.valueOf(statusCode);
        }
        
        System.debug( lprefix + intMsg.Salesforce_Error__c);       
    }

    @future
    public static void upsertIntMsgFuture(String intMsgString) {
        Int_Message__c intMsg = (Int_Message__c) JSON.deserialize(intMsgString, Int_Message__c.class);
        if (intMsg != null) upsert intMsg;
    }

    public static string getAvailabilityResponseString() {
        return '{ "status": "success", "message": "site 1234 availability", "days": [ { "scheduleDate": "2021-01-01", "year": "2021", "month": "01", "day": "01", "dayOfWeek": "Friday", "timeSlots": [ { "consultStartTime": "1000", "consultEndTime": "1020", "consultDuration": "20", "backOfficeStartTime": "1020", "backOfficeEndTime": "1040", "backOfficeDuration": "20" }, { "consultStartTime": "1200", "consultEndTime": "1220", "consultDuration": "20", "backOfficeStartTime": "1220", "backOfficeEndTime": "1240", "backOfficeDuration": "20" }, { "consultStartTime": "1400", "consultEndTime": "1420", "consultDuration": "20", "backOfficeStartTime": "1420", "backOfficeEndTime": "1440", "backOfficeDuration": "20" } ] }, { "scheduleDate": "2021-01-02", "year": "2021", "month": "01", "day": "01", "dayOfWeek": "Friday", "timeSlots": [ { "consultStartTime": "1000", "consultEndTime": "1020", "consultDuration": "20", "backOfficeStartTime": "1020", "backOfficeEndTime": "1040", "backOfficeDuration": "20" }, { "consultStartTime": "1200", "consultEndTime": "1220", "consultDuration": "20", "backOfficeStartTime": "1220", "backOfficeEndTime": "1240", "backOfficeDuration": "20" }, { "consultStartTime": "1400", "consultEndTime": "1420", "consultDuration": "20", "backOfficeStartTime": "1420", "backOfficeEndTime": "1440", "backOfficeDuration": "20" } ] } ] }';
    }

    public static string getCreateAppointmentResponseString() {
        return '{ "status": "success", "message": "appointment scheduled", "siteId": "1045", "hybrisOrderId": "W010743695", "posCustomerId": "W010743695", "hybrisCustomerId": "9987000226", "appointmentId": "08p3F0000004vAXQAY", "appointmentStatus": "scheduled", "textOptIn": false, "emailAddressOptIn": true, "appointmentDate": "2021-01-02", "consultAppointmentId": "08p3F0000004vAXQAY", "consultStartTime": "1240", "consultEndTime": "1300", "consultDuration": "20", "backOfficeAppointmentId": "08q3F0000004QB8QAM", "backOfficeStartTime": "1300", "backOfficeEndTime": "1320", "backOfficeDuration": "20" }';
    }

    public static string getUpdateAppointmentResponseString() {
        return '{ "status": "success", "message": "appointment scheduled", "siteId": "1045", "hybrisOrderId": "W010743695", "posCustomerId": "W010743695", "hybrisCustomerId": "9987000226", "appointmentId": "08p3F0000004vAXQAY", "appointmentStatus": "scheduled", "textOptIn": false, "emailAddressOptIn": true, "appointmentDate": "2021-01-02", "consultAppointmentId": "08p3F0000004vAXQAY", "consultStartTime": "1240", "consultEndTime": "1300", "consultDuration": "20", "backOfficeAppointmentId": "08q3F0000004QB8QAM", "backOfficeStartTime": "1300", "backOfficeEndTime": "1320", "backOfficeDuration": "20" }';
    }
}