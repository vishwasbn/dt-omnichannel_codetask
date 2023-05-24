/***********************************************************************************************************************************
Name      : AccountOwnerUpdateBatchTest
Usage     : Apex Controller to test AccountOwnerUpdateBatch class
Associated Controller:AccountOwnerUpdateBatch
Date      : March 2021  
************************************************************************************************************************************/
@isTest
public class AccountOwnerUpdateBatchTest {
    @testSetup
    static void testRecords()
    {
        List<Account> accounts = new List<Account>();
        for (Integer i=0;i<10;i++) {
            accounts.add(new Account(name='Account '+i,Fleet_Account_Status__c='Closed',Account_Closure_Reason__c='Bankruptcy'));
        }
        insert accounts;
    }
    static testMethod  void testBatch()
    {
        List<Account> accounts = [select id, Fleet_Account_Status__c, Account_Closure_Reason__c, ownerid, owner.name from account];
        test.startTest();
        AccountOwnerUpdateBatch accOwner = new AccountOwnerUpdateBatch();
        database.executeBatch(accOwner);
        test.stopTest();
        List<Account> accountsUpdated = [select id, Fleet_Account_Status__c, Account_Closure_Reason__c, ownerid, owner.name from account];
        system.assert(accountsUpdated[0].owner.name=='Chelsey Lupeski','Account owner not updated');
        system.assert(accountsUpdated[2].owner.name=='Chelsey Lupeski','Account owner not updated');
    }
    static testMethod void scheduleTest()
    {
        test.startTest();
        SchedulableContext sc = null;
        AccountOwnerUpdateBatch tsc = new AccountOwnerUpdateBatch();
        tsc.execute(sc);
        test.stopTest();
    }
}