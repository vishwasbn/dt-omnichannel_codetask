@isTest (seeAllData = false)
private with sharing class Appt_AppointmentServiceTest {
   
    @testSetup static void createTestClassData() {

        Appt_TestUtil.basicAppointment_StoreConfiguration();

        //FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED);
        //FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING );

        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account custAccount = new Account(RecordTypeId = personAccountRecordTypeId);
        custAccount.POS_Customer_Id__c = '1111111111';
        custAccount.LastName = 'Johnson';
        custAccount.PersonEmail = 'test@test.com';
        insert custAccount;

        Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
        Asset returnVeh = new Asset(RecordTypeId = vehRecordTypeId, accountId = custAccount.Id);
        returnVeh.name = '2015 Isuzu I-Mark';
        returnVeh.Hybris_Customer_Vehicle_Id__c = '1088';
        returnVeh.Vehicle_Manufacture_Year__c = '2015';
        returnVeh.Vehicle_Make__c = 'Isuzu';
        returnVeh.Vehicle_Model__c = 'I-Mark';
        insert returnVeh;

    }

    @IsTest
    static void testCreateAppointmentBackSuccess(){

        Appt_CreateAppointmentServiceModel.Articles item = new Appt_CreateAppointmentServiceModel.Articles();
        item.articleId = '98911';

        Appt_CreateAppointmentServiceModel.Articles item2 = new Appt_CreateAppointmentServiceModel.Articles();
        item2.articleId = '98977';

        List<Appt_CreateAppointmentServiceModel.Articles> itemss = new List<Appt_CreateAppointmentServiceModel.Articles>();
        itemss.add(item);
        itemss.add(item2);


        Appt_CreateAppointmentServiceModel model1 = new Appt_CreateAppointmentServiceModel();
        model1.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING;
        model1.posCustomerId = '';
        model1.hybrisCustomerId = ''; //0017c00000lGmg2AAC - ApptDev1
        model1.customerGuid = '';
        model1.siteId = '1235';
        model1.source = Appt_ConstantValues.APPOINTMENT_SOURCE_POS;
        model1.orderType = 'ROPIS';
        Date tday = Date.today();
        model1.appointmentDate = tday.addDays(7);
        model1.consultStartTime = '1620';
        model1.consultEndTime = '1640';
        model1.backOfficeStartTime = '1640';
        model1.backOfficeEndTime = '1700';
        model1.customerType = Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        model1.firstName = 'Philbert';
        model1.lastName = 'Chapinlysternford';
        model1.emailAddress = 'yup@test.com';
        model1.mobilePhoneNumber = '1212121122';
        model1.homePhoneNumber = '9876541230';
        model1.address1 = '123 Fake St';
        model1.zipCode = '92865';
        model1.city = 'Orange';
        model1.state = 'California';
        model1.country = 'United States';
        model1.year = '2020';
        model1.make = 'Ford';
        model1.model = 'F150';

        model1.articles = itemss;

        model1.comments = 'This is a test of the emergency broadcast network';



        
        Test.startTest();
        Appt_CreateAppointmentServiceModel modelOut = Appt_SystemService.createAppointment(model1);
        
        Test.stopTest();
        System.debug(modelOut);
        System.debug(modelOut.appointmentStatus);
        System.assert((modelOut.appointmentId != null && modelOut.appointmentId.length() > 1), 'Expecting appointmentId to be populated. modelOut.appointmentId='+modelOut.appointmentId);
        System.assert((modelOut.appointmentStatus == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING), 'Expecting appointmentStatus to be Pending. modelOut.status='+modelOut.status);

        
    }

    @IsTest
    static void testCreateAppointmentBothSuccess(){

        Appt_CreateAppointmentServiceModel.Articles item = new Appt_CreateAppointmentServiceModel.Articles();
        item.articleId = '98911';

        Appt_CreateAppointmentServiceModel.Articles item2 = new Appt_CreateAppointmentServiceModel.Articles();
        item2.articleId = '98977';

        List<Appt_CreateAppointmentServiceModel.Articles> itemss = new List<Appt_CreateAppointmentServiceModel.Articles>();
        itemss.add(item);
        itemss.add(item2);


        Appt_CreateAppointmentServiceModel model1 = new Appt_CreateAppointmentServiceModel();
        model1.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING;
        model1.posCustomerId = '1111111111';
        model1.hybrisCustomerId = 'qwe'; //0017c00000lGmg2AAC - ApptDev1
        model1.customerGuid = 'qwe';
        model1.siteId = '1235';
        model1.source = Appt_ConstantValues.APPOINTMENT_SOURCE_WEB;
        model1.orderType = 'ROPIS';
        Date tday = Date.today();
        model1.appointmentDate = tday.addDays(7);
        model1.consultStartTime = '1420';
        model1.consultEndTime = '1440';
        model1.backOfficeStartTime = '1440';
        model1.backOfficeEndTime = '1500';
        model1.customerType = Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        model1.firstName = 'Philbert';
        model1.lastName = 'Chapinlysternford';
        model1.emailAddress = 'yup@test.com';
        model1.mobilePhoneNumber = '1212121122';
        model1.homePhoneNumber = '9876541230';
        model1.address1 = '123 Fake St';
        model1.zipCode = '92865';
        model1.city = 'Orange';
        model1.state = 'California';
        model1.country = 'United States';
        model1.year = '2020';
        model1.make = 'Ford';
        model1.model = 'F150';
        model1.hybrisCustomerVehicleId = '1088';
        model1.recipientFirstName = 'Ricky';
        model1.recipientLastName = 'Bobby';
        model1.recipientEmail = 'ricky@bobby.com';
        model1.recipientPhone = '8005551212';

        model1.articles = itemss;

        model1.comments = 'This is a test of the emergency broadcast network';

        Appt_UpdateAppointmentServiceModel modelUpdate = new Appt_UpdateAppointmentServiceModel();
        modelUpdate.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        modelUpdate.checkAvailabilityFirst = true;
        modelUpdate.posCustomerId = '1111111111';
        modelUpdate.hybrisCustomerId = 'qwet'; //0017c00000lGmg2AAC - ApptDev1
        modelUpdate.customerGuid = 'qwed';
        modelUpdate.siteId = '1235';
        modelUpdate.source = Appt_ConstantValues.APPOINTMENT_SOURCE_WEB;
        modelUpdate.orderType = 'ROPIS';
        Date tooday = Date.today();
        modelUpdate.appointmentDate = tooday.addDays(1);
        modelUpdate.consultStartTime = '1520';
        modelUpdate.consultEndTime = '1540';
        modelUpdate.backOfficeStartTime = '1540';
        modelUpdate.backOfficeEndTime = '1600';
        modelUpdate.customerType = Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        modelUpdate.firstName = 'Philbert';
        modelUpdate.lastName = 'Chapinlysternford';
        modelUpdate.emailAddress = 'yupppy@test.com';
        modelUpdate.mobilePhoneNumber = '1212121122';
        modelUpdate.homePhoneNumber = '9876541230';
        modelUpdate.address1 = '123 Fake St';
        modelUpdate.zipCode = '92865';
        modelUpdate.city = 'Orange';
        modelUpdate.state = 'California';
        modelUpdate.country = 'United States';
        modelUpdate.year = '2020';
        modelUpdate.make = 'Ford';
        modelUpdate.model = 'F250';
        modelUpdate.hybrisCustomerVehicleId = '1088';
        modelUpdate.recipientFirstName = 'Ricky';
        modelUpdate.recipientLastName = 'Bobby';
        modelUpdate.recipientEmail = 'ricky@bobby.com';
        modelUpdate.recipientPhone = '8005559999';

        
        Test.startTest();
        
        Appt_CreateAppointmentServiceModel modelOut = Appt_SystemService.createAppointment(model1);
        System.assert((modelOut.appointmentId != null && modelOut.appointmentId.length() > 1), 'Expecting appointmentId to be populated. modelOut.appointmentId='+modelOut.appointmentId);
        System.assert((modelOut.appointmentStatus == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING), 'Expecting appointmentStatus to be Pending. modelOut.status='+modelOut.status);

        Appt_SystemService.getTimeSlotsBySite('1235', Date.today(), Date.today().addDays(2));

        //expect this one to fail with null appointmentId
        Appt_CreateAppointmentServiceModel modelOutUpdate = Appt_SystemService.updateAppointment(modelUpdate);
        System.assert((modelOutUpdate.appointmentId == null), 'Expecting modelOutUpdate appointmentId to be null. modelOutUpdate.appointmentId='+modelOutUpdate.appointmentId);
        System.assert((modelOutUpdate.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR), 'Expecting modelOutUpdate status to be Error. modelOutUpdate.appointmentId='+modelOutUpdate.appointmentId);

        //this now should work
        modelUpdate.appointmentId = modelOut.appointmentId;
        Appt_CreateAppointmentServiceModel modelOutUpdate2 = Appt_SystemService.updateAppointment(modelUpdate);
        
        Test.stopTest();

        System.assert((modelOutUpdate2.appointmentId != null && modelOutUpdate2.appointmentId.length() > 1), 'Expecting modelOutUpdate appointmentId to be populated. modelOutUpdate2.appointmentId='+modelOutUpdate2.appointmentId);
        System.assert((modelOutUpdate2.appointmentStatus == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED), 'Expecting modelOutUpdate appointmentStatus to be Scheduled. modelOutUpdate2.status='+modelOutUpdate2.status);

        
    }

    @IsTest
    static void testCreateAppointmentError(){

        Appt_CreateAppointmentServiceModel.Articles item = new Appt_CreateAppointmentServiceModel.Articles();
        item.articleId = '98911';

        Appt_CreateAppointmentServiceModel.Articles item2 = new Appt_CreateAppointmentServiceModel.Articles();
        item2.articleId = '98977';

        List<Appt_CreateAppointmentServiceModel.Articles> itemss = new List<Appt_CreateAppointmentServiceModel.Articles>();
        itemss.add(item);
        itemss.add(item2);


        Appt_CreateAppointmentServiceModel model1 = new Appt_CreateAppointmentServiceModel();
        model1.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING;
        model1.posCustomerId = '';
        model1.hybrisCustomerId = '161654654'; //0017c00000lGmg2AAC - ApptDev1
        model1.customerGuid = '';
        model1.siteId = '1235';
        model1.source = Appt_ConstantValues.APPOINTMENT_SOURCE_POS;
        model1.orderType = 'ServiceAppointment';
        model1.appointmentDate = Date.newInstance(2021, 2, 3);
        model1.consultStartTime = '1620';
        model1.consultEndTime = '1640';
        model1.backOfficeStartTime = '1640';
        model1.backOfficeEndTime = '1700';
        model1.customerType = Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        model1.firstName = 'Philbert';
        model1.lastName = 'Chapinlysternford';
        model1.emailAddress = 'yup@test.com';
        model1.mobilePhoneNumber = '1212121122';
        model1.homePhoneNumber = '9876541230';
        model1.address1 = '123 Fake St';
        model1.zipCode = '92865';
        model1.city = 'Orange';
        model1.state = 'California';
        model1.country = 'United States';
        model1.year = '2020';
        model1.make = 'Ford';
        model1.model = 'F150';

        model1.articles = itemss;

        model1.comments = 'This is a test of the emergency broadcast network';

        
        Test.startTest();
        Appt_CreateAppointmentServiceModel modelOut = Appt_SystemService.createAppointment(model1);
        
        Test.stopTest();

        System.assert((modelOut.appointmentId == null), 'Expecting appointmentId to be null. modelOut.appointmentId='+modelOut.appointmentId);
        System.assert((modelOut.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR), 'Expecting status to be Error. modelOut.status='+modelOut.status);

        
    }

    @isTest
    static void testGetSiteAvailability(){
        Appt_GetAvailabilityServiceModel availModel = new Appt_GetAvailabilityServiceModel();

        List<ServiceAppointment> sas = [ SELECT Id, Account.SAP_STORE_ID__c FROM ServiceAppointment ];
        System.assertEquals(true, sas.size() > 0, 'Couldnt retrieve service appointments');

        availModel.siteId = '1235';
        availModel.startDate = Date.today();
        availModel.endDate = Date.today().addDays(5);
        availModel.orderType = 'ServiceAppointment';
        availModel.customerType = Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        availModel.source = 'POS';

        Test.startTest();

        Appt_SiteAvailabilityModel returnModel = Appt_SystemService.getSiteAvailability(availModel);
        System.debug('return model = ' +returnModel);

        Test.stopTest();

        System.assertEquals(true, returnModel.status.equals('Success'));
    }

    
    @isTest
    static void testCheckAvailability(){
        Appt_GetAvailabilityServiceModel availModel = new Appt_GetAvailabilityServiceModel();

        List<ServiceAppointment> sas = [ SELECT Id, Account.SAP_STORE_ID__c FROM ServiceAppointment ];
        System.assertEquals(true, sas.size() > 0, 'Couldnt retrieve service appointments');

        System.debug('returned sas = ' +sas);
        availModel.siteId = '1235';

        availModel.appointmentDate = Datetime.now().addDays(1).format('EEEE') != 'Sunday' ? Date.today().addDays(1) : Date.today().addDays(2);
        availModel.orderType = 'ServiceAppointment';
        availModel.customerType = Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        availModel.source = 'POS';
        availModel.backOfficeStartTime = '1400';

        System.debug('avail model = ' +availModel);

        Test.startTest();

        Boolean result = Appt_SystemService.checkAvailability(availModel);

        Test.stopTest();

        System.assertEquals(true, result);
    }
}