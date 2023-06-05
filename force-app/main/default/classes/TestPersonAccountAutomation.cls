@isTest
public class TestPersonAccountAutomation {
    
    @isTest
    public static void testCaseTrigger() {
        Case test1 = new Case(Subject = 'Test Case 1',SuppliedName = 'Test Person 1 ',SuppliedEmail = 'person1@test.com',SuppliedPhone = '2813308004');
        insert test1;
        
        test1 = [SELECT AccountId FROM Case WHERE Id = :test1.Id];
        Account person = [SELECT Id FROM Account WHERE Phone = '2813308004'][0];
        System.assertEquals(person.Id,test1.AccountId);
        
        Case test2 = new Case(Subject = 'Test Case 2',SuppliedName = 'Test Person 1',SuppliedEmail = 'person1@test.com',SuppliedPhone = '8675309');
        insert test2;
        
        test2 = [SELECT AccountId FROM Case WHERE Id = :test2.Id];
        System.assertEquals(person.Id,test2.AccountId);
        
        Case test3 = new Case(Subject = 'Test Case 3',SuppliedName = 'Test Person 2',SuppliedEmail = 'person2@test.com',SuppliedPhone = '0110100001101001');
        insert test3;
        test3 = [SELECT AccountId FROM Case WHERE Id = :test3.Id];
        
        Account person2 = [SELECT Id FROM Account WHERE Id = :test3.AccountId];
        person2.PersonEmail = 'person1@test.com';
        update person2;
        
        Case test4 = new Case(Subject = 'Test Case 4',SuppliedName = 'Test Person 2',SuppliedEmail = 'person1@test.com',SuppliedPhone = '0110100001101001');
        insert test4;
        
        test4 = [SELECT AccountId FROM Case WHERE Id = :test4.Id];
        System.assertEquals(test4.AccountId,person2.Id);
    }
}