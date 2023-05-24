public without sharing class Appt_AppointmentDataProcessUtil {

    public static final String lprefix = 'Appt_AppointmentDataProcessUtil: ';
    public static final String ID_STRING_NOTNULL_NOTUSED = 'NotNullNotUsedId';

    public static Appt_CreateAppointmentServiceModel processRecord = new Appt_CreateAppointmentServiceModel();

    // *********************** Start Vehicle Process Methods ***********************
    // Reusable method that can process vehicle data
    public static Appt_CreateAppointmentServiceModel processVehicleData(Appt_CreateAppointmentServiceModel serviceModel){
        System.debug(lprefix +' Start - Appt_CreateAppointmentServiceModel');
        processRecord = serviceModel;
        runVehicleProccess();
        return processRecord;
    }

    // Overloaded method to process the Appt_UpdateAppointmentServiceModel
    public static Appt_UpdateAppointmentServiceModel processVehicleData(Appt_UpdateAppointmentServiceModel serviceModel){        
        System.debug(lprefix +' Start - Appt_UpdateAppointmentServiceModel');
        processRecord = (Appt_CreateAppointmentServiceModel) serviceModel;                
        runVehicleProccess();
        serviceModel.assetId = processRecord.assetId;
        return serviceModel;
    }

    public static void runVehicleProccess(){

        System.debug(lprefix +' Start - ProcessVehicleData');
        System.debug(processRecord);        

        Boolean skip = false;
        // Only run process if an editable field is found on the model
        if(checkVehicleFields()){
            System.debug(lprefix +' -- Some Fields found to proccess');

            // get existing vehicle info from salesforce
            Asset existingVehicle = checkForExistingVehicle(processRecord.hybrisCustomerVehicleId, processRecord.posCustomerVehicleId, processRecord.accountId);

            // check for field updates
            if(existingVehicle != null){

                // set found vehicle to the processed Record for future updates to have the correct vehicle id
                processRecord.assetId = existingVehicle.id;

                // check for updates to vehicle fields
                if(!checkForExistingVehicleChanges(existingVehicle)){  
                    System.debug(lprefix +' -- No field changes need for existing vehicle');                  
                    skip = true;
                }
            }

            if(skip == false){
                // This check for an existing vehicle match
                if(processRecord.assetId != null){
                    updateVehicle();                
                }else{              
                    createVehicle();
                }
            }            
        }

    }

    // process to update an existing vehicle record
    public static void updateVehicle(){
        System.debug(processRecord.year);
        Asset updateVehicle = buildVehicle();        
        updateVehicle.id = processRecord.assetId;
        System.debug(lprefix +' --  update vehicle');
        System.debug(updateVehicle);
        update updateVehicle;
        System.debug(lprefix +' -- update success');
        processRecord.assetId = updateVehicle.id;

    }

    // process to create a new vehicle reocord
    public static void createVehicle(){

        Asset insertVehicle = buildVehicle();
        System.debug(lprefix +' -- insert vehicle');
        System.debug(insertVehicle);
        insert insertVehicle;
        System.debug(lprefix +' -- insert success');
        processRecord.assetId = insertVehicle.id;
    }

    public static Asset buildVehicle(){
        System.debug(lprefix +' -- build vehicle fields ');        

        Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
        if(processRecord.trimId != null || processRecord.vehicleId != null){
            getReferenceInfo();
        }
        
        // build vehicle name with a default of Appointment Vehicle
        String vehicleName = 'Appointment Vehicle';
        if(processRecord.year != null && processRecord.make != null && (processRecord.model != null && processRecord.model != '')) {
            vehicleName = processRecord.year + ' ' + processRecord.make + ' ' + processRecord.model;
        } else if(processRecord.year != null && (processRecord.model != null && processRecord.model != '')){
            vehicleName = processRecord.year +  ' ' + processRecord.model;
        } else if(processRecord.model != null && processRecord.model != '') {
            vehicleName = processRecord.model;
        }

        Asset vehicle = new Asset(Name = vehicleName);
        vehicle.RecordTypeId = vehRecordTypeId;

        // check for individual field updates and add them to the vehicle if they have changed
        if(processRecord.accountId != null){vehicle.accountId = processRecord.accountId;}
        if(processRecord.contactId != null){vehicle.contactId = processRecord.contactId;}
        if(processRecord.posCustomerVehicleId != null){vehicle.POS_Customer_Vehicle_Id__c = processRecord.posCustomerVehicleId;}
        if(processRecord.hybrisCustomerVehicleId != null){vehicle.Hybris_Customer_Vehicle_Id__c = processRecord.hybrisCustomerVehicleId;}
        if(processRecord.year != null){vehicle.Vehicle_Manufacture_Year__c = processRecord.year;}
        if(processRecord.make != null){vehicle.Vehicle_Make__c = processRecord.make;}
        if(processRecord.model != null){vehicle.Vehicle_Model__c = processRecord.model;}
        if(processRecord.assemblyId != null){vehicle.Assembly_Id__c = processRecord.assemblyId;}
        if(processRecord.vehicleId != null){vehicle.Vehicle_Id__c = processRecord.vehicleId;}
        if(processRecord.trimId != null){vehicle.Trim_Id__c = processRecord.trimId;}
        if(processRecord.vehicleClass != null){vehicle.Vehicle_Class__c = processRecord.vehicleClass;}
        if(processRecord.trimName != null){vehicle.Trim_Name__c = processRecord.trimName;}

        return vehicle;
    }

    // query to get vehicle reference information and update the process model
    public static void getReferenceInfo(){        
        System.debug(lprefix +' -- get reference information');    
        // keep the query fast by not using an exclude parameter but also excluding null values
        if(processRecord.trimId == null) {processRecord.trimId = 'invalidId';}
        if(processRecord.vehicleId == null) {processRecord.vehicleId = 'invalidId';}


        List<Reference__c> referenceInfo = [SELECT  Vehicle_Year_Make__r.Vehicle_Year__c, 
                                                    Vehicle_Year_Make__r.Vehicle_Make__c, 
                                                    Trim_Name__c,
                                                    Vehicle_Class__c, 
                                                    Vehicle_Model__c,
                                                    Vehicle_Fitment_Id__c,
                                                    Trim_Id__c,
                                                    Vehicle_Model_Rec_Type__r.Vehicle_Fitment_Id__c,
                                                    Vehicle_Model_Rec_Type__r.Vehicle_Model__c, 
                                                    Vehicle_Model_Rec_Type__r.Vehicle_Class__c, 
                                                    Vehicle_Model_Rec_Type__r.Vehicle_Year_Make__r.Vehicle_Make__c, 
                                                    Vehicle_Model_Rec_Type__r.Vehicle_Year_Make__r.Vehicle_Year__c 
                                                    FROM Reference__c Where Trim_Id__c = :processRecord.trimId OR Vehicle_Fitment_Id__c = :processRecord.vehicleId LIMIT 2];
        
        // loop through vehicle reference data and update vehicle information  
        System.debug(lprefix +' -- Vehicle Reference Search ');    
        System.debug(referenceInfo); 
        

        if(referenceInfo.size() > 0){
            for(Reference__c item: referenceInfo){
                if(item.Trim_Id__c == processRecord.trimId){
                    // Capture full vehicle information if trim id is found
                    processRecord.year = item.Vehicle_Model_Rec_Type__r.Vehicle_Year_Make__r.Vehicle_Year__c;
                    processRecord.make = item.Vehicle_Model_Rec_Type__r.Vehicle_Year_Make__r.Vehicle_Make__c;                    
                    processRecord.model = item.Vehicle_Model_Rec_Type__r.Vehicle_Model__c;
                    processRecord.trimName = item.Trim_Name__c;
                    processRecord.vehicleClass = item.Vehicle_Model_Rec_Type__r.Vehicle_Class__c;
                    processRecord.vehicleId = item.Vehicle_Model_Rec_Type__r.Vehicle_Fitment_Id__c;
                    break;
                } else if (item.Vehicle_Fitment_Id__c == processRecord.vehicleId){
                    // Capture full partial vehicle information if only vehicle id is found
                    processRecord.year = item.Vehicle_Year_Make__r.Vehicle_Year__c;
                    processRecord.make = item.Vehicle_Year_Make__r.Vehicle_Make__c;                    
                    processRecord.model = item.Vehicle_Model__c;
                    processRecord.vehicleClass = item.Vehicle_Class__c;                    
                }
            }
        }  

        // clear invalidIds    
        if(processRecord.trimId == 'invalidId') {processRecord.trimId = null;}
        if(processRecord.vehicleId == 'invalidId') {processRecord.vehicleId = null;}
    }

    
    // Check for an existing vehicle in salesforce
    public static Asset checkForExistingVehicle(String hybrisVehicleId, String posVehicleId, id accountId){
        Asset returnVehicle;
        String hybrisVehicleIdString;
        String posVehicleIdString;

        //-- If not null, make sure no trailing spaces on ID fields. IF NULL, set to unused ID string since null in where clause causes perf issues
        if (hybrisVehicleId != null) {
            hybrisVehicleIdString = hybrisVehicleId.trim();
        } else {
            hybrisVehicleIdString = ID_STRING_NOTNULL_NOTUSED;
        }
        if (posVehicleId != null) {
            posVehicleIdString = posVehicleId.trim();
        } else {
            posVehicleIdString = ID_STRING_NOTNULL_NOTUSED;
        }


        Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
        List<Asset> vehs = [SELECT  Id, 
                                    Assembly_Id__c, 
                                    Vehicle_Manufacture_Year__c, 
                                    Vehicle_Make__c, 
                                    Vehicle_Model__c, 
                                    Trim_Id__c, 
                                    Vehicle_Id__c, 
                                    Vehicle_Class__c 
                            FROM Asset 
                            WHERE RecordTypeId = :vehRecordTypeId AND (POS_Customer_Vehicle_Id__c = :posVehicleIdString
                            OR Hybris_Customer_Vehicle_Id__c = :hybrisVehicleIdString) 
                            AND AccountId = :accountId];

        System.debug(lprefix+'     using Hybris_Customer_Vehicle_Id='+hybrisVehicleIdString+' and POS_Customer_Vehicle_Id='+posVehicleIdString+' Retrieved Vehicle Assets:'+vehs);
        
        if (vehs != null && vehs.size() > 0) {
            returnVehicle = vehs.get(0);
        }

        return returnVehicle;
    }

    // Check for a field to update
    public static Boolean checkVehicleFields(){
        System.debug(lprefix +' Start - check for field Changes');
        if(processRecord.model != null){return true;}
        if(processRecord.posCustomerVehicleId != null){return true;}
        if(processRecord.hybrisCustomerVehicleId != null){return true;}
        if(processRecord.year != null){return true;}
        if(processRecord.make != null){return true;}
        if(processRecord.model != null){return true;}
        if(processRecord.assemblyId != null){return true;}
        if(processRecord.vehicleId != null){return true;}
        if(processRecord.trimId != null){return true;}
        if(processRecord.vehicleClass != null){return true;}     
        System.debug(lprefix +' End - check for field Changes False');
        return false;
    }

    // Check for any changes needed to the existing vehicle record
    public static Boolean checkForExistingVehicleChanges(Asset existingVehicle){
        System.debug(lprefix +' Start - check for existing field Changes');
        if(processRecord.model != existingVehicle.Vehicle_Model__c){return true;}
        if(processRecord.year != existingVehicle.Vehicle_Manufacture_Year__c){return true;}
        if(processRecord.make != existingVehicle.Vehicle_Make__c){return true;}
        if(processRecord.model != existingVehicle.Vehicle_Model__c){return true;}
        if(processRecord.assemblyId != existingVehicle.Assembly_Id__c){return true;}
        if(processRecord.vehicleId != existingVehicle.Vehicle_Id__c){return true;}
        if(processRecord.trimId != existingVehicle.Trim_Id__c){return true;}
        if(processRecord.vehicleClass != existingVehicle.Vehicle_Class__c){return true;}  
        System.debug(lprefix +' End - check for existing  field Changes False');
        return false;
    }
    // *********************** End Vehicle Process Methods ***********************




    // *********************** Start Account Process Methods *******************************************
    // Reusable method that can process Account data
    public static Appt_CreateAppointmentServiceModel processAccountData(Appt_CreateAppointmentServiceModel serviceModel){
        System.debug(lprefix +' processAccountData() ENTRY - Appt_CreateAppointmentServiceModel');
        processRecord = serviceModel;
        runAccountProccess();
        return processRecord;
    }

    // Overloaded method to process the Appt_UpdateAppointmentServiceModel
    public static Appt_UpdateAppointmentServiceModel processAccountData(Appt_UpdateAppointmentServiceModel serviceModel){        
        System.debug(lprefix +' processAccountData() ENTRY  - Appt_UpdateAppointmentServiceModel');
        processRecord = (Appt_CreateAppointmentServiceModel) serviceModel;                
        runAccountProccess();
        serviceModel.accountId = processRecord.accountId;
        serviceModel.contactId = processRecord.contactId;
        serviceModel.posCustomerId = processRecord.posCustomerId;
        serviceModel.hybrisCustomerId = processRecord.hybrisCustomerId;
        serviceModel.customerGuid = processRecord.customerGuid;
        return serviceModel;
    }

    public static void runAccountProccess(){

        System.debug(lprefix +'runAccountProccess() ENTRY');
        System.debug(processRecord);        

        Boolean skip = false;
        // Only run process if an editable field is found on the model
        if(checkAccountFields()){
            System.debug(lprefix +' -- Some Account Fields found to proccess');

            // get existing Account info from salesforce
            Account existingAccount = checkForExistingAccount(processRecord.hybrisCustomerId, processRecord.posCustomerId, processRecord.customerGuid, processRecord.accountId);

            // check for field updates
            if(existingAccount != null){

                // set found Account to the processed Record for future updates to have the correct Account id
                processRecord.accountId = existingAccount.Id;
                processRecord.contactId = existingAccount.PersonContactId;

                //-- if opt in fields are null on record, populate from the existing account
                if (processRecord.textOptIn == null) processRecord.textOptIn = existingAccount.Appt_SMS_Opt_In__pc;
                if (processRecord.emailAddressOptIn == null) processRecord.emailAddressOptIn = existingAccount.Appt_Email_Opt_In__pc;

                // check for updates to Account fields
                if(!checkForExistingAccountChanges(existingAccount)){  
                    System.debug(lprefix +' -- No field changes need for existing Account');                  
                    skip = true;
                }
            }

            if(skip == false){
                // This check for an existing Account match
                if(processRecord.accountId != null){
                    updateAccount();                
                }else{              
                    createAccount();
                }
            }            
        }
    }

    // process to update an existing Account record
    public static void updateAccount(){
        System.debug(lprefix + ' updateAccount() ENTRY - AccountId='+processRecord.accountId);
        Account updateAccount = buildAccount();        
        updateAccount.id = processRecord.accountId;
        System.debug(lprefix +' --  update Account:'+ updateAccount);
        update updateAccount;
        System.debug(lprefix +' -- update Account success, updateAccount.id='+updateAccount.id+', updateAccount.PersonContactId='+updateAccount.PersonContactId+', updateAccount.RecordTypeId='+updateAccount.RecordTypeId);
        processRecord.accountId = updateAccount.id;
        processRecord.contactId = updateAccount.PersonContactId;
    }

    // process to create a new Account reocord
    public static void createAccount(){
        System.debug(lprefix + ' createAccount() ENTRY');
        Account insertAccount = buildAccount();
        System.debug(lprefix +' -- insert Account:'+insertAccount);
        insert insertAccount;
        System.debug(lprefix +' -- insert Account success, insertAccount.id='+insertAccount.id+', insertAccount.PersonContactId='+insertAccount.PersonContactId+', insertAccount.RecordTypeId='+insertAccount.RecordTypeId);
        processRecord.accountId = insertAccount.id;
        processRecord.contactId = insertAccount.PersonContactId;
    }

    public static Account buildAccount(){
        System.debug(lprefix +' -- buildAccount() ENTRY - processRecord:'+processRecord);        

        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

        Account acnt = new Account(RecordTypeId = personAccountRecordTypeId);
        
        // check for individual field updates and add them to the Account if they are not null
        if (processRecord.posCustomerId != null) acnt.POS_Customer_Id__c = processRecord.posCustomerId.trim();
        if (processRecord.hybrisCustomerId != null) acnt.Hybris_Customer_Id__c = processRecord.hybrisCustomerId.trim();
        if (processRecord.customerGuid != null) acnt.GUID__c = processRecord.customerGuid.trim();

        if (processRecord.firstName != null) acnt.FirstName = processRecord.firstName;
        if (processRecord.lastName != null) acnt.LastName = processRecord.lastName;
        if (processRecord.emailAddress != null) {
            acnt.Email__c = processRecord.emailAddress;
            acnt.PersonEmail = processRecord.emailAddress;
        }
        if (processRecord.homePhoneNumber != null) acnt.PersonHomePhone = processRecord.homePhoneNumber;
        if (processRecord.mobilePhoneNumber != null) acnt.PersonMobilePhone = processRecord.mobilePhoneNumber;
        if (processRecord.workPhoneNumber != null) acnt.Phone = processRecord.workPhoneNumber;

        if (processRecord.address1 != null && processRecord.address2 != null) acnt.put('ShippingStreet', processRecord.address1 + '\n' + processRecord.address2);
        else if (processRecord.address1 != null) acnt.put('ShippingStreet', processRecord.address1);

        if (processRecord.city != null) acnt.put('ShippingCity', processRecord.city);

        if (processRecord.state != null) {
            if (!String.isBlank(processRecord.state) && processRecord.state.length() < 4) {
                acnt.put('ShippingState', Appt_AppointmentUtil.convertToFullStateName(processRecord.state));
            } else {
                acnt.put('ShippingState', processRecord.state);
            }
        }

        if (processRecord.zipCode != null) acnt.put('ShippingPostalCode', processRecord.zipCode);

        if (!String.isBlank(processRecord.country)) acnt.put('ShippingCountry', processRecord.country);
        else if(!String.isBlank(processRecord.state)) acnt.put('ShippingCountry', Appt_AppointmentUtil.getCountryByState(processRecord.state.trim()));

        if (processRecord.customerType != null) acnt.Appt_Customer_Type__c = processRecord.customerType;
        if (processRecord.emailAddressOptIn != null) acnt.Appt_Email_Opt_In__pc = processRecord.emailAddressOptIn;
        if (processRecord.textOptIn != null) acnt.Appt_SMS_Opt_In__pc = processRecord.textOptIn;

        System.debug(lprefix +' -- buildAccount() EXIT, return account RecordTypeId='+acnt.RecordTypeId);  
        return acnt;
    }

    
    
    // Check for an existing Account in salesforce
    public static Account checkForExistingAccount(String hybrisCustId, String posCustId, String guid, Id accountId){
        System.debug(lprefix+'checkForExistingAccount() ENTRY - accountId='+ accountId + ', POS ID='+posCustId+', Hybris ID='+hybrisCustId+', GUID='+guid);

        //-- validate that at least one ID field is populated, if not return null
        if (String.isBlank(posCustId) && String.isBlank(hybrisCustId) && String.isBlank(guid) && String.isBlank(accountId)) {
            System.debug(lprefix+'checkForExistingAccount() EXIT - no IDs populated, including accountId, returning null');
            return null;
        }

        Account returnAccount;

        String soql = 'SELECT Id, PersonContactId, IsPersonAccount,  RecordTypeId, POS_Customer_Id__c, Hybris_Customer_Id__c, GUID__c, Appt_Customer_Type__c,  FirstName, LastName, Email__c, Appt_Email_Opt_In__pc, ' +
                            'PersonEmail, PersonMobilePhone, Phone, PersonHomePhone, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Appt_SMS_Opt_In__pc FROM Account WHERE ';
        String whereClause = buildAccountWhereClause(processRecord);
        System.debug(lprefix+'     getAccount SOQL = '+soql + whereClause);

        List<Account> custAccounts = (List<Account>)Database.query(soql + whereClause);
        System.debug(lprefix+'     AFTER SOQL Retrieved Accounts:'+custAccounts);
        Integer rowIndex = 0;
        
        if (custAccounts != null && custAccounts.size() > 0) {
            System.debug(lprefix+'     AFTER SOQL Retrieved NUMBER of Accounts='+custAccounts.size());
            if (custAccounts.size() == 1) {
                returnAccount = custAccounts.get(0);
            } else {

                //-- More than 1 account retrieved, loop through to find the account with following logic
                //--   IF accountId is populated (meaning this is Update Apointment) and account already associated with the appointmentId, use that account for the returnAccount
                //--   Otherwise if accountId is null (meaning this is create appointment), then use first account returned as sort order should sort correct account to be first, so use forist account or the returnAccount
                for (Account acnt: custAccounts) {
                    System.debug(lprefix+'     processing account:'+acnt);
                    if ((!String.isBlank(processRecord.accountId) && acnt.Id == processRecord.accountId) ||
                        (String.isBlank(processRecord.accountId) && rowIndex == 0)) {

                        returnAccount = acnt;
                        
                    } else {
                        //-- if here we retieved an account that has one of the IDs, but that is not the appointment's account. 
                        //--  Find which ID it has and Remove the ID from the ProcessModel so that it doesn't get added to appointment account, causing duplicate value eror (ID fields are unique)
                        if (acnt.POS_Customer_Id__c == processRecord.posCustomerId) {
                            processRecord.posCustomerId = null;
                        }
                        if (acnt.Hybris_Customer_Id__c == processRecord.hybrisCustomerId) {
                            processRecord.hybrisCustomerId = null;
                        }
                        if (acnt.GUID__c == processRecord.customerGuid) {
                            processRecord.customerGuid = null;
                        }
                    }

                    rowIndex++;
                }
            }
        }

        System.debug(lprefix+'checkForExistingAccount() EXIT - returnAccount:'+returnAccount);
        System.debug(lprefix+'checkForExistingAccount() EXIT - processRecord.posCustomerId='+processRecord.posCustomerId+', processRecord.hybrisCustomerId='+processRecord.hybrisCustomerId+', processRecord.customerGuid='+processRecord.customerGuid);
        return returnAccount;
    }

    //build dynamic WHERE clause for checkForExistingAccount SOQL
    //-- NOTE! This method is called by handler classes --
    public static String buildAccountWhereClause(Appt_CreateAppointmentServiceModel apptModel) {
        System.debug(lprefix+'buildAccountWhereClause() ENTRY - source='+apptModel.source+', accountId='+ apptModel.accountId +', POS ID='+apptModel.posCustomerId+', Hybris ID='+apptModel.hybrisCustomerId+', GUID='+apptModel.customerGuid);
        String whereClause = '';
        String orderByClause = '';
        Boolean posUsed = false;
        Boolean hybrisUsed = false;
        Boolean guidUsed = false;

        //--make sure no trailing spaces on ID fields
        if (apptModel.hybrisCustomerId != null) apptModel.hybrisCustomerId = apptModel.hybrisCustomerId.trim();
        if (apptModel.posCustomerId != null) apptModel.posCustomerId = apptModel.posCustomerId.trim();
        if (apptModel.customerGuid != null) apptModel.customerGuid = apptModel.customerGuid.trim();

        if (!String.isBlank(apptModel.accountId)) {
            whereClause = 'Id = \'' + apptModel.accountId + '\'';
        }


        if (!String.isBlank(apptModel.hybrisCustomerId)) {
            if (!String.isEmpty(whereClause)) whereClause += ' OR ';
            whereClause += 'Hybris_Customer_Id__c = \'' + apptModel.hybrisCustomerId + '\'';
            hybrisUsed = true;
        }

        if (!String.isBlank(apptModel.posCustomerId)) {
            if (!String.isEmpty(whereClause)) whereClause += ' OR ';
            whereClause += 'POS_Customer_Id__c = \'' + apptModel.posCustomerId + '\'';
            posUsed = true;
        }

        if (!String.isBlank(apptModel.customerGuid)) {
            if (!String.isEmpty(whereClause)) whereClause += ' OR ';
            whereClause += 'GUID__c = \'' + apptModel.customerGuid + '\'';
            guidUsed = true;
        }

        System.debug(lprefix+'    posUsed='+posUsed+', hybrisUsed='+hybrisUsed+', guidUsed='+guidUsed+', apptModel.source='+apptModel.source);

        // If Source param not null, build order by clause to sort the primary ID used, based on source, to be the first row
        if (!String.isBlank(apptModel.source) && (hybrisUsed || posUsed || guidUsed)) {
            orderByClause = ' ORDER BY ';
            if (posUsed && (apptModel.source == Appt_ConstantValues.APPOINTMENT_SOURCE_POS || apptModel.source == Appt_ConstantValues.APPOINTMENT_SOURCE_STORE)) {
                orderByClause += 'POS_Customer_Id__c NULLS LAST';
            } else if (hybrisUsed && (apptModel.source == Appt_ConstantValues.APPOINTMENT_SOURCE_WEB)) {
                orderByClause += 'Hybris_Customer_Id__c NULLS LAST';
            } else {
                //TODO - else use GUID????
                orderByClause += 'GUID__c NULLS LAST';
            }
        }
        
        System.debug(lprefix+'buildAccountWhereClause() EXIT - whereClause='+whereClause + orderByClause);
        return whereClause + orderByClause;
    }

    // Check for a field to update on Account
    public static Boolean checkAccountFields(){
        System.debug(lprefix +' checkAccountFields() ENTRY');
        if(processRecord.firstName != null){return true;}
        if(processRecord.lastName != null){return true;}
        if(processRecord.posCustomerId != null){return true;}
        if(processRecord.hybrisCustomerId != null){return true;}
        if(processRecord.customerGuid != null){return true;}
        if(processRecord.emailAddress != null){return true;}
        if(processRecord.homePhoneNumber != null){return true;}
        if(processRecord.mobilePhoneNumber != null){return true;}
        if(processRecord.workPhoneNumber != null){return true;}
        if(processRecord.address1 != null){return true;}
        if(processRecord.city != null){return true;}
        if(processRecord.state != null){return true;}
        if(processRecord.zipCode != null){return true;}
        if(processRecord.country != null){return true;}
        if(processRecord.customerType != null){return true;}
        if(processRecord.emailAddressOptIn != null){return true;}
        if(processRecord.textOptIn != null){return true;}

        System.debug(lprefix +' checkAccountFields() EXIT - returning FALSE');
        return false;
    }

    // Check for any changes needed to the existing Account record
    public static Boolean checkForExistingAccountChanges(Account existingAccount){
        System.debug(lprefix +' checkForExistingAccountChanges() ENTRY');
        if(processRecord.firstName != existingAccount.FirstName){return true;}
        if(processRecord.lastName != existingAccount.LastName){return true;}
        if(processRecord.posCustomerId != existingAccount.POS_Customer_Id__c){return true;}
        if(processRecord.hybrisCustomerId != existingAccount.Hybris_Customer_Id__c){return true;}
        if(processRecord.customerGuid != existingAccount.GUID__c){return true;}
        if(processRecord.emailAddress != existingAccount.Email__c){return true;}
        if(processRecord.emailAddress != existingAccount.PersonEmail){return true;}
        if(processRecord.homePhoneNumber != existingAccount.PersonHomePhone){return true;}
        if(processRecord.mobilePhoneNumber != existingAccount.PersonMobilePhone){return true;}
        if(processRecord.workPhoneNumber != existingAccount.Phone){return true;}
        if(processRecord.address1 != existingAccount.ShippingStreet){return true;}
        if(processRecord.city != existingAccount.ShippingCity){return true;}
        if(processRecord.state != existingAccount.ShippingState){return true;}
        if(processRecord.zipCode != existingAccount.ShippingPostalCode){return true;}
        if(processRecord.country != existingAccount.ShippingCountry){return true;}
        if(processRecord.customerType != existingAccount.Appt_Customer_Type__c){return true;}
        if(processRecord.emailAddressOptIn != existingAccount.Appt_Email_Opt_In__pc){return true;}
        if(processRecord.textOptIn != existingAccount.Appt_SMS_Opt_In__pc){return true;}
        System.debug(lprefix +' checkForExistingAccountChanges() EXIT - returning FALSE');
        return false;
    }
    // *********************** End Account Process Methods ***********************

    public static Id getPersonContactId(Id accountId) {
        System.debug(lprefix +' getPersonContactId() ENTRY - accountId='+accountId);

        Account acnt = [SELECT Id, PersonContactId FROM Account WHERE Id = :accountId];
        System.debug(lprefix +' getPersonContactId() EXIT - return PersonContactId='+acnt.PersonContactId);
        return acnt.PersonContactId;
    }
}