public class InmomentAPIUtility
{    
    @future(callout=true)
    public static void getAuthToken(){ 
        InmomentSetting__c config = InmomentSetting__c.getOrgDefaults();
        String endPoint = config.AuthUrl__c;
        
        String body = 'grant_type=password&client_id='+config.Client_Id__c+
                      '&client_secret='+config.Client_Secret__c+
                      '&username='+config.Username__c+
                      '&password='+config.Password__c;
        
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        
        Http http = new Http();
        request.setEndPoint(endPoint);
        request.setHeader('Content-Type' , 'application/x-www-form-urlencoded');
        request.setMethod('POST');
        request.setBody(body);
        
        response = http.send(request);
        
        if(response.getStatusCode() == 200 && response.getBody()!= null)
        {
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug('m ::::::'+ m.get('access_token'));
            
            config.Access_Token__c = (String) m.get('access_token');
            update config;
            
            //return String.valueOf(m.get('access_token'));
        }
        else{
            //return 'Error: Invalid Credentials.';
        }
    }
    
    @future(callout=true)
    public static void sendSurvey(String contactId, String surveyType, String surveyName){ 
        sendInmomentSurvey(contactId, surveyType, surveyName);
    }
    
    public static void sendInmomentSurvey(String contactId, String surveyType, String surveyName){ 
        InmomentSetting__c config = InmomentSetting__c.getOrgDefaults();
        
        List<Contact> contactList = [SELECT Id, FirstName, LastName, Email, AccountId, Account.Name, Account.Owner.Name,
                                     Account.ECC_Account_Number__c, Phone, MobilePhone, Account.ShippingStreet, 
                                     Account.AccountNumber, Account.Email__c, Survey_Response__c, Survey_Request__c,
                                     Account.ShippingCity, Account.ShippingState, Account.ShippingCountry, 
                                     Account.ShippingPostalcode, MailingPostalCode
                                     FROM Contact 
                                     WHERE Id =: contactId];
        
        String accessToken = config.Access_Token__c;
        
        String endPoint = config.SurveyURL__c;
        
        SurveyWrapper req = new SurveyWrapper();
        req.email = contactList[0].Email;
        
        if(ATZipCodes__c.getAll().get(contactList[0].Account.ShippingPostalcode) != null)
            req.gatewayAlias = config.AT_Gateway_Alias__c;
        else if(ATZipCodes__c.getAll().get(contactList[0].MailingPostalCode) != null)
            req.gatewayAlias = config.AT_Gateway_Alias__c;
        else
            req.gatewayAlias = config.DT_Gateway_Alias__c;
        
        List<KeyValueWrapper> mergeBindings = new List<KeyValueWrapper>();
        mergeBindings.add(new KeyValueWrapper('firstName', contactList[0].FirstName));
        
        req.mergeBindings = mergeBindings;
        
        List<KeyValueWrapper> parameters = new List<KeyValueWrapper>();
        parameters.add(new KeyValueWrapper('sapID', contactList[0].Account.ECC_Account_Number__c));
        parameters.add(new KeyValueWrapper('salesPersonName', ''));
        parameters.add(new KeyValueWrapper('contactID', contactList[0].Id));
        parameters.add(new KeyValueWrapper('firstName', contactList[0].FirstName));
        parameters.add(new KeyValueWrapper('lastName', contactList[0].LastName));
        parameters.add(new KeyValueWrapper('homePhone', contactList[0].Phone));
        parameters.add(new KeyValueWrapper('mobilePhone', contactList[0].MobilePhone));
        parameters.add(new KeyValueWrapper('workPhoneNumber', ''));
        parameters.add(new KeyValueWrapper('addressLine1', contactList[0].Account.ShippingStreet));
        parameters.add(new KeyValueWrapper('addressLine2', ''));
        parameters.add(new KeyValueWrapper('cityName', contactList[0].Account.ShippingCity));
        parameters.add(new KeyValueWrapper('districtName', ''));
        parameters.add(new KeyValueWrapper('regionName', ''));
        parameters.add(new KeyValueWrapper('postalCode', contactList[0].Account.ShippingPostalcode));
        parameters.add(new KeyValueWrapper('email', contactList[0].Email));
        //parameters.add(new KeyValueWrapper('transactionDate', Datetime.now().addDays(-1).format('MM/dd/YYYY')));
        //parameters.add(new KeyValueWrapper('transactionTime', '17:30'));
        parameters.add(new KeyValueWrapper('transactionNumber', ''));
        parameters.add(new KeyValueWrapper('appointment', ''));
        parameters.add(new KeyValueWrapper('tire', ''));
        parameters.add(new KeyValueWrapper('repair', ''));
        parameters.add(new KeyValueWrapper('wheel', ''));
        parameters.add(new KeyValueWrapper('balance', ''));
        parameters.add(new KeyValueWrapper('rotation', ''));
        parameters.add(new KeyValueWrapper('certificate', ''));
        parameters.add(new KeyValueWrapper('promo', ''));
        parameters.add(new KeyValueWrapper('storeCode', ''));
        parameters.add(new KeyValueWrapper('salesPersonId', ''));
        parameters.add(new KeyValueWrapper('surveyType', surveyType));
        parameters.add(new KeyValueWrapper('gatewayAlias', req.gatewayAlias));
        parameters.add(new KeyValueWrapper('accountName', contactList[0].Account.Name));
        parameters.add(new KeyValueWrapper('accountOwner', contactList[0].Account.Owner.Name));
        parameters.add(new KeyValueWrapper('accountNumber', contactList[0].Account.AccountNumber));
        parameters.add(new KeyValueWrapper('accountEmail', contactList[0].Account.Email__c));
        parameters.add(new KeyValueWrapper('fleetSpecialist', ''));
        parameters.add(new KeyValueWrapper('businessLocated', ''));
        parameters.add(new KeyValueWrapper('paymentTypes', ''));
        parameters.add(new KeyValueWrapper('numberOfFleetVehicles', ''));
        parameters.add(new KeyValueWrapper('servicesSignedUpFor', ''));
        parameters.add(new KeyValueWrapper('industryKeys', ''));
        parameters.add(new KeyValueWrapper('transactionStoreName', ''));
        parameters.add(new KeyValueWrapper('transactionInvoiceNumber', ''));
        parameters.add(new KeyValueWrapper('sfAccountID', contactList[0].AccountId));
        
        req.parameters = parameters;
        
        String body = JSON.serialize(req);
        System.debug('body :::::' + body);
        
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        
        Http http = new Http();
        request.setEndPoint(endPoint);
        request.setHeader('Content-Type' , 'application/json');
        request.setHeader('Authorization' , 'OAuth ' + accessToken);
        request.setMethod('POST');
        request.setBody(body);
        
        response = http.send(request);
        
        System.debug('response.getBody() :::::' + response.getBody());
        
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Boolean succeeded = (Boolean) m.get('succeeded');
        
        contactList[0].Survey_Request__c = body;
        
        if(contactList[0].Survey_Response__c != null)
            contactList[0].Survey_Response__c = response.getBody() + '\n\n' + contactList[0].Survey_Response__c;
        else
            contactList[0].Survey_Response__c = response.getBody();
            
        update contactList;
        
        FeedItem post = new FeedItem();
        post.ParentId = contactList[0].Id;
        
        if(succeeded)
            post.Body = surveyName + ' survey successfully sent on ' + Datetime.now().format() + '.';
        else
            post.Body = surveyName + ' survey sent failed.';
            
        insert post;
    }
    
