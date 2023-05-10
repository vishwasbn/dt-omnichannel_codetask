/***********************************************************************************************************************************
Name      : AccountOwnerUpdateBatchhttps://discounttiresf--fleetdev.sandbox.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#
Usage     : Batch class to update the owner of Accounts with closed accounts 
Date      : March 2021  

#1
Modified By : Rohith V	
Modified Date :  03/27/2023
User Story Number : Salesforce-214.
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
        
        //Code updated to remove Gautam Pai and to add Chelsey Lupeski as the account owner, created a custom label Fleet_Closed_Account_Owner to remove the hard coded value.
        //Salesforce-214 - Rohith.V
        
        User userRecord = [select id, username,email,federationIdentifier from user where name=:System.Label.Fleet_Closed_Account_Owner and federationIdentifier!=null];
        //Contact conRecord = [select id,name, ownerid,owner.name from contact where owner.name='Chelsey Lupeski'and recordtype.developername='B2B_Contact' ];
        //user fleetSpecialistRecord = [select id, username,federationIdentifier from user where name='Chelsey Lupeski' and federationIdentifier!=null];
        for(Account accRecord :accountList )
        {
            if(accRecord.ownerid!= userRecord.Id )
            {
                accRecord.ownerid = userRecord.Id;
                accRecord.Fleet_Specialist__c = userRecord.Id;
                //accRecord.Fleet_Primary_Contact__c=conRecord.id; 
                //accRecord.Fleet_Primary_Contact__r.ownerid = userRecord.Id;
                
                
                accountUpdateList.add(accRecord);
            }
        }
       /* list<contact> contactUpdateList= new list<contact>();
        list<contact> contactList =[select id, name, ownerid from contact where contact.accountid IN: accountUpdateList];
        for(contact conRecord :contactList )
        {
            if(conRecord.ownerid!= userRecord.Id )
            {
                 conRecord.ownerid=userRecord.Id;
                 contactUpdateList.add(conRecord);
            }
        }
       
        update contactUpdateList;*/
        try{
            update accountUpdateList;
        }
        catch(Exception ex){
            Logger logInstance = Logger.getInstance();
            logInstance.log('Account_updates_batch', 'AccountOwnerUpdateBatch', 'Account', ex, JSON.serialize(accountUpdateList));
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