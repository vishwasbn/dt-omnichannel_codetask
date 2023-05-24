public without sharing class Fleet_ApplicationController {
    
   static string lprefix = 'FLEET_ApplicationController: ';

    static Map<String, Schema.SObjectField> objectFields = 
    Schema.getGlobalDescribe().get('Fleet_Application__c').getDescribe().fields.getMap();


    @AuraEnabled
    public static string saveOrSubmitFleetApplication(Map<String, Object> fA, string appStatus){
        fA.put('Application_Status__c', appStatus);

        // Remove the fields that cannot be updated
        fA.remove('Parent_Account__c');
        fa.remove('Fleet_Application_Attachments__r');
        fA.remove('Fleet_App_Credit_References__r');
        fA.remove('Parent_Account__r');

        // Check to see if the new 'Legal Name', 'Years in business', and 'number of fleet vehicles' matches the account values
        String fleetAppId = (String) fA.get('Id');
        String companyFullLegalName = (String) fA.get('Company_Full_Legal_Name__c');
        Decimal yearsInBusiness = (Decimal) fA.get('Years_In_Business__c');
        Decimal numOfFleetVehicles = (Decimal) fA.get('Number_Of_Fleet_Vehicles__c');

        Boolean parentAccountNeedsUpdate = false; // Track if parent account needs to be updatd
        Account parentAccountRecord = [SELECT Id, Legal_Name__c, Fleet_Years_Business__c, Fleet_Number_of_Vehicles__c FROM Account
        WHERE ID IN (SELECT Parent_Account__c FROM Fleet_Application__c WHERE Id=:fleetAppId)];

        // Check to see that legal name exists in the map and isn't blank
        if(companyFullLegalName != NULL){
            // If Account legal name and fleet app legal name don't match, change the account legal name
            if(!companyFullLegalName.equals(parentAccountRecord.Legal_Name__c)){
                parentAccountRecord.Legal_Name__c = companyFullLegalName;
                parentAccountNeedsUpdate = true;
            }
        }

        // Check to see that number of fleet vehicles exists in the map and isn't blank
        if(numOfFleetVehicles != NULL ){
           // Decimal vehicleStringToNum = Integer.valueOf(numOfFleetVehicles);

            // If Account number of fleet vehicles and fleet app number of fleet vehicles don't match,
            // change the account number of fleet vehicles
            if(numOfFleetVehicles != parentAccountRecord.Fleet_Number_of_Vehicles__c){
                parentAccountRecord.Fleet_Number_of_Vehicles__c= numOfFleetVehicles;
                parentAccountNeedsUpdate = true;
            }
        }

        // Check to see that years in business exists in the map and isn't blank
        if(yearsInBusiness != NULL){
           // Decimal yearsToNum = Integer.valueOf(yearsInBusiness);

            // If Account years in business and fleet app years in business don't match, change the account years in business
            if(yearsInBusiness != parentAccountRecord.Fleet_Years_Business__c){
                parentAccountRecord.Fleet_Years_Business__c= yearsInBusiness;
                parentAccountNeedsUpdate = true;
            }

        }

        // upon Submitted status, notify the Fleet Specialist
        if (appStatus == 'Submitted')
        {
            System.debug('saveOrSubmitFleetApplication::Notify start: ' + appStatus);
            fA.put('Fleet_Application_Submitted_Date__c', date.parse(System.today().format()));
            fA.put('isApplicationSubmitted__c', true);
        }

        try{
            if(parentAccountNeedsUpdate){
                update parentAccountRecord;
            }
        }
        catch(Exception e){
            throw new AuraHandledException('Could not update account record');
        }

        Fleet_Application__c fA1 = new Fleet_Application__c();

        for(String key: fA.keySet()){
            System.debug(lprefix +'key: ' +key);
            String fieldType = String.ValueOf(objectFields.get(key).getDescribe().getType());
            System.debug(lprefix +'fieldType: ' +fieldType);
            
            // Remove the key-value if the value is empty
            if(fA.get(key).equals('') || fA.get(key) == null){
                System.debug(lprefix +'remove key');
                fA.remove(key);
            }

            System.debug(lprefix +'value: ' +fA.get(key));

            if(fieldType.equals('CURRENCY') || fieldType.equals('DOUBLE')){
                if(fa.get(key) != ''){
                    // Convert from string to integer
                   fA.put(key, Integer.valueOf(fa.get(key)));
                }
            }

            fA1.put(key, fA.get(key));
        }

        
        try{
            update fA1;
        }   
        catch(DmlException e){
            String errorMessage = 'The following fields are invalid: ';
            Integer numErrors = e.getNumDml();

            for(Integer i = 0 ; i < numErrors; i++){
                errorMessage += '[' +e.getDmlFieldNames(i) +']';
                if(i != numErrors - 1){
                    errorMessage += ',';
                }
                
            }

            throw new AuraHandledException(errorMessage);
        }

        return 'success';

    }

    @AuraEnabled
    public static Fleet_Application__c retrieveFleetAppByGUID(String guid){
        List<Fleet_Application__c> fA = [SELECT ID, Parent_Account__c, AP_Contact_Email__c, AP_Contact_Name__c, AP_Fax_Number__c,
        AP_Phone_Number__c, AP_Statement_Invoice_Email__c, Additional_Requirement__c, Affiliated_Company_doing_Business_with__c,
        Affiliated_Business_Name__c, Application_GUID__c, Application_Status__c, Application_Type__c, Approved_for_Drop_Ship__c,
        Billing_Address1__c, Billing_Address2__c, Billing_City__c, Billing_State__c, Billing_Zip__c, Company_Full_Legal_Name__c,
        Conducted_Business_in_Past__c, Conducted_Under_Business_Name__c, Credit_Amount_Requested__c, Credit_Limit_Requested__c,
        D_B__c, DBA__c, Order_Pending__c, Estimated_Monthly_Purchases__c, Federal_Tax_ID_Text__c, If_Terms_Not_Approved_Check_For_Cash__c, Attachment_Status__c,
        Number_Of_Fleet_Vehicles__c,Number_Of_Locations__c, Organization_Is_Tax_Exempt__c,Owner_Last_Name__c, Owner_Address_1__c, Owner_Email_Address__c,
        Owner_Zip_Code__c, Owner_First_Name__c, Parent_Company_Address1__c, Parent_Company_Address2__c,
        Parent_Company_City__c, Parent_Company_State__c, Parent_Phone_Number__c, Parent_Company_Zip__c, Phone_Number__c,
        Purchase_Is_Tax_Exempt__c, Purchasing_Contact__c, Purchasing_Email__c, Purchasing_Fax_Number__c, Purchasing_Phone_Number__c,
        Req_on_Invoice_City__c, Req_on_Invoice_Company_Name__c, Req_on_Invoice_Driver_Name__c, 
        Req_on_Invoice_Drivers_License__c, Req_on_Invoice_ID_Job_Num__c, Req_on_Invoice_License_Plate_Num__c, Req_on_Invoice_License_Plate_State__c,
        Req_on_Invoice_Mileage__c, Req_on_Invoice_State__c, Req_on_Invoice_Stock_Num__c, Req_on_Invoice_Street_Address__c,
        Req_on_Invoice_Unit_Num__c, Req_on_Invoice_Vehicle_Make__c, Req_on_Invoice_Vehicle_Model__c, Req_on_Invoice_Vehicle_Year__c,
        Req_on_Invoice_VIN__c, Req_on_Invoice_Zip__c, Sales_Tax__c, Shipping_Address1__c, Shipping_Address2__c, Shipping_City__c,
        Shipping_State__c, Shipping_Zip__c, State_of_Organization__c, Type_of_Business__c, Type_of_Entity__c, Years_In_Business__c,Parent_Account__r.Legal_Name__c, Parent_Account__r.Fleet_Number_of_Vehicles__c, Parent_Account__r.Fleet_Years_Business__c,
        (SELECT Id, Parent_Account__c, Attachment_Type__c, Fleet_Application__c, Name FROM Fleet_Application_Attachments__r),
        (SELECT Id, Address_1__c, Address_2__c, City__c, Company_Name__c, Email__c, Fax_Number__c,  Name, Fleet_Application__c, Phone_Number__c,
        State__c, Zip__c FROM Fleet_App_Credit_References__r)
        FROM Fleet_Application__c WHERE Application_GUID__c=:guid LIMIT 1];

        System.debug(lprefix +'fA: ' +fA);

        if(fA.size() == 0){
            throw new AuraHandledException('No Application found with that guid');
        }
        return fA[0];
    }


    @AuraEnabled
    public static string insertFleetAppAttachments(Id accountId, Id fleetAppId, List<Map<String, Object>> files){
        System.debug(accountId);
        List<String> attachmentTypes = new List<String>();
        for(Map<String, Object> file: files){
            attachmentTypes.add((String) file.get('attachmentType'));
        }

        // Delete any existing Fleet_App_Attachments that match the attachment types being uploaded
        List<Fleet_App_Attachment__c> fAs = [SELECT ID FROM Fleet_App_Attachment__c WHERE Attachment_Type__c IN :attachmentTypes
        AND Fleet_Application__c=:fleetAppId];

        delete fAs;

        for(Map<String, Object> file: files){
            Fleet_App_Attachment__c fleetAttach = new Fleet_App_Attachment__c();
            fleetAttach.Fleet_Application__c = fleetAppId;
            fleetAttach.Parent_Account__c = accountId;
            fleetAttach.Name = (String) file.get('attachmentType');
            fleetAttach.Attachment_Type__c = (String) file.get('attachmentType');

            insert fleetAttach;

            ContentVersion cv = new ContentVersion();
            cv.Title = (String) file.get('fileName');
            cv.PathOnClient = (String) file.get('fileName');
            cv.FirstPublishLocationId = fleetAttach.Id;
            cv.VersionData = EncodingUtil.base64Decode((String) file.get('fileContent'));
            cv.IsMajorVersion = true;

            insert cv;
        }
    
        return 'success';
    }

    @AuraEnabled
    public static string removeFile(Id fleetAppId, string attachmentType){
        List<Fleet_App_Attachment__c> attachmentList = [SELECT ID FROM Fleet_App_Attachment__c WHERE Fleet_Application__c=:fleetAppId 
        AND Attachment_Type__c=:attachmentType];

        if(attachmentList != NULL && attachmentList.size() > 0){
            delete attachmentList;
        }

        return 'success';
    }

    @AuraEnabled
    public static string insertCreditAppReferences(Id fleetAppId, List<Fleet_App_Credit_Reference__c> references){
        List<Fleet_App_Credit_Reference__c> faRefs = [SELECT Id FROM Fleet_App_Credit_Reference__c WHERE Fleet_Application__c=:fleetAppId];

        // Delete any existing references (if there are any)
        if(faRefs.size() != 0){
            delete faRefs;
        }
        
        for(Fleet_App_Credit_Reference__c ref: references){
            // If for some reason the app id is not populated, populate it with the param
            if(ref.Fleet_Application__c == NULL){
                ref.Fleet_Application__c = fleetAppId;
            }

            ref.Id= null;
        }

        // insert the references
        insert references;

        return 'success';
    }

}