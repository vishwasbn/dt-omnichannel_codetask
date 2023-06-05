/**
 * @description       : Customer Support from for Tires.com coumminity page.
 * @author            : Jayasurya Chirakala
 * @group             : 
 * @last modified on  : 12-16-2022
 * @last modified by  : Jayasurya Chirakala
**/
public without sharing class Ccc_customerSupportUtility {
 
    /** 
  * @description : Get the orgt id
  *
  * @param : n/a
  * @return : returns the organization id of the respective org.
  */
    @AuraEnabled(Cacheable=true)
   public static Id getOrgId(){
       return UserInfo.getOrganizationId();
   }

    /** 
  * @description :generate web to case url
  *
  * @param : n/a
  * @return : Resturn a url string to post the web to case request
  */
   
    @AuraEnabled(Cacheable=true)
   public static string getWebToCaseUrl(){
       String webToCaseUrl= System.Label.Web_To_Case_link;
       webToCaseUrl=  URL.getOrgDomainUrl().toExternalForm()+webToCaseUrl;
       return webToCaseUrl;
   }
    
    
    /** 
  * @description :Get the picklist values for a Field
  *
  * @param 1: objectName: API Name of the object 
  * @param 2: fieldName: API name of the field for above object 
  * @return : list of picklist values for the respective field.
  */
    
     @AuraEnabled(cacheable=true)
     public static List<OptionItem> getPicklistOptions(string objectName, string fieldName){       

        Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();
        Schema.DescribeFieldResult selectedField = globalDesc.get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        system.debug(selectedField);
        List<Schema.PicklistEntry> ple = selectedField.getPicklistValues();
        List<OptionItem> optionList = new List<OptionItem>();

        for( Schema.PicklistEntry f : ple)
        {
            optionList.add(new OptionItem(f.getLabel(), f.getValue()));
        }       
        return optionList;
    }

// wrapper class to hold the picklist label and value
    public without sharing class OptionItem {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
       
        public OptionItem(String label,String value) {
            this.label = label;
            this.value = value;
        }
    }   
}