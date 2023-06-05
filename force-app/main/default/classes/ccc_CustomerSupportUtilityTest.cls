@isTest 
public class ccc_CustomerSupportUtilityTest {

     @IsTest 
    public static void getPicklistOptionsTest() {

        Test.startTest();
        List<Ccc_customerSupportUtility.OptionItem> requestTypeOptions =  Ccc_customerSupportUtility.getPicklistOptions('Case', 'Deflection__c');
        List<Ccc_customerSupportUtility.OptionItem> deflectionOptions =  Ccc_customerSupportUtility.getPicklistOptions('Case', 'Request_Type__c');
        Test.stopTest();

        System.assert(deflectionOptions.size() > 1, 'Expected the Deflection__c picklist to have more then 1 option');
        System.assert(requestTypeOptions.size() > 1, 'Expected the Request_Type__c picklist to have more then 1 option');
    }

    @IsTest 
    public static void getWebToCaseUrl() {

        Test.startTest();
        String webToCaseUrl =  Ccc_customerSupportUtility.getWebToCaseUrl();
        Test.stopTest();

        System.assert(webToCaseUrl != null, 'Expected the id returned from Ccc_customerSupportUtility.getWebToCaseUrl() to not be null');
    }

    
    @IsTest 
    public static void getOrgIdTest() {

        Test.startTest();
        String id =  Ccc_customerSupportUtility.getOrgId();
        Test.stopTest();

        System.assert(id != null, 'Expected the id returned from Ccc_customerSupportUtility.getOrgId() to not be null');
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