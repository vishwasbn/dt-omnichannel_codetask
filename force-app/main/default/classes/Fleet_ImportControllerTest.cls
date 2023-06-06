//-- I was forced to set seealldata=true to access Documents to test coverage Fleet_ImportController.getCSVTemplateDocumentId()
//--  but other than Documents, all other test data is created in this test class

@isTest(SeeAllData=true)
public class Fleet_ImportControllerTest {

    
    @IsTest 
    private static void testGetImportObjectFieldNames() {
        System.debug('Fleet_ImportControllerTest...testGetImportObjectFieldNames() ENTRY--------');

        test.startTest();
        List<String> vehFieldResults = Fleet_ImportController.getImportObjectFieldNames('Fleet_Vehicle_Import__c');
        List<String> driverFieldResults = Fleet_ImportController.getImportObjectFieldNames('Fleet_Driver_Import__c');
        test.stopTest();

        System.debug('    vehFieldResults.Size() = '+vehFieldResults.Size());
        System.debug('    driverFieldResults..Size() = '+driverFieldResults.Size());
        System.debug('    vehFieldResults:'+vehFieldResults);
        System.debug('    driverFieldResults:'+driverFieldResults);

        System.assertEquals(true, vehFieldResults.size() > 9, 'Expected more than 9 fields in Fleet_Vehicle_Import__c');
        System.assertEquals(true, driverFieldResults.size() > 9, 'Expected more than 9 fields in Fleet_Driver_Import__c');

        for (String field: vehFieldResults) {
            if (field.contains('Plate__c')) System.assertEquals('License_Plate__c', field, 'Expect field named License_Plate__c. Instead got ' + field);
        }
        for (String field: driverFieldResults) {
            if (field.contains('State__c')) System.assertEquals('Driver_License_State__c', field, 'Expect field named Driver_License_State__c. Instead got ' + field);
        }

        System.debug('Fleet_ImportControllerTest...testGetImportObjectFieldNames() EXIT--');
    }

    @IsTest 
    private static void testInsertImportObjects() {
        System.debug('Fleet_ImportControllerTest...testInsertImportObjects() ENTRY--------');

        Account testAccount = new Account(Name='Test Import Account');
        insert testAccount;
        System.debug('    testAccount:'+testAccount);

        //setup test driver import data
        List<Map<String,Object>> driverList = new List<Map<String,Object>>();
        Map<String,Object> driverMap1 = new Map<String,Object>();
        Map<String,Object> driverMap2 = new Map<String,Object>();
        String custRefNum1 = '123uio123uio';
        String custRefNum2 = 'kjh345kjh345';
        String drLicNum1 = 'X12312312';
        String drLicNum2 = 'Q67867867';
        String drLicState1 = 'Texas';
        String drLicState2 = 'Idahooooooooo';
        String email1 = 'apex+test1@ethos.com';
        String email2 = 'apex+test2@ethos.com';
        String firstName1 = 'Ricky';
        String firstName2 = 'Bobby';
        String lastName1 = 'Simpson';
        String lastName2 = 'Simpsonson';
        String phone1 = '1231231233';
        String phone2 = '3213213211';
        String mobile1 = '5675675677';
        String mobile2 = '7657657565';
        String title1 = 'CEO';
        String title2 = 'CFO';
        driverMap1.put('Customer_Reference_Number__c', custRefNum1);
        driverMap1.put('Driver_License_Number__c', drLicNum1);
        driverMap1.put('Driver_License_State__c', drLicState1);
        driverMap1.put('Email__c', email1);
        driverMap1.put('First_Name__c', firstName1);
        driverMap1.put('Last_Name__c', lastName1);
        driverMap1.put('Mobile__c', phone1);
        driverMap1.put('Phone__c', mobile1);
        driverMap1.put('Title__c', title1);
        driverList.add(driverMap1);
        driverMap2.put('Customer_Reference_Number__c', custRefNum2);
        driverMap2.put('Driver_License_Number__c', drLicNum2);
        driverMap2.put('Driver_License_State__c', drLicState2);
        driverMap2.put('Email__c', email2);
        driverMap2.put('First_Name__c', firstName2);
        driverMap2.put('Last_Name__c', lastName2);
        driverMap2.put('Mobile__c', phone2);
        driverMap2.put('Phone__c', mobile2);
        driverMap2.put('Title__c', title2);
        driverList.add(driverMap2);


        test.startTest();
        List<Map<String, Object>> driverResults = Fleet_ImportController.insertImportObjects(testAccount.Id, 'Fleet_Driver_Import__c', driverList, 'driver_import_test.csv', 2, null);
        List<Map<String, Object>> vehResults = Fleet_ImportController.insertImportObjects(testAccount.Id, 'Fleet_Vehicle_Import__c', createVehicleFieldListMap(), 'veh_import_test.csv', 2, null);
        test.stopTest();

        //----- driver analysis -----------
        //get record type Id for B2B Driver RT on Contact object
        Id driverRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Driver').getRecordTypeId();
        System.debug('    driverRT:'+driverRT);
        Contact driver1 = [SELECT Id, Name, Driver_License_Number__c FROM Contact WHERE ECC_Customer_Reference_Number__c = :custRefNum1 AND RecordTypeId = :driverRT];
        System.debug('    driver1:'+driver1);

        System.assertEquals(drLicNum1, driver1.Driver_License_Number__c, 'Expected driver license number = ' + drLicNum1);

        //----- VEHICLE analysis -----------
        Id vehRT = Schema.Sobjecttype.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
        System.debug('    vehRT:'+vehRT);
        Asset veh = [SELECT Id, Name, Vehicle_License_Plate__c FROM Asset WHERE Customer_Vehicle_Number__c = '456okok456okok' AND RecordTypeId = :vehRT];
        System.debug('    veh:'+veh);

        System.assertEquals('AU65D457', veh.Vehicle_License_Plate__c, 'Expected veh license number = AU65D457');

        System.debug('Fleet_ImportControllerTest...testInsertImportObjects() EXIT--');
    }

