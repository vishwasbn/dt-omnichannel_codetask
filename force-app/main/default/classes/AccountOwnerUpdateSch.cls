public class AccountOwnerUpdateSch implements Schedulable{

    public void execute(SchedulableContext sc){
         String status='Closed';
        String recordType='B2B';
        // 'Gautam Pai'
        // select id, Fleet_Account_Status__c, Account_Closure_Reason__c, ownerid, owner.name,Fleet_Specialist__c from account where owner.name ='Gautam Pai' AND Fleet_Specialist__r.name='Chelsey Lupeski' And Fleet_Account_Status__c='Closed'
        List<Account> accountList=[select id, Fleet_Account_Status__c, Account_Closure_Reason__c, ownerid, owner.name from account where (owner.name!=:System.Label.Fleet_Closed_Account_Owner) AND (Fleet_Account_Status__c=:status and Account_Closure_Reason__c!=null and recordtype.name=:recordType) LIMIT 100];
        List<Account> accountUpdateList = new List<Account>();
        User userRecord = [select id, username,federationIdentifier from user where name=:System.Label.Fleet_Closed_Account_Owner and federationIdentifier!=null];
        //Contact conRecord = [select id,name, ownerid,owner.name from contact where owner.name='Chelsey Lupeski'and recordtype.developername='B2B_Contact' ];
        //user fleetSpecialistRecord = [select id, username,federationIdentifier from user where name='Chelsey Lupeski' and federationIdentifier!=null];
        for(Account accRecord :accountList )
        {
            if(accRecord.ownerid!= userRecord.Id )
            {
                accRecord.ownerid = userRecord.Id;
                accRecord.Fleet_Specialist__c = userRecord.Id;
               // accRecord.Fleet_Primary_Contact__c=conRecord.id;
                accountUpdateList.add(accRecord);
            }
        }
        update accountUpdateList;
    }
}