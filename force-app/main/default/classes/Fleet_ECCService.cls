//---Class used for calling ECC
public class Fleet_ECCService
{
    public static Boolean stopOutboundUpdate = false;

    public static String lprefix = 'FLEET_ECC_SERVICE:';

    //---Determine if the automatic ECC callouts should be disabled
    public static Boolean disableECCCallout()
    {
        Boolean returnValue = false;

        if (Fleet_IntegrationUtil.getSettingBooleanValue( Fleet_Values.SETTING_ECC_DISABLE_ALL_OUTGOING))
        {
            System.debug( lprefix + 'Disable all outgoing flag is set, preventing callout');
            return true;
        }

        String userName =  UserInfo.getUserName();
        String supressOutboundUserList = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_SUPPRESS_OUTBOUND_USER_LIST);

        Boolean isIntUser = false;

        if (supressOutboundUserList != null && supressOutboundUserList != '')
        {
            isIntUser = supressOutboundUserList.contains(userName);
        }

        if (isIntUser)
        {
            System.debug( lprefix + 'Current User is ' + userName + ' preventing callout');
            returnValue = true;
        }
        else if (stopOutboundUpdate) 
        {
            System.debug( lprefix + 'Current User is ' + userName + ' and stopOutboundUpdate is set, preventing callout');
            returnValue = true;
        }
        else 
        {
            System.debug( lprefix + 'Current User is ' + userName + ' allowing callout');
            returnValue = false;
        }

