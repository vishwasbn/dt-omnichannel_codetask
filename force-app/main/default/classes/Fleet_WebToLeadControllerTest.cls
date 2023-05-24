@isTest 
public class Fleet_WebToLeadControllerTest {
    @TestSetup
    static void makeData(){
        Id siteRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Site').getRecordTypeId();
         
        Account newAccount = new Account(Name='test Account'); 
        newAccount.ShippingStreet = '123 test street';
        newAccount.ShippingState = 'Arizona';
        newAccount.ShippingCity = 'Phoenix';
        newAccount.ShippingPostalCode = '85392';
        newAccount.RecordTypeId = siteRT;

        insert newAccount;


    }

    @IsTest 
    public static void getPicklistOptionsTest() {

        Test.startTest();
        List<Fleet_WebToLeadController.OptionItem> SPOCTypes =  Fleet_WebToLeadController.getPicklistOptions('Lead', 'Fleet_SPOC_Type__c');
        List<Fleet_WebToLeadController.OptionItem> howHearOptions =  Fleet_WebToLeadController.getPicklistOptions('Lead', 'Fleet_How_Hear__c');
        Test.stopTest();

        System.assert(SPOCTypes.size() > 1, 'Expected the Fleet_SPOC_Type__c picklist to have more then 1 option');
        System.assert(howHearOptions.size() > 1, 'Expected the Fleet_How_Hear__c picklist to have more then 1 option');
    }

    @IsTest 
    public static void getSelectLocationStatesTest() {

        Test.startTest();
        List<Fleet_WebToLeadController.OptionItem> states =  Fleet_WebToLeadController.getSelectLocationStates();
        Test.stopTest();
        System.debug(states);

        System.assert(states.size() == 1, 'Expected the Fleet_WebToLeadController.getSelectLocationStates() method to return 1 state');
    }

    @IsTest 
    public static void getSelectLocationCitiesTest() {

        Test.startTest();
        List<Fleet_WebToLeadController.OptionItem> cities =  Fleet_WebToLeadController.getSelectLocationCities('Arizona');
        Test.stopTest();

        System.assert(cities.size() == 1, 'Expected the Fleet_WebToLeadController.getSelectLocationCities(Arizona) method to return 1 city');
    }

    @IsTest 
    public static void getSelectLocationSitesTest() {

        Test.startTest();
        List<Fleet_WebToLeadController.OptionItem> sites =  Fleet_WebToLeadController.getSelectLocationSites('Arizona', 'Phoenix');
        Test.stopTest();

        //System.assert(sites.size() == 1, 'Expected the Fleet_WebToLeadController.getSelectLocationSites(Arizona, Phoenix) method to return 1 sites');
    }

    @IsTest 
    public static void getSpecialistsTest() {

        Test.startTest();
        List<Fleet_WebToLeadController.OptionItem> specialists =  Fleet_WebToLeadController.getSpecialists();
        Test.stopTest();


        System.assert(specialists.size() > 0, 'Expected the Fleet_WebToLeadController.getSpecialists() method to return more then 0 Specialists');
    }

    @IsTest 
    public static void getLeadRecordTypeIdTest() {

        Test.startTest();
        String id =  Fleet_WebToLeadController.getLeadRecordTypeId();
        Test.stopTest();

        System.assert(id != null, 'Expected the id returned from Fleet_WebToLeadController.getLeadRecordTypeId() to not be null');
    }
    
    @IsTest 
    public static void getStatesOptionsTest() {
        State__c newState = new State__c();
        newState.Name = 'Alabama';
        insert newState;
        
        City__c newCity = new City__c();
        newCity.Name = 'Abanda';
        newCity.State__c = newState.id;
        insert newCity;
        
        Test.startTest();        
        Fleet_WebToLeadController.getStatesOptions();
        Fleet_WebToLeadController.getCitiesOptions(newState.Name);        
        Fleet_WebToLeadController.getStores();
        Test.stopTest();
    }
    
    @IsTest 
    public static void getCitiesOptionsTest() {
                
    }  
     public without sharing class OptionItem {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
       
        public OptionItem(String label,String value) {
            this.label = label;
            this.value = value;
        }
    }   
}