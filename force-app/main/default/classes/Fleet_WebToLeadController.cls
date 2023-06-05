//---Fleet Web to Lead Controller
public without sharing class Fleet_WebToLeadController
{
    public static String lprefix = 'FLEET_WEBTOLEADCONT:';

     //---Get the picklist values for a Field
     @AuraEnabled(cacheable=true)
     public static List<OptionItem> getPicklistOptions(string objectName, string fieldName)
     {
        System.debug( lprefix + 'Getting picklist values for: ' + objectName +'.' + fieldName);

        Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();
        Schema.DescribeFieldResult selectedField = globalDesc.get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        system.debug(selectedField);
        List<Schema.PicklistEntry> ple = selectedField.getPicklistValues();
        List<OptionItem> optionList = new List<OptionItem>();

        for( Schema.PicklistEntry f : ple)
        {
            optionList.add(new OptionItem(f.getLabel(), f.getValue()));
        }       

        System.debug( lprefix + 'Values found: ' + optionList);

        return optionList;
    }

    // Start: Edited By Vaneet for state and city changes 
    @AuraEnabled(cacheable=true)
    public static List<OptionItem> getStatesOptions(){
        Set<String> statesSet = new Set<String>();
        List<String> stateslst = new List<String>();
        List<OptionItem> optionList = new List<OptionItem>();
        List<State__c> states = [select Name from State__c];
        for(State__c state : states){
            statesSet.add(state.Name);           
            
        } 
        stateslst.addAll(statesSet);
        stateslst.sort();
        for(String valueRow : stateslst)  
            optionList.add(new OptionItem(valueRow,valueRow));        
        //optionList.sort();
        return optionList;
    }

    @AuraEnabled(cacheable=true)
    public static List<OptionItem> getCitiesOptions(String state){
        List<State__c> StateId = [Select id from state__c where Name= :state];
        Set<String> citiesSet = new Set<String>();
        List<OptionItem> optionList = new List<OptionItem>();
        List<String> citieslst = new List<String>(); 
        List<City__c> cities = [Select Name from City__c where State__c = :StateId[0].id];
        for(City__c city : cities){
            citiesSet.add(city.Name);           
        } 
        citieslst.addAll(citiesSet);
        citieslst.sort();
         for(String valueRow : citieslst) 
         optionList.add(new OptionItem(valueRow,valueRow));
        return optionList;
    }

    // End: Edited By Vaneet for state and city changes 

    //---Get the list of active States
    @AuraEnabled(cacheable=true)
    public static List<OptionItem> getSelectLocationStates(){

        //---Get the Record Type
        Id siteRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Site').getRecordTypeId();

        Set<String> valueSet = new Set<String>();

        //---Query the list of Sites
        for( Account siteRow : [SELECT id, name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode FROM Account  WHERE RecordTypeId = :siteRT ORDER BY ShippingState])
        {
            if(siteRow.ShippingState!= null && !valueSet.contains(siteRow.ShippingState))
            	valueSet.add(siteRow.ShippingState);
        }

        List<OptionItem> optionList = new List<OptionItem>();
        for(String valueRow : valueSet)  optionList.add(new OptionItem(valueRow,valueRow));

        System.debug( lprefix + 'Returning the following States: ' + optionList);
        
        return optionList;
    }

    //---Get the list of active Cities
    @AuraEnabled(cacheable=true)
    public static List<OptionItem> getSelectLocationCities(String state){

        //---Get the Record Type
        Id siteRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Site').getRecordTypeId();

        Set<String> valueSet = new Set<String>();

        //---Query the list of Sites
        for( Account siteRow : [SELECT id, name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode FROM Account  WHERE RecordTypeId = :siteRT AND ShippingState = :state ORDER BY ShippingCity])
        {
            if(siteRow.ShippingCity!= null && !valueSet.contains(siteRow.ShippingCity))
            	valueSet.add(siteRow.ShippingCity);
        }

        List<OptionItem> optionList = new List<OptionItem>();
        for(String valueRow : valueSet)  optionList.add(new OptionItem(valueRow,valueRow));

        System.debug( lprefix + 'Returning the following Cities: ' + optionList);
        
        return optionList;
    }

    //---Get the list of active Sites
    @AuraEnabled(cacheable=true)
    public static List<OptionItem> getSelectLocationSites(String state, String city){

        //---Get the Record Type
        Id siteRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Site').getRecordTypeId();

        List<OptionItem> optionList = new List<OptionItem>();

        //---Query the list of Sites
        for( Account siteRow : [SELECT id, name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode FROM Account  WHERE RecordTypeId = :siteRT AND ShippingState = :state AND ShippingCity = :city 
                               AND Store_Status__c != 'Closed' AND (Site_Type__c ='DISCOUNT TIRE COMPANY' OR Site_Type__c ='AMERICA\'S TIRE COMPANY') ORDER BY ShippingCity])
        {
          String siteDesc = '(' + siteRow.name + ') ' + siteRow.ShippingStreet + ' ' +  siteRow.ShippingCity + ', ' + siteRow.ShippingState + ' ' + siteRow.ShippingPostalCode;
          optionList.add(new OptionItem(siteDesc, siteRow.Id));
        }

        System.debug( lprefix + 'Returning the following Sites: ' + optionList);
        
        return optionList;
    }

    //---Get the list of active Specialists
    @AuraEnabled(cacheable=true)
    public static List<OptionItem> getSpecialists(){

        System.debug( lprefix + 'Getting specialist picklist values ');

        List<OptionItem> optionList = new List<OptionItem>();

        for( User userRow : [SELECT Id, Name  FROM User WHERE IsActive = true AND Fleet_Is_Specialist__c = TRUE ORDER BY FirstName])
        {
            optionList.add(new OptionItem(userRow.Name, userRow.Id));
        }    

        System.debug( lprefix + 'Values found: ' + optionList);
        
        return optionList;
    }

    //---Get the Lead Record Type
    @AuraEnabled(cacheable=true)
    public static String getLeadRecordTypeId(){
        return Schema.Sobjecttype.Lead.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
    }

    public without sharing class OptionItem {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
       
        public OptionItem(String label,String value) {
            this.label = label;
            this.value = value;
        }
    }   
    
    @AuraEnabled(cacheable=true)
    public static List<OptionItem> getStores(){
        List<OptionItem> storeList = new List<OptionItem>();
        Id recordTypeId = [SELECT Id, Name from RecordType WHERE Name = 'Site'].Id;
        List<Account> storeAccounts = [SELECT Id, Store_ID__c, SAP_STORE_ID__c, Name, ShippingCity, ShippingState FROM Account WHERE RecordTypeId = :recordTypeId AND Store_ID__c != null AND SAP_STORE_ID__c != null ORDER BY Store_ID__c];
        for(Account acc : storeAccounts){
            String label = acc.Store_ID__c + '-' + acc.SAP_STORE_ID__c + ' : ' +acc.Name+ ' : '+ acc.ShippingState + ' : '+acc.ShippingCity;
            storeList.add(new OptionItem(label, acc.Id));
        }
        return storeList;
    }
}