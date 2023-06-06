public without sharing class Fleet_CommunityImportUtil {
    public static String lprefix = 'FLEET_IMP:';
    public static String IMPORT_SOURCE_TEST = 'TestImportToolTEST';
    public static String IMPORT_SOURCE_FAILED = 'FAILED_TO_IMPORT';
    public static String IMPORT_ITEM_STATUS_VALIDATED = 'Validated';
    public static String IMPORT_ITEM_STATUS_SUCCESS = 'Loaded';
    public static String IMPORT_ITEM_STATUS_FAILURE = 'Error';
    public static Integer MAX_ERROR_LENGTH = 1199;

    // ---------------------- FLEET VEHICLE IMPORT --------------------------------------------------
    //Util method to handle import of VEHICLE CSV into Asset object records with record type "Vehicle"
    public static List<Fleet_Vehicle_Import__c> importFleetVehicles(List<Id> vehicleImportIds) {
        System.debug(lprefix + 'importFleetVehicles() ENTRY - param vehicleImportIds:' + vehicleImportIds);

        //get list of Fleet_Vehicle_Import__c using parameter Ids 
        List<Fleet_Vehicle_Import__c> impVehicles= [SELECT Id, Name, AccountId__c, Fleet_Import__c, Import_Item_Status__c, Import_Item_Error__c, 
                                                    Customer_Vehicle_Number__c, License_Plate__c, Make__c, Model__c, Vehicle_Year__c, VIN__c, Vehicle_Type__c 
                                                    FROM Fleet_Vehicle_Import__c WHERE Id in :vehicleImportIds];
        System.debug( lprefix + '     Retrieved List<Fleet_Vehicle_Import__c>:' + impVehicles);

        if (impVehicles != null && impVehicles.size() > 0) {

            //get records type Id for Vehicle RT on Asset object
            Id vehicleRT = Schema.Sobjecttype.Asset.getRecordTypeInfosByDeveloperName().get(Fleet_Values.ASSET_RECORD_TYPE_VEHICLE).getRecordTypeId();
            System.debug( lprefix + '     Asset Vehicle Record Type Id = ' + vehicleRT);

            //create list of Asset objects to bulk save later
            List<Asset> vehicleAssetList = new List<Asset>();

            //loop through import driver records and create Asset records with record type = 'Vehicle'
            for (Fleet_Vehicle_Import__c impVehicle: impVehicles) {
                System.debug( lprefix + '     INSIDE LOOP for impVehicle:' + impVehicle);
                Asset vehicleAsset = new Asset(AccountId = impVehicle.AccountId__c, RecordTypeId = vehicleRT);
                vehicleAsset.VIN__c = impVehicle.VIN__c;
                vehicleAsset.Customer_Vehicle_Number__c = impVehicle.Customer_Vehicle_Number__c;
                vehicleAsset.Vehicle_License_Plate__c = impVehicle.License_Plate__c;
                vehicleAsset.Vehicle_Make__c = impVehicle.Make__c;
                vehicleAsset.Vehicle_Model__c = impVehicle.Model__c;
                vehicleAsset.Vehicle_Manufacture_Year__c = impVehicle.Vehicle_Year__c;
                vehicleAsset.Name = impVehicle.Vehicle_Year__c + ' ' + impVehicle.Make__c + ' ' + impVehicle.Model__c;
                vehicleAsset.Vehicle_Type_Other__c = impVehicle.Vehicle_Type__c;

                System.debug( lprefix + '    Adding to vehicleAssetList Vehcile Asset:' + vehicleAsset);
                vehicleAssetList.add(vehicleAsset);
            }

        //call method to insert the Assets, save any errors on impVehicles
        insertVehicleAssets(vehicleAssetList, impVehicles);
        }

        System.debug(lprefix + 'importFleetVehicles() EXIT - impVehicles:' + impVehicles);
        return impVehicles;
    }

    //this method will insert all VEHICLE Assets that can be saved, and update the list of Fleet_Vehicle_Import__c to reflect any import items that failed to save
    public static void insertVehicleAssets(List<Asset> newAssets, List<Fleet_Vehicle_Import__c> impObjs) {
        System.debug(lprefix + 'insertVehicleAssets() ENTRY - inserting new vehcile assets:'+ newAssets);

        System.debug(lprefix + '----------Inserting Assets ... CPU Time: ' +Limits.getCpuTime());
        List<Database.SaveResult> saveResults = Database.insert(newAssets, false);
        Logger logInstance = Logger.getInstance();
        logInstance.log('Community Import Util', 'Fleet_CommunityImportUtil', 'Asset', saveResults);
        System.debug(lprefix + '----------Finished Inserting Assets ... CPU Time: ' +Limits.getCpuTime());

        for (Integer i = 0; i < saveResults.size(); i++) {
            System.debug('     save Asset result: ' +saveResults[i]);
            System.debug('     isSuccess() ? : ' +saveResults[i].isSuccess() );
            logInstance.log('Community Import Util', 'Fleet_CommunityImportUtil', 'Before Fleet_Vehicle_Import__c update');
            Fleet_Vehicle_Import__c impObj = impObjs[i];

            if (saveResults[i].isSuccess()) {
                System.debug('   >>>> SUCCESS <<<<<');
                impObjs[i].Import_Item_Status__c = IMPORT_ITEM_STATUS_SUCCESS;

            } else {
                // found error
                System.debug('   <<<<<< ERROR >>>>>>>');
                String errors = '';
                if (saveResults[i].errors != null) {
                    for (Database.Error err : saveResults[i].errors) {
                        errors += err.getMessage() + '\r\n';
                    }
                    impObjs[i].Import_Item_Status__c = IMPORT_ITEM_STATUS_FAILURE;
                    impObjs[i].Import_Item_Error__c = truncateError(errors);

                    System.debug(lprefix + 'insertVehcileAssets() - WARNING!, got error inserting Asset on index='+i+' , error:'+ errors);
                }
            }
            System.debug(lprefix + '    for UPSERT Fleet_Vehicle_Import__c['+i+']: Import_Item_Status__c=' +impObjs[i].Import_Item_Status__c+',Import_Item_Error__c='+impObjs[i].Import_Item_Error__c);
        }

        //upsert the list of Fleet_Vehicle_Import__c with success or failure status for each, and any error messages
        System.debug(lprefix + '----------Upserting Fleet_Vehicle_Import__c List... CPU Time: ' +Limits.getCpuTime());
        upsert impObjs;
        logInstance.log('Community Import Util', 'Fleet_CommunityImportUtil', 'After Fleet_Vehicle_Import__c update', JSON.serialize(impObjs));
        System.debug(lprefix + '----------Finished upserting Fleet_Vehicle_Import__c List... CPU Time: ' +Limits.getCpuTime());

        System.debug(lprefix + 'insertVehicleAssets() EXIT - upserted import objects list with import statuses, upserted impObjs:'+ impObjs);
    }


    // ---------------------- FLEET DRIVER IMPORT --------------------------------------------------------
    //Util method to handle import of DRIVER CSV into Contact object records with record type "B2B Driver"
    public static List<Fleet_Driver_Import__c> importFleetDrivers(List<Id> driverImportIds) {
        System.debug(lprefix + 'importFleetDrivers() ENTRY - param driverImportIds:' + driverImportIds);

        //get list of Fleet_Driver_Import__c using parameter Ids 
        List<Fleet_Driver_Import__c> impDrivers= [SELECT Id, Name, AccountId__c, Fleet_Import__c, Import_Item_Status__c, Import_Item_Error__c, 
                                                    Customer_Reference_Number__c, Driver_License_Number__c, Driver_License_State__c, Email__c, 
                                                    First_Name__c, Last_Name__c, Mobile__c, Phone__c, Title__c 
                                                    FROM Fleet_Driver_Import__c WHERE Id in :driverImportIds];

        System.debug( lprefix + '     Retrieved List<Fleet_Driver_Import__c>:' + impDrivers);

        if (impDrivers != null && impDrivers.size() > 0) {

            //get record type Id for B2B Driver RT on Contact object
            Id driverRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Driver').getRecordTypeId();
            System.debug( lprefix + '     Contact Driver Record Type Id = ' + driverRT);

            //Query the account to get the ownerId of the account, which we need to set the ownerId on the new Contact records before insert.
            // Since there is only one account, just grab off of the first import driver object
            Account acnt = [SELECT Id, OwnerId FROM Account WHERE Id = :impDrivers[0].AccountId__c];
            System.debug( lprefix + '     Retrieved following Account for Id=' + impDrivers[0].AccountId__c + ', Account:' + acnt);

            //create list of Contact objects to bulk save later
            List<Contact> driverContactList = new List<Contact>();

            //loop through import driver records and create Contact records with record type = 'B2B Driver'
            for (Fleet_Driver_Import__c impDriver: impDrivers) {
                System.debug( lprefix + '     INSIDE LOOP for impDriver:' + impDriver);
                Contact driverContact = new Contact(AccountId = impDriver.AccountId__c, RecordTypeId = driverRT);
                //driverContact.OwnerId=acnt.OwnerId;
                driverContact.Email = impDriver.Email__c;
                driverContact.ECC_Customer_Reference_Number__c = impDriver.Customer_Reference_Number__c;
                driverContact.Driver_License_Number__c = impDriver.Driver_License_Number__c;
                if(impDriver.Driver_License_State__c != null) {
                    driverContact.Driver_License_State__c = impDriver.Driver_License_State__c;
                }                
                driverContact.FirstName = impDriver.First_Name__c;
                driverContact.LastName = impDriver.Last_Name__c;
                driverContact.MobilePhone = impDriver.Mobile__c;
                driverContact.Phone = impDriver.Phone__c;
                driverContact.Title = impDriver.Title__c;
                //driverContact.Name = 'Driver ' + impDriver.First_Name__c + ' ' + impDriver.Last_Name__c;

                System.debug( lprefix + '    Adding to driverContactList Driver Contact:' + driverContact);
                driverContactList.add(driverContact);
            }

        //call method to insert the Contacts, save any errors on impDrivers
        insertDriverContacts(driverContactList, impDrivers);
        }
        
        System.debug(lprefix + 'importFleetDrivers() EXIT - impDrivers:' + impDrivers);
        return impDrivers;
    }

    //this method will insert all Driver Contacts that can be saved, and update the list of Fleet_Driver_Import__c to reflect any import items that failed to save
    public static void insertDriverContacts(List<Contact> newContacts, List<Fleet_Driver_Import__c> impObjs) {
        System.debug(lprefix + 'insertDriverContacts() ENTRY - inserting new driver contacts:'+ newContacts);

        System.debug(lprefix + '----------Inserting Driver Contacts ... CPU Time: ' +Limits.getCpuTime());
        List<Database.SaveResult> saveResults = Database.insert(newContacts, false);
        Logger logInstance = Logger.getInstance();
        logInstance.log('Community Import Util', 'Fleet_CommunityImportUtil', 'Contact', saveResults);
        System.debug(lprefix + '----------Finished Inserting Driver Contacts ... CPU Time: ' +Limits.getCpuTime());

        for (Integer i = 0; i < saveResults.size(); i++) {
            System.debug('     save Contact result: ' +saveResults[i]);
            System.debug('     isSuccess() ? : ' +saveResults[i].isSuccess() );
            logInstance.log('Community Import Util', 'Fleet_CommunityImportUtil', 'Before Fleet_Vehicle_Import__c upsert');
            Fleet_Driver_Import__c impObj = impObjs[i];

            if (saveResults[i].isSuccess()) {
                System.debug('   >>>> SUCCESS <<<<<');
                impObjs[i].Import_Item_Status__c = IMPORT_ITEM_STATUS_SUCCESS;

            } else {
                // found error
                System.debug('   <<<<<< ERROR >>>>>>>');
                String errors = '';
                if (saveResults[i].errors != null) {
                    for (Database.Error err : saveResults[i].errors) {
                        errors += err.getMessage() + '\r\n';
                    }
                    impObjs[i].Import_Item_Status__c = IMPORT_ITEM_STATUS_FAILURE;
                    impObjs[i].Import_Item_Error__c = truncateError(errors);

                    System.debug(lprefix + 'insertDriverContacts() - WARNING!, got error inserting Contact on index='+i+' , error:'+ errors);
                }
            }
            System.debug(lprefix + '    for UPSERT Fleet_Driver_Import__c['+i+']: Import_Item_Status__c=' +impObjs[i].Import_Item_Status__c+',Import_Item_Error__c='+impObjs[i].Import_Item_Error__c);
        }

        //upsert the list of Fleet_Driver_Import__c with success or failure status for each, and any error messages
        System.debug(lprefix + '----------Upserting Fleet_Driver_Import__c List... CPU Time: ' +Limits.getCpuTime());
        upsert impObjs;
        logInstance.log('Community Import Util', 'Fleet_CommunityImportUtil', 'After Fleet_Vehicle_Import__c upsert', JSON.serialize(impObjs));
        System.debug(lprefix + '----------Finished upserting Fleet_Driver_Import__c List... CPU Time: ' +Limits.getCpuTime());

        System.debug(lprefix + 'insertDriverContacts() EXIT - upserted import objects list with import statuses, upserted impObjs:'+ impObjs);
    }

    public static String truncateError(String rawError) {
        if (rawError != null && rawError.length() > MAX_ERROR_LENGTH) {
            return rawError.substring(0,MAX_ERROR_LENGTH);
        } else {
            return rawError;
        }
    }
}