    /*
    {
       "email": "someemail@somedomain.com",
       "gatewayAlias": "someGatewayAlias",
       "mergeBindings": [
          {
             "key": "mergeBindingKey",
             "value": "mergeBindingValue"
          }
       ],   
       "parameters": [
          {
             "key": "parameterKey",
             "value": "parameterValue"
          },
          {
             "key": "anotherParameterKey",
             "value": "anotherParameterValue"
          }
       ]   
    }
    
    {
       "email": "someemail@somedomain.com",
       "gatewayAlias": "Fleet_DT_Email",
       "mergeBindings": [
          {
             "key": "firstName",
             "value": "<SFDC-Contact-FirstName-String-Value-Placeholder>"
          }
       ],  
       "parameters": [
          {
             "key": "accountID",
             "value": "<SFDC-AccountID-String-Value-Placeholder>"
          },
          {
             "key": "salesPersonName",
             "value": "<SFDC-SalesPersonName-String-Value-Placeholder>"
          },
                .
                .
                .
          ]
    }
    */
    
    public class SurveyWrapper
    {
        public String email;
        public String gatewayAlias;
        public List<KeyValueWrapper> mergeBindings;
        public List<KeyValueWrapper> parameters;
    }
    
    public class KeyValueWrapper
    {
        public String key;
        public String value;
        
        public KeyValueWrapper(String key,
                               String value)
        {
            this.key = key;
            this.value = value;
        }
    }
}