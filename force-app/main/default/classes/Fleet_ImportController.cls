public with sharing class Fleet_ImportController {

    public static String lprefix = 'FLEET_Fleet_CNTLR: ';
    public static final String IMPORT_SOURCE = 'ImportTool';
    public static final String IMPORT_STATUS_PENDING = 'Pending';
    public static final String IMPORT_STATUS_COMPLETED = 'Completed';
    public static final String IMPORT_STATUS_FAILED = 'Failed';

    public static final String IMPORT_VEHICLE_ERROR = 'Vehicle import error! Make, Model and 4-digit Year are required in each row.';
    public static final String IMPORT_DRIVER_ERROR = 'Driver import error! Please check if Last Name is missing or Driver License State entered is incorrect (must be full state name or two digit abbreviation).';

    // Returns a list of all fields that exist in Fleet_Site__c object
    @AuraEnabled(cacheable=true)
    public static List<String> getImportObjectFieldNames(String objectApi){
        System.debug(lprefix +'getImportObjectFieldNames() Entry - object api name: ' +objectApi);
        SObjectType importObjectType = Schema.getGlobalDescribe().get(objectApi);
        Map <String, Schema.SObjectField> fieldMap = importObjectType.getDescribe().fields.getMap();

        System.debug(lprefix +'      object type: ' +importObjectType);
        
        List<String> fieldNames = new List<String>();

        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            schema.describefieldresult dfield = sfield.getDescribe();
            fieldNames.add(dfield.getName());
        }

        System.debug(lprefix +'getImportObjectFieldNames() EXIT - field names: ' +fieldNames);
        return fieldNames;
    }

    // Returns a URL for downloadable CSV template based on Import Type
    @AuraEnabled(cacheable=true)
    public static String getCSVTemplateDocumentId(String importType){
        System.debug(lprefix +'getCSVTemplateDocumentId() Entry - importType = ' +importType);
        Document csvFileDoc;
        String csvFileName;
        String csvFileDocId;

        if (importType == Fleet_Values.FLEET_IMPORT_TYPE_DRIVERS) {
            csvFileName = Fleet_SettingUtil.getSettingValue(Fleet_Values.SETTING_FLEET_DRIVER_CSV_TEMPLATE);
        } else if (importType == Fleet_Values.FLEET_IMPORT_TYPE_VEHICLES) {
            csvFileName = Fleet_SettingUtil.getSettingValue(Fleet_Values.SETTING_FLEET_VEHICLE_CSV_TEMPLATE);
        }
        System.debug(lprefix+'     csvFileName = ' + csvFileName);

        csvFileDoc = [SELECT Id, Name, DeveloperName FROM Document WHERE DeveloperName = :csvFileName];
        System.debug(lprefix+'     csvFileDoc = ' + csvFileDoc);

        if (csvFileDoc != null) {

            csvFileDocId = csvFileDoc.Id;
            System.debug(lprefix +'getCSVTemplateDocumentId() EXIT - csvFileDocId = ' +csvFileDocId);
            return csvFileDocId;

        } else {
            System.debug(lprefix +'WARNING! Could not retrieve Document - getCSVTemplateDocumentId() EXIT - csvFileDocId = null');
            return null;
        }
    }


    @AuraEnabled
    public static List<Map<String, Object>> insertImportObjects(Id accountId, String objType, List<Map<String,Object>> imports, string fileName, Integer listLength, Id importId){
        Logger logInstance = Logger.getInstance();
        System.debug(lprefix +'insertImportObjects() ENTRY - objType=' +objType + ', fileName=' + fileName +', importId=' + importId + ', listLength=' + listLength);
        System.debug(lprefix +'    accountId = ' +accountId);
        System.debug(lprefix +'    imports:' +imports);

        //imports the list of states for comparison/conversion
        List<Fleet_State_Abbrev__mdt> stateCompareList = [ SELECT State_Abbrev__c, State_Output__c FROM Fleet_State_Abbrev__mdt];
        
        // Create and insert import object if importId is null
        if(importId == null){
            logInstance.log('Import Controller', 'Fleet_ImportController', 'Before Fleet_Import__c creation');
            Fleet_Import__c imp = new Fleet_Import__c(File_Name__c=fileName, Number_of_Records__c=listLength, Import_Status__c=IMPORT_STATUS_PENDING); //, Import_Type__c='Fleet');
            imp.AccountId__c = accountId;
            insert imp;
            logInstance.log('Import Controller', 'Fleet_ImportController', 'Before Fleet_Import__c creation', JSON.serialize(imp));
            importId = imp.Id;
            System.debug(lprefix +'    after inserting Fleet_Import__c since Id null, importId = ' +importId);
        }

        // Set the source and import id of the List<Map> objects using the created or supplied importId
        for(Map<String,Object> impMap: imports){
            impMap.put('Fleet_Import__c', importId);
        }

        // validatedMap contains two lists, 'success' and 'fail'. Success will be imported to the db, failed will be appended after insertion
        Map<String, List<Map<String,Object>>> validatedMap = validateImportFields(objType, imports);
        System.debug(lprefix +'     after validation: ' +validatedMap);

        // Create a list of sobjects (Sobject determined by objtype parameter)
        List<SObject> importObjects = new List<SObject>();

        // Check to see that we have successfully validated import objects
        System.debug(lprefix +'      validated import objects size=' + validatedMap.get('success').size() + ', validated import objects: ' +validatedMap.get('success'));
        
        if(validatedMap.get('success').size() > 0){

            try {
                // Iterate through successfully validated imports
                for(Map<String, Object> imp: validatedMap.get('success')){
                    logInstance.log('Import Controller', 'Fleet_ImportController', 'Before SObject creation');
                    // We need to cast each Map into an object specified by the 'objType' parameter using getGlobalDescribe()
                    SObject importObj = Schema.getGlobalDescribe().get(objType).newSObject();

                    //set account id
                    importObj.put('AccountId__c', accountId);

                    // Iterate through the Map<> object passed into the method, set the fields for the newly created object using the passed in map
                    for(String fieldName: imp.keySet()){
                        String fieldAPIName = getValidFieldAPIName(fieldName, objType);
                        System.debug(lprefix +'    csv key: ' +fieldName);
                        System.debug(lprefix +'    value: ' +imp.get(fieldName));
                        System.debug(lprefix +'    fieldAPIName: ' +fieldAPIName);

                        // Check for State Conversion
                        if(fieldAPIName == 'Driver_License_State__c'){
                            // Cast to a string
                            String state = (String) imp.get(fieldName);
                            // Convert to a valid state a 2 digit code is entered
                            if(state.length() > 0){
                                state = Fleet_Util.convertTwoDigitStateToFullName(state, stateCompareList);
                            }                            

                            System.debug(state);
                            importObj.put(fieldAPIName, state);
                        } else {
                            system.debug('====fieldAPIName>'+fieldAPIName);
                            system.debug('====imp.get(fieldName)>'+imp.get(fieldName));
                            if(String.isNotBlank(fieldAPIName) && String.isNotBlank(fieldName)){
                                importObj.put(fieldAPIName, imp.get(fieldName));
                            }
                            
                        }
                        
                    }

                    if(importObj.get('Import_Item_Error__c') == null){
                        importObj.put('Import_Item_Error__c', 'N/A');
                    }

                    // Add new importObj to import object list
                    importObjects.add(importObj);
                }

                // Insert the newly created sobjects
                insert importObjects;
                logInstance.log('Import Controller', 'Fleet_ImportController', 'after SObject creation', JSON.serialize(importObjects));
                
                // Get list of Ids of the importObjects list
                List<Id> importObjIds = new List<Id>();
                for(SObject obj: importObjects){
                    importObjIds.add(obj.Id);
                }


                List<SObject> importResults = new List<SObject>();

                // Call specific util class method based on the obj type
                System.debug(lprefix +'   Calling Fleet_CommunityImportUtil with objType: ' +objType);
                if(objType.equals('Fleet_Vehicle_Import__c')){
                    importResults = Fleet_CommunityImportUtil.importFleetVehicles(importObjIds);
                }
                else if(objType.equals('Fleet_Driver_Import__c')){
                    importResults = Fleet_CommunityImportUtil.importFleetDrivers(importObjIds);
                }

                // Convert import results back to a list of maps
                List<Map<String,Object>> importObjListToMap = new List<Map<String,Object>>();
                for(SObject obj: importResults){
                    importObjListToMap.add(obj.getPopulatedFieldsAsMap());
                }

                // Insert the failed imports into the resulting import object map
                importObjListToMap.addAll(validatedMap.get('fail'));

                System.debug(lprefix +'insertImportObjects() EXIT - return importObjListToMap: ' +importObjListToMap);
                return importObjListToMap;
            }
            catch(Exception e){
                logInstance.log('Import Controller', 'Fleet_ImportController', e);
                System.debug(lprefix +'   !!!!!!!!!! EXCEPTION CAIGHT: ' +e);
                
                if(objType.equals(Fleet_Values.FLEET_IMPORT_TYPE_VEHICLES_OBJECT)){
                    throw new AuraHandledException(e.getMessage());

                } else if(objType.equals(Fleet_Values.FLEET_IMPORT_TYPE_DRIVERS_OBJECT)){
                    throw new AuraHandledException(IMPORT_DRIVER_ERROR);

                } else {
                    throw new AuraHandledException(e.getMessage());
                }
            }
        }
        else {
            System.debug(lprefix +'insertImportObjects() EXIT - return validatedMap.get(fail): ' +validatedMap.get('fail'));
            return validatedMap.get('fail');
        }
    }

    //-- This method allows for looser header row (row #1) in the import csv file, so that headers can be more user friendly and not required _ and __c in field names
    private static String getValidFieldAPIName(String csvFieldName, String objType) {
        System.debug(lprefix +'getValidFieldAPIName() ENTRY - param objType= ' +objType + ', csvFieldName = ' + csvFieldName);
        String fieldAPIName;

        If (objType == Fleet_Values.FLEET_IMPORT_TYPE_DRIVERS_OBJECT) {

            //map field names for DRIVER import
            if (csvFieldName.containsIgnoreCase('first') && csvFieldName.containsIgnoreCase('name')) {
                fieldAPIName = 'First_Name__c';
            } else if (csvFieldName.containsIgnoreCase('last') && csvFieldName.containsIgnoreCase('name')) {
                fieldAPIName = 'Last_Name__c';
            } else if (csvFieldName.containsIgnoreCase('license') && csvFieldName.containsIgnoreCase('state')) {
                fieldAPIName = 'Driver_License_State__c';
            } else if (csvFieldName.containsIgnoreCase('license') && csvFieldName.containsIgnoreCase('number')) {
                fieldAPIName = 'Driver_License_Number__c';
            } else if (csvFieldName.containsIgnoreCase('reference') && csvFieldName.containsIgnoreCase('number')) {
                fieldAPIName = 'Customer_Reference_Number__c';
            } else if (csvFieldName.containsIgnoreCase('title')) {
                fieldAPIName = 'Title__c';
            } else if (csvFieldName.containsIgnoreCase('email')) {
                fieldAPIName = 'Email__c';
            } else if (csvFieldName.containsIgnoreCase('phone')) {
                fieldAPIName = 'Phone__c';
            } else if (csvFieldName.containsIgnoreCase('mobile')) {
                fieldAPIName = 'Mobile__c';
            } else {
                fieldAPIName = csvFieldName;
            }

        } else if (objType == Fleet_Values.FLEET_IMPORT_TYPE_VEHICLES_OBJECT) {

            //map field names for VEHICLE import
            if (csvFieldName.containsIgnoreCase('license') && csvFieldName.containsIgnoreCase('plate')) {
                fieldAPIName = 'License_Plate__c';
            } else if (csvFieldName.containsIgnoreCase('vehicle') && csvFieldName.containsIgnoreCase('number')) {
                fieldAPIName = 'Customer_Vehicle_Number__c';
            } else if (csvFieldName.containsIgnoreCase('vehicle') && csvFieldName.containsIgnoreCase('type')) {
                fieldAPIName = 'Vehicle_Type__c';
            } else if (csvFieldName.containsIgnoreCase('make')) {
                fieldAPIName = 'Make__c';
            } else if (csvFieldName.containsIgnoreCase('model')) {
                fieldAPIName = 'Model__c';
            } else if (csvFieldName.containsIgnoreCase('year')) {
                fieldAPIName = 'Vehicle_Year__c';
            } else if (csvFieldName.containsIgnoreCase('vin')) {
                fieldAPIName = 'VIN__c';
            } else {
                fieldAPIName = csvFieldName;
            }
        }

        System.debug(lprefix +'getValidFieldAPIName() EXIT - fieldAPIName = ' + fieldAPIName);
        return fieldAPIName;
    }

    //validate the fields in the import objects
    public static Map<String, List<Map<String,Object>>> validateImportFields(String objType, List<Map<String, Object>> fleetImports){
        Logger logInstance = Logger.getInstance();
        System.debug(lprefix +'validateImportFields() ENTRY - param objType= ' +objType + ', fleetImports:' + fleetImports);

        // Two lists to track 'success' (valid imports) and 'failed' (invalid imports)
        List<Map<String,Object>> successfulImports = new List<Map<String,Object>>();
        List<Map<String,Object>> failedImports = new List<Map<String,Object>>();

        // Create a map of Map<String, Schema.DescribeFieldResult> that will store field name as key and field description as value
        Map<String, Schema.DescribeFieldResult> objectNonStringFields = new Map<String, Schema.DescribeFieldResult>();

        // Get a map of the sobject fields
        Map<String, Schema.SObjectField> sObjectFields = Schema.getGlobalDescribe().get(objType).getDescribe().fields.getMap();

        // Iterate through fields, save ONLY fields that are not string fields. Used for picklist and date validation from import file
        for(String key: sObjectFields.keySet()){
            System.debug(lprefix +'     in sobjectfields map: ' +key +', ' +sObjectFields.get(key));
            
            Schema.DescribeFieldResult field = sObjectFields.get(key).getDescribe();
            Schema.DisplayType fieldType = field.getType();
            if(fieldType != Schema.DisplayType.TEXTAREA || fieldType != Schema.DisplayType.STRING){
                objectNonStringFields.put(sObjectFields.get(key).getDescribe().getName(), field);
                System.debug(lprefix +'     Added key-value to objectNonStringFields: ' +sObjectFields.get(key) +', ' +field);
            }
        }


        for(Map<String,Object> obj: fleetImports){
            System.debug(lprefix +'     ---------validating fleet import: ' +Limits.getCpuTime());

            Boolean validImport = true;
            String importErrorMessage = '';

            for(String fieldName : objectNonStringFields.keySet()) {
                if(obj.get(fieldName) == null){
                    continue;
                }

                System.debug(lprefix +'      objectNonStringFields : ' +fieldName +', ' +objectNonStringFields.get(fieldName));

                Schema.DisplayType fieldType = objectNonStringFields.get(fieldName).getType();
                System.debug(lprefix +'       field: ' +fieldName +' , ' +fieldType);
                if(fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST){

                    List<String> importPicklistValues = obj.get(fieldName).toString().split(';');
                    for(String val: importPicklistValues){
                        if(!checkValidPicklistValue(objectNonStringFields.get(fieldName), val)){
                            validImport = false;
                            importErrorMessage += ('Invalid text value: \'' +obj.get(fieldName) +'\' at dropdown field \'' +fieldName +'\'\n');
                            System.debug(lprefix +'   !!!! Invalid picklist value: \'' +obj.get(fieldName) +'\' at field \'' +fieldName);
                        }
                    }
                } else if(fieldType == Schema.DisplayType.DATE){
                    if(checkValidDateValue(obj.get(fieldName))){
                        obj.put(fieldName, Date.valueOf(obj.get(fieldName).toString()));
                    }
                    else{
                        validImport = false;
                        importErrorMessage += ('Invalid Date value: \'' +obj.get(fieldName) +'\' at field \'' +fieldName +'\'\n');
                        System.debug(lprefix +'    !!!! Invalid Date value: \'' +obj.get(fieldName) +'\' at field \'' +fieldName);
                    }
                } else if(fieldType == Schema.DisplayType.DOUBLE || fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.PERCENT){
                    Double dec = null;

                    System.debug('    --- DOUBLE ---- fieldName = '+fieldName);
                    
                    try {
                        System.debug('    Casting ' +fieldName +' to decimal');

                        String fieldValue = obj.get(fieldName).toString();
                        fieldValue = fieldValue.trim();
                        fieldValue = fieldValue.remove(',');
                        dec = Decimal.valueOf(fieldValue);
                        obj.put(fieldName, dec);
                    }
                    catch(Exception e){
                        logInstance.log('Import Controller', 'Fleet_ImportController', e);
                        validImport = false;
                        importErrorMessage += ('Invalid Year value: \'' +obj.get(fieldName) +'\' at field \'' +fieldName +'\'\n');
                        System.debug(lprefix +'    !!!! Invalid Year value: \'' +obj.get(fieldName) +'\' at field \'' +fieldName);
                    }
                } else if(fieldType == Schema.DisplayType.INTEGER){
                    //Integer intgr = null;
                    System.debug('       Casting ' +fieldName +' to integer: BUT COMMENTED OUT!!!');// +obj.get(fieldName).toString());
                    
                    //commented out following because INTEGER is never called and scewed test coverage percentage
                    // try {
                    //     intgr = Integer.valueOf(obj.get(fieldName).toString());
                    // }
                    // catch(Exception e){} //Swallow exception
                    
                    // obj.put(fieldName, intgr);

                } else if(fieldType == Schema.DisplayType.BOOLEAN){
                    System.debug(lprefix +'        Casting ' +obj.get(fieldName).toString() +' to Boolean');
                    obj.put(fieldName, Boolean.valueOf(obj.get(fieldName).toString()));
                }

            }

            // If obj is valid, add it to the success list, otherwise add it to the failure list
            if(validImport){
                successfulImports.add(obj);
            }
            else {
                obj.put('Name', '----');
                obj.put('Id', '----');
                obj.put('Import_Item_Status__c', 'Error');
                obj.put('Import_Item_Error__c', importErrorMessage);
                failedImports.add(obj);
            }
            System.debug(lprefix +'     ---------finished validating obj: ' +Limits.getCpuTime());

        }

        Map<String, List<Map<String,Object>>> returnMap = new Map<String, List<Map<String,Object>>>();
        System.debug(lprefix +'     successfulImports: ' + successfulImports);
        returnMap.put('success', successfulImports);
        System.debug(lprefix +'     failedImports: ' + failedImports);
        returnMap.put('fail', failedImports); // NOTE: failed imports will have a 'message' key-value to describe error, do not cast to Fleet_Site__c

        System.debug(lprefix +'validateImportFields() EXIT - returnMap:' + returnMap);
        return returnMap;
    }


    // Returns whether or not given picklist value matches with a picklist value in sObject
    public static Boolean checkValidPicklistValue(Schema.DescribeFieldResult field, Object picklistValue){
        List<Schema.PicklistEntry> values = field.getPicklistValues();

        for(Schema.PicklistEntry validPicklistVal: values){ 
            if(picklistValue == validPicklistVal.getValue() || String.isBlank(picklistValue.toString())){
                return true;
            }
        }

        return false;
    }


    // Returns whether or not a date is in the correct format (yyyy-mm-dd)
    public static Boolean checkValidDateValue(Object dateVal){
        if(Pattern.matches('\\d\\d\\d\\d-\\d\\d-\\d\\d', dateVal.toString())){
            return true;
        }

        return false;
    }
}