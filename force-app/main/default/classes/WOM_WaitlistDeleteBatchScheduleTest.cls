/****************************************************************************************************************************
* @description       : Test class for WOM_WaitlistDeleteBatchSchedule
* @author            : Capgemini 
* @last modified on  : 02-28-2023

Modification Log:
----------------------------------------------------------------------------------------------------------
Developer       Mod Number      Date                    User Story          Description
----------------------------------------------------------------------------------------------------------
Anuradha        M-001           07th Feb 2023           WOM-1599              Test class for WOM_WaitlistDeleteBatchSchedule
Vishal          M-002           16th Mar 2023                                 Modified the changes as per the static analysis report
G Anil          M-003           24th Mar 2023                                 added test user and system.assertEquals for testschedule
****************************************************************************************************************************/
@isTest (seeAllData = false)
public class WOM_WaitlistDeleteBatchScheduleTest {
    /**
    * @Method Name       : dataSetup
    * @description       : It is used to create data needed for testing 
    * @author            : G Anil
    * @last modified on  : 24-03-2023
    **/ 
    @testSetup 
    static void dataSetup(){
        
        //insert User
        List<User> usr = WOM_TestDataUtility.createUsers(1,'Test','User','System Administrator',true);
        usr[0].User_Store_Id__c='123123';
        insert usr; 
    }
    /**
    *  @description : testschedule 
    *  @name        : testschedule 
    */
    public static testMethod void testschedule() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
        Test.StartTest();
            WOM_WaitlistDeleteBatchSchedule scheduleJob = new WOM_WaitlistDeleteBatchSchedule();
            String sch = '0 0 23 * * ?';
            String jobId = system.schedule('Test Waitlist Nightly Batch Run', sch, scheduleJob); 
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
   
         // Verify the expressions are the same
        System.assertEquals(sch,ct.CronExpression,'check for schedule');
        Test.stopTest(); 
    }
}
    
    
    
}