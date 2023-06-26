/**
 * Created by Kaj Petersen, 7Summits on 3/12/18.
 */

@IsTest
private class Peak_ChecklistBaseControllerTest {

    public static User testUser{get;set;}

    @IsTest
    public static void setupTestData(){
        testUser = Peak_TestUtils.createStandardUser();
    }

    @IsTest
    static void testBasicChecklistFunctions() {

        setupTestData();

        try{
            insert testUser;
        } catch (Exception e){
            testUser.ContactId = null;
            insert testUser;
        }

        Peak_Response testResponse = new Peak_Response();
        Id testUserId = String.valueOf(testUser.Id);

        // Test getChecklistForUser with no checklist created, assert no checklist found
        testResponse = Peak_ChecklistBaseController.getChecklistForUser(testUserId);
        System.assert(Peak_Utils.isNullOrEmpty(testResponse.results));

        //Test createChecklistForUser, assert Peak_Response.success == true
        testResponse = Peak_ChecklistBaseController.createChecklistForUser(testUserId);
        System.assertEquals(true, testResponse.success);

        // Test getChecklistForUser, assert result is found
        testResponse = testResponse = Peak_ChecklistBaseController.getChecklistForUser(testUserId);
        System.assert(!Peak_Utils.isNullOrEmpty(testResponse.results));

    }


    @IsTest
    static void testTaskGrouping() {

        //Test Peak_ChecklistHelper.getTasksForGroups
        //Create list of fake ids to pass
        List<Id> fakeTaskGroupIds = new List<Id>();
        fakeTaskGroupIds.add(Peak_TestUtils.getFakeId(User.SObjectType));
        fakeTaskGroupIds.add(Peak_TestUtils.getFakeId(Account.SObjectType));

        List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> testTaskWrappers =
                Peak_ChecklistHelper.getTasksForGroups(fakeTaskGroupIds);

        System.assertEquals(testTaskWrappers.size(), fakeTaskGroupIds.size());

        // Use those results to test Peak_ChecklistHelper.formatTasksFromMDT
        Peak_CheckList__c testPeakChecklist = new Peak_Checklist__c();
        insert testPeakChecklist;

        List<Peak_Checklist_Task__c> testChecklistTasks = Peak_ChecklistHelper.formatTasksFromMDTWrapper(testTaskWrappers,testPeakChecklist.Id);
        System.assertEquals(testChecklistTasks.size(),testTaskWrappers.size());

        //Test Peak_ChecklistBaseController.getTaskGroups
        List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper> testTaskGroupWrapperList =
                Peak_ChecklistBaseController.getTaskGroups();

        System.assertEquals('testTaskGroup1', testTaskGroupWrapperList[0].label);
        System.assert(!Peak_Utils.isNullOrEmpty(testTaskGroupWrapperList));


        //Test Peak_ChecklistBaseController.getTasks
        List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> testTaskWrapperList =
                Peak_ChecklistBaseController.getTasks();

        System.assertEquals('test', testTaskWrapperList[0].label);
        System.assert(!Peak_Utils.isNullOrEmpty(testTaskWrapperList));


    }

