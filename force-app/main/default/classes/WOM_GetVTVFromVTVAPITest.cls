/*========================================================================================================
* @author: Capgemini
* @date: 18th Jan'23
* @description: Mock class for Get VTV controller - WOM_GetVTVFromVTVAPI

Modification Log:
----------------------------------------------------------------------------------------------------------
Developer       Mod Number      Date                    User Story          Description
----------------------------------------------------------------------------------------------------------
Anuradha       M-001           18th Jan'23             WOM-52              Initial development. Get VTV information
Akilan		   M-002		   03-07-23		           WOM-2782		 	   Added Type in Int Message query to filter out the correct Int Message
Anil G         M-003           03-07-23                                    Added Type in Int Message query to filter out the correct Int Message
========================================================================================================== */
@isTest(SeeAllData=false)
public class WOM_GetVTVFromVTVAPITest {
    
    /**
    * @description : It is used to create data needed for testing  
    * @author Lim Gabba | 12-12-2022 
    * @last modified by  : Srajan
   * @last modified on  : 01-03-2023
    **/
    @testSetup 
    static void setup() {
        Apex_Bypass__c apexCustomSettingRec = new Apex_Bypass__c();
        apexCustomSettingRec.Name = 'Test User';
        apexCustomSettingRec.Work_Order_Trigger__c = false;
        insert apexCustomSettingRec;
        
        //insert User
        List<User> usr = WOM_TestDataUtility.createUsers(1,'Test','User','System Administrator',true);
        usr[0].User_Store_Id__c='123123';
        insert usr; 
        
        //insert operating hours
        List<OperatingHours> opHrs = WOM_TestDataUtility.createOpHours(1,'Test Operating Hours');
        insert opHrs;
        
        //insert account of record type 'Site'
        List<Account> acct = WOM_TestDataUtility.createAccounts(1,'Test Account','Site');
        acct[0].Store_Id__c='123123';
        insert acct;
        
        //insert Service Territory
        List<ServiceTerritory> servTerr = WOM_TestDataUtility.createServiceTerritory(1,'Test Service Territory',true);
        insert servTerr; 
        
        //insert location
        List<Schema.Location> loc = WOM_TestDataUtility.createLocation(3,'Bay 01','Available','Flat','Site',false);
        loc[1].Name = 'Bay 02';
        loc[2].Name = 'Bay 03';
        loc[2].WOM_Multiple_Vehicles__c = true;
        insert loc;
        
        //insert work orders
        list<WorkOrder> listWOs = WOM_TestDataUtility.createWO(1,'Awaiting Service',-30,loc[0].id);
        listWOs[0].WOM_VTV_Inspection_ID__c = '2b155400-2e79-11ea-9be3-c9b200c94e7f';
        insert listWOs;
        
    }
    
    
    @isTest
    static void validateVTVDetailsPositiveScenario() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_API_Endpoint__mdt apiDetails=[select WOM_Client_Id__c,WOM_Client_Secret__c,WOM_Content_Type__c,WOM_Authorization_Header__c,WOM_Endpoint_URL__c,WOM_Method__c,WOM_Mock_Request__c, WOM_Mock_Response__c, DeveloperName from WOM_API_Endpoint__mdt where DeveloperName='WOM_GetVTVFromVTVAPI'];
                
                WOM_GetVTVFromVTVAPIHttpCalloutMock mockClass = new WOM_GetVTVFromVTVAPIHttpCalloutMock(200, 'OK', apiDetails.WOM_Mock_Response__c);
                Test.setMock(HttpCalloutMock.class, mockClass);
                WOM_GetVTVFromVTVAPI.getVTVInfoAPICall('2b155400-2e79-11ea-9be3-c9b200c94e7f'); 

