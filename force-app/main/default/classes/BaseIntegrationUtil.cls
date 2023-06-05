public virtual class BaseIntegrationUtil {

    public static String lprefix = 'INT_UTIL:';
    public static Integer MAX_CHARS = 50000;

    public static string bearerToken;

    //---Store as private for cache
    private static List<DT_Integration_Setting__mdt> dtIntSettingList;

    //---Check the cache and query if needed
    public static List<DT_Integration_Setting__mdt> getIntSettings(String integrationSystem)
    {
        if (dtIntSettingList == null || dtIntSettingList.size() == 0)
        {
            dtIntSettingList = [SELECT DeveloperName, Value__c, System__c FROM DT_Integration_Setting__mdt WHERE System__c = :integrationSystem];
        }

        return dtIntSettingList;
    }

    //---Get a single System Setting, using/reloading the cache if needed
    public static String getSettingValue(String developerName, String integrationSystem)
    {
        String returnVal = '';

        List<DT_Integration_Setting__mdt> settingList = getIntSettings(integrationSystem);

        for (DT_Integration_Setting__mdt sRow : settingList)
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
    public static Integer getSettingIntValue(String developerName, String integrationSystem)
    {
        Integer returnVal = 0;
        String currValue = getSettingValue(developerName, integrationSystem);

        if (currValue == null || currValue == '')
        {
            System.debug( lprefix + 'Error converting '+ integrationSystem+ ' integration settings ' + developerName + ' to Integer, no setting value found.');   
            return returnVal;
        } 

        try 
        {
            returnVal = Integer.valueOf(currValue);
        } 
        catch (Exception ex) 
        {
            String errorMessage = ex.getMessage();
            System.debug( lprefix + 'Error converting '+ integrationSystem+ ' integration settings  ' + developerName + ' value: ' + currValue + ' to Integer');   
        }

        return returnVal;
    }


    //---Get the Boolean Value - If empty or invalid, the response will be false
    public static Boolean getSettingBooleanValue(String developerName, String integrationSystem)
    {
        Boolean returnVal = false;
        String currValue = getSettingValue(developerName, integrationSystem);

        if (!String.isBlank(currValue) && (currValue.toUpperCase().contains('YES') || currValue.toUpperCase().contains('TRUE')))
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
            String url = 'callout:DTExperienceOAuth';
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
            recordError( intMsg, ex.getMessage());
        }

        bearerToken = bToken;
        System.debug( lprefix + 'Timing-OAuth: ' + getDuration(startTimeOAuth, Datetime.now()) + ' ms');     

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
        intMsg.Payload__c = body;
        intMsg.Status__c = Int_Values.STATUS_ERROR;
        intMsg.External_Error__c = 'OAuth attempt, no access token found in payload.';
        
        System.debug( lprefix + intMsg.External_Error__c + ' Payload:' + intMsg.Payload__c);
        
        if (intMsg.Id == null)
        {
            insert intMsg;
        }
        else 
        {
            update intMsg;    
        }
    }

    //---Handle an external error (not used)
    public static void handleExternalError(Int_Message__c intMsg, String errorMessage)
    {
        intMsg.Status__c = Int_Values.STATUS_ERROR;
        intMsg.External_Error__c += errorMessage;
        
        System.debug( lprefix + 'Error :' + errorMessage);
        
        if (intMsg.Id == null)
        {
            insert intMsg;
        }
        else 
        {
            update intMsg;    
        }
    }

    //---Execute an external GET request, this requires the HTTP Request and Int Message to be prepared first
    public static String getRequestBody(HttpRequest req, Int_Message__c intMsg)
    {
        System.debug(lprefix + 'getRequestBody() HttpRequest:'+req); //DEBUG

        //---NOTE: Cannot save the IntMessage until both callouts are complete (SF Error)
        Int_Message__c intMsgBToken = new Int_Message__c(Type__c=Int_Values.TYPE_FLEET_OAUTH, Status__c=Int_Values.STATUS_PENDING);

        String bToken = getBearerToken(intMsgBToken);

        if (bToken == '')
        {
            //---Save the details of the OAuth token requst (NOTE only saving IntMessage for OAuth if there is an issue)
            if (intMsgBToken.Id == null)
            {
                insert intMsgBToken;
            } 
            else 
            {
                update intMsgBToken;
            }

            //---Update the details of the GET request
            intMsg.Status__c = Int_Values.STATUS_ERROR;
            intMsg.External_Error__c = 'No OAuth token retrieved, unable to make GET';
            
            System.debug( lprefix + intMsg.External_Error__c);
            upsert intMsg;

            return '';
        } 

        req.setHeader('Authorization', 'Bearer ' + bToken);

        String body = '';
  
        try
        {
            Http objHttp = new Http();

            DateTime startTime = Datetime.now();   
            HTTPResponse objRes = objHttp.send(req);

            intMsg.Duration__c = getDuration(startTime, Datetime.now() );
            System.debug( lprefix + 'Timing-API: ' + intMsg.Duration__c + ' ms');

            body = objRes.getBody();
            //System.debug(lprefix + 'getRequestBody() Body:'+body); //DEBUG
            recordGetResults(intMsg, body);
            
        }
        catch(Exception ex)
        {  
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
        intMsg.Status__c = Int_Values.STATUS_ERROR;
        intMsg.External_Error__c += errorMessage;
        
        System.debug( lprefix + 'Exception :' + errorMessage);

        if (intMsg.Id == null)
        {
            insert intMsg;
        }
        else 
        {
            update intMsg;    
        }
    }

    //---Execute an external PUT request, this requires the HTTP Request and Int Message to be prepared first
    // public static String putRequestBody(HttpRequest req, Int_Message__c intMsg)
    // {
    //     //---NOTE: Cannot save the IntMessage until both callouts are complete (SF Error)
    //     Int_Message__c intMsgBToken = new Int_Message__c(Type__c=Int_Values.TYPE_FLEET_OAUTH, Status__c=Int_Values.STATUS_PENDING);

    //     String bToken = getBearerToken(intMsgBToken);

    //     if (bToken == '')
    //     {
    //         //---Save the details of the OAuth token requst (NOTE only saving IntMessage for OAuth if there is an issue)
    //         if (intMsgBToken.Id == null)
    //         {
    //             insert intMsgBToken;
    //         } 
    //         else 
    //         {
    //             update intMsgBToken;
    //         }

    //         //---Update the details of the GET request
    //         intMsg.Status__c = Int_Values.STATUS_ERROR;
    //         intMsg.External_Error__c += 'No OAuth token retrieved, unable to make GET';
            
    //         System.debug( lprefix + intMsg.External_Error__c);
    //         upsert intMsg;

    //         return '';
    //     } 

    //     req.setHeader('Authorization', 'Bearer ' + bToken);

    //     String body = '';
  
    //     try
    //     {
    //         // set up outbound request
    //         Http objHttp = new Http();
            
    //         req.setBody(intMsg.Payload__c);
            
    //         DateTime startTime = Datetime.now();  
    //         HTTPResponse objRes = objHttp.send(req);

    //         intMsg.Duration__c = getDuration(startTime,  Datetime.now() );
    //         System.debug( lprefix + 'Timing-API: ' + intMsg.Duration__c + ' ms');

    //         body = objRes.getBody();
    //         recordGetResults(intMsg, body);
    //     }
    //     catch(Exception ex)
    //     {  
    //         recordError(intMsg, ex.getMessage());
    //     }

    //     return body;
    // }

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