public class Fleet_AccountsTransferUtil {
    @AuraEnabled
    public static List<User> search(String objectName, List<String> fields, String searchTerm, String lbl)
    {  
        String searchTermVal='%'+searchTerm+'%';
        Boolean isActive = (lbl == 'New Owner' ? TRUE : FALSE);
        List<User> userList = [select Id, Name, Username, Phone, Profile.Name, IsActive 
                               from User 
                               where Name like : searchTermVal
                               and Profile.Name = 'Fleet Sales User'];
        
        if(isActive)
            userList = [select Id, Name, Username, Phone, Profile.Name, IsActive 
                        from User 
                        where Name like : searchTermVal
                        and Profile.Name = 'Fleet Sales User'
                        and IsActive = true];
        
        return userList;
    }
    
    class AccountObj
    {
        public Id id;
        public String name;
        public String ownerName;        
    }
    
    @AuraEnabled
    public static String transferAccountsOwnership(String oldOwner, String newOwner)
    {        
        system.debug('@@@ oldOwner: '+ oldOwner);
        system.debug('@@@ newOwner: '+ newOwner);

        Map<String, String> userFleet= new Map<String, String>{'Chelsey Lupeski' => 'Dan Meadows', 'Dan Meadows' => 'Chelsey Lupeski', 'Brad Randall' => 'Joshua Merrill', 'Brett Mecham' => 'Alexander Marrufo'};

        List<User> oldUserList = [select id,name from User where username=:oldOwner limit 1]; 
        system.debug('@@@ owner list: '+ oldUserList);
        List<Account> accountList =null;
        if(oldUserList!=null && oldUserList.size()>0)
        {
            accountList = [select id, Name, ownerId, owner.Name, Fleet_Specialist__c from Account where ownerId=:oldUserList[0].id];   
            system.debug('@@@ accountList: '+ accountList);  
        }
        String status='';
        List<User> newUserList = [select id,name from User where username=:newOwner limit 1];        
        if(accountList==null || accountList.size()==0)
        {
            status = 'No account records owned by the Current Owner';
        }
        else if(accountList!=null && accountList.size()>0 && newUserList!=null && newUserList.size()>0 && oldUserList!=null && oldUserList.size()>0)
        {        
            for(Account a: accountList)
            {
                system.debug('@@@ account: '+ a);
                if(a.Fleet_Specialist__c != null && a.ownerId != a.Fleet_Specialist__c){
                    if(newUserList[0].Name == 'Chelsey Lupeski' || newUserList[0].Name == 'Danny Meadows' || newUserList[0].Name == 'Brad Randall' || newUserList[0].Name == 'Brett Mecham'){
                        system.debug('Owner: '+ newUserList[0].Name);
                        User u = [select id, Name from user where name = :userFleet.get(newUserList[0].Name) LIMIT 1];
                        system.debug('User: '+ u.Name);
                        a.Fleet_Specialist__c = u.id;
                    }
                    a.ownerId = newUserList[0].id;    
                }else{
                    a.ownerId = newUserList[0].id;    
                    if(newUserList[0].Name == 'Chelsey Lupeski' || newUserList[0].Name == 'Danny Meadows' || newUserList[0].Name == 'Brad Randall' || newUserList[0].Name == 'Brett Mecham'){
                        User u = [select id, Name from user where name = :userFleet.get(newUserList[0].Name) LIMIT 1];
                        a.Fleet_Specialist__c = u.id;
                    }else{
                        a.Fleet_Specialist__c = newUserList[0].id;
                    }
                }            
            }
        }
        else{
            status = 'Please check the your input. Transfer failed';
        }
        
        if(accountList != null && accountList.size() > 0)
        {
            List<sObject> acctSObjectList = (List<SObject>)accountList;
            Fleet_AccountsMassTransferBatch fleetMassTransferBatch = new Fleet_AccountsMassTransferBatch(acctSObjectList);
            String jobId = Database.executeBatch(fleetMassTransferBatch, 50);
            status = 'Job Id: ' + jobId + '. Processing ' + accountList.size() + ' accounts owner update.';
            // status = 'Processing ' + accountList.size() + ' accounts owner update.';

        } 
        /*
        if(accountList != null && accountList.size()>0 && accountList.size()<10000)
        {
            upsert accountList;
            status = 'Transfer Successful';
        }*/
        return status;
    }
    


    @AuraEnabled
    public static String getJobStatus(String jobId)
    {
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email, ExtendedStatus
                          from AsyncApexJob where Id =: jobId]; 
        
        return a.Status;
    }
}