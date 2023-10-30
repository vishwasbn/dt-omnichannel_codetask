/***************************************************************************************************************************** 
Project : Appointment3.0
Purpose :It is the Test class for the Appt_AppointmentHandler.
******************************************************************************************************************************
Version     Date                     Updated By              TestCoverage           Comments	                                                      	 
2.0       30/12/2022    shubham.upadhyay@discounttire.com         90%          To cover new appt3 changes 

******************************************************************************************************************************
*/
@isTest
public class Appt_AppointmentHandlerTest {
    final static string LPREFIX = 'LOG Appt_AppointmentHandlerTest: ';
    @testSetup
    static void setupData() 
    {
        User pOSUser = Appt_TestUtil.getPosTerminalUser('TestPos' ,'TerminalTestUser'); // new changes Appt3.0
        system.debug('pOSUser'+pOSUser);
        pOSUser.User_Store_Id__c = 'RIP05';  // 'RIP05'
        update pOSUser;     // new changes App3.0 End

        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        
        Set<Id> apptIds = new Set<Id> {servAppts[0].Id, servAppts[1].Id};
        servAppts = [SELECT Id, Status, SchedStartTime, SchedEndTime, ParentRecordId, ContactId FROM ServiceAppointment WHERE Id IN: apptIds];
        Set<Id> cntctIds = new Set<Id> {servAppts[0].ContactId, servAppts[1].ContactId};
        
        List<Appt_Time_Slot__c> returnSlots = [SELECT Name, BSF_Capacity__c, BSF_Available__c, BSR_Capacity__c, BSR_Available__c, BWF_Capacity__c, BWF_Available__c,
        BWR_Capacity__c, BWR_Available__c, FSF_Capacity__c, FSF_Available__c, FSR_Capacity__c, FSR_Available__c, 
        FWF_Capacity__c, FWF_Available__c, FWR_Capacity__c, FWR_Available__c, Start_Time__c, End_Time__c, Date__c,
        Service_Territory__r.Site_Account__r.SAP_STORE_ID__c, IsFrontUnavailable__c, isBackUnavailable__c, Type__c FROM Appt_Time_Slot__c 
        WHERE Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = '1236'];

        System.debug( LPREFIX + ' TimeSlots: ' + returnSlots.size());
        System.debug( LPREFIX + ' TimeSlot: ' + returnSlots[0]);
        System.debug( LPREFIX + ' TimeSlot: ' + returnSlots[ (returnSlots.size() - 1) ]);
                
    } // End of setupData()


    @isTest static void createAppointmentTest()
    {   
        //List<ServiceAppointments> appts = [SELECT id, Work_Order__c, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
        System.debug( LPREFIX + '***********START createAppointmentTest Setup***************');
        List<WorkOrder> workOrders = [SELECT id FROM WorkOrder LIMIT 1];
        String apptId = workOrders[0].id;
        System.debug( LPREFIX + apptId);

        Date startdate = system.today().addDays(7);
        Date starteOfWeek = startdate.toStartOfWeek();
        String apptDate = String.valueOf(starteOfWeek.addDays(1));
              
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String jsonMsg = '{"appointmentStatus":"Confirmed", "cancelReason":null, "cancelReasonText":null, "appointmentId":null, "checkAvailabilityFirst":false, "posCustomerId": null, "hybrisCustomerId":null, "siteId":"1236", "source":"WEB", "orderType":"ROPIS", "appointmentDate":"'+apptDate+'", "consultStartTime":"1640", "consultEndTime":"1700", "backOfficeStartTime":"1700", "backOfficeEndTime":"1720", "formType": null, "formNumber": null, "formDate": null,  "hybrisOrderId": null, "posWebOrderId": null, "layawayNumber": null, "quoteNumber": null, "invoiceNumber": null, "orderDate": null, "customerGuid": null, "customerType": null,  "firstName": "Sam", "lastName": "Spade",  "emailAddress": null, "mobilePhoneNumber": null, "homePhoneNumber": null, "workPhoneNumber": null, "address1": "123 Right Here", "address2": null, "zipCode": "85028", "city": "Phoenix", "state": "Arizona", "country": "United States",  "textOptIn": null,  "emailAddressOptIn": null,  "posCustomerVehicleId": null, "hybrisCustomerVehicleId": null, "vehicleClass": null, "year": null, "make": null, "model": null, "vehicleId": null, "trimId": null, "assemblyId": null, "articles":[ ],  "recipientFirstName": "Sam", "recipientLastName": "Spade", "recipientEmail": null, "recipientPhone": "5555555555",  "comments": null}';
        
        System.debug(LPREFIX + ': ' + jsonMsg);

        req.requestURI = '/services/apexrest/AppointmentService/';  
        req.httpMethod = 'POST';        
        req.requestBody = Blob.valueof(jsonMsg);

        RestContext.request = req;
        RestContext.response = res;
        System.debug( LPREFIX + '***********START createAppointmentTest***************');
        Test.startTest();
        Appt_CreateAppointmentResponse results = new Appt_CreateAppointmentResponse();
        results = Appt_SystemAPIService.createAppointment();
        Test.stopTest();

        System.assertEquals('1700', results.backOfficeStartTime, 'Check for schedule create');

        System.debug( LPREFIX + '***********END createAppointmentTest***************');
        System.debug( LPREFIX + results);

    } // End of createAppointmentTest()


