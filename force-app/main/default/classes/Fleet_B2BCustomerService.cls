/**
  Modified date: 23/01/2023
  Modified by: Ritika Sharma
  User story: SF-915
 * */
@RestResource(urlMapping='/b2bcustomer')
global class Fleet_B2BCustomerService
{
    public static String lprefix = 'FLEET_B2B_SERVICE:';

    @HttpPut
    //---Public service to recieve new B2BCustomerData
    global static B2BReponse updateB2BCustomerData()
    {
        String payload = RestContext.request.requestBody != null ? RestContext.request.requestBody.toString() : '';
        system.debug('@@@ put runs: '+ payload);
        return updateB2BCustomerDataBody(payload);
    }

    //---Primary method for handing incoming updates
    public static B2BReponse updateB2BCustomerDataBody(String payload)
    {
        //---Immediately record the incoming call
        Int_Message__c intMsg = new Int_Message__c();
        intMsg.Type__c = Int_Values.TYPE_B2BCUSTOMER_INCOMING;
        intMsg.Payload__c = payload;
        intMsg.Status__c = Int_Values.STATUS_PENDING;
        insert intMsg;
        
        //---Overall try/catch for any unhandled exceptions
        try 
        {
            processIncomingUpdate(payload, intMsg);
        } 
        catch (Exception ex) 
        {
            setSFError(intMsg, 'updateB2BCustomerDataBody', 'Unhandled Exception :' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }

        B2BReponse b2bResp = new B2BReponse();

        //---Check for Error or if success
        /***********************************************************************/
        //Added this additional step to ignore the cyclic error issue with ShippingState and Duplicate Contact creation error conditions
        boolean byPassError = false;
        if (intMsg.Status__c == Int_Values.STATUS_ERROR && Boolean.valueOf(Label.Fleet_Ignore_Cyclic_Errors)){
            if(intMsg.Salesforce_Error__c.contains('FIELD_INTEGRITY_EXCEPTION') ||
               intMsg.Salesforce_Error__c.contains('DUPLICATES_DETECTED')){
                   byPassError = true;
            }            
        }    
        /***********************************************************************/
        if (intMsg.Status__c == Int_Values.STATUS_ERROR)
        {
            if(!byPassError){
	            b2bResp.Status = 'error';
    	        b2bResp.Message = intMsg.Salesforce_Error__c;
            }else{
	            b2bResp.Status = 'success';
    	        b2bResp.Message = 'Update bypassed';
            }
            intMsg.Response__c = '' + b2bResp;
            System.debug( lprefix + 'Error Found: ' +  intMsg.Salesforce_Error__c);
        }
        else 
        {
            intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;
            intMsg.Submitted_Date__c = DateTime.now();

            b2bResp.Status = 'success';
            b2bResp.Message = 'Update successfull';

            intMsg.Response__c = '' + b2bResp;

            System.debug( lprefix + 'Successful Update');
        }

        System.debug( lprefix + 'Updating IntMessage: ' + intMsg);
        update intMsg;

        return b2bResp;
    }

    //---Set that there was a Salesforce Error
    public static void setSFError(Int_Message__c intMsg, String codeLocation, String error)
    {
        intMsg.Status__c = Int_Values.STATUS_ERROR;
        intMsg.Salesforce_Error__c = codeLocation + ':' + error;
        System.debug( lprefix + intMsg.Salesforce_Error__c);       
    }

    //---Process the incoming update
    public static void processIncomingUpdate(String payload, Int_Message__c intMsg)
    {
        if (payload == null || payload == '')
        {
            intMsg.Status__c = Int_Values.STATUS_ERROR;
            intMsg.Salesforce_Error__c = 'No payload found, cannot parse';
            return;
        }

        Fleet_B2BCustomerModel b2bModel = null;
   
        Boolean hasError = false;
        String errorMessage = '';

        //---Parse Message (in Try/Catch for parse errors)
        try 
        {
            b2bModel = Fleet_B2BCustomerModel.parse(payload);
        } 
        catch (Exception ex) 
        {
            setSFError(intMsg, 'processIncomingUpdate', 'Error parsing payload ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            return;
        }

        //---Update the Account Record
        String acctId = processAccountData( b2bModel, intMsg);
    
        if (intMsg.Status__c == Int_Values.STATUS_ERROR) return;

        //---Update the Contact Records
        processContactData( b2bModel, intMsg, acctId);
    }

    //---Process Account Data
    public static String processAccountData(Fleet_B2BCustomerModel b2bModel, Int_Message__c intMsg)
    {
        List<Fleet_State_Abbrev__mdt> stateCompareList = [ SELECT State_Abbrev__c, State_Output__c FROM Fleet_State_Abbrev__mdt];
        Account currAcct = null;
        String eccId = b2bModel.eccId;
  
        //---Load Records (in Try/Catch for soql errors)
        try 
        {   
            List<Account> acctList = new List<Account>();

            //---Looup by Salesforce Id
            if (b2bModel.salesforceId != null && b2bModel.salesforceId != '')
            {
                //Added PhoneExtension in the query for bi-directional syn
                acctList = [SELECT Id, Name, ECC_Account_Number__c, Fleet_Specialist__c, Legal_Name__c, Payment_Key_Terms__c, Fleet_POS_Notes__c, Fleet_Private_Notes__c, Fleet_Public_Notes__c, Account_Type__c, Accounting_Clerk__c, Credit_Limit__c, ECC_Corporate_Group__c, Fleet_Use_Certificates__c, Phone,Phone_Extension__c, PO_Required__c, Invoice_Copy_Sent__c, Payment_Type__c, Tax_Classification__c, Fleet_Invoice_AR_Fields__c, ECC_AutoIntegrate__c, ShippingCountryCode, ShippingStateCode, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingState, ECC_Industry_Key__c, ECC_Billing_Block_Sale_Area__c, ECC_Posting_Block_Company_Code__c, ECC_State__c, ECC_Country__c, ECC_Account_Manager__c, ECC_Account_Company__c, ECC_Street_4__c, SAP_Created_Date__c FROM Account WHERE Id = :b2bModel.salesforceId];
            }

            //---Lookup by SAP Id
            if (acctList == null || acctList.size() == 0)
            {        
                //---Strip leading zeros for alternate compare in salesforce        
                String eccIdNoZeros = getECCIdNoZeros(eccId);
                //Added PhoneExtension in the query for bi-directional syn
                acctList = [SELECT Id, Name, ECC_Account_Number__c, Fleet_Specialist__c, Legal_Name__c, Payment_Key_Terms__c, Fleet_POS_Notes__c, Fleet_Private_Notes__c, Fleet_Public_Notes__c, Account_Type__c, Accounting_Clerk__c, Credit_Limit__c, ECC_Corporate_Group__c, Fleet_Use_Certificates__c, Phone,Phone_Extension__c, PO_Required__c, Invoice_Copy_Sent__c, Payment_Type__c, Tax_Classification__c, Fleet_Invoice_AR_Fields__c, ECC_AutoIntegrate__c, ShippingCountryCode, ShippingStateCode, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingState, ECC_Industry_Key__c, ECC_Billing_Block_Sale_Area__c, ECC_Posting_Block_Company_Code__c, ECC_State__c, ECC_Country__c, ECC_Account_Manager__c, ECC_Account_Company__c, ECC_Street_4__c, SAP_Created_Date__c FROM Account WHERE ECC_Account_Number__c = :eccId OR ECC_Account_Number__c = :eccIdNoZeros];
            }

            if (acctList != null && acctList.size() > 0) currAcct = acctList[0];
        } 
        catch (Exception ex) 
        {
            setSFError(intMsg, 'processAccountData1','Error Retrieving matching records for ECC Id' + eccId + ' ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            return null;
        }

        if (currAcct == null)
        {
            intMsg.Status__c = Int_Values.STATUS_ERROR;
            intMsg.Salesforce_Error__c = 'Cannot find existing Account for ECC Id' +eccId; 
            return null;
        }

        //---Map to an update Account Object
        intMsg.Object_Type__c = 'Account';
        intMsg.RecordId__c = currAcct.Id;

        //---Find a matching Fleet specailist for the account manager user
        List<user> userList = new List<user>();
        User fleetSpecialist = new User();

        if(b2bModel.accountManager != null && b2bModel.accountManager != '')
        {
            userList = [SELECT Id, Fleet_ECC_Key__c FROM User WHERE Fleet_ECC_Key__c = :b2bModel.accountManager];
            if(userList.size() > 0){
                fleetSpecialist = userList[0];
                System.debug(fleetSpecialist );
            }              
        }
        
        //---Check if this is the first synch from ECC for this Account
        Boolean isFirstSynch = (currAcct.ECC_Account_Number__c == null || currAcct.ECC_Account_Number__c == '');

        Account updateAcct = Fleet_B2BCustomerModel.buildUpdateAccount(currAcct, b2bModel, fleetSpecialist.id, stateCompareList);
        
        if (updateAcct != null)
        {
            System.debug( lprefix + 'Have created an update Account with the following values :' + updateAcct);

            try 
            {
                update updateAcct;
            } 
            catch (Exception ex) 
            {
                setSFError(intMsg, 'processAccountData2','Error updating Account record for ECC Id' + eccId + ' ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                return null;
            }
        }
        else 
        {
            System.debug( lprefix + 'All field values match, no need to update Account');
        }

        //---If this is the first Synch, then send outbound messages
        if (isFirstSynch)
        {
            System.debug( lprefix + 'This is the first synch for Account:' + currAcct.Id + ' with ECC Id: ' + updateAcct.ECC_Account_Number__c + ' sending Account Notes update and any preexisting contacts');

            Account firstSynchAcct = new Account();
            firstSynchAcct.Id = currAcct.Id;
            firstSynchAcct.ECC_Account_Number__c = updateAcct.ECC_Account_Number__c;
            firstSynchAcct.Fleet_Public_Notes__c = currAcct.Fleet_Public_Notes__c;
            firstSynchAcct.Fleet_Private_Notes__c = currAcct.Fleet_Private_Notes__c;
        
            Fleet_AccountTriggerHandler.sendOutboundForAccountECCSynch( firstSynchAcct);
            Fleet_ContactTriggerHandler.sendOutboundForAccountECCSynch( firstSynchAcct.Id);
        }

        return currAcct.Id;
    }

    //---Process Account Data
    public static void processContactData(Fleet_B2BCustomerModel b2bModel, Int_Message__c intMsg, String acctId)
    {
        if (b2bModel.contacts == null || b2bModel.contacts.size() == 0)
        {
            System.debug( lprefix + 'No contacts found in the payload, no Contact updates necessary');
            return;
        }

        Id b2bContactRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();
        List<Contact> currContactList = new List<Contact>();
       
        //---Load Records (in Try/Catch for soql errors)
        try 
        {   
            //---Get the list of Contacts
            //Added PhoneExtension in the query for bi-directional syn
            currContactList = [SELECT Id, FirstName, LastName, Phone,Phone_Extension__c,Send_Invoice_Receipt__c,Is_Alternate_Contact__c, Title, Email, Department, ECC_Contact_Person_Id__c, ECC_Contact_Person_Department__c, Fleet_SPOC_Purchasing__c, ECC_Customer_Reference_Number__c, ECC_Is_Primary_Contact__c, ECC_Create_Values__c, ECC_Pending_Fields__c FROM Contact WHERE AccountId = :acctId AND RecordTypeId = :b2bContactRT];
        } 
        catch (Exception ex) 
        {
            setSFError(intMsg, 'processContactData1','Error Retrieving matching Contact records for Account SF Id' + acctId + ' ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            return;
        }

        //----Create the insert and update list
        List<Contact> updateContactList = new List<Contact>();
        List<Contact> insertContactList = new List<Contact>();
        
		/*
        Map<String, Id> contactNameIdMap = new Map<String, Id>();
        for(Contact con : currContactList){
            contactNameIdMap.put(con.FirstName.toUpperCase()+' '+con.LastName.toUpperCase(), con.Id);
        }
        */
        
        //---Scan the contacts passed in
        for (Fleet_B2BCustomerModel.Contacts b2bCRow : b2bModel.contacts)
        {
            Contact updateContact = Fleet_B2BCustomerModel.buildUpdateContact(currContactList, b2bCRow, b2bContactRT, acctId);
            if (updateContact != null){
                if(updateContact.Id != null) updateContactList.add(updateContact);
                else insertContactList.add(updateContact);
            }
        }

        if (updateContactList.size() > 0 || insertContactList.size() > 0)
        {
            Fleet_ContactTriggerHandler.stopECCCall = true;
            
            if(updateContactList.size() > 0){
            System.debug( lprefix + 'Updating the following Contacts :' + updateContactList);

            try 
            {
                update updateContactList;
            } 
            catch (Exception ex) 
            {
                setSFError(intMsg, 'processContactData1','Error updating Contact records for Account Id' + acctId + ' ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            }
            }
            
            if(insertContactList.size() > 0){
            System.debug( lprefix + 'Inserting the following Contacts :' + insertContactList);

            try 
            {
                insert insertContactList;
            } 
            catch (Exception ex) 
            {
                setSFError(intMsg, 'processContactData1','Error inserting Contact records for Account Id' + acctId + ' ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            }
            }    

        }
        else 
        {
            System.debug( lprefix + 'All field values match for all contacts, no need to update Contacts');
        }
    }

    //---Get the Account by SAP Number  - This is a synchronous callout method  PA
     public static boolean getB2BCustomerData(String sapAccountId)
     {
        String eccId = getECCIdPadded(sapAccountId);

        String endUrl = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_B2B_CUSTOMER_GET_URL);
        endUrl += eccId;

         Int_Message__c intMsg = new Int_Message__c(Type__c=Int_Values.TYPE_B2BCUSTOMER_OUTBOUND_REQUEST, Status__c=Int_Values.STATUS_PENDING, Url__c=endUrl);
 
         HttpRequest req = buildB2BHttpReq( endUrl);
 
         String body = Fleet_IntegrationUtil.getRequestBody(req, intMsg);
         upsert intMsg;

         if (body == null)
         {
             System.debug( lprefix + 'Request for B2B data record FAILED');
             return false;
         } 

         //---Set the flag to prevent feedback loop (inbound leading to outbound)
         Fleet_ECCService.stopOutboundUpdate = true;

          //---Overall try/catch for any unhandled exceptions
        try 
        {
            processIncomingUpdate(body, intMsg);
        } 
        catch (Exception ex) 
        {
            setSFError(intMsg, 'getB2BCustomerData','Unhandled Exception :' + ex.getMessage() + ' ' + ex.getStackTraceString());
            return false;          
        }

        //---Check for Error or if success
        if (intMsg.Status__c == Int_Values.STATUS_ERROR)
        {
            System.debug( lprefix + 'Error Found: ' +  intMsg.Salesforce_Error__c);
        }
        else 
        {
            intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;
            intMsg.Submitted_Date__c = DateTime.now();
         
            System.debug( lprefix + 'Successful Update');
        }

        System.debug( lprefix + 'Updating IntMessage: ' + intMsg);
        update intMsg;

        return true;
     }

     //---Build the B2B Http Request
    public static HttpRequest buildB2BHttpReq(String endUrl)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:FleetExperienceAPI' + endUrl);
        req.setHeader('Content-Type','application/json');
        req.setMethod('GET');
        req.setHeader('dtSourceSystem', Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_DT_SOURCE_SYSTEM));  
        req.setHeader('dtSourceSubsystem', Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_DT_SOURCE_SUBSYSTEM) ); 
        req.setHeader('dtRequestIdentifier', Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_DT_REQUEST_IDENTIFIER));  

        return req;
    }

    global class B2BReponse
    {
        public String Status;
        public String Message;
    }

    //---Strip off leading zeros
    public static string getECCIdNoZeros(String eccId)
    {
        //---Strip leading zeros for alternate compare in salesforce        
        String eccIdNoZeros = eccId;
        while(eccIdNoZeros.startsWith('0') && eccIdNoZeros.length() > 1){
            eccIdNoZeros = eccIdNoZeros.substring(1,eccIdNoZeros.length());
        }
          
        return eccIdNoZeros;
    }

    //---Add the necessary leading zeros
    public static string getECCIdPadded(string eccId)
    {
        if (eccId == null) return '';
        String returnVal = eccId.leftPad(10, '0');
        return returnVal;
    }

    public static void testCallGetAccount()
    {
        String accountId = '21782';
        getB2BCustomerData(accountId);
    }
}