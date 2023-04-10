/***********************************************************************************************************************************
Name      : AccountOwnerUpdateBatch
Usage     : Batch class to update the owner of Accounts with closed accounts 
Date      : March 2021  
************************************************************************************************************************************/ 
public class AccountOwnerUpdateBatch implements Database.Batchable<sObject>, Schedulable{
    
    public database.queryLocator start(Database.batchablecontext bc)    
    {
        String status='Closed';
        String recordType='B2B';
        return  Database.getQueryLocator('select id, Fleet_Account_Status__c, Account_Closure_Reason__c, ownerid, owner.name from account where Fleet_Account_Status__c=:status and Account_Closure_Reason__c!=null and recordtype.name=:recordType');
    }
    public void execute(Database.batchablecontext bc, List<Account> accountList)
    {
        List<Account> accountUpdateList = new List<Account>();
        User userRecord = [select id, username,federationIdentifier from user where name='Gautam Pai' and federationIdentifier!=null];
        user fleetSpecialistRecord = [select id, username,federationIdentifier from user where name='Chelsey Lupeski' and federationIdentifier!=null];
        for(Account accRecord :accountList )
        {
            if(accRecord.ownerid!= userRecord.Id )
            {
                accRecord.ownerid = userRecord.Id;
                accRecord.Fleet_Specialist__c = fleetSpecialistRecord.Id;
                accountUpdateList.add(accRecord);
            }
        }
        try{
            update accountUpdateList;
        }
        catch(Exception ex){
            Logger logInstance = Logger.getInstance();
            logInstance.log('Account_updates', 'AccountOwnerUpdateBatch', 'Account', ex, JSON.serialize(accountUpdateList));
        }
        
    }
    public void finish(Database.batchablecontext bc)
    {
        
    }
    public void execute(SchedulableContext sc)
    {
        AccountOwnerUpdateBatch accountBatch = new AccountOwnerUpdateBatch();
        database.executeBatch(accountBatch);
    }
}