@isTest
public class Appt_AppointmentDataProcessUtilTest {

    @testSetup
    static void setupData() 
    {
        //List<ServiceAppointment> createData = new List<ServiceAppointment>();
        //createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);
    } 

    @isTest static void checkForExistingVehicleChangesTest()
    {   
        Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();   
        Account myAccount = new Account(Name='Testys Account');
        Contact myContact = new Contact();
        myContact.FirstName = 'Testy';
        myContact.LastName = 'Testerson';
        insert myContact;
        insert myAccount;
        
        serviceModel.accountId = myAccount.id;
        serviceModel.contactId = myContact.id;
        System.debug('***************Start Test************');
        Test.startTest();
        serviceModel = Appt_AppointmentDataProcessUtil.processVehicleData(serviceModel);
        System.debug(serviceModel);
        Test.stopTest();  
        System.debug('***************End Test************');
        System.debug(serviceModel);
        System.debug(serviceModel.assetId);
        //System.assertEquals('Error', results.status, 'Check for error');    
        System.assert(serviceModel.assetId == null, 'Vehicle should not have been created');     
    } 

    @isTest static void checkReferenceVehicleLookup()
    {   
        Reference__c trimRef = new Reference__c();
        //Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
        trimRef.Vehicle_Fitment_Id__c = '123';
        trimRef.Name = 'Test Ref';


        Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();   
        Account myAccount = new Account(Name='Testys Account');
        insert myAccount;
        Contact myContact = new Contact();
        myContact.FirstName = 'Testy';
        myContact.LastName = 'Testerson';
        myContact.AccountId = myAccount.id;
        insert myContact;        
        insert trimRef;
        
        serviceModel.accountId = myAccount.id;
        serviceModel.contactId = myContact.id;
        serviceModel.vehicleId = '123';
        System.debug('***************Start Test************');
        Test.startTest();
        serviceModel = Appt_AppointmentDataProcessUtil.processVehicleData(serviceModel);
        System.debug(serviceModel);
        Test.stopTest();  
        System.debug('***************End Test************');
        System.debug(serviceModel);
        System.debug(serviceModel.assetId);
        //System.assertEquals('Error', results.status, 'Check for error');    
        System.assert(serviceModel.assetId != null, 'check for vehicle id');       
    } 

    @isTest static void checkReferenceVehicleTrimLookup()
    {   
        Reference__c trimRef = new Reference__c();
        //Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
        trimRef.Trim_Id__c = '123';
        trimRef.Name = 'Test Ref';


        Appt_UpdateAppointmentServiceModel serviceModel = new Appt_UpdateAppointmentServiceModel();   
        Account myAccount = new Account(Name='Testys Account');
        insert myAccount;
        Contact myContact = new Contact();
        myContact.FirstName = 'Testy';
        myContact.LastName = 'Testerson';
        myContact.AccountId = myAccount.id;
        insert myContact;        
        insert trimRef;
        
        serviceModel.accountId = myAccount.id;
        serviceModel.contactId = myContact.id;
        serviceModel.trimId = '123';
        System.debug('***************Start Test************');
        Test.startTest();
        
        serviceModel = Appt_AppointmentDataProcessUtil.processVehicleData(serviceModel);
        
        Test.stopTest();  
        System.debug('***************End Test************');
        System.debug(serviceModel);
        System.debug(serviceModel.assetId);
        //System.assertEquals('Error', results.status, 'Check for error');    
        System.assert(serviceModel.assetId != null, 'check for vehicle id');  
    } 

    @isTest static void checkForExistingAccountChangesTest()
    {   
       
        Account testAccount = new Account();  
        
        System.debug('***************Start Test************');
        Test.startTest();
        Boolean checkfield = Appt_AppointmentDataProcessUtil.checkForExistingAccountChanges(testAccount);
        Boolean checkForFields = Appt_AppointmentDataProcessUtil.checkAccountFields();
        Test.stopTest();  
        System.debug('***************End Test************');
        System.debug(checkfield);
        //System.assertEquals('Error', results.status, 'Check for error');    
        System.assert(checkfield == true, 'Should return true for a field change on Appt_Email_Opt_In__pc');     
        System.assert(checkForFields == false, 'Should not find any fields to update');     

    } 

}