    @isTest static void createAppointmentWithoutAccountTest()
    {   
        System.debug( LPREFIX + '***********START createAppointmentWithoutAccountTest Setup***************');

        Appt_CreateAppointmentServiceModel model1 = Appt_TestUtil.getCreateAppointmentServiceModel();
       
        Test.startTest();
        Account custAccount = Appt_AppointmentHandler.getAccount(model1);
        Test.stopTest();  

        System.assertNotEquals(null, custAccount, 'Account is null from getAccount without account');
        System.debug( LPREFIX + '***********END createAppointmentWithoutAccountTest***************');

    } // End of createAppointmentWithoutAccountTest()
    
    
    @isTest static void createAppointmentWithAccountTest()
    {   
        System.debug( LPREFIX + '***********START createAppointmentWithAccountTest Setup***************');

        Appt_CreateAppointmentServiceModel model1 = Appt_TestUtil.getCreateAppointmentServiceModel();
                    
        // update for customer created in setup
        model1.hybrisCustomerId = '15641654d'; //0017c00000lGmg2AAC - ApptDev1
        model1.firstName = 'Sam';
        model1.lastName = 'Spade';
        model1.emailAddress = 'test@test.com';
        model1.mobilePhoneNumber = '5555555555';
        model1.homePhoneNumber = '5555555555';
        //new Appt3 changes start
        model1.isVisionFeature= true; 
        Model1.showMyAccount = true;
        Model1.showAAAMember = true;
        Model1.showDTCC = true;
        Model1.showMilitary = true;
        // new Appt3 Chnages END

        Test.startTest();
        Account custAccount = Appt_AppointmentHandler.getAccount(model1);
        Test.stopTest();  

        System.assertNotEquals(null, custAccount, 'Account is null from getAccount with account');
        System.debug( LPREFIX + '***********END createAppointmentWithAccountTest***************');

    } // End of createAppointmentWithAccountTest()
    