    private static List<Map<String,Object>> createVehicleFieldListMap() {
        System.debug('Fleet_ImportControllerTest...createVehicleFieldListMap() ENTRY---------');

        //setup test driver import data
        List<Map<String,Object>> vehList = new List<Map<String,Object>>();
        Map<String,Object> vehMap1 = new Map<String,Object>();
        Map<String,Object> vehMap2 = new Map<String,Object>();

        vehMap1.put('Customer_Vehicle_Number__c', '123kjh123kjh');
        vehMap1.put('License_Plate__c', 'AU65D454');
        vehMap1.put('Make__c', 'Ford');
        vehMap1.put('Model__c', 'Tuarus');
        vehMap1.put('Vehicle_Year__c', '1999');
        vehMap1.put('VIN__c', '23j4h2342334h87878g');
        vehMap1.put('Vehicle_Type__c', 'Commercial');
        vehList.add(vehMap1);
        vehMap2.put('Customer_Vehicle_Number__c', '456okok456okok');
        vehMap2.put('License_Plate__c', 'AU65D457');
        vehMap2.put('Make__c', 'Tesla');
        vehMap2.put('Model__c', 'Model X');
        vehMap2.put('Vehicle_Year__c', '2018');
        vehMap2.put('VIN__c', '2334534534534h87878g');
        vehMap2.put('Vehicle_Type__c', 'My Automobile');
        vehList.add(vehMap2);

        System.debug('       vehList:'+vehList);
        System.debug('Fleet_ImportControllerTest...createVehicleFieldListMap() EXIT--');
        return vehList;
    }

    // -- The following test method uses the SeeAllData=true because there was no other option. When I inserted test data,
    //  -- I got error that "Document already exists", but my test code couldn't access the Documents. Hence SeeAllData=true

    @IsTest     
    private static void testGetCSVTemplateDocumentId(){
        System.debug('Fleet_ImportControllerTest...testGetCSVTemplateDocumentId() ENTRY--------');
    
        Document document = new Document();
        document.Body = Blob.valueOf('Some Text');
        document.ContentType = 'application/pdf';
        document.DeveloperName = 'Fleet_Driver_Import_CSV_Template';
        document.IsPublic = true;
        document.Name = 'Test Document';

        List<Folder> folderIds = [select id from folder where name = 'Sales Tax Exemption Certificates'];

        document.FolderId = folderIds.get(0).Id;
        insert document;
            
        Document document1 = new Document();
        document1.Body = Blob.valueOf('Some Text');
        document1.ContentType = 'application/pdf';
        document1.DeveloperName = 'Fleet_Vehicle_Import_CSV_Template';
        document1.IsPublic = true;
        document1.Name = 'Test Document';

        document1.FolderId = folderIds.get(0).Id;
        insert document1;
        
        test.startTest();
        String driverDocId  = Fleet_ImportController.getCSVTemplateDocumentId(Fleet_Values.FLEET_IMPORT_TYPE_DRIVERS);
        String vehDocId  = Fleet_ImportController.getCSVTemplateDocumentId(Fleet_Values.FLEET_IMPORT_TYPE_VEHICLES);
        test.stopTest();

        System.debug('    driverDocId = '+driverDocId);
        System.debug('    vehDocId = '+vehDocId);

        System.assert(driverDocId instanceOf Id, 'Expected a valid Id for the driverDocId');
        System.assert(vehDocId instanceOf Id, 'Expected a valid Id for the vehDocId');
    
        System.debug('Fleet_ImportControllerTest...testGetCSVTemplateDocumentId() EXIT--');
    }

}