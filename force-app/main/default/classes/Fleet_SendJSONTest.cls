@isTest(seeAllData=true)
public class Fleet_SendJSONTest {    
    public static testMethod void fleet_SendJSONTestMethod()
    {
        Id profileId1 = [Select Id From Profile Where Name ='System Administrator'].Id;
        User adminUser = Fleet_TestUtility.createUser('',profileId1,'Satya','Siva');
        Test.startTest();        
        System.runAs(adminUser) {            
            Fleet_SendJSON fsJ = new Fleet_SendJSON();       
            Database.executeBatch(fsJ,200);
        }        
        Test.stopTest();       
    }
}