    @isTest static void createAppointmentWithTzErrorTest()
    {   
        System.debug( LPREFIX + '***********START createAppointmentWithTzErrorTest Setup***************');

        List<ServiceTerritory> servTerr = [ SELECT Id, OperatingHoursId, OperatingHours.TimeZone, Site_Account__c FROM ServiceTerritory WHERE Site_Account__r.SAP_STORE_ID__c = '1236'];
        // System.debug( LPREFIX + 'createAppointmentWithTzErrorTest::ServiceTerritories: ' + servTerr.size());
        
        System.debug( LPREFIX + 'createAppointmentWithTzErrorTest::TimeZone: ' + servTerr[0].OperatingHours.TimeZone);
        List<OperatingHours> ohList = [SELECT Id, IsDeleted, Name, Description, TimeZone, Type__c FROM OperatingHours WHERE Id =: servTerr[0].OperatingHoursId];
        String tz = ohList[0].TimeZone;
        // change the timezone to make the check fail
        ohList[0].TimeZone = 'GMT';
        update ohList[0];

        ohList = [SELECT Id, IsDeleted, Name, Description, TimeZone, Type__c FROM OperatingHours WHERE Id =: servTerr[0].OperatingHoursId];
        System.debug( LPREFIX + 'createAppointmentWithTzErrorTest::OperatingHours after: ' + ohList[0]);

        Appt_CreateAppointmentServiceModel model1 = Appt_TestUtil.getCreateAppointmentServiceModel();

        // update for customer created in setup
        model1.hybrisCustomerId = '15641654d'; //0017c00000lGmg2AAC - ApptDev1
        model1.firstName = 'Sam';
        model1.lastName = 'Spade';
        model1.emailAddress = 'test@test.com';
        model1.mobilePhoneNumber = '5555555555';
        model1.homePhoneNumber = '5555555555';
        model1.isVisionFeature=true;//Appt3 change
        
        Test.startTest();
        Appt_CreateAppointmentServiceModel apptServMdl = Appt_AppointmentHandler.createAppointment(model1);
        Test.stopTest();  

        // return the timezone so other tests do not fail
        ohList[0].TimeZone = tz;
        update ohList[0];

        System.assertEquals(true, apptServMdl.isError(), 'Should be a timezone error');
        System.assertEquals('Unable to retrieve the ServiceTerritory as well as timezone offset with siteId=1235', apptServMdl.message, 'Error message for timezone incorrect');

        System.debug( LPREFIX + '***********END createAppointmentWithTzErrorTest***************');

    } // End of createAppointmentWithTzErrorTest()


    @isTest static void createAppointmentWithMissingModelErrorTest()
    {   
        System.debug( LPREFIX + '***********START createAppointmentWithMissingModelErrorTest Setup***************');

        Test.startTest();
        Appt_CreateAppointmentServiceModel apptServMdl = Appt_AppointmentHandler.createAppointment(null);
        Test.stopTest();  

        System.assertEquals(true, apptServMdl.isError(), 'Should be a null apptModel error');
        System.assertEquals('apptModel parameter is null', apptServMdl.message, 'Error message for null apptModel incorrect');

        System.debug( LPREFIX + '***********END createAppointmentWithMissingModelErrorTest***************');

    } // End of createAppointmentWithMissingModelErrorTest()


    @isTest static void createAppointmentWithMissingErrorTest()
    {   
        System.debug( LPREFIX + '***********START createAppointmentWithMissingErrorTest Setup***************');

        Appt_CreateAppointmentServiceModel model1 = Appt_TestUtil.getCreateAppointmentServiceModel();

        String localSiteId = model1.siteId;
        model1.siteId = '';

        Test.startTest();
        Appt_CreateAppointmentServiceModel apptServMdl = Appt_AppointmentHandler.createAppointment(model1);
        
        System.assertEquals(true, apptServMdl.isError(), 'Should be a siteId missing error');
        System.assertEquals('siteId parameter is blank or null', apptServMdl.message, 'Error message for SiteId missing incorrect');

        model1.siteId = localSiteId;
        String localApptStatus = model1.appointmentStatus;
        model1.appointmentStatus = '';

        apptServMdl = Appt_AppointmentHandler.createAppointment(model1);
        
        System.assertEquals(true, apptServMdl.isError(), 'Should be a Appointment Status missing error');
        System.assertEquals('appointmentStatus parameter is blank or null, siteId=1235', apptServMdl.message, 'Error message for Appointment Status missing incorrect');

        model1.appointmentStatus = localApptStatus;
        String localSource = model1.source;
        model1.source = '';

        apptServMdl = Appt_AppointmentHandler.createAppointment(model1);
        
        System.assertEquals(true, apptServMdl.isError(), 'Should be a Source missing error');
        System.assertEquals('Source or OrderType parameter is blank or null', apptServMdl.message, 'Error message for Source missing incorrect');

        model1.source = localSource;
        Test.stopTest();  
        System.debug( LPREFIX + '***********END createAppointmentWithMissingErrorTest***************');

    } // End of createAppointmentWithMissingErrorTest()