                Int_Message__c intMessage = [Select id,Status__c from Int_Message__c WHERE Type__c=:WOM_APIHelper.TYPE_WOM_GET_VTV_INFORMATION  limit 1];
                System.assertEquals('Successful',intMessage.Status__c,'VTV GET - Positive Test Case - Failed');

        
            Test.stopTest();
        }
    }
        @isTest
    static void validateVTVDetailsNegativeScenario() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_API_Endpoint__mdt apiDetails=[select WOM_Client_Id__c,WOM_Client_Secret__c,WOM_Content_Type__c,WOM_Authorization_Header__c,WOM_Endpoint_URL__c,WOM_Method__c,WOM_Mock_Request__c, WOM_Mock_Response__c, DeveloperName from WOM_API_Endpoint__mdt where DeveloperName='WOM_GetVTVFromVTVAPI'];
                
                WOM_GetVTVFromVTVAPIHttpCalloutMock mockClass = new WOM_GetVTVFromVTVAPIHttpCalloutMock(400, 'OK', apiDetails.WOM_Mock_Response__c);
                Test.setMock(HttpCalloutMock.class, mockClass);
                WOM_GetVTVFromVTVAPI.getVTVInfoAPICall('2b155400-2e79-11ea-9be3-c9b200c94e7f'); 

                
                Int_Message__c intMessage = [Select id,Status__c,Type__c from Int_Message__c WHERE Type__c=:WOM_APIHelper.TYPE_WOM_GET_VTV_INFORMATION limit 1];
                System.assertEquals('Error',intMessage.Status__c,'VTV GET - Negative Test Case - Failed');
        
            Test.stopTest();
        }
    } 
    @isTest
    static void validateVTVDetailsNullScenario() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_GetVTVFromVTVAPI.getVTVInfoAPICall('2b155400-2e79-11ea-9be3-c9b200c94e7f'); 
                Int_Message__c intMessage = [Select id,Status__c from Int_Message__c WHERE Type__c=:WOM_APIHelper.TYPE_WOM_GET_VTV_INFORMATION  limit 1];
                System.assertEquals('Error',intMessage.Status__c,'VTV GET - Negative Test Case - Failed');
        
            Test.stopTest();
        }
    }
    
    @isTest
    static void validateVTVNotLiveScenario() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_API_Endpoint__mdt apiDetails=[select WOM_Client_Id__c,WOM_Client_Secret__c,WOM_Content_Type__c,WOM_Authorization_Header__c,WOM_Endpoint_URL__c,WOM_Method__c,WOM_Mock_Request__c, WOM_Mock_Response__c, DeveloperName from WOM_API_Endpoint__mdt where DeveloperName='WOM_GetVTVFromVTVAPI'];
                
                WOM_API_Endpoint__mdt vtvEndPoint = new WOM_API_Endpoint__mdt( WOM_isnotlive__c = true,WOM_Mock_Request__c= '',WOM_Content_Type__c='',WOM_Mock_Response__c=apiDetails.WOM_Mock_Response__c);
                
                WOM_GetVTVFromVTVAPIHttpCalloutMock mockClass = new WOM_GetVTVFromVTVAPIHttpCalloutMock(200, 'OK', vtvEndPoint.WOM_Mock_Response__c);
                Test.setMock(HttpCalloutMock.class, mockClass);
                HttpRequest vtvRequest =  WOM_GetVTVFromVTVAPI.buildGetVTVInfoByInspectionId('2b155400-2e79-11ea-9be3-c9b200c94e7f', vtvEndPoint);
                HttpResponse vtvResponse = WOM_GetVTVFromVTVAPI.vtvInfoByInspectionIdHTTPCallOut(vtvRequest);
                String salesforceIntMessageId = WOM_APIHelper.buildIntMessage(WOM_APIHelper.TYPE_WOM_ADD_WAITLIST,Int_Values.STATUS_PENDING ,'', '' ,'','','', null);
                WOM_GetVTVFromVTVAPI.parseVTVInfoByInspectionIdResponse('2b155400-2e79-11ea-9be3-c9b200c94e7f',vtvResponse,vtvEndPoint,salesforceIntMessageId);
                
                Int_Message__c intMessage = [Select id,Status__c from Int_Message__c WHERE Type__c=:WOM_APIHelper.TYPE_WOM_GET_VTV_INFORMATION limit 1];
                System.assertEquals('Successful',intMessage.Status__c,'VTV GET - Not Live Test Case - Failed');

            Test.stopTest();
        }
    }
    @isTest
    static void validateVTVNoInspectionIdScenario() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_GetVTVWrapper resultWrapper = WOM_GetVTVFromVTVAPI.getVTVInfoAPICall(null); 
                System.assertEquals('',resultWrapper.identifierCollection[0].identifierItem.condition,'VTV GET - No Inspection Id Test Case - Failed');
            Test.stopTest();
        }
    }
    @isTest
    static void wrapperClassCoverage() {
		WOM_API_Endpoint__mdt getVTVMetadata = WOM_APIHelper.getEndPointDetails(WOM_APIHelper.WOM_GETVTVFROMVTVAPI);
        WOM_GetVTVWrapper vtvObj = (WOM_GetVTVWrapper)JSON.deserialize(getVTVMetadata.WOM_Mock_Response__c,WOM_GetVTVWrapper.Class); 
        vtvObj.identifierCollection[0].identifierItem.auditDate = '';
        vtvObj.identifierCollection[0].identifierItem.comments = '';
        vtvObj.identifierCollection[0].identifierItem.condition = '';
        vtvObj.identifierCollection[0].identifierItem.customerDroppingOff = false;
        vtvObj.identifierCollection[0].identifierItem.customerVehicleId = '';
        vtvObj.identifierCollection[0].identifierItem.dotCommunicationOptIn = false;
        vtvObj.identifierCollection[0].identifierItem.driverEmail = '';
        vtvObj.identifierCollection[0].identifierItem.driverName = '';
        vtvObj.identifierCollection[0].identifierItem.driverPhone = '';
        vtvObj.identifierCollection[0].identifierItem.hhmmss = '';
        vtvObj.identifierCollection[0].identifierItem.inspectionId = '';
        vtvObj.identifierCollection[0].identifierItem.isCarryOut = false;
        vtvObj.identifierCollection[0].identifierItem.isSpareInUse = false;
        vtvObj.identifierCollection[0].identifierItem.kilometers = 0;
        vtvObj.identifierCollection[0].identifierItem.location = '';
        vtvObj.identifierCollection[0].identifierItem.mileage = 0;
        vtvObj.identifierCollection[0].identifierItem.notificationPreference = '';
        vtvObj.identifierCollection[0].identifierItem.objectType = '';
        vtvObj.identifierCollection[0].identifierItem.reason = '';
        vtvObj.identifierCollection[0].identifierItem.replaceAllTires = false;
        vtvObj.identifierCollection[0].identifierItem.replaceAllWheels = false;
        vtvObj.identifierCollection[0].identifierItem.rotationPattern = '';
        vtvObj.identifierCollection[0].identifierItem.siteId = 0;
        vtvObj.identifierCollection[0].identifierItem.source = '';
        vtvObj.identifierCollection[0].identifierItem.tpmsStatus = '';
        vtvObj.identifierCollection[0].identifierItem.wheelLock = false;
        vtvObj.identifierCollection[0].identifierItem.yearkey = '';
        vtvObj.identifierCollection[0].identifierItem.yyyymmdd = '';

        WOM_GetVTVWrapper.Audit auditObj = new WOM_GetVTVWrapper.Audit();
        auditObj.auditDateTime = '';
        auditObj.deviceId = '';
        auditObj.employeeNumber = '';
        auditObj.location = '';
        auditObj.siteId = 0;
        auditObj.source = '';
        auditObj.storeCode = '';
        vtvObj.identifierCollection[0].identifierItem.audit = auditObj;

        WOM_GetVTVWrapper.Customer customerObj = new WOM_GetVTVWrapper.Customer();
        customerObj.customerId = '';
        customerObj.email = '';
        customerObj.firstName = '';
        customerObj.lastName = '';
        customerObj.lastUpdated = '';
        customerObj.phone = '';
        vtvObj.identifierCollection[0].identifierItem.customer = customerObj;

        WOM_GetVTVWrapper.Vehicle vehicleObj = new WOM_GetVTVWrapper.Vehicle();
        vehicleObj.acesBodyType = '';
        vehicleObj.acesDriveId = '';
        vehicleObj.acesVehicleId = '';
        vehicleObj.assemblyId = '';
        vehicleObj.chassisId = '';
        vehicleObj.frontAssembly = '';
        vehicleObj.frontPSI = '';
        vehicleObj.imageURL = '';
        vehicleObj.isDualRearWheel = false;
        vehicleObj.isNonOE = false;
        vehicleObj.isStaggered = false;
        vehicleObj.licensePlate = '';
        vehicleObj.licensePlateState = '';
        vehicleObj.make = '';
        vehicleObj.model = '';
        vehicleObj.rearAssembly = '';
        vehicleObj.rearPSI = '';
        vehicleObj.trimId = '';
        vehicleObj.trimName = '';
        vehicleObj.isVehicleIdPresent = false;
        vehicleObj.vehicleId = '';
        vehicleObj.vin = '';
        vehicleObj.year = '';
        vtvObj.identifierCollection[0].identifierItem.vehicle = vehicleObj;

        WOM_GetVTVWrapper.VehicleAttributes vehicleAttributesObj = new WOM_GetVTVWrapper.VehicleAttributes();
            WOM_GetVTVWrapper.OeTireSizeCollection oeTireSizeObj = new WOM_GetVTVWrapper.OeTireSizeCollection();
                WOM_GetVTVWrapper.OeTireSizeItem oeTireSizeItemObj = new WOM_GetVTVWrapper.OeTireSizeItem();
                    oeTireSizeItemObj.oeTireSize = '';
                    oeTireSizeItemObj.oeTireModel = '';
                    oeTireSizeItemObj.axle = '';
                    oeTireSizeItemObj.width = '';
                    oeTireSizeItemObj.aspectRatio = '';
                    oeTireSizeItemObj.diameter = '';
                    oeTireSizeItemObj.construct = '';
                    oeTireSizeItemObj.loadIndex = 0;
                    oeTireSizeItemObj.speedRating = '';
                    oeTireSizeItemObj.wheelDiameter = '';
                    oeTireSizeItemObj.wheelRimWidth = '';
                    oeTireSizeItemObj.offset = '';
                    oeTireSizeItemObj.wheelSeat = '';
                    oeTireSizeItemObj.psi = 0;
                    oeTireSizeItemObj.tireConstruction = '';
                    oeTireSizeItemObj.lugTorq = '';
                    oeTireSizeItemObj.pitch = '';
                    oeTireSizeItemObj.pitchUom = '';
                    oeTireSizeItemObj.threadDiameter = '';
                    oeTireSizeItemObj.threadDiameterUom = '';
                    oeTireSizeItemObj.lugType = '';
                    oeTireSizeItemObj.circleDiameter = '';
                    oeTireSizeItemObj.hubBore = '';
                    oeTireSizeItemObj.numberOfBolts = 0;
                    oeTireSizeItemObj.oeStatus = '';
                oeTireSizeObj.oeTireSizeItem = oeTireSizeItemObj;
            List<WOM_GetVTVWrapper.OeTireSizeCollection>  oeTireSizeCollectionObj= new List<WOM_GetVTVWrapper.OeTireSizeCollection>();
            oeTireSizeCollectionObj.add(oeTireSizeObj);
            vehicleAttributesObj.oeTireSizeCollection =oeTireSizeCollectionObj;
            WOM_GetVTVWrapper.SpecialNotesCollection specialNotesObj = new WOM_GetVTVWrapper.SpecialNotesCollection();
                WOM_GetVTVWrapper.SpecialNotesItem specialNotesItemObj = new WOM_GetVTVWrapper.SpecialNotesItem();
                    specialNotesItemObj.name='';
                    specialNotesItemObj.lines='';
                specialNotesObj.specialNotesItem = specialNotesItemObj;
            List<WOM_GetVTVWrapper.SpecialNotesCollection> specialNotesCollectionObj = new List<WOM_GetVTVWrapper.SpecialNotesCollection>();            
            specialNotesCollectionObj.add(specialNotesObj);
            vehicleAttributesObj.specialNotesCollection =specialNotesCollectionObj;
        vtvObj.identifierCollection[0].identifierItem.vehicleAttributes = vehicleAttributesObj;
        
        List<WOM_GetVTVWrapper.TireCollection> tireCollectionObj= new List<WOM_GetVTVWrapper.TireCollection>();
            WOM_GetVTVWrapper.TireCollection tireObj = new WOM_GetVTVWrapper.TireCollection();
                WOM_GetVTVWrapper.TireItem tireItemObj = new WOM_GetVTVWrapper.TireItem();
                    tireItemObj.dotNumber = '';
                    tireItemObj.loadIndex = '';
                    tireItemObj.loadRange = '';
                    tireItemObj.recallFlag = false;
                    tireItemObj.servicesPerformed = '';
                    tireItemObj.tireAge = '';
                    tireItemObj.tireLocation = '';
                    tireItemObj.tireStatus = '';
                    tireItemObj.treadEntryMode = '';
                    WOM_GetVTVWrapper.RecallDetails recallDetailsObj = new WOM_GetVTVWrapper.RecallDetails();
                        recallDetailsObj.additionalInfo = '';
                        recallDetailsObj.nhtsaId = '';
                        recallDetailsObj.recallName = '';
                        recallDetailsObj.validFrom = '';
                        recallDetailsObj.validTo = '';
                    tireItemObj.recallDetails = recallDetailsObj;
                    List<WOM_GetVTVWrapper.TreadDepthCollection> treadDepthCollectionObj = new List<WOM_GetVTVWrapper.TreadDepthCollection>();
                        WOM_GetVTVWrapper.TreadDepthCollection treadDepthObj = new WOM_GetVTVWrapper.TreadDepthCollection();
                            WOM_GetVTVWrapper.TreadDepthItem treadDepthItemObj = new WOM_GetVTVWrapper.TreadDepthItem();
                                treadDepthItemObj.confidence = ''; 
                                treadDepthItemObj.reading = ''; 
                                treadDepthItemObj.location = ''; 
                            treadDepthObj.treadDepthItem =treadDepthItemObj;
                        treadDepthCollectionObj.add(treadDepthObj);
                    tireItemObj.treadDepthCollection=treadDepthCollectionObj;
                    List<WOM_GetVTVWrapper.RawReadingCollection> rawReadingCollectionObj = new List<WOM_GetVTVWrapper.RawReadingCollection>();
                        WOM_GetVTVWrapper.RawReadingCollection rawReadingObj = new WOM_GetVTVWrapper.RawReadingCollection();
                            WOM_GetVTVWrapper.RawReadingItem rawReadingItemObj = new WOM_GetVTVWrapper.RawReadingItem();
                                rawReadingItemObj.confidence = ''; 
                                rawReadingItemObj.reading = ''; 
                                rawReadingItemObj.location = ''; 
                            rawReadingObj.rawReadingItem =rawReadingItemObj;
                        rawReadingCollectionObj.add(rawReadingObj);
                    tireItemObj.rawReadingCollection=rawReadingCollectionObj;

                tireObj.tireItem = tireItemObj;
        tireCollectionObj.add(tireObj);
        vtvObj.identifierCollection[0].identifierItem.tireCollection = tireCollectionObj;
        System.assertEquals(0,vtvObj.identifierCollection[0].identifierItem.mileage,'VTV GET - Wrapper Class Testing - Failed');
    }
    
    
    
}