        return returnValue;
    }
   
    //---Primary method for sending a list of messages
    public static void sendMessges(List<Id> messageIdList)
    {
        System.debug( lprefix + 'Received the following list of Int Message Ids ' + messageIdList);
  
        List<Id> messageIdSetList = new List<Id>();
        Integer counter = 0;
        Integer maxMesages = Fleet_IntegrationUtil.getSettingIntValue( Fleet_Values.SETTING_INT_MESSAGE_MAX_PROCESS_COUNT);
        
        System.debug( lprefix + 'Processing ' + messageIdList + ' messages, using a max message setting of: ' + maxMesages);

        for( Id rowId : messageIdList)
        {
            if (counter >= maxMesages)
            {
                System.debug( lprefix + 'Sending a Set of Int Message Ids ' + messageIdSetList.size() + ' ' + messageIdSetList);
                sendMessgesSet(messageIdSetList);   //---Sending the Message set

                //---Clearing the list and the counter
                messageIdSetList = new List<Id>();
                counter = 0;
            }
        
            messageIdSetList.add( rowId);
            counter++;
        }            

        if (messageIdSetList.size() > 0)
        {
            System.debug( lprefix + 'Sending the last Set of Int Message Ids ' + messageIdSetList.size() + ' ' + messageIdSetList);
            sendMessgesSet(messageIdSetList);    //---Sending the final Message set
        } 
    }

    //---Send the Set as a future call
    @future(callout=true)
    public static void sendMessgesSet(List<Id> messageIdList)
    {
        System.debug( lprefix + 'Received the following Set of Int Message Ids ' + messageIdList);

        List<Int_Message__c> updateMessageList = new List<Int_Message__c>();

        for (Id mId : messageIdList)
        {
            Int_Message__c intMsg = sendMessage(mId, false);

            if (intMsg != null) updateMessageList.add( intMsg);
        }

        update updateMessageList;
    }

    //---Use the retry as a future call
    @future(callout=true)
    public static void sendRetryMessges(List<Id> messageIdList)
    {
        System.debug( lprefix + 'Received the following list of Retry Int Message Ids ' + messageIdList);

        List<Int_Message__c> updateMessageList = new List<Int_Message__c>();

        for (Id mId : messageIdList)
        {
            Int_Message__c intMsg = sendMessage(mId, true);

            if (intMsg != null) updateMessageList.add( intMsg);
        }

        update updateMessageList;
    }

    //---Send a single message
    public static Int_Message__c sendMessage(Id msgId, Boolean isRetry)
    {
        System.debug( lprefix + 'Sending Message Id: ' + msgId);

        Int_Message__c intMsg = [SELECT Id, Status__c, Type__c, Payload__c, Retry_Count__c, Salesforce_Error__c, External_Error__c, Last_Retry_Date__c FROM Int_Message__c WHERE ID = :msgId];

        //---Set values to defaults for being able to add retry messages and logic
        if (intMsg.Retry_Count__c == null) intMsg.Retry_Count__c = 0;
        if (intMsg.External_Error__c == null) intMsg.External_Error__c = '';
        if (intMsg.Salesforce_Error__c == null) intMsg.Salesforce_Error__c = '';

        if (intMsg == null)
        {
            System.debug( lprefix + 'Int Message not found, this should not happen: ' + msgId);
            return null;
        }
        else if (intMsg.Type__c != Int_Values.TYPE_ACCOUNT_ECC && intMsg.Type__c != Int_Values.TYPE_CONTACT_ECC)
        {
            System.debug( lprefix + 'Int Message Type is not correct for this process: ' + intMsg);
            return null;
        }

        if (isRetry)
        {
            if (intMsg.Status__c != Int_Values.STATUS_ERROR)
            {
                System.debug( lprefix + 'Int Message status for Retry is not Error, may have already been reprocessed: ' + intMsg);
                return null;
            }

            //---Record as a retry
            recordRetry(intMsg);
        }
        else 
        {
            if (intMsg.Status__c != Int_Values.STATUS_PENDING && intMsg.Status__c != Int_Values.STATUS_QUEUED)
            {
                System.debug( lprefix + 'Int Message status is not pending, may have already been processed: ' + intMsg);
                return null;
            }
        }

        System.debug( lprefix + 'Starting to process Message: ' + intMsg);

        //---Build the callout
        String endUrl = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_B2B_CUSTOMER_PUT_URL);
        intMsg.Url__c = endUrl;
        intMsg.Submitted_Date__c = DateTime.now();

        HttpRequest req = null;

        try 
        {
            req = buildECCHttpReq( endUrl);
        }
        catch (Exception ex) 
        {
            handleSFException(intMsg, ex);
            return intMsg;
        }

        try 
        {
            String body = Fleet_IntegrationUtil.putRequestBody(req, intMsg);
            if (body == null)
            {
                handleExternalError( intMsg, 'No Body returnd from Experience API');
            }
            else 
            {
                parseAndReadResults(intMsg, body);
            } 
        } 
        catch (Exception ex) 
        {
            handleSFException(intMsg, ex);
        }

        return intMsg;
    }

    //---Parse and read the results
    public static void parseAndReadResults(Int_Message__c intMsg, String body)
    {
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(body);
                
        Object retObjStatus = results.get('status');
        Object retObjMessage = results.get('message');

        String retStatus = retObjStatus == null ? '' : (String)results.get('status');
        String retMessage = retObjMessage == null ? '' :  (String)results.get('message');

        System.debug( lprefix + 'Recieved the following response  status: ' + retStatus + '  message: ' + retMessage);

        Boolean isSuccess = retStatus != null && retStatus != '' && retStatus == Fleet_Values.MESSAGE_STATUS_SUCCESS;

        if (isSuccess)
        {
            intMsg.Status__c = Int_Values.STATUS_SUBMITTED;
            //update intMsg;

            System.debug( lprefix + 'Succesful Submit with Resonse: ' + body + '  for Message: ' + intMsg);
        }
        else 
        {
            handleExternalError( intMsg, 'Error Reponse ' + retStatus + '  message: ' + retMessage);
        }
    }

    //---record retry
    public static void recordRetry(Int_Message__c intMsg)
    {
        if (intMsg.Retry_Count__c == null) intMsg.Retry_Count__c = 0;

        //---Record as a retry
        intMsg.Retry_Count__c++;
        String retryMessage = Fleet_Values.LINE_BREAK + '--- Retry #' + intMsg.Retry_Count__c + ' at: ' + Datetime.now() + ' ---' + Fleet_Values.LINE_BREAK;
        intMsg.External_Error__c += retryMessage;
        intMsg.Salesforce_Error__c += retryMessage;
        intMsg.Last_Retry_Date__c = Datetime.now();   
    }

    //---Handle sf exception
    public static void handleSFException(Int_Message__c intMsg, Exception ex)
    {
        String errorMessage = ex == null ?  'error' : ex.getMessage();

        intMsg.Status__c = Int_Values.STATUS_ERROR;
        intMsg.Salesforce_Error__c += errorMessage;
        
        System.debug( lprefix + 'Exception :' + errorMessage);

        //---Save on exception
        if (intMsg.Id == null)
        {
            insert intMsg;
        }
        else 
        {
            update intMsg;    
        }
    }

    //---Handle an external error
    public static void handleExternalError(Int_Message__c intMsg, String errorMessage)
    {
        intMsg.Status__c = Int_Values.STATUS_ERROR;
        intMsg.External_Error__c += errorMessage;
        
        System.debug( lprefix + 'Error :' + errorMessage);
        
        //---Save on Error
        if (intMsg.Id == null)
        {
            insert intMsg;
        }
        else 
        {
            update intMsg;    
        }
    }

    //---Build the ECC Http Request
    public static HttpRequest buildECCHttpReq(String endUrl)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:FleetExperienceAPI' + endUrl);
        req.setMethod('PUT');
        req.setHeader('Content-Type','application/json');
        req.setHeader('dtSourceSystem', Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_DT_SOURCE_SYSTEM));  
        req.setHeader('dtSourceSubsystem', Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_DT_SOURCE_SUBSYSTEM) ); 

        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);

        req.setHeader('dtRequestIdentifier', guid);  

        return req;
    }
}