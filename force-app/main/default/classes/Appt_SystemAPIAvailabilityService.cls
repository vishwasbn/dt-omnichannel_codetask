@RestResource(urlMapping='/AppointmentAvailabilityService')
global class Appt_SystemAPIAvailabilityService{
    public static String lprefix = 'LOG Appt_SystemAPIAvailabilityService: ';
    public static Boolean intMsgEnabled = true;
    //Addedd for SO-41
    public static Logger logInstance = Logger.getInstance();
   
    @HttpPost
    global static Appt_SiteAvailabilityResponse getAvailability() {
        //start timer for performance loging
        DateTime startTimeAll = Datetime.now();       
        String payload = RestContext.request.requestBody != null ? RestContext.request.requestBody.toString() : '';
        Appt_SiteAvailabilityResponse returnModel = processAvailabilityPayload(payload);
        System.debug( lprefix + 'T-API ALL: ' + Fleet_IntegrationUtil.getDuration(startTimeAll, Datetime.now()) + ' ms');
        return returnModel;
    }

    public static Appt_SiteAvailabilityResponse processAvailabilityPayload(String payload) {
        
        Integer statusCode = null;
        DateTime startTimeAll = Datetime.now();

        //---0. Record Errors and Log Request and Response if enabled
        Int_Message__c intMsg = new Int_Message__c(
            Type__c = 'APPT_GET_AVAILABILITY_INCOMING'
            , Payload__c = payload
            , Status__c = Int_Values.STATUS_PENDING
        );
        System.debug(lprefix + ' ' + intMsg);

        // 1. Parse Payload (in Try/Catch for parse errors)
        Appt_GetAvailabilityRequest request = null;
        Appt_GetAvailabilityServiceModel getAvailabilityModel = null;
        try {
            request = Appt_GetAvailabilityRequest.parse(payload);
            System.debug(lprefix + 'GET AVAILABILITY request: ' + request);

            getAvailabilityModel = Appt_GetAvailabilityServiceModel.parseGetAvailabilityRequest(request);
            System.debug(lprefix + 'GET AVAILABILITY service model: ' + getAvailabilityModel);
        } catch (Exception ex) {
            // Set any unhandled exceptions as 500
            statusCode = 500;
            Appt_SystemAPIServiceHandler.setSFError(intMsg, 'getAvailability', 'Error parsing payload ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
            System.debug(lprefix + 'error parsing Create Appointment Request or Service Model: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            // SO-41 START:  Added logInstance 
            String errDetails = 'Cause: '+ ex.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ ex.getMessage();
            logInstance.Log(LPREFIX, Appt_SystemAPIAvailabilityService.class.getName(), errDetails); // SO-41 END
        }

        // 2. Pass Model to createAppointment
        Appt_SiteAvailabilityModel updatedModel = null;
        if (getAvailabilityModel != null) 
        {
            try {
                updatedModel = Appt_SystemService.getSiteAvailability(getAvailabilityModel);
                System.debug(lprefix + 'UPDATED create appointment service model: ' + updatedModel);

                // track statusCode
                if (updatedModel != null && updatedModel.statusCode != null) {
                    statusCode = Integer.valueOf(updatedModel.statusCode);
                }
            /*} catch (Appt_AppointmentException ex) {
                statusCode = (ex.errorCode != null) ? ex.errorCode: 500; // Set as incoming value or default as 500
                Appt_SystemAPIServiceHandler.setSFError(intMsg, 'getAvailability', 'Error generating getAvailability() response: ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
                System.debug(lprefix + 'Error generating getAvailability() response: ' + ex.getMessage() + ' ' + ex.getStackTraceString());*/
            } catch (Exception ex) {
                // Set any unhandled exceptions as 500
                statusCode = 500;
                Appt_SystemAPIServiceHandler.setSFError(intMsg, 'getAvailability', 'Error generating getAvailability() response:' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
                System.debug(lprefix + 'Error generating getAvailability() response: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                // SO-41 START:  Added logInstance 
                String errDetails = 'Cause: '+ ex.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ ex.getMessage();
                logInstance.Log(LPREFIX, Appt_SystemAPIAvailabilityService.class.getName(), errDetails); // SO-41 END
            }
        }
        
        // 3. Build Response model
        Appt_SiteAvailabilityResponse response = null;
        if (updatedModel != null) {
            try {
                response = new Appt_SiteAvailabilityResponse(updatedModel);
                System.debug(lprefix + 'Appt_SiteAvailabilityResponse: ' + response);
                intMsg.Response__c = String.valueOf(response);
                if (response != null ) {
                    if (response.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS && (response.days == null || response.days.size() < 1)) {
                        response.message = 'No Availability for this site.';
                    }
                }
            }  catch (Exception ex) {
                statusCode = 500;
                Appt_SystemAPIServiceHandler.setSFError(intMsg, 'getAvailability', 'Error generating getAvailability() response: ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
                System.debug(lprefix + 'Error generating getAvailability() response: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                // SO-41 START:  Added logInstance 
                String errDetails = 'Cause: '+ ex.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ ex.getMessage();
                logInstance.Log(LPREFIX, Appt_SystemAPIAvailabilityService.class.getName(), errDetails); // SO-41 END
            }
        }

        // 4. return success or error response
        Boolean isValidResponse = Appt_SystemAPIServiceHandler.validateGetAvailabilityResponse(response, intMsg, statusCode); // updates Int Msg 
        
        // set status code if one is defined
        Appt_SystemAPIServiceHandler.setStatusCode(statusCode);
        System.debug(lprefix + ' statusCode logged: ' + statusCode + ' statusCode set: ' + RestContext.response.statusCode);

        //---Update the Int Logs
        intMsg.Duration__c = Datetime.now().getTime() - startTimeAll.getTime();
        intMsg.Logs__c = Int_Values.getTimingLog();

        // log int msg
        if (intMsgEnabled == true) Appt_SystemAPIServiceHandler.upsertIntMsgFuture(JSON.serialize(intMsg));
        System.debug(lprefix + ' ' + intMsg);
        
        // when false, return a new an error response
        if (!isValidResponse) {
            // If a response was returned, use existing values. Else, return the Int Msg errors
            Appt_SiteAvailabilityResponse errorResponse = new Appt_SiteAvailabilityResponse();
            errorResponse.status = (response != null) ? response.status : Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            // Not all status codes can be handled, so include the status code returned in the response
            errorResponse.message = (response != null && response.message != null) ? response.message + ' - Status Code: ' + String.valueOf(statusCode) : intMsg.Salesforce_Error__c;

            return errorResponse;
        }
        return response;
    }
}