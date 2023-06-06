/**
 * Created by shashiarrabeli on 5/4/18.
 */
@isTest
public with sharing class Peak_ChecklistMDTTaskGroupControllerTest {
    @IsTest
    public static void testSaveTaskGroup() {
        Peak_Response testResponseGroup = new Peak_Response();
        testResponseGroup = Peak_ChecklistMDTTaskGroupController.saveTaskGroup('RWalk');

        // Cannot insert MDT in tests
        system.assertEquals(false, testResponseGroup.success);
    }

    @IsTest
    public static void testSaveTaskGroupForNull(){
        Peak_Response testResponseGroupNull = new Peak_Response();
        testResponseGroupNull = Peak_ChecklistMDTTaskGroupController.saveTaskGroup('');
        system.assertEquals(false, testResponseGroupNull.success);

    }
    @IsTest
    public static void testGetDeployGroupResult(){
        Peak_Response testResponseGroup = new Peak_Response();
        String GroupJobId='Test';
        testResponseGroup = Peak_ChecklistMDTTaskGroupController.getDeployGroupResult(GroupJobId);
        System.assertEquals(true, testResponseGroup.success);
    }
    @IsTest
    public static void testGetDeployGroupResultForNull(){
        Peak_Response testResponseGroup = new Peak_Response();
        String GroupJobId='';
        testResponseGroup = Peak_ChecklistMDTTaskGroupController.getDeployGroupResult(GroupJobId);
        //System.assertEquals(false, testResponseGroup.success);
        System.assert(Peak_Utils.isNullOrEmpty(testResponseGroup.results));
    }

    @IsTest
    public static void testDeleteTaskGroup(){
        Peak_Response peakResponse = Peak_ChecklistMDTTaskGroupController.deleteTaskGroup('Test_Task_Group', 'Test Task Group');
        System.assertNotEquals(null, peakResponse);
    }
}