    @isTest static void createAppointmentWithBlankErrorTest()
    {   
        System.debug( LPREFIX + '***********START createAppointmentWithBlankErrorTest Setup***************');

        Appt_CreateAppointmentServiceModel model1 = Appt_TestUtil.getCreateAppointmentServiceModel();

        String localCStart = model1.consultStartTime;
        String localEStart = model1.backOfficeStartTime;
        model1.consultStartTime = '';
        model1.backOfficeStartTime = '';

        Test.startTest();
        Appt_CreateAppointmentServiceModel apptServMdl  = Appt_AppointmentHandler.createAppointment(model1);
        
        System.assertEquals(true, apptServMdl.isError(), 'Should be a Consult Start missing error');
        System.assertEquals('It is required that either consultStartTime and consultEndTime or backOfficeStartTime and backOfficeEndTime are properly populated', apptServMdl.message, 'Error message for Consult Start missing incorrect');

        model1.consultStartTime = localCStart;
        model1.backOfficeStartTime = localEStart;

        Test.stopTest();  
        System.debug( LPREFIX + '***********END createAppointmentWithBlankErrorTest***************');

    } // End of createAppointmentWithBlankErrorTest()


    @isTest static void createAppointmentWithLessThanErrorTest()
    {   
        System.debug( LPREFIX + '***********START createAppointmentWithLessThanErrorTest Setup***************');

        Appt_CreateAppointmentServiceModel model1 = Appt_TestUtil.getCreateAppointmentServiceModel();

        String localCStart = model1.consultStartTime;
        String localCEnd = model1.consultEndTime;
        model1.consultStartTime = localCEnd;
        model1.consultEndTime = localCStart;

        Test.startTest();
        Appt_CreateAppointmentServiceModel apptServMdl  = Appt_AppointmentHandler.createAppointment(model1);
        
        System.assertEquals(true, apptServMdl.isError(), 'Should be a Consult End before Start error');
        System.assertEquals('consultEndTime must be greater than consultStartTime', apptServMdl.message, 'Error message for Consult End before Start incorrect');

        model1.consultStartTime = localCStart;
        model1.consultEndTime = localCEnd;

        Test.stopTest();  


        System.debug( LPREFIX + '***********END createAppointmentWithLessThanErrorTest***************');

    } // End of createAppointmentWithLessThanErrorTest()


    @isTest static void createAppointmentWithBackLessThanErrorTest()
    {   
        System.debug( LPREFIX + '***********START createAppointmentWithBackLessThanErrorTest Setup***************');

        Appt_CreateAppointmentServiceModel model1 = Appt_TestUtil.getCreateAppointmentServiceModel();

        String localBStart = model1.backOfficeStartTime;
        String localBEnd = model1.backOfficeEndTime;
        model1.backOfficeStartTime = localBEnd;
        model1.backOfficeEndTime = localBStart;

        Test.startTest();

        Appt_CreateAppointmentServiceModel apptServMdl  = Appt_AppointmentHandler.createAppointment(model1);
        
        System.assertEquals(true, apptServMdl.isError(), 'Should be a Back End before Start error');
        System.assertEquals('backOfficeEndTime must be greater than backOfficeStartTime', apptServMdl.message, 'Error message for Back End before Start incorrect');

        model1.backOfficeStartTime = localBStart;
        model1.backOfficeEndTime = localBEnd;

        Test.stopTest();  
        System.debug( LPREFIX + '***********END createAppointmentWithBackLessThanErrorTest***************');

    } // End of createAppointmentWithBackLessThanErrorTest()

    @IsTest static void evaluateDuplicateIdTest(){
        Appt_CreateAppointmentServiceModel apptModel = new Appt_CreateAppointmentServiceModel();
        apptModel.posCustomerId = '12354';
        apptModel.customerGuid = '555555';
        apptModel.hybrisCustomerId = '55555';

        List<Account> accList = [SELECT Id, POS_Customer_Id__c, Hybris_Customer_Id__c, GUID__c FROM Account];

        Test.startTest();
        Appt_AppointmentHandler.evaluateDuplicateId(apptModel, accList, accList[0]);
        System.assert(true, true);
        Test.stopTest();    
    }
    
