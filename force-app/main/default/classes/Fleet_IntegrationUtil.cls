public abstract class Fleet_IntegrationUtil
{
    public static String lprefix = 'FLEET_INT_UTIL:';
    public static Integer MAX_CHARS = 50000;

    public static string bearerToken;

    //---Store as private for cache
    private static List<Fleet_Integration_Settings__mdt> fleetSettingList;

    //---Check the cache and query if neeeded
    public static List<Fleet_Integration_Settings__mdt> getFleetSettings()
    {
        if (fleetSettingList == null || fleetSettingList.size() == 0)
        {
            fleetSettingList = [SELECT DeveloperName, Value__c FROM Fleet_Integration_Settings__mdt];
        }

        return fleetSettingList;
    }

    //---Get a single System Setting, using/reloading the cache if needed
    public static String getSettingValue(String developerName)
    {
        String returnVal = '';

        List<Fleet_Integration_Settings__mdt> settingList = getFleetSettings();

        for (Fleet_Integration_Settings__mdt sRow : settingList)
        {
            if (sRow.DeveloperName == developerName)
            {
                returnVal = sRow.Value__c;
                break;
            }
        }

        return returnVal;
    }

    //---Get the Integer Value - If empty or invalid, the response will be zero
    public static Integer getSettingIntValue(String developerName)
    {
        Integer returnVal = 0;
        String currValue = getSettingValue(developerName);

        if (currValue == null || currValue == '')
        {
            System.debug( lprefix + 'Error converting settings ' + developerName + ' to Integer, no setting value found.');   
            return returnVal;
        } 

        try 
        {
            returnVal = Integer.valueOf(currValue);
        } 
        catch (Exception ex) 
        {
           // Logger logInstance = Logger.getInstance();
           // logInstance.log('Integration Util', 'Fleet_IntegrationUtil', ex);
            String errorMessage = ex.getMessage();
            System.debug( lprefix + 'Error converting settings ' + developerName + ' value: ' + currValue + ' to Integer');   
        }

        return returnVal;
    }

    //---Get the Boolean Value - If empty or invalid, the response will be false
    public static Boolean getSettingBooleanValue(String developerName)
    {
        Boolean returnVal = false;
        String currValue = getSettingValue(developerName);

        if (currValue != null && currValue != '' && (currValue.toUpperCase().contains('YES') || currValue.toUpperCase().contains('TRUE')))
        {
            returnVal = true;
        }

        return returnVal;
    }

    //---Get the Bearer Token for Authentication
    public static String getBearerToken( Int_Message__c intMsg)
    {
        if (bearerToken != null && bearerToken != '')
        {
            System.debug( lprefix + 'Bearer Token found, no need to get another: ' + bearerToken);
            return bearerToken;
        } 

        Datetime startTimeOAuth = Datetime.now();  
    
        String bToken  = '';

        try
        {
            String url = 'callout:FleetExperienceOAuth';
            intMsg.URL__c = url;

            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setMethod('POST');
            req.setBody('grant_type=client_credentials&scope=READ');
            

            Http objHttp = new Http();
            HTTPResponse objRes = objHttp.send(req);

            bToken = parseBToken(intMsg, objRes.getBody());
        }
        catch(Exception ex)
        {
           // Logger logInstance = Logger.getInstance();
           // logInstance.log('Integration Util', 'Fleet_IntegrationUtil', ex);
            system.debug('=====ex>'+ex);
            system.debug('=====ex.getMessage()>'+ex.getMessage());
            recordError( intMsg, ex.getMessage());
        }

        bearerToken = bToken;
        System.debug( lprefix + 'Timing-OAuth: ' + Fleet_IntegrationUtil.getDuration(startTimeOAuth, Datetime.now()) + ' ms');     

        return bToken;
    }

    //---Parse the bearer token
    public static String parseBToken(Int_Message__c intMsg, String body)
    {
        String bToken = ''; 

        JSONParser objParse = JSON.createParser(body);
        while (objParse.nextToken() != null) 
        {
            if (objParse.getCurrentToken() == JSONToken.FIELD_NAME && objParse.getText() == 'access_token')
            {
                objParse.nextToken();
                bToken = objParse.getText();
                recordSuccess(intMsg);
            }
        }

        if (bToken == '') recordNoToken(intMsg, body);

        return bToken;
    }

    //---Record success
    public static void recordSuccess(Int_Message__c intMsg)
    {
        intMsg.Payload__c = 'Sucessful access_token.  Hidden for security reasons.';
        intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;

        System.debug( lprefix + intMsg.Payload__c);
        //---NOTE:  Cannot Save OAuth IntMessage before acutal outbound WS, otherwise will recieve error:  "You have uncommitted work pending. Please commit or rollback before calling out"
    }

    //---Set for no payload
    public static void recordNoToken(Int_Message__c intMsg, String body)
    {
        //Logger logInstance = Logger.getInstance();
        //logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'Before Int_Message__c creation');   
        intMsg.Payload__c = body;
        intMsg.Status__c = Int_Values.STATUS_ERROR;
        intMsg.External_Error__c = 'OAuth attempt, no access token found in payload.';
        
        System.debug( lprefix + intMsg.External_Error__c + ' Payload:' + intMsg.Payload__c);
        
        if (intMsg.Id == null)
        {
            insert intMsg;
            //logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c creation', JSON.serialize(intMsg));
        }
        else 
        {
            update intMsg;   
           // logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c update', JSON.serialize(intMsg)); 
        }
    }

    //---Handle an external error (not used)
    public static void handleExternalError(Int_Message__c intMsg, String errorMessage)
    {
       // Logger logInstance = Logger.getInstance();
       // logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'Before Int_Message__c creation');   
        
        intMsg.Status__c = Int_Values.STATUS_ERROR;
        intMsg.External_Error__c += errorMessage;
        
        System.debug( lprefix + 'Error :' + errorMessage);
        
        if (intMsg.Id == null)
        {
            insert intMsg;
            //logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c creation', JSON.serialize(intMsg));
        }
        else 
        {
            update intMsg; 
           // logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c update', JSON.serialize(intMsg));   
        }
    }

    //---Execute an external GET request, this requires the HTTP Request and Int Message to be prepared first
    public static String getRequestBody(HttpRequest req, Int_Message__c intMsg)
    {
        //Logger logInstance = Logger.getInstance();
        //logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'Before Int_Message__c creation');  
        //---NOTE: Cannot save the IntMessage until both callouts are complete (SF Error)
        Int_Message__c intMsgBToken = new Int_Message__c(Type__c=Int_Values.TYPE_FLEET_OAUTH, Status__c=Int_Values.STATUS_PENDING);

        //getting the token from cache if exists there
        String bToken = TokenCacheController.getCachedToken('ECC', intMsgBToken);

        if (bToken == '')
        {
            //---Save the details of the OAuth token requst (NOTE only saving IntMessage for OAuth if there is an issue)
            if (intMsgBToken.Id == null)
            {
                insert intMsgBToken;
                //logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c insert', JSON.serialize(intMsgBToken));   
            } 
            else 
            {
                update intMsgBToken;
                //logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c update', JSON.serialize(intMsgBToken));   
            }

            //---Update the details of the GET request
            intMsg.Status__c = Int_Values.STATUS_ERROR;
            intMsg.External_Error__c = 'No OAuth token retrieved, unable to make GET';
            
            System.debug( lprefix + intMsg.External_Error__c);
            upsert intMsg;

            return '';
        } 

        req.setHeader('Authorization', 'Bearer ' + bToken);

        req.setTimeout(Integer.valueOf(Label.Fleet_API_Request_Timeout) * 1000); //Setting timeout to 30 seconds.
        
        String body = '';
  
        try
        {
            Http objHttp = new Http();

            DateTime startTime = Datetime.now();   
            HTTPResponse objRes = objHttp.send(req);

            intMsg.Duration__c = getDuration(startTime, Datetime.now() );
            System.debug( lprefix + 'Timing-API: ' + intMsg.Duration__c + ' ms');

            body = objRes.getBody();
            recordGetResults(intMsg, body);
            
        }
        catch(Exception ex)
        {  
           // logInstance.log('Integration Util', 'Fleet_IntegrationUtil', ex);  
            recordError(intMsg, ex.getMessage());
        }

        return body;
    }

    //---Record the results of the GET
    public static void recordGetResults(Int_Message__c intMsg, String body)
    {
        intMsg.Response__c = (body != null && body.length() > MAX_CHARS) ? body.left(MAX_CHARS) : body;

        if (body == '')
        {
            intMsg.Status__c = Int_Values.STATUS_ERROR;
            intMsg.External_Error__c = 'External request, but no body found.';
            System.debug( lprefix + intMsg.External_Error__c);
        }
        else 
        {
            intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;
            System.debug( lprefix + 'Successful GET: ' + body.length() + ' characters');
        }
    }

    public static void recordError(Int_Message__c intMsg, String errorMessage)
    {
       // Logger logInstance = Logger.getInstance();
      //  logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'Before Int_Message__c creation');
        
        intMsg.Status__c = Int_Values.STATUS_ERROR;
        intMsg.External_Error__c += errorMessage;
        
        System.debug( lprefix + 'Exception :' + errorMessage);

        if (intMsg.Id == null)
        {
            insert intMsg;
           // logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c insert', JSON.serialize(intMsg));   
        }
        else 
        {
            update intMsg; 
          //  logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c update', JSON.serialize(intMsg));   
        }
    }

    //---Execute an external PUT request, this requires the HTTP Request and Int Message to be prepared first
    public static String putRequestBody(HttpRequest req, Int_Message__c intMsg)
    {
      //  Logger logInstance = Logger.getInstance();
      //  logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'Before Int_Message__c creation');
        //---NOTE: Cannot save the IntMessage until both callouts are complete (SF Error)
        Int_Message__c intMsgBToken = new Int_Message__c(Type__c=Int_Values.TYPE_FLEET_OAUTH, Status__c=Int_Values.STATUS_PENDING);

        //getting the token from Cache, if exists there
        String bToken = TokenCacheController.getCachedToken(TokenCacheController.ECC, intMsg);

        if (bToken == '')
        {
            //---Save the details of the OAuth token requst (NOTE only saving IntMessage for OAuth if there is an issue)
            if (intMsgBToken.Id == null)
            {
                insert intMsgBToken;
             //   logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c insert', JSON.serialize(intMsgBToken));   
            } 
            else 
            {
                update intMsgBToken;
             //   logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c update', JSON.serialize(intMsgBToken));   
            }

            //---Update the details of the GET request
            intMsg.Status__c = Int_Values.STATUS_ERROR;
            intMsg.External_Error__c += 'No OAuth token retrieved, unable to make GET';
            
            System.debug( lprefix + intMsg.External_Error__c);
            upsert intMsg;
           // logInstance.log('Integration Util', 'Fleet_IntegrationUtil', 'After Int_Message__c upsert', JSON.serialize(intMsg));   
            return '';
        } 

        req.setHeader('Authorization', 'Bearer ' + bToken);

        String body = '';
  
        try
        {
            // set up outbound request
            Http objHttp = new Http();
            
            req.setBody(intMsg.Payload__c);
            
            DateTime startTime = Datetime.now();  
            HTTPResponse objRes = objHttp.send(req);

            intMsg.Duration__c = getDuration(startTime,  Datetime.now() );
            System.debug( lprefix + 'Timing-API: ' + intMsg.Duration__c + ' ms');

            body = objRes.getBody();
            recordGetResults(intMsg, body);
        }
        catch(Exception ex)
        {  
           // logInstance.log('Integration Util', 'Fleet_IntegrationUtil', ex);   
            recordError(intMsg, ex.getMessage());
        }

        return body;
    }

    //---Get the Duration 
    public static Integer getDuration(DateTime startTime, Datetime endTime)
    {
        Integer elapsedMinutes = endTime.minute() - startTime.minute();
        Integer elapsedSeconds = endTime.second() - startTime.second();
        Integer elapsedMiliseconds = endTime.millisecond() - startTime.millisecond();

        Integer totalMili =  (elapsedMinutes * 60 * 1000) + (elapsedSeconds * 1000) + elapsedMiliseconds;

        return totalMili;
    }
}