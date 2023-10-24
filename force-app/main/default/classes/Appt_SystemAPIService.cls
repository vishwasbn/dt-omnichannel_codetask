@RestResource(urlMapping='/AppointmentService')
global class Appt_SystemAPIService {
    public static String lprefix = 'LOG Appt_SystemAPIService: ';
    public static Boolean intMsgEnabled = true;
    
    // SO-41 START:  Added logInstance 
    Public Static Logger logInstance = Logger.getInstance();

    /* 
        API endpoints - note two POST methods cannot exist in the same class
    */

    @HttpPost
    global static Appt_CreateAppointmentResponse createAppointment() {
        
        String payload = RestContext.request.requestBody != null ? RestContext.request.requestBody.toString() : '';
        return processCreateAppointmentPayload(payload);
    }

    @HttpPut
    global static Appt_UpdateAppointmentResponse updateAppointment() {
        String payload = RestContext.request.requestBody != null ? RestContext.request.requestBody.toString() : '';
        return processUpdateAppointmentPayload(payload);
    }

    public static Appt_CreateAppointmentResponse processCreateAppointmentPayload(String payload) {
        
        DateTime startTimeAll = Datetime.now();
        Integer statusCode = null;

        //---0. Record Errors and Log Request and Response if enabled
        Int_Message__c intMsg = new Int_Message__c(
            Type__c = 'APPT_CREATE_APPOINTMENT_INCOMING'
            , Payload__c = payload
            , Status__c = Int_Values.STATUS_PENDING
        );
        System.debug(lprefix + ' ' + intMsg);

        // 1. Parse Payload (in Try/Catch for parse errors)
        Appt_CreateAppointmentRequest request = null;
        Appt_CreateAppointmentServiceModel createAppointmentModel = null;
        try {
            request = Appt_CreateAppointmentRequest.parse(payload);
            System.debug(lprefix + 'create appointment request: ' + request);

            createAppointmentModel = Appt_CreateAppointmentServiceModel.parseCreateAppointmentRequest(request);
            System.debug(lprefix + 'create appointment service model: ' + createAppointmentModel);
            System.debug(Json.serializePretty(createAppointmentModel));
        }
        catch (Exception ex) {
            // Set any unhandled exceptions as 500
            statusCode = 500;
            Appt_SystemAPIServiceHandler.setSFError(intMsg, 'createIncomingAppointment', 'Error parsing payload ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
            System.debug(lprefix + 'error parsing Create Appointment Request or Service Model: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            // SO-41 START:  Added logInstance 
			String errDetails = 'Cause: '+ ex.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ ex.getMessage();
            logInstance.Log(LPREFIX, Appt_SystemAPIService.class.getName(), errDetails); // SO-41 END
        }

        
        // 2. Pass Model to createAppointment
        Appt_CreateAppointmentServiceModel updatedCreateAppointmentModel = null;
        if (createAppointmentModel != null) 
        {
            try {
                updatedCreateAppointmentModel = Appt_SystemService.createAppointment(createAppointmentModel);
                System.debug(lprefix + 'UPDATED create appointment service model: ' + updatedCreateAppointmentModel);

                // track statusCode
                if (updatedCreateAppointmentModel != null && updatedCreateAppointmentModel.statusCode != null) {
                    statusCode = Integer.valueOf(updatedCreateAppointmentModel.statusCode);
                }
            } catch (Appt_AppointmentException ex) {
                statusCode = (ex.errorCode != null) ? ex.errorCode: 500; // Set as incoming value or default as 500
                Appt_SystemAPIServiceHandler.setSFError(intMsg, 'createIncomingAppointment', 'Exception Thrown during createAppointment(): ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
                System.debug(lprefix + 'error parsing updated Create Appointment model: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                
                // SO-41 START:  Added logInstance 
                String errDetails = 'Cause: '+ ex.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ ex.getMessage();
                logInstance.Log(LPREFIX, Appt_SystemAPIService.class.getName(), errDetails); // SO-41 END
                
            } catch (Exception ex) {
                statusCode = 500; // Set any unhandled exceptions as 500
                Appt_SystemAPIServiceHandler.setSFError(intMsg, 'createIncomingAppointment', 'Error processing appointment: ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
                System.debug(lprefix + 'error Processing Appointment: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                
                // SO-41 START:  Added logInstance 
                String errDetails = 'Cause: '+ ex.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ ex.getMessage();
                logInstance.Log(LPREFIX, Appt_SystemAPIService.class.getName(), errDetails); // SO-41 END
            }
        }
        
        // 3. Build Create Appointment Response
        Appt_CreateAppointmentResponse response = null;
        if (updatedCreateAppointmentModel != null) {
            try {
                response = new Appt_CreateAppointmentResponse(updatedCreateAppointmentModel);
                System.debug(lprefix + ' Appt_CreateAppointmentResponse: ' + response);
                intMsg.Response__c = String.valueOf(response);
            } catch (Exception ex) {
                statusCode = 500;
                Appt_SystemAPIServiceHandler.setSFError(intMsg, 'createIncomingAppointment', 'Error creating appointment response ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
                System.debug(lprefix + 'error parsing updated Create Appointment model: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                
                // SO-41 START:  Added logInstance 
                String errDetails = 'Cause: '+ ex.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ ex.getMessage();
                logInstance.Log(LPREFIX, Appt_SystemAPIService.class.getName(), errDetails); // SO-41 END
            }
        }

        // 4. return success or error response
        Boolean isValidResponse = Appt_SystemAPIServiceHandler.validateCreateAppointmentResponse(response, intMsg, statusCode); // updates Int Msg 

        // set status code if one is defined
        Appt_SystemAPIServiceHandler.setStatusCode(statusCode);
        System.debug(lprefix + ' statusCode logged: ' + statusCode + ' statusCode set: ' + RestContext.response.statusCode);

        //---Update the Int Logs
        intMsg.Duration__c = Datetime.now().getTime() - startTimeAll.getTime();
        intMsg.Logs__c = Int_Values.getTimingLog();

        // log int msg
        if (intMsgEnabled == true) Appt_SystemAPIServiceHandler.upsertIntMsgFuture(JSON.serialize(intMsg));
        System.debug(lprefix + ' ' + intMsg);

        if (!isValidResponse) {
            // If a response was returned, use existing values. Else, return the Int Msg errors
            Appt_CreateAppointmentResponse errorResponse = new Appt_CreateAppointmentResponse();
            errorResponse.status = (response != null && response.status != null) ? response.status : Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            
            // Not all status codes can be handled, so include the status code returned in the response
            errorResponse.message = (response != null && response.message != null) ? response.message + ' - Status Code: ' + String.valueOf(statusCode) : intMsg.Salesforce_Error__c;

            return errorResponse;
        }
        return response;
    }

    public static Appt_UpdateAppointmentResponse processUpdateAppointmentPayload(String payload) {
        
        DateTime startTimeAll = Datetime.now();
        Integer statusCode = null;

        //---0. Record Errors and Log Request and Response if enabled
        Int_Message__c intMsg = new Int_Message__c(
            Type__c = 'APPT_UPDATE_APPOINTMENT_INCOMING'
            , Payload__c = payload
            , Status__c = Int_Values.STATUS_PENDING
        );
        System.debug(lprefix + ' ' + intMsg);
        
        // 1. Parse Payload (in Try/Catch for parse errors)
        Appt_UpdateAppointmentRequest request = null;
        Appt_UpdateAppointmentServiceModel updateAppointmentModel = null;
        try {
            request = Appt_UpdateAppointmentRequest.parse(payload);
            System.debug(lprefix + 'update appointment request: ' + request);

            updateAppointmentModel = Appt_UpdateAppointmentServiceModel.parseUpdateAppointmentRequest(request);
            System.debug(lprefix + 'update appointment service model: ' + request);
        } catch (Exception ex) {
            // Set any unhandled exceptions as 500
            statusCode = 500;
            Appt_SystemAPIServiceHandler.setSFError(intMsg, 'updateIncomingAppointment', 'Error parsing payload ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
            System.debug(lprefix + 'error parsing update Appointment Request or Service Model: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            
            // SO-41 START:  Added logInstance 
			String errDetails = 'Cause: '+ ex.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ ex.getMessage();
            logInstance.Log(LPREFIX, Appt_SystemAPIService.class.getName(), errDetails); // SO-41 END
        }


        // 2. Pass Model to updateAppointment
        Appt_UpdateAppointmentServiceModel modifiedUpdateAppointmentModel = null;
        if (updateAppointmentModel != null) 
        {
            try {
                modifiedUpdateAppointmentModel = Appt_SystemService.updateAppointment(updateAppointmentModel);
                System.debug(lprefix + 'MODIFIED updatedCreateAppointmentModel: ' + modifiedUpdateAppointmentModel);

                // track statusCode
                if (modifiedUpdateAppointmentModel != null && modifiedUpdateAppointmentModel.statusCode != null) statusCode = Integer.valueOf(modifiedUpdateAppointmentModel.statusCode);
            } catch (Appt_AppointmentException ex) {
                statusCode = (ex.errorCode != null) ? ex.errorCode: 500; // Set as incoming value or default as 500
                Appt_SystemAPIServiceHandler.setSFError(intMsg, 'createIncomingAppointment', 'Error updating appointment response ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
                System.debug(lprefix + 'error parsing updated Appointment model: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                
                // SO-41 START:  Added logInstance 
                String errDetails = 'Cause: '+ ex.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ ex.getMessage();
                logInstance.Log(LPREFIX, Appt_SystemAPIService.class.getName(), errDetails); // SO-41 END
                
            } catch (Exception ex) {
                // Set any unhandled exceptions as 500
                statusCode = 500;
                Appt_SystemAPIServiceHandler.setSFError(intMsg, 'updateIncomingAppointment', 'Error processing appointment ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
                System.debug(lprefix + 'error Processing Appointment: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                // SO-41 START:  Added logInstance 
                String errDetails = 'Cause: '+ ex.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ ex.getMessage();
                logInstance.Log(LPREFIX, Appt_SystemAPIService.class.getName(), errDetails); // SO-41 END
            }
        }


        // 3. Build Response Model
        Appt_UpdateAppointmentResponse response = null;
        if (modifiedUpdateAppointmentModel != null) {
            try {
                response = new Appt_UpdateAppointmentResponse(modifiedUpdateAppointmentModel);
                if (response != null) intMsg.Response__c = JSON.serialize(response);
                
            }  catch (Exception ex) {
                statusCode = 500;
                Appt_SystemAPIServiceHandler.setSFError(intMsg, 'updateIncomingAppointment', 'Error processing update response ' + ex.getMessage() + ' ' + ex.getStackTraceString(), statusCode);
                System.debug(lprefix + 'error parsing updated Appointment model: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                // SO-41 START:  Added logInstance 
                String errDetails = 'Cause: '+ ex.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ ex.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ ex.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ ex.getMessage();
                logInstance.Log(LPREFIX, Appt_SystemAPIService.class.getName(), errDetails); // SO-41 END
            }
        }

        // 4. return success or error response
        Boolean isValidResponse = Appt_SystemAPIServiceHandler.validateUpdateAppointmentResponse(response, intMsg, statusCode); // updates Int Msg 

        // set status code if one is defined
        Appt_SystemAPIServiceHandler.setStatusCode(statusCode);
        System.debug(lprefix + ' statusCode logged: ' + statusCode + ' statusCode set: ' + RestContext.response.statusCode);

        intMsg.Duration__c = Datetime.now().getTime() - startTimeAll.getTime();

        // log int msg
        if (intMsgEnabled == true) Appt_SystemAPIServiceHandler.upsertIntMsgFuture(JSON.serialize(intMsg));
        System.debug(lprefix + ' ' + intMsg);

        if (!isValidResponse) {
            // If a response was returned, use existing values. Else, return the Int Msg errors
            Appt_UpdateAppointmentResponse errorResponse = new Appt_UpdateAppointmentResponse();
            errorResponse.status = (response != null && response.status != null) ? response.status : Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            
            // Not all status codes can be handled, so include the status code returned in the response
            errorResponse.message = (response != null && response.message != null) ? response.message + ' - Status Code: ' + String.valueOf(statusCode) : intMsg.Salesforce_Error__c;
            return errorResponse;
        }
        return response;
    }
}