@isTest 
public class Fleet_WebToLeadAssignmentControllerTest {
    
    @TestSetup
    Public static Void SetUpData(){
        
        Account A = New Account();
        A.RecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Site').getRecordTypeId();
        A.Name = 'test';
        Insert A;
        
        Lead L = New Lead();
        L.Preferred_Store__c= A.id;
        L.Email='specialistLess50@testorg.com'; 
        L.LastName='specialistLess50';
        L.state__c = 'New York';
        L.Company = 'ABC'; 
        L.Status = 'New';
        L.Fleet_Purchase_Product__c = 'Both';
        L.Fleet_Years_Business__c = 2;
        L.Selectedcity__c = 'New York';
        //L.Fleet_Prefer_Purchase__c='Purchase Order';
        Insert L;
        
    }
    
    /*
    @IsTest
    public static void AssignleadTest(){
        
        Id LeadId = [Select Id from Lead limit 1].Id;
        
        List<Id> LeadIdList =new List<Id>();
        LeadIdList.add(LeadId);
        Fleet_WebToLeadAssignmentController.assignLead(LeadIdList);
        
    }
  */
    
    @IsTest 
    public static void assignLeadTest() {
        System.debug('TEST YEST: createTestClassData() ------- ENTRY');
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Fleet Sales User']; 
        User specialistLess50 = new User(Alias = 'standl', Email='specialistLess50@testorg.com', 
                                         EmailEncodingKey='UTF-8', LastName='specialistLess50', LanguageLocaleKey='en_US', 
                                         LocaleSidKey='en_US', ProfileId = p.Id, 
                                         TimeZoneSidKey='America/Los_Angeles', UserName='specialistLess50@testorg.com');
        specialistLess50.Fleet_Specialist_Assignment_Group__c = '1-50';
        specialistLess50.Fleet_Is_Specialist__c = true;
        specialistLess50.Fleet_Purchase_Category_Group__c='ALL';
        insert specialistLess50;
        User specialistLess100 = new User(Alias = 'standf', Email='specialistLess100@testorg.com', 
                                          EmailEncodingKey='UTF-8', LastName='specialistLess100', LanguageLocaleKey='en_US', 
                                          LocaleSidKey='en_US', ProfileId = p.Id, 
                                          TimeZoneSidKey='America/Los_Angeles', UserName='specialistLess100@testorg.com');
        specialistLess100.Fleet_Specialist_Assignment_Group__c = '50+';
        specialistLess100.Fleet_Is_Specialist__c = true;
        specialistLess100.Fleet_Purchase_Category_Group__c='ALL';
        insert specialistLess100;
        User user100 = new User(Alias = 'stan65', Email='specialistLess101@testorg1.com', 
                                EmailEncodingKey='UTF-8', LastName='specialistLess100', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = p.Id, Fleet_Assignment_State__c='Alaska',Fleet_Assignment_City_New__c='Anchorage',
                                TimeZoneSidKey='America/Los_Angeles', UserName='specialistLess101@testorg1.com');
        user100.Fleet_Specialist_Assignment_Group__c = '50+';
        user100.Fleet_Is_Specialist__c = true;
        user100.Fleet_Purchase_Category_Group__c='ALL';
        insert user100;
        User specialistMore100 = new User(Alias = 'stand34', Email='specialistMore100@testorg.com', 
                                          EmailEncodingKey='UTF-8', LastName='specialistMore100', LanguageLocaleKey='en_US', 
                                          LocaleSidKey='en_US', ProfileId = p.Id, 
                                          TimeZoneSidKey='America/Los_Angeles', UserName='stand34@testorg.com');
        specialistMore100.Fleet_Specialist_Assignment_Group__c = '100+';
        specialistMore100.Fleet_Is_Specialist__c = true;
        specialistMore100.Fleet_Purchase_Category_Group__c='ALL';
        insert specialistMore100;
        
        User specialist = new User(Alias = 'stand45', Email='specialistMore100@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='specialistMore100', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = p.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='stand45@testorg.com',Fleet_Assignment_State__c='Alaska');
        specialist.Fleet_Specialist_Assignment_Group__c = '100+';
        specialist.Fleet_Is_Specialist__c = true;
        specialist.Fleet_Purchase_Category_Group__c='ALL';
        insert specialist;
        
        System.debug('TEST YEST: createTestClassData() ------- About to insert test lead');
        
        //Id, OwnerId, Fleet_Specialist_Id__c, Fleet_Number_of_Vehicles__c, Fleet_Specialist__c, Fleet_Preferred_Store_Id__c, Preferred_Store__c
        //Required fields are missing: [LastName, Company, Fleet_Prefer_Purchase__c, Fleet_Years_Business__c, Fleet_Purchase_Product__c, Fleet_Business_Located__c, Fleet_How_Hear__c]: 
        Lead leadLess50Vehs = new Lead(LastName='TestLead111', Company='TestLead111 ribs4r4', 
                    Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+dtfs1674r4.a@ethos.com',
                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', 
                    Fleet_Business_Located__c='Arizona', Fleet_How_Hear__c='Website', Selectedcity__c='Mesa');
        leadLess50Vehs.Fleet_Number_of_Vehicles__c = 34;
        leadLess50Vehs.State__c = 'New';
        insert leadLess50Vehs;
        
        System.debug('TEST YEST: createTestClassData() ------- successfully inserted test lead');
        Lead lead46Vehs = new Lead(LastName='TestLead222', Company='TestLead222 frank087776', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+dtfs1674r4r4.b@ethos.com',
                                   Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c= 'Alabama',City__c='Huntsville', Fleet_How_Hear__c='Website', Selectedcity__c='Mobile');
        lead46Vehs.Fleet_Number_of_Vehicles__c = 46;
        lead46Vehs.State__c = 'New';
        insert lead46Vehs;
        
        Lead lead34Vehs = new Lead(LastName='TestLead2224', Company='TestLead22442 frank', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+dtfs1645667.b@ethos.com',
                                   Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c= 'Hawaii', Fleet_How_Hear__c='Website', Selectedcity__c='Hilo');
        lead34Vehs.Fleet_Number_of_Vehicles__c = 59;
        lead34Vehs.State__c = 'New';
        upsert lead34Vehs;
        
        Lead lead65Vehs = new Lead(LastName='TestLead222345', Company='TestLead222344 frank5667', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+dt1324fs1654327.b@ethos.com',
                                   Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', Fleet_How_Hear__c='Website', Selectedcity__c='Mesa');
        lead65Vehs.Fleet_Number_of_Vehicles__c = 65;
        lead65Vehs.State__c = 'New';
        upsert lead65Vehs;
        
        Lead lead113Vehs = new Lead(LastName='TestLead3335', Company='TestLead333 yipee22245', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+dtfs133367.c@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', Fleet_How_Hear__c='Website', Selectedcity__c='Mesa');
        lead113Vehs.Fleet_Number_of_Vehicles__c = 113;
        lead113Vehs.State__c = 'New';
        upsert lead113Vehs;
        
        Lead lead114Vehs = new Lead(LastName='TestLead3336', Company='TestLead333 yipee43322', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+dtfs165557.c@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Colorado', Fleet_How_Hear__c='Website', Selectedcity__c='Denver');
        lead114Vehs.Fleet_Number_of_Vehicles__c = 14;
        lead114Vehs.State__c = 'New';
        upsert lead114Vehs;
        
        Lead lead115Vehs = new Lead(LastName='TestLead33366', Company='TestLead333 yipeerr', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex67+dtfs167423.c@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Florida', Fleet_How_Hear__c='Website', Selectedcity__c='Miami');
        lead115Vehs.Fleet_Number_of_Vehicles__c = 51;
        lead115Vehs.State__c = 'New';
        upsert lead115Vehs;
        
        Lead leadWithSpecialist = new Lead(LastName='TestLead444', Company='TestLead444 wacka', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+dtfs16745.d@ethos.com',
                                           Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', Fleet_How_Hear__c='Other', Selectedcity__c='Mesa');
        leadWithSpecialist.Fleet_Number_of_Vehicles__c = 6;
        leadWithSpecialist.Fleet_Specialist_Id__c = specialistLess100.Id;
        leadWithSpecialist.State__c = 'New';
        upsert leadWithSpecialist;
        
        System.debug('TEST YEST: createTestClassData() ------- EXIT');
        
        
        System.debug('TEST YEST: assignLeadTest() ------- ENTRY');
        
        List<Lead> testLeads = new List<Lead>();
        List<Id> testLeadIds = new List<Id>();
        testLeads = [SELECT Id FROM Lead];
        if (testLeads != null) {
            for (Lead ld: testLeads) {
                testLeadIds.add(ld.Id);
            }
        }
        
        System.debug('TEST YEST: assignLeadTest() ------- testLeadIds:' + testLeadIds);
        
        Test.startTest();
        Fleet_WebToLeadAssignmentController.assignLead(testLeadIds);
        Test.stopTest();
        system.debug('testLeadIds'+testLeadIds);
        List<Lead> postTestLeads = [SELECT Id, OwnerId, Fleet_Specialist_Id__c, Selectedcity__c, Fleet_Number_of_Vehicles__c, Fleet_Specialist__c, Fleet_Preferred_Store_Id__c, Preferred_Store__c FROM Lead];
        System.debug('TEST YEST: assignLeadTest() ------- postTestLeads:' + postTestLeads);
        
        if (postTestLeads != null) {
            for (Lead ld: postTestLeads) {
                System.debug('TEST YEST: Post assignment lead:' + ld);
                System.assert(ld.OwnerId != null, 'The test lead was expected to have OwnerId populated');
            }
        }
        
        Map<Id, User> ownerList = new Map<Id, User>( [ SELECT Id, Name, Fleet_Specialist_Assignment_Group__c FROM User WHERE IsActive = true AND Fleet_Is_Specialist__c = TRUE ] );
        
        // get the Chatter feed items
        List<FeedItem> postList = [ SELECT Id, ParentId, Type, Title, Body, LinkUrl, HasLink, RelatedRecordId, IsClosed, Status FROM FeedItem ];
        // System.debug('Chatter: ' + postList.size());
        // System.debug('Chatter: ' + postList);
        
        for (Integer idx = 0; idx < postList.size(); ++idx){
            System.assert(postList[idx].Title.contains('Lead Assignment'), 'Chatter post title incorrect');
            System.assert(postList[idx].Body.contains('has been submitted and assigned to you'), 'Chatter post body incorrect');
            System.assert(postList[idx].Body.contains(ownerList.get(postList[idx].ParentId).Name), 'Chatter post owner name incorrect');
            System.assert(postList[idx].HasLink, 'Chatter post Hyperlink is missing');
        }
        
        System.debug('TEST YEST: assignLeadTest() DONE ----------------------------');
    }
    
    //DT0010309-method if city!= null
    @istest 
    static void testLead()
    {
        Id B2bRecordType= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2B').getRecordTypeId();
        Profile p = [SELECT Id FROM Profile WHERE Name='Fleet Sales User']; 
        List<Id> testLeadIds = new List<Id>();
        User user90 = new User(Alias = 'stan651', Email='specialistuser90@testorg1.com', 
                               EmailEncodingKey='UTF-8', LastName='specialistuser90', LanguageLocaleKey='en_US', 
                               LocaleSidKey='en_US', ProfileId = p.Id, Fleet_Assignment_State__c='Alabama',Fleet_Assignment_City_New__c='Montgomery',
                               TimeZoneSidKey='America/Los_Angeles', UserName='stan651@testorg1.com');
        user90.Fleet_Specialist_Assignment_Group__c = '100+';
        user90.Fleet_Is_Specialist__c = true;
        user90.isActive = true;
        user90.Fleet_Purchase_Category_Group__c='ALL';
        insert user90;
        User userALL = new User(Alias = 'userAll', Email='userAll0@testorg1.com', 
                                EmailEncodingKey='UTF-8', LastName='userAllNew', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = p.Id, Fleet_Assignment_State__c='ALL',
                                TimeZoneSidKey='America/Los_Angeles', UserName='userAll0@testorg1.com');
        userALL.Fleet_Specialist_Assignment_Group__c = '100+';
        userALL.Fleet_Is_Specialist__c = true;
        userALL.isActive = true;
        userALL.Fleet_Purchase_Category_Group__c='ALL';
        insert userALL;
        Lead lead117Vehs = new Lead(LastName='TestLead33312', Company='TestLead333 yupi', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+dtfs16712.c@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Alabama',City__c='Montgomery', Fleet_How_Hear__c='Website', Selectedcity__c='Mobile');
        lead117Vehs.Fleet_Number_of_Vehicles__c = 140;
        lead117Vehs.State__c = 'New';
        lead117Vehs.RecordtypeId = B2bRecordType;
        Lead lead118Vehs = new Lead(LastName='TestLead118', Company='TestLead333 yupi66', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+TestLead118@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', Fleet_How_Hear__c='Website', Selectedcity__c='Mesa');
        lead118Vehs.Fleet_Number_of_Vehicles__c = 140;
        lead118Vehs.State__c = 'New';
        lead118Vehs.RecordtypeId = B2bRecordType;
        
        Lead lead119Vehs = new Lead(LastName='lead119Vehs', Company='TestLead333 yupi77', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+lead119Veh77s@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', City__c='Tucson',Fleet_How_Hear__c='Website', Selectedcity__c='Mesa');
        lead119Vehs.Fleet_Number_of_Vehicles__c = 140;
        lead119Vehs.RecordtypeId = B2bRecordType;
        lead119Vehs.State__c = 'New';
        Test.startTest();
        upsert lead117Vehs;
        upsert lead118Vehs;
        upsert lead119Vehs;
        testLeadIds.add(lead117Vehs.id);
        testLeadIds.add(lead118Vehs.id);
        testLeadIds.add(lead119Vehs.id);
        Fleet_WebToLeadAssignmentController.assignLead(testLeadIds);
        Test.stopTest();
        
        List<lead> leadlist = [SELECT Id, Fleet_Purchase_Product__c,Name, Selectedcity__c, Fleet_Specialist__r.Fleet_Specialist_Assignment_Group__c,owner.name,Fleet_Specialist__r.Fleet_Assignment_State__c,Fleet_Business_Located__c FROM Lead];
        system.debug('leadlist++'+leadlist);
        //system.assert(leadlist[0].Fleet_Specialist__c!=null,leadlist[0].name+'has lead owner'+leadlist[0].owner.name+'has fleet specialist'+leadlist[0].Fleet_Specialist__c );
        //system.assert(leadlist[0].Fleet_Specialist__r.Fleet_Specialist_Assignment_Group__c=='100+' );
        //system.assert(leadlist[1].Fleet_Specialist__c!=null);
        //system.assert(leadlist[2].Fleet_Specialist__c!=null);
    }
    //DT0010309-method 
    @istest 
    static void testLeadBasedOnVEhicleNumber()
    {
        Id B2bRecordType= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2B').getRecordTypeId();
        Profile p = [SELECT Id FROM Profile WHERE Name='Fleet Sales User']; 
        List<Id> testLeadIds = new List<Id>();
        User user102 = new User(Alias = 'user102', Email='user102@testorg1.com', 
                                EmailEncodingKey='UTF-8', LastName='user102New', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = p.Id,
                                TimeZoneSidKey='America/Los_Angeles', UserName='user102@testorg1.com');
        user102.Fleet_Specialist_Assignment_Group__c = '100+';
        user102.Fleet_Is_Specialist__c = true;
        user102.isActive = true;
        //
        //user11.LeadAssignmentPriority__c=null;
        user102.Fleet_Purchase_Category_Group__c='ALL';
        user102.Fleet_Assignment_State__c='Arizona';
        //
        insert user102;
        Lead lead120Vehs = new Lead(LastName='lead120Vehs5', Company='TestLead333 yupi3', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+lead120Vehs5@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale',Fleet_Business_Located__c='Arizona', City__c='Tucson',Fleet_How_Hear__c='Website', Selectedcity__c='Mesa');
        lead120Vehs.Fleet_Number_of_Vehicles__c = 140;
        lead120Vehs.State__c = 'New';
        lead120Vehs.RecordtypeId = B2bRecordType;
        insert lead120Vehs;
        testLeadIds.add(lead120Vehs.id);
        test.startTest();
        Fleet_WebToLeadAssignmentController.assignLead(testLeadIds);
        test.stopTest();
        List<lead> leadlist=[select id ,Fleet_Specialist__c from lead];
        //system.assert(leadlist[0].Fleet_Specialist__c!=null); 
    } 
    
    @istest                                                  
    static void testGeneral()
    {   List<User> specialistList = new List<User>();
     List<FeedItem> chatterPostList =new List<FeedItem>();
     
     Id B2bRecordType= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2B').getRecordTypeId();
     Profile p = [SELECT Id FROM Profile WHERE Name='Fleet Sales User']; 
     List<Id> testLeadIds = new List<Id>();
     User user102 = new User(Alias = 'user1026', Email='user102@testorg1.com', 
                             EmailEncodingKey='UTF-8', LastName='user102New', LanguageLocaleKey='en_US', 
                             LocaleSidKey='en_US', ProfileId = p.Id,
                             TimeZoneSidKey='America/Los_Angeles', UserName='user102@testorg1.com');
     user102.Fleet_Specialist_Assignment_Group__c = '100+';
     user102.Fleet_Is_Specialist__c = true;
     user102.isActive = true;
     insert user102;
     User user11 = new User(Alias = 'user11', Email='user11@testorg1.com', 
                            EmailEncodingKey='UTF-8', LastName='user11New', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', ProfileId = p.Id,
                            TimeZoneSidKey='America/Los_Angeles', UserName='user11@testorg1.com');
     user11.Fleet_Specialist_Assignment_Group__c = '100+';
     user11.Fleet_Is_Specialist__c = true;
     user11.isActive = true;
     user11.LeadAssignmentPriority__c=null;
     user11.Fleet_Purchase_Category_Group__c='ALL';
     user11.Fleet_Assignment_State__c='Arizona';
     insert user11;
     specialistList.add(user102);
     specialistList.add(user11);
     
     Lead lead120Vehs = new Lead(LastName='lead120Vehs', Company='TestLead333 yupi', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+lead120Vehs@ethos.com',
                                 Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale',Fleet_Business_Located__c='Texas',Fleet_How_Hear__c='Website', Selectedcity__c='Austin');
     lead120Vehs.Fleet_Number_of_Vehicles__c = 140;
     lead120Vehs.State__c = 'New';
     lead120Vehs.RecordtypeId = B2bRecordType;
     
     upsert lead120Vehs;
     
     Lead lead1201Vehs = new Lead(LastName='lead120Vehs2', Company='TestLead333 ydupi', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+lead120Vesshs@ethos.com',
                                  Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale',Fleet_Business_Located__c='Texas',Fleet_How_Hear__c='Website', Selectedcity__c='Austin');
     lead1201Vehs.Fleet_Number_of_Vehicles__c = 140;
     lead1201Vehs.State__c = 'New';
     lead1201Vehs.RecordtypeId = B2bRecordType;
     lead1201Vehs.OwnerId=user11.Id;
     upsert lead1201Vehs;
     
     Lead lead1202Vehs = new Lead(LastName='lead120Vehs3', Company='TestLead333 yusspi', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+lead120Vehdds@ethos.com',
                                  Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale',Fleet_Business_Located__c='Texas',Fleet_How_Hear__c='Website', Selectedcity__c='Austin');
     lead1202Vehs.Fleet_Number_of_Vehicles__c = 140;
     lead1202Vehs.State__c = 'New';
     lead1202Vehs.RecordtypeId = B2bRecordType;
     lead1202Vehs.Fleet_Specialist_Id__c=user11.Id;
     upsert lead1202Vehs;
     Lead lead120Vehs2 = new Lead(LastName='lead120Vehs5', Company='TestLead333 yupisss2', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+lead120Vehsssas2@ethos.com',
                                  Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale',Fleet_How_Hear__c='Website',Fleet_Business_Located__c='Arizona', Selectedcity__c='Mesa');
     lead120Vehs2.Fleet_Number_of_Vehicles__c = 140;
     lead120Vehs2.State__c = 'New';
     lead120Vehs2.RecordtypeId = B2bRecordType;
     upsert lead120Vehs2;
     testLeadIds.add(lead120Vehs.id);
     test.startTest();
     Fleet_WebToLeadAssignmentController.assignLead(testLeadIds);
     lead120Vehs2.Fleet_Purchase_Product__c=null;
     testLeadIds.add(lead120Vehs.id);
     Fleet_WebToLeadAssignmentController.assignLead(testLeadIds);
     lead120Vehs2.Fleet_Business_Located__c=null;
     testLeadIds.add(lead120Vehs.id);
     Fleet_WebToLeadAssignmentController.assignLead(testLeadIds);
     lead120Vehs2.Fleet_Purchase_Product__c='Both';
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingStateOrCity(  specialistList, lead120Vehs2,true);
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingStateOrCity(  specialistList, lead120Vehs2,false);
     lead120Vehs2.Fleet_Purchase_Product__c='Bothtest';
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingStateOrCity(  specialistList, lead120Vehs2,true);
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingStateOrCity(  specialistList, lead120Vehs2,false);
     lead120Vehs2.Fleet_Purchase_Product__c=null;
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingStateOrCity(  specialistList, lead120Vehs2,true);
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingStateOrCity(  specialistList, lead120Vehs2,false);
     lead120Vehs2.Fleet_Purchase_Product__c='Both';
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingAllState(  specialistList, lead120Vehs2);
     lead120Vehs2.Fleet_Purchase_Product__c='Resale';
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingAllState(  specialistList, lead120Vehs2);
     lead120Vehs2.Fleet_Purchase_Product__c='Bothtest';
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingAllState(  specialistList, lead120Vehs2);
     lead120Vehs2.Fleet_Purchase_Product__c=null;
     Fleet_WebToLeadAssignmentController.getSpecialistFromPurchaseGroupWithMatchingAllState(  specialistList, lead120Vehs2);
     Fleet_WebToLeadAssignmentController.getRandomSpecialistFromPurchaseGroup( specialistList,  'groupValue');
     Fleet_WebToLeadAssignmentController.getRandomSpecialistFromGroup( specialistList,  'groupValue');
     lead120Vehs2.Fleet_Business_Located__c='null';
     testLeadIds.add(lead120Vehs.id);
     Fleet_WebToLeadAssignmentController.assignLead(testLeadIds);
     Fleet_WebToLeadAssignmentController.postFeed(user102.id,  'userName', lead120Vehs2.id, chatterPostList);
     Fleet_WebToLeadAssignmentController.assignLeads(lead120Vehs2, lead120Vehs2.id, specialistList,  chatterPostList);
     lead120Vehs2.Fleet_Purchase_Product__c='Both';
     Fleet_WebToLeadAssignmentController.assignLeads(lead120Vehs2, lead120Vehs2.id, specialistList,  chatterPostList);
     lead120Vehs2.Fleet_Purchase_Product__c='Resale';
     Fleet_WebToLeadAssignmentController.assignLeads(lead120Vehs2, lead120Vehs2.id, specialistList,  chatterPostList);
     test.stopTest();
     List<lead> leadlist=[select id ,Selectedcity__c, Fleet_Specialist__c from lead];
     //system.assert(leadlist[0].Fleet_Specialist__c!=null); 
    } 
    
}