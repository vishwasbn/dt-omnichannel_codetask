/**
 * Created by shashi arrabeli on 4/25/18.
 */
@IsTest
public with sharing class Peak_ChecklistMDTControllerTest {
    @IsTest
    public static void testSaveTask() {
        Peak_Response testResponse = new Peak_Response();
        testResponse = Peak_ChecklistMDTController.saveTask('Walking');
        //test comment

        // Cannot insert MDT in tests!
        system.assertEquals(false, testResponse.success);
    }
    
    @IsTest
    public static void testGetDeployResult(){
        Peak_Response testResponse = new Peak_Response();
        testResponse = Peak_ChecklistMDTController.getDeployResult('Test12');
        system.assertEquals(true, testResponse.success);
    }
    
     @IsTest
    public static void testDeleteTask(){
        Peak_Response testResponse2 = new Peak_Response();
        testResponse2 = Peak_ChecklistMDTController.deleteTask('Test_Task', 'Test Task');
	     System.assertNotEquals(null, testResponse2);
    }

}