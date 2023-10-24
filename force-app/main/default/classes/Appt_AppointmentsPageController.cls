public without sharing class Appt_AppointmentsPageController {
    public String incomingParameters { get; set; } // JSON serialized map
    public String rawIncomingParameters {get; set; } // parameters + ''
    public String jsonString { get; set; } // json
    public String action { get; set; }
    public static final String JSON_ARGS = 'jsonArgs';

    public Int_Message__c intMessage { get; set; }

    //public String jsonSerializeTest { get; set; }
    
    public Appt_AppointmentsPageController() {
        intMessage = new Int_Message__c(Status__c = 'Pending', Type__c = 'apptPageIncoming');
        incomingParameters = '';
        jsonString = '';
        action = '';
        
        try {
            // 0. Get Raw form input
            incomingParameters = JSON.serialize(ApexPages.currentPage().getParameters());
            System.debug('appointmentsPageController -- getParams() = ' +incomingParameters);
            rawIncomingParameters = ApexPages.currentPage().getParameters()+'';
            
            // 1. Search for expected form value
            Map<String, object> parametersMap=new Map<String, object>();
            if (ApexPages.currentPage() != null 
                && ApexPages.currentPage().getParameters() != null 
                && ApexPages.currentPage().getParameters().size() > 0)
            {
                parametersMap=ApexPages.currentPage().getParameters();
                jsonString = getJsonArgs(parametersMap);
                if (jsonString != '') intMessage.Response__c = jsonString;
            }
            
            // 2. check first key if jsonArgs not found
            if (jsonString == null || jsonString == '') 
            {
                jsonString = getFirstKey(parametersMap.keySet());
            }

            // 3. process the JSON to find the action
            processJson(jsonString);
            intMessage.Payload__c = 'Action: ' + action + '\n\n json + ' + jsonString + '\n\n\n Raw Paramaters: '+rawIncomingParameters;
            intMessage.Status__c = 'Successful';
            
            // update intMessage;

        } catch (exception e) {
            intMessage.Status__c = 'Error';
            intMessage.Salesforce_Error__c = e.getMessage();
            if (intMessage.Payload__c == null || intMessage.Payload__c == '' && rawIncomingParameters != null) intMessage.Payload__c = 'Raw Paramaters: ' +rawIncomingParameters;
            // SO-41 START:  Added logInstance 
            String LPREFIX = 'Appt_AppointmentsPageController :';
    		Logger logInstance = Logger.getInstance();
            String errDetails = 'Cause: '+ e.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ e.getMessage();
            logInstance.Log(LPREFIX, Appt_AppointmentsPageController.class.getName(), errDetails); // SO-41 END
        }
    }

    public String getJsonArgs(Map<String, Object> parametersMap) 
    {
        System.debug('params: ' + parametersMap + '');

        // get JSON string from key
        for(String key: parametersMap.keyset()){
            System.debug('key: ' + key);
            System.debug('key param: ' + parametersMap.get(key));
            
            if (key.equalsIgnoreCase(JSON_ARGS)){
                //jsonSerializeTest = JSON.serialize(parametersMap.get(key));

                String paramMapString = parametersMap.get(key)+'';
                paramMapString = paramMapString.replace('\\"', 'in.');
                paramMapString = paramMapString.remove('\'');
                paramMapString = paramMapString.remove('%27');
                return paramMapString;
            }
        }
        return '';
    }

    public String getFirstKey(Set<String> parametersKeySet) 
    {
        System.debug('parametersKeySet: ' + parametersKeySet + '');
        List<String> invalidKeys = new List<String> { 'cshc', 'inst', 'url', 'sid', 'originalRequestIsPost', 'RSID', 'SUORG' };

        // get JSON string from key
        for(String key: parametersKeySet){
            System.debug('key: ' + key);
            
            
            if (key.length() > 0 && !invalidKeys.contains(key)){
                //jsonSerializeTest = JSON.serialize(key);
                return key;
            }
        }
        return '';
    }

    public void processJson(String jsonString) 
    {
        if (jsonString == null || jsonString == '') {
            System.debug('No JSON found - exiting processJson method');
            return;
        }


        // decode the json string (this is a catch all since the payload being passed in encoded from the JXBrowser)
        jsonString = EncodingUtil.urlDecode(jsonString, 'UTF-8');

        // get the action value
        Map<String,Object> parsedJson = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        System.debug(parsedJson);
        System.debug(parsedJson.get('action'));
        if (parsedJson.get('action') != null && parsedJson.get('action') != '') action = String.valueOf(parsedJson.get('action'));
        // else {
        //     String newJsonString = JSON.serialize(jsonString);
        //     jsonString = newJsonString;
        //     Map<String,Object> newparsedJson = (Map<String,Object>) JSON.deserializeUntyped(jsonString);

        //     if (newparsedJson.get('action') != null && newparsedJson.get('action') != '') action = String.valueOf(newparsedJson.get('action'));

        // }
    }

    public void logInput() {
        if (intMessage!= null) upsert intMessage;
    }
}