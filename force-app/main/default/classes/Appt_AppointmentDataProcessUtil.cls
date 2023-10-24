public without sharing class Appt_AppointmentDataProcessUtil {

    public static final String lprefix = 'Appt_AppointmentDataProcessUtil: ';
    public static final String ID_STRING_NOTNULL_NOTUSED = 'NotNullNotUsedId';

    public static Appt_CreateAppointmentServiceModel processRecord = new Appt_CreateAppointmentServiceModel();

    // *********************** Start Vehicle Process Methods ***********************
    // Reusable method that can process vehicle data
    public static Appt_CreateAppointmentServiceModel processVehicleData(Appt_CreateAppointmentServiceModel serviceModel){
        System.debug(lprefix +' Start - Appt_CreateAppointmentServiceModel'+serviceModel);
        processRecord = serviceModel;
        runVehicleProccess();
        return processRecord;
    }

    // Overloaded method to process the Appt_UpdateAppointmentServiceModel
    public static Appt_UpdateAppointmentServiceModel processVehicleData(Appt_UpdateAppointmentServiceModel serviceModel){        
        System.debug(lprefix +' Start - Appt_UpdateAppointmentServiceModel'+serviceModel);
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
            // Appt 3.0 changes - Lookup for vehicle based on MDM vehicle Id if calling applications pass it, otherwise lookup based on legacy fields.
			Asset existingVehicle;
            if (String.isNotBlank(processRecord.customerVehicleId)) {
                existingVehicle = checkForExistingVehicleAppt3(processRecord.customerVehicleId, processRecord.accountId);
            }
            
            if (existingVehicle == null) {
                existingVehicle = checkForExistingVehicle(processRecord.hybrisCustomerVehicleId, processRecord.posCustomerVehicleId, processRecord.accountId);
            }
            // Appt 3.0 changes - End			

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
		System.debug(lprefix +' -- before build vehicle fields '+processRecord);        

        Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
        if(processRecord.trimId != null || processRecord.vehicleId != null){
            getReferenceInfo();
        }
        System.debug(lprefix +' -- after build vehicle fields '+processRecord);
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
        // Appts 3.0 - In an update scenario where if a asset record is based on MDM vehicle Id , dont update the legacy fields.
		if (String.isBlank(processRecord.customerVehicleId) || String.isBlank(processRecord.assetId)) {
            if(processRecord.posCustomerVehicleId != null){vehicle.POS_Customer_Vehicle_Id__c = processRecord.posCustomerVehicleId;}
            if(processRecord.hybrisCustomerVehicleId != null){vehicle.Hybris_Customer_Vehicle_Id__c = processRecord.hybrisCustomerVehicleId;}
        }
		// Appts 3.0 - End
        // check for individual field updates and add them to the vehicle if they have changed
        if(processRecord.accountId != null){vehicle.accountId = processRecord.accountId;}
        if(processRecord.contactId != null){vehicle.contactId = processRecord.contactId;}
        if(processRecord.year != null){vehicle.Vehicle_Manufacture_Year__c = processRecord.year;}
        if(processRecord.make != null){vehicle.Vehicle_Make__c = processRecord.make;}
        if(processRecord.model != null){vehicle.Vehicle_Model__c = processRecord.model;}
        if(processRecord.assemblyId != null){vehicle.Assembly_Id__c = processRecord.assemblyId;}
        if(processRecord.vehicleId != null){vehicle.Vehicle_Id__c = processRecord.vehicleId;}
        if(processRecord.trimId != null){vehicle.Trim_Id__c = processRecord.trimId;}
        if(processRecord.vehicleClass != null){vehicle.Vehicle_Class__c = processRecord.vehicleClass;}
        if(processRecord.trimName != null){vehicle.Trim_Name__c = processRecord.trimName;}
        //Appt 3.0 Changes Start - Fields for Hybris -User Story# APPT3-71/78
        if(!String.isBlank(processRecord.customerVehicleId)){vehicle.Appt3_Customer_Vehicle_Id__c = processRecord.customerVehicleId.trim();}
        if (processRecord.isVisionFeature != null && processRecord.isVisionFeature) {
            vehicle.Appt3_Fitment_Lift_Id__c = processRecord.fitmentLiftId;
            vehicle.Appt3_Front_Tire_Size__c = processRecord.frontTireSize;
            vehicle.Appt3_Rear_Tire_Size__c = processRecord.rearTireSize;
            vehicle.Appt3_Front_Tire_Diameter__c = processRecord.frontTireDiameter;
            vehicle.Appt3_Rear_Tire_Diameter__c = processRecord.rearTireDiameter;
            vehicle.Appt3_Assembly_Type__c = processRecord.assemblyType;
            vehicle.Appt3_Color__c = processRecord.color;
            vehicle.Appt3_Generic_Vehicle_Category__c = processRecord.genericVehicleCategory;
            vehicle.Appt3_Generic_Vehicle_SubCategory__c = processRecord.genericVehicleSubCategory;
            vehicle.Vehicle_License_Plate__c = processRecord.licensePlate;
            vehicle.Appt3_Type_Of_Vehicle__c = processRecord.vehicleType;
            vehicle.Appt3_Vehicle_Image_URL__c = processRecord.imageURL;
          
        }    
        // Appt 3.0 changes - End		

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

		//Appt 3.0 - Added Appt 3.0 fields to the select clause
        Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
        List<Asset> vehs = [SELECT  Id, 
                                    Assembly_Id__c, Appt3_Fitment_Lift_Id__c, Appt3_Front_Tire_Size__c, Appt3_Rear_Tire_Size__c,
                                    Vehicle_Manufacture_Year__c, Appt3_Front_Tire_Diameter__c, Appt3_Rear_Tire_Diameter__c, Appt3_Assembly_Type__c, Appt3_Customer_Vehicle_Id__c,
                                    Vehicle_Make__c, Appt3_Color__c, Appt3_Generic_Vehicle_SubCategory__c, Appt3_Generic_Vehicle_Category__c,
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
        // Appt 3.0 Changes - validations added for Vision fields 
        if(processRecord.customerVehicleId != null){return true;}
        if(processRecord.fitmentLiftId != null){return true;}
        if(processRecord.frontTireSize != null){return true;}
        if(processRecord.rearTireSize != null){return true;}
        if(processRecord.frontTireDiameter != null){return true;}
        if(processRecord.assemblyType != null){return true;}
        if(processRecord.color != null){return true;}
        if(processRecord.genericVehicleCategory != null){return true;}
        if(processRecord.genericVehicleSubCategory!= null){return true;}
        if(processRecord.licensePlate != null){return true;}        
        // Appt 3.0 Changes - End 
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
        if(processRecord.trimId != existingVehicle.Trim_Id__c){return true;}

        //Appt 3.0 Changes - Added this for User Story# APPT3-408  
        if(processRecord.isVisionFeature == null || !processRecord.isVisionFeature) {
            if(processRecord.vehicleId != existingVehicle.Vehicle_Id__c){return true;}
        if(processRecord.vehicleClass != existingVehicle.Vehicle_Class__c){return true;}
        }
        //Appt 3.0 Changes - Added this for User Story# APPT3-187  
        if(processRecord.customerVehicleId != existingVehicle.Appt3_Customer_Vehicle_Id__c){return true;}  
        //Appt 3.0 Changes End
        //Appt 3.0 Changes - Vision fields added for validation
        if(processRecord.isVisionFeature != null && processRecord.isVisionFeature) {
        	if(processRecord.fitmentLiftId != existingVehicle.Appt3_Fitment_Lift_Id__c){return true;}
            if(processRecord.frontTireSize != existingVehicle.Appt3_Front_Tire_Size__c){return true;}
            if(processRecord.rearTireSize != existingVehicle.Appt3_Rear_Tire_Size__c){return true;}
            if(processRecord.frontTireDiameter != existingVehicle.Appt3_Front_Tire_Diameter__c){return true;}
            if(processRecord.rearTireDiameter != existingVehicle.Appt3_Rear_Tire_Diameter__c){return true;} // added just now
            if(processRecord.assemblyType != existingVehicle.Appt3_Assembly_Type__c){return true;}
            if(processRecord.color != existingVehicle.Appt3_Color__c){return true;}
            if(processRecord.genericVehicleCategory != existingVehicle.Appt3_Generic_Vehicle_Category__c){return true;}
            if(processRecord.genericVehicleSubCategory != existingVehicle.Appt3_Generic_Vehicle_SubCategory__c){return true;}
            if(processRecord.licensePlate != existingVehicle.Vehicle_License_Plate__c){return true;}
            //Appt 3.0 Changes Start Added for Alert Center -  -User Story# APPT3-187  
            if(processRecord.hybrisCustomerVehicleId!= existingVehicle.Hybris_Customer_Vehicle_Id__c){return true;}
            if(processRecord.posCustomerVehicleId!= existingVehicle.POS_Customer_Vehicle_Id__c){return true;}
            //Appt 3.0 Changes Start Added for Alert Center -  -User Story# APPT3-187  
            
        }
        //Appt 3.0 Changes - End
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
            // Appt 3.0 changes - Lookup for account based on MDM customer Id if calling applications pass it, otherwise lookup will be based on legacy fields.
            Account existingAccount;
            if (String.isNotBlank(processRecord.customerId)) {
                existingAccount = checkForExistingAccountAppt3(processRecord.customerId, processRecord.accountId); 
            }
            
            
            if (existingAccount == null) {
                existingAccount = checkForExistingAccount(processRecord.hybrisCustomerId, processRecord.posCustomerId, processRecord.customerGuid, processRecord.accountId);
            }
                        
            // Appt 3.0 changes - End

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
                }else {            
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
        // Appts 3.0 - In an update scenario where an account is identified based on MDM Customer ID, dont update the legacy fields that identify the customer.
        if (String.isBlank(processRecord.accountId ) || String.isBlank(processRecord.customerId )) {
            if (processRecord.posCustomerId != null) acnt.POS_Customer_Id__c = processRecord.posCustomerId.trim();
            if (processRecord.hybrisCustomerId != null) acnt.Hybris_Customer_Id__c = processRecord.hybrisCustomerId.trim();
            if (processRecord.customerGuid != null) acnt.GUID__c = processRecord.customerGuid.trim();
        }
        // Appts 3.0 - End
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
        // Appt3.0 Changes Start - Fields for Hybris User Story# APPT3-71/78       
        if (processRecord.companyName != null) {acnt.Appt3_Company_Name__c = processRecord.companyName;}
        if (processRecord.fleetNumber != null) {acnt.Appt3_Fleet_Number__c = processRecord.fleetNumber;}
        if (processRecord.customerId != null) {acnt.Appt3_Customer_Id__c = processRecord.customerId.trim();}    
        // Appt3.0 Changes Start - Fields for Hybris User Story# APPT3-71/78
        // Appt 3.0 changes - Mapping added for new vision payload fields
        if (processRecord.isVisionFeature != null && processRecord.isVisionFeature) {
            if(!String.isBlank(processRecord.customerId)){acnt.Appt3_Customer_Id__c = processRecord.customerId.trim();}
            if (processRecord.middleInitial != null) acnt.MiddleName = processRecord.middleInitial;
            if (processRecord.suffix != null) acnt.Suffix = processRecord.suffix;
            if (processRecord.showMyAccount != null) {acnt.Appt3_My_Account__c = processRecord.showMyAccount;}
            if (processRecord.showAAAMember != null) {acnt.Appt3_AAA_Membership__c = processRecord.showAAAMember;}
            if (processRecord.showDTCC != null) {acnt.Appt3_Private_Label_Cardholder__c= processRecord.showDTCC;}
            if (processRecord.showMilitary != null) {acnt.Appt3_Military__c = processRecord.showMilitary;}
            if (processRecord.companyName != null) {acnt.Appt3_Company_Name__c = processRecord.companyName;}
            if (processRecord.companyName2 != null) {acnt.Appt3_Company_Name2__c = processRecord.companyName2;}
            if (processRecord.fleetNumber != null) {acnt.Appt3_Fleet_Number__c = processRecord.fleetNumber;}     
                        //Vision payload always sends 2 character country code, so fetch country based on state. Fallback is 'United States'.
            String country = Appt_AppointmentUtil.getCountryByState(processRecord.state.trim());
            system.debug('country value is->'+country);
            acnt.put('ShippingCountry', (country != null ? country : 'United States')); 
            //Code added for B2B Customers - To poulate Company Name as Last Name
            if (processRecord.customerType == Appt_ConstantValues.CUSTOMER_TYPE_FLEET )
            {
                if ((!String.isBlank(processRecord.companyName))&& (!String.isBlank(processRecord.companyName2)))
                {
                    acnt.LastName = processRecord.companyName2;                 
                    acnt.FirstName = processRecord.companyName;
                } 
                else if (!String.isBlank(processRecord.companyName)) {
                    acnt.LastName = processRecord.companyName;        
                }  
                else if (!String.isBlank(processRecord.companyName2)) {
                    acnt.LastName = processRecord.companyName2;        
                }    
            }
        }    
        // Appt 3.0 changes - End        

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
		//Appt 3.0 - Added Appt3.0 fields to the select clause
        String soql = 'SELECT Id, PersonContactId, IsPersonAccount,  RecordTypeId, POS_Customer_Id__c, Hybris_Customer_Id__c, GUID__c, Appt_Customer_Type__c,  FirstName, LastName, Email__c, Appt_Email_Opt_In__pc, Appt3_Customer_Id__c, Appt3_Military__c, Appt3_AAA_Membership__c, ' +
                            'PersonEmail, PersonMobilePhone, Phone, PersonHomePhone, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Appt_SMS_Opt_In__pc, Appt3_Private_Label_Cardholder__c, Appt3_My_Account__c FROM Account WHERE ';
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
        
        // Appt 3.0 Changes - validation added for New customer fields in the payload
        if(processRecord.customerId != null) {return true;} 
        if(processRecord.fleetNumber != null) {return true;} 
        if(processRecord.companyName != null) {return true;} 
        if(processRecord.showMilitary != null) {return true;}
        if(processRecord.showAAAMember != null) {return true;}
        if(processRecord.showDTCC != null) {return true;}            
        if(processRecord.showMyAccount != null) {return true;}
        
        // Appt 3.0 Changes End

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
        // Appt 3.0 changes - validation added for New customer fields in the payload
        if(processRecord.isVisionFeature != null && processRecord.isVisionFeature) {
        	if(processRecord.customerId != existingAccount.Appt3_Customer_Id__c){return true;}
            if(processRecord.showMilitary != existingAccount.Appt3_Military__c) {return true;}
            if(processRecord.showAAAMember != existingAccount.Appt3_AAA_Membership__c) {return true;}
            if(processRecord.showDTCC != existingAccount.Appt3_Private_Label_Cardholder__c) {return true;} 
            if(processRecord.showMyAccount != existingAccount.Appt3_My_Account__c) {return true;}
        }
        // Appt 3.0 changes - End
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

    // Appt 3.0 - Check for an existing Account in salesforce based on MDM Customer ID
    public static Account checkForExistingAccountAppt3(String customerId, Id accountId){
        System.debug(lprefix+'checkForExistingAccountAppt3() ENTRY - accountId='+ accountId + ', Customer ID='+customerId);
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(); 
        Account returnAccount;
        String whereClause = '';
        //-- validate that at least one ID field is populated, if not return null
        if (String.isBlank(customerId) && String.isBlank(accountId)) {
            System.debug(lprefix+'checkForExistingAccountAppt3() EXIT - no IDs populated, including accountId, returning null');
            return null;
        }
        

        String soql = 'SELECT Id, PersonContactId, IsPersonAccount,  RecordTypeId, POS_Customer_Id__c, Appt3_Customer_Id__c, Appt3_Military__c, Appt3_AAA_Membership__c, '+
            		  'Hybris_Customer_Id__c, GUID__c, Appt_Customer_Type__c,  FirstName, LastName, Email__c, Appt_Email_Opt_In__pc, Appt3_Private_Label_Cardholder__c, ' +
                      'PersonEmail, PersonMobilePhone, Phone, PersonHomePhone, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, Appt3_My_Account__c, '+
            		  'ShippingCountry, Appt_SMS_Opt_In__pc,ECC_Account_Number__c,Fleet_AR_App_Status__c FROM Account WHERE ';
        
        if(!String.isBlank(accountId)){
            System.debug('Found matching account id: ' +accountId);
            whereClause = 'Id=' +'\'' +accountId +'\'';
        }
        else if (!String.isBlank(customerId)) {
            whereClause = 'Appt3_Customer_Id__c = \'' + customerId + '\'     AND RecordTypeId = \''+ personAccountRecordTypeId +'\'' ;
        }
        
        System.debug(lprefix+'     getAccount SOQL = '+soql + whereClause);

        List<Account> custAccounts = (List<Account>)Database.query(soql + whereClause);
        System.debug(lprefix+'     AFTER SOQL Retrieved Accounts:'+custAccounts);
        
        if (custAccounts != null && custAccounts.size() == 1) {
            System.debug(lprefix+'     AFTER SOQL Retrieved NUMBER of Accounts='+custAccounts.size());
                returnAccount = custAccounts.get(0);
        }

        System.debug(lprefix+'checkForExistingAccountAppt3() EXIT - returnAccount:'+returnAccount);
        return returnAccount;
    }

    // Appt 3.0 - Check for an existing vehicle in salesforce based on MDM vehicle Id
    public static Asset checkForExistingVehicleAppt3(String customerVehicleId, Id accountId){
        Asset returnVehicle;
        String customerVehicleIdString;

        //-- If not null, make sure no trailing spaces on ID fields. IF NULL, set to unused ID string since null in where clause causes perf issues
        if (customerVehicleId != null) {
            customerVehicleIdString = customerVehicleId.trim();
        } else {
            customerVehicleIdString = ID_STRING_NOTNULL_NOTUSED;
        }

        Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
        List<Asset> vehs = [SELECT  Id, Assembly_Id__c, Appt3_Fitment_Lift_Id__c, Appt3_Front_Tire_Size__c, Appt3_Rear_Tire_Size__c,
                            Vehicle_Manufacture_Year__c, Appt3_Front_Tire_Diameter__c, Appt3_Rear_Tire_Diameter__c, Appt3_Assembly_Type__c, Appt3_Customer_Vehicle_Id__c,
                            Vehicle_Make__c, Appt3_Color__c, Appt3_Generic_Vehicle_SubCategory__c, Appt3_Generic_Vehicle_Category__c,
                            Vehicle_Model__c, Vehicle_License_Plate__c, Trim_Id__c, Vehicle_Id__c,Vehicle_Class__c,Hybris_Customer_Vehicle_Id__c,POS_Customer_Vehicle_Id__c
                            FROM Asset 
                            WHERE RecordTypeId = :vehRecordTypeId AND Appt3_Customer_Vehicle_Id__c = :customerVehicleIdString
                            AND AccountId = :accountId];

        System.debug(lprefix+'     using Customer_Vehicle_Id='+customerVehicleIdString+' Retrieved Vehicle Assets:'+vehs);
        
        if (vehs != null && vehs.size() > 0) {
            returnVehicle = vehs.get(0);
        }

        return returnVehicle;
    }    
}