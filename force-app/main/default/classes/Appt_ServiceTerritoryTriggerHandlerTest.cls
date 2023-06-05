@isTest
public with sharing class Appt_ServiceTerritoryTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
    }

    @IsTest
    static void Appt_ServiceTerritoryTriggerHandlerTest(){

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduserdt65489465489214SFG4235!@%@testorg.com');      
        
        User u2 = new User(Alias = 'standt2', Email='standarduser@testorg2.com', 
            EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduserdt65489465489214SFG464235!@%@testorg.com');   
            
        List<ServiceTerritory> configTerritory  = [SELECT 
                                                    id, 
                                                    Site_Account__r.SAP_STORE_ID__c,
                                                    Site_Account__r.Store_ID__c 
                                                    FROM ServiceTerritory LIMIT 1];
        
        u.User_Store_Id__c = configTerritory[0].Site_Account__r.SAP_STORE_ID__c;
        insert u;  
        insert u2;                                          

        System.debug('***Start Test***');
        Test.startTest();
        configTerritory[0].OwnerId = u2.id;
        update configTerritory;    
        
        Test.stopTest();
        System.debug('***End Test***');

        List<ServiceTerritoryShare> existingSharedStoresList = [SELECT
                                    id, 
                                    UserOrGroupId, 
                                    UserOrGroup.Name, 
                                    ParentId,  
                                    AccessLevel, 
                                    RowCause 
                                    FROM ServiceTerritoryShare 
                                    WHERE UserOrGroupId = :u.id];
        System.debug('ShareRecord: ' +existingSharedStoresList);
        System.assert(existingSharedStoresList[0].UserOrGroupId == u.id, 'Checks for user id match');
        System.assert(existingSharedStoresList[0].ParentId == configTerritory[0].id, 'Checks for territory id match');
        
    }
}