    @IsTest
    static void testCreateTasksForUser() {
        setupTestData();

        try{
            insert testUser;
        } catch (Exception e){
            testUser.ContactId = null;
            insert testUser;
        }

        List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper> taskGroupMDTWrappers = Peak_ChecklistBaseController.getTaskGroups();
        List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> taskMDTWrappers = Peak_ChecklistBaseController.getTasks();

        List<Community_Task_Group_Assignment__mdt> groupAssignments = new List<Community_Task_Group_Assignment__mdt>();

        Test.startTest();

        // Create tasks for user
        Peak_Response testResponse = Peak_ChecklistBaseController.createTasksFromFormForUser(testUser.Id,
                JSON.serialize(taskMDTWrappers), JSON.serialize(taskGroupMDTWrappers));

        // Query tasks for user
        List<Peak_Checklist_Task__c> tasks = new List<Peak_Checklist_Task__c>([SELECT Id, Complete__c FROM
                Peak_Checklist_Task__c WHERE Peak_Checklist__r.User__c = :testUser.Id]);

        // Assert that the user was assigned all possible tasks! (since we passed in the full list)
        System.assertEquals(tasks.size(),taskMDTWrappers.size());

        // Run createTasksFromFormForUser again
        Peak_Response testResponse2 = Peak_ChecklistBaseController.createTasksFromFormForUser(testUser.Id,
                JSON.serialize(taskMDTWrappers), JSON.serialize(taskGroupMDTWrappers));

        // Query tasks for user again
        List<Peak_Checklist_Task__c> tasks2 = new List<Peak_Checklist_Task__c>([SELECT Id, Complete__c FROM
                Peak_Checklist_Task__c WHERE Peak_Checklist__r.User__c = :testUser.Id]);

        //assure list size has not changed (should not be creating duplicate tasks for user)
        System.assertEquals(tasks2.size(),taskMDTWrappers.size());

        // Alter taskGroupMDTWrappers to set some to isSelected = true,
        taskGroupMDTWrappers[0].isSelected = true;

        // Delete current tasks,
        delete tasks[0];

        // Run createTasksFromFormForUser again,
        Peak_Response testResponse3 = Peak_ChecklistBaseController.createTasksFromFormForUser(testUser.Id,
                JSON.serialize(taskMDTWrappers), JSON.serialize(taskGroupMDTWrappers));

        // Query tasks for user again
        List<Peak_Checklist_Task__c> tasks3 = new List<Peak_Checklist_Task__c>([SELECT Id, Complete__c FROM
                Peak_Checklist_Task__c WHERE Peak_Checklist__r.User__c = :testUser.Id]);

        System.assertEquals(tasks3.size(), taskMDTWrappers.size() + 1);

        // Test update
        testResponse = Peak_ChecklistBaseController.updateTask(tasks3[0]);
        system.assertEquals(testResponse.success,true);

        Test.stopTest();
    }

    @isTest
    public static void testCreateChecklistAndTasksForUser() {
        setupTestData();

        try{
            insert testUser;
        } catch (Exception e){
            testUser.ContactId = null;
            insert testUser;
        }

        List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper> taskGroupMDTWrappers = Peak_ChecklistBaseController.getTaskGroups();
        List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> taskMDTWrappers = Peak_ChecklistBaseController.getTasks();



        // Test the success route
        Peak_Response  testResponse = Peak_ChecklistBaseController.createChecklistAndTasksForUser(String.valueOf(testUser.Id),taskGroupMDTWrappers[0].id);
        System.assertEquals(testResponse.success,true);

        // Trip the failure route with an invalid user Id (use the task group Id instead, which is of course not a real user ID)
        testResponse = Peak_ChecklistBaseController.createChecklistAndTasksForUser(String.valueOf(taskGroupMDTWrappers[0].id),taskGroupMDTWrappers[0].id);
        System.assertEquals(testResponse.success,false);

    }

    @isTest
    public static void testMDTWrappers(){

        //Test Peak_CommunityTaskGroupMDTWrapper
        Community_Task_Group__mdt mdtGroup = new Community_Task_Group__mdt();

        Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper wrapper =
                Peak_CommunityTaskGroupMDTWrapper.formatMDTtoWrapper(mdtGroup);

        List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper> testWrapperList =
                Peak_CommunityTaskGroupMDTWrapper.getTaskGroupsList();


        //Test Peak_CommunityTaskMDTWrapper
        Community_Task__mdt mdtTask = new Community_Task__mdt();

        Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper taskWrapper =
                Peak_CommunityTaskMDTWrapper.formatMDTtoWrapper(mdtTask, 1);

        List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> testTaskWrappers = Peak_CommunityTaskMDTWrapper.getTaskList();

        List<Id> fakeIds = new List<Id>();

        fakeIds.add(Peak_TestUtils.getFakeId(User.SObjectType));

        List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> testTaskWrapperList =
                Peak_CommunityTaskMDTWrapper.getTasksForGroupsList(fakeIds);
	    System.assertNotEquals(null, testTaskWrapperList);
    }

}