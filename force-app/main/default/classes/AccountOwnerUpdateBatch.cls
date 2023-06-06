/***********************************************************************************************************************************
Name      : AccountOwnerUpdateBatchhttps://discounttiresf--fleetdev.sandbox.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#
Usage     : Batch class to update the owner of Accounts with closed accounts 
Date      : March 2021  

#1
Modified By : Rohith V	
Modified Date :  03/27/2023
User Story Number : Salesforce-214.
************************************************************************************************************************************/ 
public class AccountOwnerUpdateBatch implements Database.Batchable<sObject>, Schedulable, Database.stateful{
    String newOwner;
    String newSpecialist;
    public AccountOwnerUpdateBatch(){
      newOwner = System.Label.New_AccountOwner; 
      newSpecialist = System.Label.New_Specialist; 
    }
    
    public database.queryLocator start(Database.batchablecontext bc)    
    {
        String status='Closed';
        String recordType='B2B';                 
        String ownername=System.Label.Fleet_Closed_Account_Owner; 
        return  Database.getQueryLocator('select id, name, Fleet_Account_Status__c, Account_Closure_Reason__c, ownerid, owner.name from account where Fleet_Account_Status__c=:status and Account_Closure_Reason__c!=null and recordtype.name=:recordType  and owner.name!=: ownername');
    }
    public void execute(Database.batchablecontext bc, List<Account> accountList)
    {
        System.debug(' account list name '+accountList[0].name);
        
        List<Account> accountUpdateList = new List<Account>();
        
        //Code updated to remove Gautam Pai and to add Chelsey Lupeski as the account owner, created a custom label Fleet_Closed_Account_Owner to remove the hard coded value.
        //Salesforce-214 - Rohith.V
        
        User userRecord = [select id, username,email,federationIdentifier from user where name=:System.Label.Fleet_Closed_Account_Owner and federationIdentifier!=null];
        for(Account accRecord :accountList )
        {
            if(accRecord.ownerid!= userRecord.Id )
            {
                System.debug('Acc record name is '+accRecord.name);
                accRecord.ownerid = userRecord.Id;
                accRecord.Fleet_Specialist__c = userRecord.Id;
                
                accountUpdateList.add(accRecord);
            }
        }
        update accountUpdateList;
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