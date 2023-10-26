@isTest
public class Appt_AppointmentDataProcessUtilTest {
    
    @testSetup
    static void setupData() 
    {  //Uncommented the below two lines as a part of Appt3.0
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);
    } 
    
    @isTest static void checkForExistingVehicleChangesTest()
    {   
        Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();   
        Appt_UpdateAppointmentServiceModel updateModel = new Appt_UpdateAppointmentServiceModel();
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
        // updateModel= Appt_AppointmentDataProcessUtil.processVehicleData(updateModel);
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
        Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();   
        
        //Account accRecored = [SELECT id,Name FROM Account LIMIT 1];
        System.debug('***************Start Test************');
        Test.startTest();
        serviceModel.isVisionFeature=null;
        Boolean checkfield = Appt_AppointmentDataProcessUtil.checkForExistingAccountChanges(testAccount);
        Boolean checkForFields = Appt_AppointmentDataProcessUtil.checkAccountFields();
        Test.stopTest();  
        System.debug('***************End Test************');
        System.debug(checkfield);
        //System.assertEquals('Error', results.status, 'Check for error');    
        System.assert(checkfield == true, 'Should return true for a field change on Appt_Email_Opt_In__pc');     
        System.assert(checkForFields == false, 'Should not find any fields to update');     
        
    } 
    
    // Appt 3.0 - Check for an existing Account in salesforce-checkForExistingAccountAppt3    
    @isTest static void appt3checkForExistingAccountChangesTest()
    {          
        Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();   
        Account myAccount = new Account(FirstName = 'Test',LastName = 'Acc');
        insert myAccount; 
        
        System.debug('***************Start Test************');
        Test.startTest(); 
        Account accRecored = [SELECT id, Name FROM Account where id =: myAccount.Id];
        system.debug('accRecored'+accRecored);
        Account testAccount = Appt_AppointmentDataProcessUtil.checkForExistingAccountAppt3(myAccount.Appt3_Customer_Id__c, myAccount.Id);         
        Test.stopTest();  
        System.debug('***************End Test************');
        System.assert(testAccount.FirstName == 'Test', 'Existing account name does not match');     
        
    } 
    
    
    
    // Appt 3.0 - Check for an existing Account in salesforce-checkForExistingVehicleAppt3    
    @isTest static void appt3checkForExistingVehicleAppt3()
    {          
        Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();   
        Account myAccount = new Account(Name='Testys Account');
        insert myAccount; 
        Asset ast = new Asset(Name ='Testys Vehicle', AccountId = myAccount.Id, Vehicle_Id__c = '12345', Appt3_Customer_Vehicle_Id__c ='13456'); 
        insert ast;
        System.debug('***************Start Test************');
        Test.startTest();
        Asset checkAst = new Asset();  
        checkAst = Appt_AppointmentDataProcessUtil.checkForExistingVehicleAppt3('13456', myAccount.Id);        
        Test.stopTest();  
        System.debug('***************End Test************');
        System.assert(checkAst.Vehicle_Id__c == '12345', 'Existing vehicle id does not match');     
        
    } 
    /*  @isTest static void checkForExistingVehicleChangesforOldAppt()
{   

Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();  
Account myAccount = new Account(Name='Testys Account');
insert myAccount; 


System.debug('***************Start Test************');
Test.startTest();
Asset ast = new Asset();  
Boolean Vehicle = Appt_AppointmentDataProcessUtil.checkForExistingVehicleChanges(ast);
Test.stopTest();  
System.debug('***************End Test************');
//System.debug(checkfield);
//System.assertEquals('Error', results.status, 'Check for error');    
// System.assert(checkfield == true, 'Should return true for a field change on Appt_Email_Opt_In__pc');     
// System.assert(checkForFields == false, 'Should not find any fields to update');     

} */
    
    
    @isTest static void buildAccounttest()
        
    {          
        
        Appt_AppointmentDataProcessUtil.processRecord.customerId ='12345';
        Appt_AppointmentDataProcessUtil.processRecord.isVisionFeature = true;
        Appt_AppointmentDataProcessUtil.processRecord.middleInitial ='MI';
        Appt_AppointmentDataProcessUtil.processRecord.Suffix ='Mr';
        Appt_AppointmentDataProcessUtil.processRecord.country = 'United States';
        Appt_AppointmentDataProcessUtil.processRecord.state = 'AZ';
        Appt_AppointmentDataProcessUtil.processRecord.city = 'Chandler';
        Appt_AppointmentDataProcessUtil.processRecord.zipCode ='85248-3559';
        Appt_AppointmentDataProcessUtil.processRecord.showMyAccount = true;
        Appt_AppointmentDataProcessUtil.processRecord.showAAAMember = true;
        Appt_AppointmentDataProcessUtil.processRecord.showDTCC = true;
        Appt_AppointmentDataProcessUtil.processRecord.showMilitary = true;
        Appt_AppointmentDataProcessUtil.processRecord.companyName ='TestCompany';
        Appt_AppointmentDataProcessUtil.processRecord.companyName2 ='TestCompany2';
        Appt_AppointmentDataProcessUtil.processRecord.fleetNumber ='678903';
        Test.startTest();
        Account testAccount1 = Appt_AppointmentDataProcessUtil.buildAccount();
        System.assertEquals('12345', testAccount1.Appt3_Customer_Id__c, 'Customer Id is 12345'); 
        Test.stopTest(); 
        
        
        
    }
    
            @isTest static void buildVehicletest()
        
    {
        
        Appt_AppointmentDataProcessUtil.processRecord.model='Toyota';
        Appt_AppointmentDataProcessUtil.processRecord.color='Red';
        Appt_AppointmentDataProcessUtil.processRecord.year='2022';
        Appt_AppointmentDataProcessUtil.processRecord.isVisionFeature = true;
        Test.startTest();
        Asset testVehicle2 = Appt_AppointmentDataProcessUtil.buildVehicle();
        System.assertEquals('Red', testVehicle2.Appt3_Color__c, 'Vehicle color is Red');
        Test.stopTest(); 
        
        
        
    }
    
    @isTest static void checkForExistingAccountChangesWhenNoneMatchesTest(){
        Account existingAccount = new Account();
        Appt_AppointmentDataProcessUtil.processRecord.textOptIn=true;
        existingAccount.Appt_SMS_Opt_In__pc = Appt_AppointmentDataProcessUtil.processRecord.textOptIn;
        existingAccount.FirstName = Appt_AppointmentDataProcessUtil.processRecord.firstName;
        existingAccount.LastName = Appt_AppointmentDataProcessUtil.processRecord.lastName;
        existingAccount.POS_Customer_Id__c = Appt_AppointmentDataProcessUtil.processRecord.posCustomerId;
        existingAccount.Hybris_Customer_Id__c = Appt_AppointmentDataProcessUtil.processRecord.hybrisCustomerId;
        existingAccount.GUID__c = Appt_AppointmentDataProcessUtil.processRecord.customerGuid;
        existingAccount.Email__c = Appt_AppointmentDataProcessUtil.processRecord.emailAddress;
        existingAccount.PersonEmail = Appt_AppointmentDataProcessUtil.processRecord.emailAddress;
        existingAccount.PersonHomePhone = Appt_AppointmentDataProcessUtil.processRecord.homePhoneNumber;
        existingAccount.PersonMobilePhone = Appt_AppointmentDataProcessUtil.processRecord.mobilePhoneNumber;
        existingAccount.Phone = Appt_AppointmentDataProcessUtil.processRecord.workPhoneNumber;
        existingAccount.ShippingStreet = Appt_AppointmentDataProcessUtil.processRecord.address1;
        existingAccount.ShippingCity = Appt_AppointmentDataProcessUtil.processRecord.city;
        existingAccount.ShippingState = Appt_AppointmentDataProcessUtil.processRecord.state ;
        existingAccount.ShippingPostalCode = Appt_AppointmentDataProcessUtil.processRecord.zipCode;
        existingAccount.ShippingCountry = Appt_AppointmentDataProcessUtil.processRecord.country ;
        existingAccount.Appt_Customer_Type__c = Appt_AppointmentDataProcessUtil.processRecord.customerType;
        Appt_AppointmentDataProcessUtil.processRecord.emailAddressOptIn=true;
        existingAccount.Appt_Email_Opt_In__pc = Appt_AppointmentDataProcessUtil.processRecord.emailAddressOptIn;
        existingAccount.Appt3_Customer_Id__c = Appt_AppointmentDataProcessUtil.processRecord.customerId ;
        Appt_AppointmentDataProcessUtil.processRecord.showMilitary=true;
        Appt_AppointmentDataProcessUtil.processRecord.showAAAMember=true;
        Appt_AppointmentDataProcessUtil.processRecord.showDTCC=true;
        Appt_AppointmentDataProcessUtil.processRecord.showMyAccount=true;
        existingAccount.Appt3_Military__c = Appt_AppointmentDataProcessUtil.processRecord.showMilitary;
        existingAccount.Appt3_AAA_Membership__c = Appt_AppointmentDataProcessUtil.processRecord.showAAAMember;
        existingAccount.Appt3_Private_Label_Cardholder__c = Appt_AppointmentDataProcessUtil.processRecord.showDTCC ;
        existingAccount.Appt3_My_Account__c = Appt_AppointmentDataProcessUtil.processRecord.showMyAccount;       
         Appt_AppointmentDataProcessUtil.processRecord.isVisionFeature=true;
        Test.startTest();
        Boolean result = Appt_AppointmentDataProcessUtil.checkForExistingAccountChanges(existingAccount);  
        System.assert(result==false, 'checkExistingAccount results false');
        Test.stopTest();
        
    }
    
    @isTest static void checkForExistingVehicleChangesWhenNoneMatchesTest()
    {
        Asset existingVehicle = new Asset();
        Appt_AppointmentDataProcessUtil.processRecord.isVisionFeature=true;
        existingVehicle.Appt3_Fitment_Lift_Id__c = Appt_AppointmentDataProcessUtil.processRecord.fitmentLiftId;
        existingVehicle.Appt3_Front_Tire_Size__c = Appt_AppointmentDataProcessUtil.processRecord.frontTireSize;
        existingVehicle.Appt3_Rear_Tire_Diameter__c = Appt_AppointmentDataProcessUtil.processRecord.frontTireDiameter;
        existingVehicle.Appt3_Assembly_Type__c = Appt_AppointmentDataProcessUtil.processRecord.assemblyType;
        existingVehicle.Appt3_Color__c = Appt_AppointmentDataProcessUtil.processRecord.color;
        existingVehicle.Appt3_Generic_Vehicle_SubCategory__c = Appt_AppointmentDataProcessUtil.processRecord.genericVehicleCategory;
        existingVehicle.Appt3_Generic_Vehicle_SubCategory__c = Appt_AppointmentDataProcessUtil.processRecord.genericVehicleSubCategory;
        existingVehicle.Vehicle_License_Plate__c = Appt_AppointmentDataProcessUtil.processRecord.licensePlate;
        existingVehicle.Hybris_Customer_Vehicle_Id__c = Appt_AppointmentDataProcessUtil.processRecord.hybrisCustomerVehicleId;
        existingVehicle.POS_Customer_Vehicle_Id__c = Appt_AppointmentDataProcessUtil.processRecord.posCustomerVehicleId;
        Test.startTest();
        Boolean result = Appt_AppointmentDataProcessUtil.checkForExistingVehicleChanges(existingVehicle);
        System.assert(result==false, 'checkExistingAccount results false');
        Test.stopTest();
               
        
    }
     // Appt 3.0 - Check for an existing Account in salesforce-checkForExistingAccountAppt3    
    @isTest static void appt3checkForExistingAccountChangesTest2()
    {          
        Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();   
        Account myAccount = new Account(FirstName = 'Test',LastName = 'Acc');
        Appt_AppointmentDataProcessUtil.processRecord.isVisionFeature = true;
        insert myAccount; 
        
        System.debug('***************Start Test************');
        Test.startTest(); 
        Account accRecored = [SELECT id, Name FROM Account where id =: myAccount.Id];
        system.debug('accRecored'+accRecored);
        Account testAccount = Appt_AppointmentDataProcessUtil.checkForExistingAccountAppt3(myAccount.Appt3_Customer_Id__c, myAccount.Id);         
        Test.stopTest();  
        System.debug('***************End Test************');
        System.assert(testAccount.FirstName == 'Test', 'Existing account name does not match');     
        
    } 
    
      @isTest static void appt3checkForExistingAccountChangesWhereClauseTest()
    {          
        Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();   
        Account myAccount = new Account(FirstName = 'Test',LastName = 'Acc', Appt3_Customer_Id__c='1121');
        Appt_AppointmentDataProcessUtil.processRecord.isVisionFeature = true;
        insert myAccount; 
        
        System.debug('***************Start Test************');
        Test.startTest(); 
       // Account accRecored = [SELECT id, Name FROM Account where id =: myAccount.Id];
        //system.debug('accRecored'+accRecored);
        Account testAccount = Appt_AppointmentDataProcessUtil.checkForExistingAccountAppt3(myAccount.Appt3_Customer_Id__c, null);         
        Test.stopTest();  
        system.debug('testAccount'+testAccount);
        System.debug('***************End Test************');
        System.assert(testAccount.FirstName == 'Test', 'Existing account name does not match');     
        
    } 
    
    
       @isTest static void buildAccounttestOrg(){          
        Appt_AppointmentDataProcessUtil.processRecord.isVisionFeature = true;
        Appt_AppointmentDataProcessUtil.processRecord.customerType ='FLEET';
        Appt_AppointmentDataProcessUtil.processRecord.lastName =null;
        Appt_AppointmentDataProcessUtil.processRecord.state = 'AZ';
        Appt_AppointmentDataProcessUtil.processRecord.companyName ='TestCompany';
        Appt_AppointmentDataProcessUtil.processRecord.companyName2 ='TestCompany2';
        Test.startTest();
        Account testAccount1 = Appt_AppointmentDataProcessUtil.buildAccount();
        System.debug('LastName ------------->' + Appt_AppointmentDataProcessUtil.processRecord.lastName); 
         System.debug('LastName2 ------------->' + testAccount1.LastName); 
        System.assertEquals('TestCompany2', testAccount1.LastName, 'TestCompany2'); 
        Test.stopTest(); 
           
    }
     @isTest static void buildAccounttestOrg2(){         
        Appt_AppointmentDataProcessUtil.processRecord.isVisionFeature = true;
        Appt_AppointmentDataProcessUtil.processRecord.customerType ='FLEET';
        Appt_AppointmentDataProcessUtil.processRecord.lastName =null;
        Appt_AppointmentDataProcessUtil.processRecord.state = 'AZ';
        Appt_AppointmentDataProcessUtil.processRecord.companyName = null;
        Appt_AppointmentDataProcessUtil.processRecord.companyName2 ='TestCompany2';
        Test.startTest();
        Account testAccount1 = Appt_AppointmentDataProcessUtil.buildAccount();
        System.assertEquals('TestCompany2', testAccount1.LastName, 'TestCompany2'); 
        Test.stopTest(); 
     }
    
    //SO-559 
    @isTest static void processAcountFleetTestCoverage(){   
    	Appt_CreateAppointmentServiceModel crtServiceMdl = new Appt_CreateAppointmentServiceModel();
        crtServiceMdl.customerType = 'Fleet';
        crtServiceMdl.fleetNumber = '0000065629';
        crtServiceMdl.companyName = 'Keller Services';
		crtServiceMdl.emailAddress = 'test@test.com';
        crtServiceMdl.firstName = 'Test B2B';
        crtServiceMdl.lastName = 'Driver Contact';
        crtServiceMdl.mobilePhoneNumber = '8888888888';
        Account acnt = new Account();
        acnt.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        acnt.Name = 'Keller Service';
        //acnt.LastName = 'test';
        acnt.ECC_Account_Number__c = '65629';
        acnt.Fleet_AR_App_Status__c = 'Approved';
        acnt.Country__c = 'United States';
        acnt.Selected_State__c = 'Alabama';
        insert acnt;
        Appt_AppointmentDataProcessUtil.processAccountData(crtServiceMdl);
        
        Id b2bDriverContactRecordTypeId =  Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Driver').getRecordTypeId();
        Contact cnct = new Contact(RecordTypeId = b2bDriverContactRecordTypeId);
        cnct.AccountId = acnt.Id;
        cnct.FirstName = crtServiceMdl.firstName+'Test'.trim();
        cnct.LastName = crtServiceMdl.lastName+'TestLName'.trim();
        cnct.Email = 'test123@test.com';
        cnct.Phone = '7878787878';
        
        insert cnct;
        Appt_AppointmentDataProcessUtil.processAccountData(crtServiceMdl);
        
        
    }
    
    @isTest static void processAcountRetailTestCoverage(){  
        Appt_CreateAppointmentServiceModel crtServiceMdl = new Appt_CreateAppointmentServiceModel();
        crtServiceMdl.customerType = 'Retail';
        crtServiceMdl.fleetNumber = '0000065629';
        crtServiceMdl.companyName = 'Keller Services';
		crtServiceMdl.emailAddress = 'test@test.com';
        crtServiceMdl.firstName = 'Test B2B';
        crtServiceMdl.lastName = 'Driver Contact';
        crtServiceMdl.mobilePhoneNumber = '8888888888';
        Appt_AppointmentDataProcessUtil.processAccountData(crtServiceMdl);
        
        Account acnt = new Account();
        acnt.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        acnt.FirstName = 'Keller';
        acnt.LastName = 'Service';
        acnt.ECC_Account_Number__c = '65629';
        acnt.Fleet_AR_App_Status__c = 'Approved';
        acnt.Country__c = 'United States';
        acnt.Selected_State__c = 'Alabama';
        insert acnt;
        
        Appt_UpdateAppointmentServiceModel updtServiceMdl = new Appt_UpdateAppointmentServiceModel();
        
        updtServiceMdl.accountId = acnt.Id;
        updtServiceMdl.contactId = acnt.PersonContactId;
        updtServiceMdl.posCustomerId = '123456';
        updtServiceMdl.customerGuid = '1234454';
        updtServiceMdl.hybrisCustomerId = '654321';
        
        Appt_AppointmentDataProcessUtil.processAccountData(updtServiceMdl);
    }
	
	// SO-559 END 
}