@isTest
public class AccountOwnerUpdateSchTest {
@testSetup
    static void testRecords()
    {
        List<Account> accounts = new List<Account>();
        for (Integer i=0;i<10;i++) {
            accounts.add(new Account(name='Account '+i,Fleet_Account_Status__c='Closed',Account_Closure_Reason__c='Bankruptcy'));
        }
        insert accounts;
    }
   
    static testMethod void scheduleTest()
    {
        test.startTest();
        SchedulableContext sc = null;
        AccountOwnerUpdateSch tsc = new AccountOwnerUpdateSch();
        tsc.execute(sc);
        test.stopTest();
    }
}