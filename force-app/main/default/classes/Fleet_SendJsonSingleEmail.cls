global class Fleet_SendJsonSingleEmail implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    List<Account> acctList;      
    Boolean isDelta = false;
    Boolean isRange = false;
    DateTime fromDate = null;
    DateTime toDate = null;
    Integer noOfDays = 0;
    Fleet_SendJsonSingleEmail batchClass;
    global void execute(SchedulableContext sc) {     
        Database.executebatch(this.batchClass,200);
    }
    public Fleet_SendJsonSingleEmail(Fleet_SendJsonSingleEmail e)
    {
        this.batchClass = e;        
    }
    public Fleet_SendJsonSingleEmail(){acctList = new  List<Account>();}
    public Fleet_SendJsonSingleEmail(Integer noOfDays){
        acctList = new  List<Account>();  
        this.noOfDays = noOfDays;
    }
    public Fleet_SendJsonSingleEmail(Boolean delta,String fromDate){
        acctList = new  List<Account>();   
        isDelta = delta;
        if(fromDate!=null){
            String[] datetokens = fromDate.split('/');
            Date myDate = Date.newInstance(Integer.valueOf(datetokens[0]), Integer.valueOf(datetokens[1]), Integer.valueOf(datetokens[2]));
            this.fromDate = DateTime.newInstance(myDate.year(),myDate.month(),myDate.day(),0,0,0);
        }        
    }
    public Fleet_SendJsonSingleEmail(Boolean isRange,String fromDate, String toDate){        
        acctList = new  List<Account>();  
        this.isRange = isRange;         
        if(fromDate!=null){
            String[] datetokens = fromDate.split('/');
            Date myDate = Date.newInstance(Integer.valueOf(datetokens[0]), Integer.valueOf(datetokens[1]), Integer.valueOf(datetokens[2]));
            this.fromDate = DateTime.newInstance(myDate.year(),myDate.month(),myDate.day(),10,0,0);
        }
        if(toDate!=null){
            String[] datetokens = toDate.split('/');
            Date myDate = Date.newInstance(Integer.valueOf(datetokens[0]), Integer.valueOf(datetokens[1]), Integer.valueOf(datetokens[2]));
            this.toDate = DateTime.newInstance(myDate.year(),myDate.month(),myDate.day(),-7,0,0);
        }        
    }
    
    public Iterable<sObject> start(Database.BatchableContext bc) {          
        List<Account> accts;        
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('B2B').getRecordTypeId();
        try{
            if(this.noOfDays != 0)
            {
                String query1 =  'Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=\''+devRecordTypeId+'\' and name !=null and ECC_Account_Number__c !=null and (CreatedDate = LAST_N_DAYS:'+ noOfDays+' or LastModifiedDate = LAST_N_DAYS:'+noOfDays+')';    
                accts = Database.query(query1);               
            }
            else if(this.isRange == true){
                if(Test.isRunningTest()){
                    accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null and Fleet_Account_Status__c != 'Closed' and ECC_Posting_Block_Company_Code__c != 'X' and  ((CreatedDate >=:fromDate and CreatedDate <= :this.toDate)  or (LastModifiedDate >= :this.fromDate and LastModifiedDate <= :this.toDate)) LIMIT 10];
                }
                else{
                    accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null and Fleet_Account_Status__c != 'Closed' and ECC_Posting_Block_Company_Code__c != 'X' and  ((CreatedDate >=:fromDate and CreatedDate <= :this.toDate)  or (LastModifiedDate >= :this.fromDate and LastModifiedDate <= :this.toDate))];
                }
                System.debug(accts);
            } else if(this.isDelta && this.fromDate == null){
                if(Test.isRunningTest()){
                    accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null and Fleet_Account_Status__c != 'Closed' and ECC_Posting_Block_Company_Code__c != 'X' and  (CreatedDate = TODAY or LastModifiedDate = TODAY) LIMIT 10];
                }
                else{
                    accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null and Fleet_Account_Status__c != 'Closed' and ECC_Posting_Block_Company_Code__c != 'X' and  (CreatedDate = TODAY or LastModifiedDate = TODAY)];
                }
            } else  if(this.isDelta && this.fromDate != null){  
                if(Test.isRunningTest()){
                    accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null and Fleet_Account_Status__c != 'Closed' and ECC_Posting_Block_Company_Code__c != 'X' and  (CreatedDate >= :this.fromDate or LastModifiedDate >= :this.fromDate)limit 10];
                    
                }else{
                    accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null and Fleet_Account_Status__c != 'Closed' and ECC_Posting_Block_Company_Code__c != 'X' and  (CreatedDate >= :this.fromDate or LastModifiedDate >= :this.fromDate)];
                    
                }
                
                //accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null and Fleet_Account_Status__c != 'Closed' and ECC_Posting_Block_Company_Code__c != 'X' and  (CreatedDate >= :this.fromDate or LastModifiedDate >= :this.fromDate)];
            } else{
                if(Test.isRunningTest()){
                    accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null and Fleet_Account_Status__c != 'Closed'  and ECC_Posting_Block_Company_Code__c != 'X' LIMIT 10];   
                }
                else{
                    accts = [Select Id,Name,ECC_Account_Number__c,Phone,Lead_Email__c, ShippingAddress,RecordTypeId from Account  where recordtypeid=:devRecordTypeId and name !=null and ECC_Account_Number__c !=null and Fleet_Account_Status__c != 'Closed'  and ECC_Posting_Block_Company_Code__c != 'X'];   
                }
            }
            
            
        }catch(Exception e){
            Logger logInstance = Logger.getInstance();
            logInstance.log('Send JSON Single Email', 'Fleet_SendJsonSingleEmail', e);
        }        
        System.debug('Accts size is ..........  '+accts.size());
        return (List<sObject>)accts;
    }
    public void execute(Database.BatchableContext bc, List<sObject> records){  
        System.debug('Records Size '+records.size());
        acctList.addAll((List<Account>)records);      
    }          
    public void finish(Database.BatchableContext bc){      
        List<Account> acctListSubset = new List<Account>();
        Integer countIndicator = 0, part = 0;
        date myDate = date.today();        
        String day='';
        String month='';
        if(myDate.month()<10){
            month='0'+myDate.month();
        }else{
            month= String.valueOf(myDate.month());
        }
        if(myDate.day()<10){
            day='0'+myDate.day();
        }else {
            day=String.valueOf(myDate.day());
        }
        String yesterday = month + day + String.valueOf(myDate.year());
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        for(Account a :acctList){            
            acctListSubset.add(a);
            countIndicator++;         
            if(acctListSubset.size() == 20000 || countIndicator == acctList.size()){
                part++;                   
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                if(this.isDelta || this.isRange)
                    attachment.setFileName('RegularFeedDT'+yesterday+'.JSON');    
                else
                    attachment.setFileName('RegularFeedDT'+yesterday+'.JSON');
                attachment.setBody(Blob.valueOf(JSON.serializePretty(acctListSubset)));     
                attachments.add(attachment);        
                acctListSubset = new List<Account>();                
            }
        }
        Messaging.SingleEmailMessage singleEmailMessage = new Messaging.SingleEmailMessage();
        if(FleetEmailAddresses__c.getOrgDefaults().Email_Address__c!=NULL){
            singleEmailMessage.setToAddresses(FleetEmailAddresses__c.getOrgDefaults().Email_Address__c.split(','));
        }
        if(attachments.size() == 0 )
        {
            singleEmailMessage.setSubject('Account Details: No account records found.');
            singleEmailMessage.setPlainTextBody('There are no Account records found.');
        }
        else  if(this.noOfDays != 0){
            singleEmailMessage.setSubject('Account Details: Account Records for the past '+noOfDays+' days.');
            singleEmailMessage.setPlainTextBody('Please find attached the Account Details Delta Records for the past '+noOfDays+' days.');
        }
        else  if(this.isRange){
            
            singleEmailMessage.setSubject('Account Details: Account Records between '+this.fromDate+' and '+this.toDate);
            singleEmailMessage.setPlainTextBody('Please find attached the Account Details Delta Records  between '+this.fromDate+' and '+this.toDate);
        }
        else  
            if(this.isDelta && this.fromDate == null){
                singleEmailMessage.setSubject('Account Details: Delta Records attached.');
                singleEmailMessage.setPlainTextBody('Please find attached the Account Details Delta Records for today.');
            }else if(this.isDelta && this.fromDate != null){
                singleEmailMessage.setSubject('Account Details: Delta Records from '+this.fromDate+' attached.');
                singleEmailMessage.setPlainTextBody('Please find attached the Account Details Delta Records from '+this.fromDate+'.');
            }else{
                singleEmailMessage.setSubject('Account Details: All Records attached.');
                singleEmailMessage.setPlainTextBody('Please find attached the Account Details Records.');
            }
        singleEmailMessage.setFileAttachments(attachments);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{singleEmailMessage});
    }                
}