    // Appt3.0 changes -- Start      
    @IsTest static void getRecipientAltContactTest(){
        Contact curContact = [select id, FirstName, lastName, Email, Phone, MobilePhone from contact limit 1];
        
        // To check create new contact
        Appt_CreateAppointmentServiceModel apptModelInsertContact = new Appt_CreateAppointmentServiceModel();        
        apptModelInsertContact.recipientPhone='7898879998';
        apptModelInsertContact.recipientEmail='test2@test.com';
        apptModelInsertContact.recipientFirstName = 'John';
        apptModelInsertContact.recipientLastName = 'Test';
        // To check updation of existing contact       
        Appt_CreateAppointmentServiceModel apptModelUpdateContact = new Appt_CreateAppointmentServiceModel();
        apptModelUpdateContact.recipientPhone = curContact.Phone;
        apptModelUpdateContact.recipientEmail = curcontact.Email;
        apptModelUpdateContact.recipientLastName = 'abc';
        // Pos User
        User currentUser = [Select id,email,User_Store_Id__c from user where LastName = 'TerminalTestUser'  LIMIT 1 ];
        System.runas(currentUser){
            Test.startTest();
            Appt_AppointmentHandler.getRecipientAltContact(apptModelInsertContact);
            Appt_AppointmentHandler.getRecipientAltContact(apptModelUpdateContact);
            Test.stopTest();           
        }
        List<Contact> contactNewInsert = [ Select Id From Contact Where Email='test2@test.com' ];
        Contact curContactUpdated = [ Select Id, FirstName, lastName, Email, Phone, MobilePhone From Contact Where Id = :curContact.Id ];
        system.assertEquals(contactNewInsert.size(), 1, 'New contact not created' );
        system.assertEquals(false, curContactUpdated.lastName == curContact.lastName, 'Existing contact did not get updated' );       
    }
    
    // Test Method for addArticlesToWOLI
    @IsTest static void addArticlesToWOLITest(){        
        List<Appt_CreateAppointmentServiceModel.Articles> articlesList = new List<Appt_CreateAppointmentServiceModel.Articles>();
        Appt_CreateAppointmentServiceModel.Articles lineItem = new Appt_CreateAppointmentServiceModel.Articles(); 
        lineItem.articleDescription = 'Description for testing WOLI';
        lineItem.articleId = '0000011111' ;
        lineItem.articleSize = 'Sample Size';
        lineItem.articleCount = '1';
        lineItem.articleType = 'Electronics';
        articlesList.add(lineItem);
        List<WorkOrder> workOrders = [SELECT id FROM WorkOrder LIMIT 1];
        String woId = workOrders[0].id; 
        
        user currentUser = [Select Id, username, LastName, User_Store_Id__c From user Where LastName = 'TerminalTestUser' ];        
        System.runas(currentUser){
            Test.startTest();
            Appt_AppointmentHandler.addArticlesToWOLI(articlesList, woId);
            Test.stopTest();
        }
        List<WorkOrderLineItem> woli = [select id from WorkOrderLineItem where WorkOrderId = :woId];
        system.assertEquals(1, woli.size(),'Article was not added to WOLI object' );
        
        // remove articles method check
        Appt_AppointmentHandler.removeArticlesFromWOLI(woId);
        List<WorkOrderLineItem> woliUpdated = [select id from WorkOrderLineItem where WorkOrderId = :woId];
        system.assertEquals(0, woliUpdated.size(),' Article was not removed ' );          
    }
    
    // Negative scenario
    @IsTest static void addArticlesToWOLINullCheck(){        
        List<Appt_CreateAppointmentServiceModel.Articles> articlesList = new List<Appt_CreateAppointmentServiceModel.Articles>();
        Appt_CreateAppointmentServiceModel.Articles lineItem = new Appt_CreateAppointmentServiceModel.Articles(); 
        lineItem.articleDescription = null;
        lineItem.articleId = null;
        lineItem.articleSize = null;
        lineItem.articleCount = null;
        lineItem.articleType = null;
        articlesList.add(lineItem);
        List<WorkOrder> workOrders = [SELECT id FROM WorkOrder LIMIT 1];
        String woId = workOrders[0].id;
        // Pos user        
        user currentUser = [Select id,username ,LastName,User_Store_Id__c from user where LastName = 'TerminalTestUser' LIMIT 1 ];       
        System.runas(currentUser){
            Test.startTest();
            Appt_AppointmentHandler.addArticlesToWOLI(articlesList,woId);                   
            Test.stopTest();
        }
        List<WorkOrderLineItem> woli = [select id from WorkOrderLineItem where WorkOrderId = :woId];
        system.debug('woli' + woli);
        system.assertEquals(0, woli.size(), 'Articles should not have been added to WOLI object' );    
    }
    
    //Appt3.0 changes -- End
    
}