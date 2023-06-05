@IsTest
private class Peak_CommunityTaskMDTWrapperTest {
    @isTest
    public static void testGetTaskList() {
        List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> tasks = Peak_CommunityTaskMDTWrapper.getTaskList();
        system.assertEquals(1, tasks.size());
    }
    
    @isTest
    public static void testGetTasksForGroupsList() {
        List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> tasks = Peak_CommunityTaskMDTWrapper.getTasksForGroupsList(null);
        system.assertEquals(1, tasks.size());
    }
}