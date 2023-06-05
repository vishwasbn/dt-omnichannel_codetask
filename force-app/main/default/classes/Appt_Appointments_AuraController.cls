public without sharing class Appt_Appointments_AuraController {
	public static String incomingParameters { get; set; } // JSON serialized map
    public static String rawIncomingParameters {get; set; } // parameters + ''
    public static String jsonString { get; set; } // json
    public static String action { get; set; }
    public static final String JSON_ARGS = 'c__jsonArgs';

    public static Int_Message__c intMessage { get; set; }

    //public String jsonSerializeTest { get; set; }
    @auraEnabled
    public static Wrapper callOnLoading(String jsonBuild) {
        jsonBuild = jsonBuild.replace('"','\'');
        system.debug('jsonBuild --- '+jsonBuild);
        intMessage = new Int_Message__c(Status__c = 'Pending', Type__c = 'apptPageIncoming');
        system.debug(json.serialize(intMessage));
        incomingParameters = '';
        jsonString = '';
        action = '';
        
        try {
            // 0. Get Raw form input
            incomingParameters = jsonBuild;
            System.debug('appointmentsPageController -- getParams() = ' +jsonBuild);
            rawIncomingParameters = jsonBuild+'';
            
            // 1. Search for expected form value
            Map<String, object> parametersMap=new Map<String, object>();
            if (jsonBuild != null 
                && jsonBuild.length() > 0)
            {
                parametersMap =(Map<String, Object>) JSON.deserializeUntyped(jsonBuild);
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
            wrapper wrap = new wrapper(jsonString, action);
            return wrap;
            // update intMessage;

        } catch (exception e) {
            intMessage.Status__c = 'Error';
            intMessage.Salesforce_Error__c = e.getMessage();
            if (intMessage.Payload__c == null || intMessage.Payload__c == '' && rawIncomingParameters != null) intMessage.Payload__c = 'Raw Paramaters: ' +rawIncomingParameters;
        }
        return null;
    }

    public static String getJsonArgs(Map<String, Object> parametersMap) 
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

    public static String getFirstKey(Set<String> parametersKeySet) 
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

    public static void processJson(String jsonString) 
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

    public static void logInput() {
        if (intMessage!= null) upsert intMessage;
    }
    
    @auraEnabled
    public static String callConstructor(){
        return 'jsonString';
        //Appt_AppointmentsPageController app = new Appt_AppointmentsPageController();
    }
    public class wrapper{
        @auraEnabled
        public String jsonString;
        @auraEnabled
        public String action;
        
        public wrapper(String jsonString, String action){
            this.jsonString = jsonString;
            this.action = action;
        }
        
    }
}