global class Fleet_SendJSON implements Database.Batchable<sObject>,Database.Stateful{
    //public transient List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
    List<Account> acctList;  
    public Fleet_SendJSON()
    {
        acctList = new  List<Account>();            
    }
    public Iterable<sObject> start(Database.BatchableContext bc) {  
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('B2B').getRecordTypeId();
        System.debug('Record type id is '+devRecordTypeId);
        List<Account> accts;
        if(Test.isRunningTest()){
            accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null limit 1];
        }else
        {
            accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null];
        }
        
        System.debug('Size is '+accts.size());
        System.debug(JSON.serialize(accts)); 
        List<sObject> sObjList= (List<sObject>) accts;        
        return sObjList;
    }
    public void execute(Database.BatchableContext bc, List<sObject> records){  
        acctList.addAll((List<Account>)records);      
    }      
    
    public void finish(Database.BatchableContext bc){ 
        List<Account> acctListSubset;
        Integer i = 0;
        acctListSubset = new List<Account>();
        for(Account a :acctList)
        {            
            acctListSubset.add(a);
            i++;
            If(acctListSubset.size() == 5000 || i==acctList.size())
            {
                sendEmail(acctListSubset);            
                acctListSubset = new List<Account>();                
            }
        }
    }
    Integer j = 0;
    public void sendEmail(List<Account> acctList){
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        Blob b = Blob.valueOf(JSON.serialize(acctList));
        j++;
        attach.setFileName('Account Details-Part'+j+'.JSON');
        
        attach.setBody(b);
        semail.setSubject('Account Details');
        String[] sendTo = new String[]{'satya.siva@cyan360.com','sumeet.narang@discounttire.com','christopher.blevans@discounttire.com'};
            semail.setToAddresses(sendTo);
        //   mail.setCCAddresses(new String[]{''});
        semail.setPlainTextBody('Please find the attached Account details');
        semail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});   
    }
}