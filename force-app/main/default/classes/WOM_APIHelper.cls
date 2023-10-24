/*========================================================================================================
* @author: Capgemini
* @date: 20th Dec'22
* @description: Helper Call for API callouts

Modification Log:
------------------------------------------------------------------------------------
Developer      Mod Number   Date                User Story      Description
------------------------------------------------------------------------------------
Lim             M-001                                           Initial development
Akilan          M-002       11th Jan 2023       WOM-37          Added Notification Label for One Reach Platform Event
Anuradha        M-003       19th Jan 2023       WOM-1783        Modify Components to reference WOM_Customer_Type__c instead of AccountRecordType
Akilan          M-004       23rd Jan 2023       WOM-37          Modifed get Phone Number Method
Akilan          M-005       21st Feb 2023                       Static Code Analysis Changes
Anuradha        M-006       03rd Mar 2023                       Removal of WITH SECURITY_ENFORCED
G Anil          M-007       23rd Mar 2023                       added system.loglevel statements in generateAuthBearer
Akilan          M-008       28th Mar 2023                       Added Final Static String for PullList status and source x
Hrushikesh      M-009       12 April 2023                       Adding try/Catch for log framework
========================================================================================================== */

/**
 * @description       
 * INT_Message Logging for all the Integrations Status Info:
    1. While sending Status: Pending
    2. While receiving based on sucess or Error Update the Status
 * @author             Lim Gabba
 * @group               
 * @last modified on   02-03-2023
 * @last modified by   Akilan
**/
public without sharing class WOM_APIHelper {
    
    public static final String TYPE_WOM_FITMENT_PSI = 'WOM_FITMENT_PSI';
    public static final String TYPE_WOM_ADD_WAITLIST = 'WOM_ADD_WAITLIST';
    public static final String TYPE_WOM_UPDATE_WAITLIST = 'WOM_UPDATE_WAITLIST';
    public static final String TYPE_WOM_GET_WAITLIST = 'WOM_GET_WAITLIST';
    public static final String TYPE_WOM_WORKORDER_PLATFORM_EVENT = 'WOM_WORKORDER_PLATFORM_EVENT';
    public static final String TYPE_WOM_FITMENT_NOTES_API = 'WOM_FITMENT_NOTES_API';
    public static final String TYPE_WOM_WORKORDER_INFORMATION = 'WOM_WORKORDER_INFORMATION';
    public static final String TYPE_WOM_ONEREACH_PLATFORM_EVENT = 'WOM_ONEREACH_PLATFORM_EVENT';
    public static final String TYPE_WOM_GET_VTV_INFORMATION = 'WOM_GET_VTV_INFORMATION';
    public static final String TYPE_WOM_FITMENT_ATTRIBUTES = 'WOM_FITMENT_ATTRIBUTES';
    public static final String TYPE_WOM_POST_VTV_INFORMATION = 'WOM_POST_VTV_INFORMATION';
    public static final String TYPE_WOM_PUT_VTV_INFORMATION = 'WOM_PUT_VTV_INFORMATION';

    public static final String WOM_GETWAITLISTBYSC = 'WOM_GetWaitlistDataByStoreCode';
    public static final String WOM_ADDWAITLIST = 'WOM_AddWaitlist';
    public static final String WOM_UPDATEWAITLIST = 'WOM_UpdateWaitlist';
    public static final String WOM_WAITLISTCANCELLEDSTATUS = 'cancelled';
    public static final String WOM_NAMED_CRED_DEVELOPER_NAME = 'WOMExperienceAPI';
    public static final String REST_GET = 'GET';
    public static final String REST_POST = 'POST';
    public static final String REST_PUT = 'PUT';
    public static final String HORIZON = 'Horizon';
    public static final String CONTENT_TYPE = 'application/json';
    public static final Integer DEFAULT_TIMEOUT = 15000;    

    // INTEGRATION AUTHENTICATION PARAMS 
    public static final String WOM_DTCORRELATIONID_PARAM = 'dtCorrelationId';
    public static final String WOM_DTREQUESTIDENTIFIER_PARAM = 'dtRequestIdentifier';
    public static final String WOM_DTSOURCESYSTEM_PARAM = 'dtSourceSystem';
    public static final String WOM_DTSOURCESUBSYSTEM_PARAM = 'dtSourceSubsystem';
    public static final String WOM_DTCONTENTTYPE_PARAM = 'Content-Type';
    public static final String WOM_DTAUTHORIZATION_PARAM = 'Authorization';
    public static final String TYPE_WOM_BEARERTOKEN = 'WOM_BEARERTOKEN';
    
    // INTEGRATION STATUS CODES
    public static final Integer WOM_STATUS_200 = 200;
    public static final Integer WOM_STATUS_201 = 201;
    public static final Integer WOM_STATUS_204 = 204;
    public static final Integer WOM_STATUS_206 = 206;
    
    //VTV GET
    public static final String WOM_GETVTVFROMVTVAPI = 'WOM_GetVTVFromVTVAPI';
    public static final String VTV = 'VTV';
    
    //VTV POST PUT
    public static final String WOM_POSTVTVINFORMATION = 'WOM_PostVTVInformation';
    public static final String WOM_PUTVTVINFORMATION ='WOM_PutVTVInformation';
    
    //FITMENT Air Pressure
    public static final String WOM_GETPSIFROMFITMENTAPI = 'WOM_GetPSIFromFitmentAPI';
    public static final String FITMENT = 'Fitment';
    
     
    //Fitment Attributes
    public static final String WOM_GETFITMENTATTRIBUTES = 'WOM_GetFitmentAttributes';
    
    // ONE REACH
    public static final String NOTIFICATION_TYPE_BAYOUT = 'WOMBAYOUT';
    public static final String NOTIFICATION_SOURCE_WEB = 'WEB';
    public static final String NOTIFICATION_CHANNEL_SMS = 'SMS';
    public static final String NOTIFICATION_COMM_TYPE_TRANSACTION = 'Transaction';
    public static final String NOTIFICATION_SMS_STATE = 'initial';
    public static final String NOTIFICATION_SMS_REQUEST_TYPE = 'WOMBAYOUTPICKUP';
    
    // CAR PULL LIST
    public static final String WOM_CARPULLLISTAPI = 'WOM_CarPulllistAPI';
    public static final String WOM_CARSYSTEM = 'CAR';
    public static final String TYPE_WOM_CAR_PULLLIST = 'WOM_CAR_PULLLIST';
    public static final String TYPE_WOM_CAR_PULLLIST_PRINT = 'WOM_CAR_PULLLIST_PRINT';
    public static final String WOM_PULLLIST_SOURCE_UI = 'UI';
    public static final String WOM_PULLLIST_SOURCE_PRINT = 'PRINT';
    public static final String WOM_PULLLISTSTATUS_NEW = 'Customer Q';
    public static final String WOM_PULLLISTSTATUS_AWAITING_SERVICE = 'Service Q';
    public static final String WOM_PULLLISTSTATUS_IN_BAY = 'In Bay';
    public static final String WOM_PULLLISTSTATUS_BAY_OUT = 'Completed';
    
    // WORKORDER STATUS
    public static final String WOM_WOSTATUS_NEW = 'New';
    public static final String WOM_WOSTATUS_AWAITING_SERVICE = 'Awaiting Service';
    public static final String WOM_WOSTATUS_IN_BAY = 'In Bay';
    public static final String WOM_WOSTATUS_BAY_OUT = 'Bay Out';
    public static final String WOMOKTA = 'WOMOKTA'; 
    public static Cache.OrgPartition orgPart = Cache.Org.getPartition('local.womBearertokencache');
    
    //FITMENT NOTES
    public static final String WOM_FITMENTNOTESAPI = 'WOM_GetFitmentNotesAPI';
    public static final String WOM_ENDPOINT_CATEGORY = '&category=TPMS&category=LIFT&category=SPEC';
    
    // Object Types
    public static final String OBJECTTYPE_WAITLIST = 'WOM_Waitlist__c';
    public static final String OBJECTTYPE_WOLI = 'WorkOrderLineItem';
    public static final String OBJECTTYPE_WORKORDER = 'WorkOrder';
    public static final String OBJECTTYPE_ASSET = 'Asset';
    public static final String OBJECTTYPE_ACCOUNT = 'Account';
    public static final String OBJECTTYPE_SERVICEAPPOINTMENT = 'ServiceAppointment';
    
    /**
    * @description Accessing the cached token to avoid repeated callouts
    * @author Lim Gabba
    * @param  destinationSystem
    * @return Access Token/Bearer Token
    **/
    public static String getCachedToken(String destinationSystem){
        String token = '';    
        try{    
             token = generateAuthBearer();
            if(destinationSystem == WOMOKTA){
                token = (String)orgPart.get(WOMOKTA);
                if(String.isBlank(token)) {
                    System.debug(System.LoggingLevel.DEBUG,'okta token not available in the cache, performing refresh');
                    token = refreshToken(destinationSystem);
                }else{
                    System.debug(System.LoggingLevel.DEBUG,'okta token retrieved from cache');
                }
            }
        }catch(Exception ex){
            WOM_LogFramework.logExceptions('getCachedToken', WOM_APIHelper.class.getName(), '', ex);
        }
        return token;
    }

    /**
    * @description Refreshing the cached token by getting a new token via callout
    * @author Lim Gabba
    * @param  destinationSystem
    * @return Access Token/Bearer Token
    **/
    public static String refreshToken(String destinationSystem){
        String token = '';
        try{
            token = generateAuthBearer();
            if(String.isNotBlank(token)) {
                orgPart.put(WOMOKTA,token,Integer.valueOf(System.Label.WOM_oktaTokenCacheExpiration));
                System.debug(System.LoggingLevel.DEBUG,'orgPart token'+orgPart); 
                System.debug(System.LoggingLevel.DEBUG,'okta token refreshed'); 
            }
        }catch(Exception ex){
            WOM_LogFramework.logExceptions('refreshToken', WOM_APIHelper.class.getName(), '', ex);
        }    
        return token;
    }
    
    /**
    * @description To Create INT Message for Logging any successfully or failed Integration Call
    * @author  Lim Gabba | 11-28-2022 
    * @param intType 
    * @param status 
    * @param endpoint 
    * @param payload 
    * @param response 
    * @param sfdcError 
    * @param externalError 
    * @param salesforceId 
    * @return String 
    **/
    public static String buildIntMessage(String intType, 
                                        String status, 
                                        String endpoint, 
                                        String payload,
                                        String response, 
                                        String sfdcError, 
                                        String externalError, 
                                        String salesforceId)
    {       
        String returnId ;
        try{
            Int_Message__c intMessage = new Int_Message__c (Type__c = intType,
                                                            Status__c = status, 
                                                            Url__c = endpoint, 
                                                            Payload__c = payload, 
                                                            Response__c= response,
                                                            Salesforce_Error__c = sfdcError, 
                                                            External_Error__c = externalError,
                                                            Id = salesforceId,
                                                            Logs__c = Int_Values.getTimingLog());
            Database.upsertResult uResult = Database.upsert(intMessage, false);
            returnId = uResult.isSuccess() ? uResult.getId() : '';
        }catch(Exception ex){
            WOM_LogFramework.logExceptions('buildIntMessage', WOM_APIHelper.class.getName(), '', ex);
        }    
        return  returnId;
    }
    
    /**
    * @description To Create INT Message for Logging any successfully or failed Integration Call
    * @author  Lim Gabba | 11-28-2022 
    * @param intType 
    * @param status 
    * @param endpoint 
    * @param payload   : Request of the API 
    * @param response  : Response Of the API 
    * @param sfdcError : Salesforce Internal Error 
    * @param externalError 
    * @param salesforceIntMessageId
    * @param stackTrace 
    * @param recordId
    * @param objectType 
    * @return String 
    **/
    public static String buildIntMessage (String intType, 
                                          String status, 
                                          String endpoint,
                                          String payload, 
                                          String response, 
                                          String sfdcError, 
                                          String externalError, 
                                          String salesforceIntMessageId, 
                                          String stackTrace,
                                          String recordId,
                                          String objectType)
    {       
        String returnId ;
        try{
            Int_Message__c intMessage = new Int_Message__c (Type__c = intType,
                                                            Status__c = status, 
                                                            Url__c = endpoint, 
                                                            Payload__c = payload, 
                                                            Response__c= response,
                                                            Salesforce_Error__c = sfdcError, 
                                                            External_Error__c = externalError,
                                                            Id = salesforceIntMessageId,
                                                            Logs__c = stackTrace,
                                                            RecordId__c = recordId,
                                                            Object_Type__c = objectType);
            Database.upsertResult uResult = Database.upsert(intMessage, false);
            returnId = uResult.isSuccess() ? uResult.getId() : '';
        }catch(Exception ex){
            WOM_LogFramework.logExceptions('buildIntMessage', WOM_APIHelper.class.getName(), '', ex);
        }        
        return  returnId ;
    }
        
    /**
    * @description Returns the most relevant phone number for the WO
    * @author Akilan Ganesan | 20-12-2022 
    * @param  woRecord
    * @return Phone Number as per required 
    **/
    public static string getPhoneforWO(WorkOrder woRecord){
        String phone='';
        try{
            System.debug(System.LoggingLevel.DEBUG,'woRecord.Account.Recordtype.Name>>'+woRecord.Account.Recordtype.Name);
            System.debug(System.LoggingLevel.DEBUG,'woRecord.WOM_Customer_Type__c>>'+woRecord.WOM_Customer_Type__c);       
            if(woRecord.WOM_Customer_Type__c == 'Person' && woRecord.Account.PersonMobilePhone != null){
                phone = woRecord.Account.PersonMobilePhone ;
            }
        }catch(Exception ex){
            WOM_LogFramework.logExceptions('getPhoneforWO', WOM_APIHelper.class.getName(), '', ex);
        }     
        return phone;
    }
    
    /**
    * @description 
    * @author Lim Gabba | 03-06-2023 
    * @return string 
    **/
    public static string generateAuthBearer(){
        String url = system.label.WOM_DTExperienceOAuthNC;
        System.debug(System.LoggingLevel.DEBUG,'url:'+url);
        HttpRequest authRequest = new HttpRequest();
        authRequest.setEndpoint(url); 
        authRequest.setHeader('Accept', 'application/json');
        authRequest.setHeader('Content-Type','application/x-www-form-urlencoded');
        authRequest.setMethod(REST_POST);
        authRequest.setBody('grant_type=client_credentials&scope=READ');
        authRequest.setTimeout(DEFAULT_TIMEOUT);
        Http http = new Http();
        HTTPResponse authResponse = new HTTPResponse();        
        authResponse = http.send(authRequest);
        Map<String,Object> responseMap = new Map<String,Object>();
        System.debug(System.LoggingLevel.DEBUG,'authResponse');
        try{
            System.debug('Response'+authResponse.getBody());
            If(authResponse.getStatusCode() == 200){
                responseMap = (Map<String,Object>)JSON.deserializeUntyped(authResponse.getBody());
                System.debug(System.LoggingLevel.DEBUG,+String.valueof(responseMap.get('access_token')));
                return String.valueof(responseMap.get('access_token'));
            }
        }catch(Exception ex){
            WOM_LogFramework.logExceptions('generateAuthBearer', WOM_APIHelper.class.getName(), '', ex);
        }     
        return null;
    }

    /**
    * @description  To get the endPoint details for requested interface
    * @param        interfaceName
    * @return       WOM_API_Endpoint__mdt Metadata Records relevant to the callout
    */
    public static WOM_API_Endpoint__mdt getEndPointDetails(string interfaceName){
        WOM_API_Endpoint__mdt endPointDetails;
        try {
            endPointDetails = [SELECT WOM_Client_Id__c, WOM_Client_Secret__c,  WOM_Content_Type__c, WOM_Authorization_Header__c, 
                               WOM_Endpoint_URL__c, WOM_Method__c, WOM_Mock_Request__c,
                               WOM_Mock_Response__c, Label, DeveloperName, WOM_Blank_request_format__c,
                               WOM_System_Name__c, WOM_Token_Endpoint_URL__c, WOM_API_TimeOut_milliseconds__c,
                               WOM_dtSourceSubsystem__c,WOM_dtSourceSystem__c,WOM_isnotlive__c
                               FROM WOM_API_Endpoint__mdt 
                               WHERE Label = :interfaceName 
                               AND WOM_System_Name__c = :getSystemName() WITH SECURITY_ENFORCED
                               LIMIT 1 ];
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Exception :' + ex.getMessage());
        }
        return endPointDetails;
    }
    
    
    /**
    * @return       Current SystemName to differentiate between sandboxes
    * @description  To read the system name / Sandbox Names Or Production dynamically
    */
    public static string getSystemName(){
        url domainURL = URL.getOrgDomainUrl();
        string systemName = domainURL.gethost().substringBetween('--','.');
        systemName = systemName == null ? 'Prod' : systemName;
        systemName = systemName.toUpperCase();
        return systemName;
    }
    
    /**
     * @description  Return only one reason if multiple are selected(Required in POST/PUT Horizon call)
     * @param        reasonString
     * @return       String
     */
    public static string resonFormatting(String reasonString){ 
        String reasonValue = '';
        try{
            if(reasonString != null ){
                list<String> reasonValues = reasonString.split(';');
                If(reasonValues.size() > 1){
                    reasonValue =  reasonValues[0];
                }else{
                    reasonValue = reasonString;
                }
            }
            if(reasonValue == 'Flat Repair'){
                reasonValue = 'Flat repair';
            }else if(reasonValue == 'New Tires/Wheels'){
                reasonValue = 'New tires/wheels';
            }else{
                reasonValue = reasonValue;
            }
        }catch(Exception ex){
            WOM_LogFramework.logExceptions('resonFormatting', WOM_APIHelper.class.getName(), '', ex);
        }    
        return reasonValue;
    }

   
    
}