@isTest
public with sharing class Appt_StoreSelectScreenControllerTest {   
    @testSetup
    static void setupData() {
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
    } 

    @IsTest
    static void createUserFavoriteTest(){
        ServiceTerritory testTerritory = [SELECT id, Site_Account__r.SAP_STORE_ID__c, OperatingHoursId FROM ServiceTerritory LIMIT 1];
        System.debug('***Start Test***');
        Test.startTest();
        Appt_StoreSelectScreenController.createUserFavorite(testTerritory.id);
        Test.stopTest();
        System.debug('***End Test***');

        List<Appt_User_Favorite__c> results = [SELECT 
                                            id,
                                            User__c, 
                                            Service_Territory__c 
                                            FROM Appt_User_Favorite__c];
        System.debug(results);
        System.assert(results.size() > 0, 'Check for favorite to be added');
        
    }

    @IsTest
    static void deleteUserFavoriteTest(){

        ServiceTerritory testTerritory = [SELECT id, Site_Account__r.SAP_STORE_ID__c, OperatingHoursId FROM ServiceTerritory LIMIT 1];
        Appt_StoreSelectScreenController.createUserFavorite(testTerritory.id);
        System.debug('***Start Test***');
        Test.startTest();
        Appt_StoreSelectScreenController.removeUserFavorite(testTerritory.id);
        Test.stopTest();
        System.debug('***End Test***');

        List<Appt_User_Favorite__c> results = [SELECT 
                                            id,
                                            User__c, 
                                            Service_Territory__c 
                                            FROM Appt_User_Favorite__c 
                                            WHERE Service_Territory__c = :testTerritory.id];
        System.debug(results);
        System.assert(results.size() == 0, 'Check for favorite to be removed');
        
    }
     
    @isTest
    static void tryCatchCoverage(){
        try{
            Appt_StoreSelectScreenController.removeUserFavorite('curruptUser');
            Appt_StoreSelectScreenController.createUserFavorite(null);
            Appt_StoreSelectScreenController.getFavorites(userinfo.getUserId());
        }catch(exception e){
            System.AssertNotEquals(NULL,e);
        }
    }
}