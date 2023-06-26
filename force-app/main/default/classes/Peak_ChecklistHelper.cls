/**
 * Created by kentheberling on 3/20/18.
 */

public with sharing class Peak_ChecklistHelper {

    /*
       Creates Task Wrappers from queried Task MDTs, if testing just creates test wrappers
    */
    public static List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> getTasks(){

        if(Test.isRunningTest()){

            //Create some test TaskMDTWrappers
            List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> testTaskWrapperList =
                    new List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper>();

            Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper testTaskWrapper =
                    new Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper();

            testTaskWrapper.isSelected = true;
            testTaskWrapper.label = 'test';

            testTaskWrapperList.add(testTaskWrapper);

            return testTaskWrapperList;

        }else{

            //Create Task Wrapper from Task MDTs
            return Peak_CommunityTaskMDTWrapper.getTaskList();
        }

    }

    /*
        Creates Task Wrappers from Task MDTs queried by Group Id, if testing just creates test wrappers
     */
    public static List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> getTasksForGroups(List<Id> groupIds) {

        if(Test.isRunningTest()){
            List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> testTaskWrapperList =
                    new List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper>();

            for(Integer i = 0; i < groupIds.size(); i++) {
                //Create some test TaskMDTWrappers

                Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper testTaskWrapper =
                        new Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper();

                testTaskWrapper.isSelected = true;
                testTaskWrapper.label = 'testTaskForGroup' + i;

                testTaskWrapperList.add(testTaskWrapper);
            }

            return testTaskWrapperList;

        }else {
            //Create Task Wrapper from Task MDTs queried by Group Id
            return Peak_CommunityTaskMDTWrapper.getTasksForGroupsList(groupIds);
        }
    }

    /*
        Creates Task Group Wrappers from Task Group MDTs, if testing just creates test wrappers
    */
    public static List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper> getTaskGroups(){

        if(Test.isRunningTest()){
            //List of test Task Group Wrappers
            List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper> testTaskGroupWrapperList =
                    new List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper>();

            //First test Task Group Wrapper
            Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper testTaskGroupWrapper =
                    new Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper();
            testTaskGroupWrapper.label = 'testTaskGroup1';
            testTaskGroupWrapper.isSelected = false;
            testTaskGroupWrapper.id = Peak_TestUtils.getFakeId(User.SObjectType);

            testTaskGroupWrapperList.add(testTaskGroupWrapper);

            //Second test Task Group Wrapper
            Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper testTaskGroupWrapper2 =
                    new Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper();


            testTaskGroupWrapper2.label = 'testTaskGroup2';
            testTaskGroupWrapper2.isSelected = false;
            testTaskGroupWrapper2.id = Peak_TestUtils.getFakeId(Account.SObjectType);

            testTaskGroupWrapperList.add(testTaskGroupWrapper2);

            return testTaskGroupWrapperList;

        }else{
            //Get Task Groups
            return Peak_CommunityTaskGroupMDTWrapper.getTaskGroupsList();
        }
    }

    /*
        Format MDT wrappers as native Peak_Checklist_Task__c and assign to a Checklist
     */
    public static List<Peak_Checklist_Task__c> formatTasksFromMDTWrapper (List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> wrapperTasks, Id checkListId){
        List<Peak_Checklist_Task__c> returnList = new List<Peak_Checklist_Task__c>();

        // For each wrapper, format as Peak_Checklist_Task__c object
        for (Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper wrapperTask : wrapperTasks ){

            returnList.add(new Peak_Checklist_Task__c(
                Peak_Checklist__c = checkListId,
                Name = wrapperTask.Label,
                Complete__c = false
            ));
        }

        return returnList;
    }

    /*
        Get checklist and related tasks for user, based on active or inactive
     */
    public static List<Peak_Checklist__c> getChecklistForUser(Id userId, Boolean isActive){

        return [SELECT Completed__c, Completed_Tasks__c, Name, Number_of_Tasks__c,
                    (SELECT Id, Name, Complete__c, Order__c FROM Peak_Checklist_Tasks__r ORDER BY Order__c)
                From Peak_Checklist__c
                WHERE Peak_Checklist__c.User__c =:userId AND Is_Active__c = :isActive];
    }

    /*
        This method will check for an existing Task MDT
    */
    @AuraEnabled
    public static Boolean checkForDeactivatedTask(String newTaskName){
        List<Community_Task__mdt> taskMDTList = new List<Community_Task__mdt>();
        Boolean taskExists = FALSE;

        //If not running a test -- Query Task MDTs to see if the task exists
        if(!test.isRunningTest()){
            taskMDTList = [SELECT Id, DeveloperName, Label FROM Community_Task__mdt WHERE Deactivate__c = TRUE AND DeveloperName = :newTaskName];
        }

        //If the task exists, activate it by setting Deactivate__c to false and return
        if(!Peak_Utils.isNullOrEmpty(taskMDTList)){
            taskExists = TRUE;
        }
        return taskExists;
    }

    /*
        This method will check for an existing Task Group MDT
    */
    @AuraEnabled
    public static Boolean checkForDeactivatedTaskGroup(String newTaskGroupName){
        List<Community_Task_Group__mdt> taskGroupMDTList = new List<Community_Task_Group__mdt>();
        Boolean taskExists = FALSE;

        //If not running a test -- Query Task Group MDTs to see if the group exists
        if(!test.isRunningTest()){
            taskGroupMDTList = [SELECT Id, DeveloperName, Label FROM Community_Task_Group__mdt WHERE Deactivate__c = TRUE AND DeveloperName = :newTaskGroupName];
        }

        //If the task exists, activate it by setting Deactivate__c to false and return
        if(!Peak_Utils.isNullOrEmpty(taskGroupMDTList)){
            taskExists = TRUE;
        }
        return taskExists;
    }
}