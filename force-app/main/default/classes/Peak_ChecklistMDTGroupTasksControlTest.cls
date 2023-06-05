/**
 * Created by melindagrad on 6/5/18.
 */

@isTest
public with sharing class Peak_ChecklistMDTGroupTasksControlTest {

    @isTest
    public static void testSaveTaskGroupAssignments(){

        String taskGroupName = 'TEST';
        List<String> selectedTaskNames = new List<String>();
        selectedTaskNames.add('TEST1');
        selectedTaskNames.add('TEST2');

        Peak_Response response = Peak_ChecklistMDTGroupTasksController.saveTaskGroupAssignments (taskGroupName, selectedTaskNames);
        //response = Peak_ChecklistMDTGroupTasksController.saveTaskGroupAssignments (null, null);
        System.assertNotEquals(null, response);
    }

    @IsTest
    public static void testGetDeployGroupResult(){
        Peak_Response testResponseGroup = new Peak_Response();
        String GroupJobId='Test';
        testResponseGroup = Peak_ChecklistMDTGroupTasksController.getDeployGroupResult(GroupJobId);
       system.debug('testResponseGroup: '+testResponseGroup.success);
       // System.assertEquals(true, testResponseGroup.success);
    }
    @IsTest
    public static void testGetDeployGroupResultForNull(){
        Peak_Response testResponseGroup = new Peak_Response();
        String GroupJobId='';
        //String GroupJobId='NULL';
        testResponseGroup = Peak_ChecklistMDTGroupTasksController.getDeployGroupResult(GroupJobId);
        //System.assertEquals(false, testResponseGroup.success);
        System.assert(Peak_Utils.isNullOrEmpty(testResponseGroup.results));

    }

    @isTest
    public static void testDeactivateField(){
        String selectedTaskName = 'Test Task Name';
        Set<String> setTaskNamesToDeactivate = new Set<String>();

        Metadata.CustomMetadataValue testValue = Peak_ChecklistMDTGroupTasksController.deactivateField(setTaskNamesToDeactivate, selectedTaskName);
        System.assertNotEquals(NULL, testValue);

        setTaskNamesToDeactivate.add(selectedTaskName);
        testValue = Peak_ChecklistMDTGroupTasksController.deactivateField(setTaskNamesToDeactivate, selectedTaskName);
        System.assertNotEquals(NULL, testValue);
    }

    @isTest
    public static void testGetTaskGroupAssignment(){
        List<Community_Task_Group_Assignment__mdt> taskGroupAssignmentList = Peak_ChecklistMDTGroupTasksController.getTaskGroupAssignment();
        System.assertEquals(0, taskGroupAssignmentList.size());
    }
}