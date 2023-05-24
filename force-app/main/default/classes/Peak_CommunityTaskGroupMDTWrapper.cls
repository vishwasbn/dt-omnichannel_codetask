public with sharing class Peak_CommunityTaskGroupMDTWrapper {

    /*
        Create Task Group Wrapper from Task Group MDTs
    */
    public static List<Peak_CommunityTaskGroupWrapper> getTaskGroupsList(){

        List<Peak_CommunityTaskGroupWrapper> returnList = new List<Peak_CommunityTaskGroupWrapper>();

        //Query Task Group MDTs
        //Included where logic to refresh only the active ones
        List<Community_Task_Group__mdt> taskGroupMDTList = [SELECT Id, DeveloperName, Label FROM Community_Task_Group__mdt where Deactivate__c = false];

        //For each MDT create a wrapper
        for(Community_Task_Group__mdt theTaskGroupMDT : taskGroupMDTList ){
           returnList.add(formatMDTtoWrapper(theTaskGroupMDT));

       }

        return returnList;
    }

    /*
        Format Task Group MDT into Wrapper
    */
    public static Peak_CommunityTaskGroupWrapper formatMDTtoWrapper(Community_Task_Group__mdt mdtTaskGroup){
        Peak_CommunityTaskGroupWrapper taskGroupWrapper = new Peak_CommunityTaskGroupWrapper();


        taskGroupWrapper.id = mdtTaskGroup.Id;
        taskGroupWrapper.isSelected = false;
        taskGroupWrapper.label = mdtTaskGroup.Label;
        taskGroupWrapper.name = mdtTaskGroup.DeveloperName; // Copying Developer name of metadata type record

        return taskGroupWrapper;

    }

    //Inner class to wrap metadata
    public class Peak_CommunityTaskGroupWrapper{
        @AuraEnabled public String name {get;set;} // Developer name of metadata type record
        @AuraEnabled public Id id {get;set;}
        @AuraEnabled public Boolean isSelected {get;set;}
        @AuraEnabled public String label {get;set;}

    }
}