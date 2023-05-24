public class Fleet_InvoiceIntegrationUtil extends Fleet_IntegrationUtil{

    public static String lprefix = 'FLEET_INT_UTIL:';
    public static Integer MAX_CHARS = 50000;

    public static string bearerToken;
    public static String respBody;
    public static HttpRequest reqBody;

    //---Store as private for cache
    private static List<Fleet_Integration_Settings__mdt> fleetSettingList;

    @future
    public static void DmlIntMessageOprations(String  intMsgId){
        Logger logInstance = Logger.getInstance();
        logInstance.log('Invoice Integration', 'Fleet_InvoiceIntegrationUtil', 'Before Int_Message__c insert/update');
         //---NOTE: Cannot save the IntMessage until both callouts are complete (SF Error)
        Int_Message__c intMsgBToken = new Int_Message__c(Type__c=Int_Values.TYPE_FLEET_OAUTH, Status__c=Int_Values.STATUS_PENDING);

       
            //---Save the details of the OAuth token requst (NOTE only saving IntMessage for OAuth if there is an issue)
            if (intMsgBToken.Id == null)
            {
                insert intMsgBToken;
                logInstance.log('Invoice Integration', 'Fleet_InvoiceIntegrationUtil', 'After Int_Message__c insert', JSON.serialize(intMsgBToken));    
            } 
            else 
            {
                update intMsgBToken;
                logInstance.log('Invoice Integration', 'Fleet_InvoiceIntegrationUtil', 'After Int_Message__c update', JSON.serialize(intMsgBToken));    
            }
            
            logInstance.log('Invoice Integration', 'Fleet_InvoiceIntegrationUtil', 'Before Int_Message__c upsert');    
            //---Update the details of the GET request
            Int_Message__c intMsg=[SELECT id,Status__c,External_Error__c FROM Int_Message__c where id=:intMsgId];
            intMsg.Status__c = Int_Values.STATUS_ERROR;
            intMsg.External_Error__c = 'No OAuth token retrieved, unable to make GET';
            
            System.debug( lprefix + intMsg.External_Error__c);
            upsert intMsg;
            logInstance.log('Invoice Integration', 'Fleet_InvoiceIntegrationUtil', 'After Int_Message__c upsert', JSON.serialize(intMsg));    
          

    }
    
     @future
    public static void HttpReqSend(String  intMsgId){
        Int_Message__c intMsg=[SELECT id,Status__c,External_Error__c FROM Int_Message__c where id=:intMsgId];
         try
        {
            Http objHttp = new Http();

            DateTime startTime = Datetime.now();   
            system.debug('sending reqBody'+reqBody);
            HTTPResponse objRes = objHttp.send(reqBody);intMsg.Duration__c = getDuration(startTime, Datetime.now() );                                   
            respBody = objRes.getBody();            
            recordGetResults(intMsg, respBody);
            
        }
        catch(Exception ex)
        {
            Logger logInstance = Logger.getInstance();
            logInstance.log('Invoice Integration', 'Fleet_InvoiceIntegrationUtil', ex);
           system.debug('Exception in getRequestBody'+ex.getStackTraceString());
            recordError(intMsg, ex.getMessage());
        }

    }
    //---Execute an external GET request, this requires the HTTP Request and Int Message to be prepared first
    public static String getRequestBody(HttpRequest req, Int_Message__c intMsg)
    {
        //---NOTE: Cannot save the IntMessage until both callouts are complete (SF Error)
        Int_Message__c intMsgBToken = new Int_Message__c(Type__c=Int_Values.TYPE_FLEET_OAUTH, Status__c=Int_Values.STATUS_PENDING);

        String bToken = getBearerToken(intMsgBToken);

     
         if (bToken == '')
        {
            Fleet_InvoiceIntegrationUtil.DmlIntMessageOprations(intMsg.Id);
            return '';
        }
        

        req.setHeader('Authorization', 'Bearer ' + bToken);
        system.debug('bToken'+ bToken);
        req.setTimeout(Integer.valueOf(Label.Fleet_API_Request_Timeout) * 1000); //Setting timeout to 30 seconds.
        String body = '';
        reqBody=req;
        Fleet_InvoiceIntegrationUtil.HttpReqSend(intMsg.Id);
        return respBody;
        
    }


}