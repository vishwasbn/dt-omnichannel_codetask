global class Fleet_AccountsMassTransferBatch implements Database.Batchable<sObject>, Database.Stateful{
    //public transient List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
    List<sObject> sObjList;
    String finalstr;
    
    public Fleet_AccountsMassTransferBatch(List<SObject> accountList)
    {
        this.sObjList = accountList;
       
        String header = 'Record Id, Name , Error \n';
        finalstr = header ;
    }
    
    public Iterable<sObject> start(Database.BatchableContext bc) {  
        return sObjList;
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> records){
        List<Account> acctList =(List<Account>)records;
        System.debug('acctList :::::' + acctList[0].OwnerId);
        System.debug('@@@ acctList :' + acctList);

        Database.upsertResult[] srList = Database.upsert(acctList, false); 
        
        for(Integer idx = 0; idx < srList.size(); idx++) {
            if(srList[idx].isSuccess()) {
                
            } else {
                List<Database.Error> errors = srList[idx].getErrors();
                for(Database.Error err : Errors) 
                {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    finalstr += acctList[idx].id + ',' + acctList[idx].Name + ',' + err.getMessage() +'\n';
                }
            }
        }     
    }
     
    public void finish(Database.BatchableContext bc)
    {
        blob csvBlob = Blob.valueOf(finalstr);
        
        List<Folder> folderList = [SELECT id from Folder WHERE Name = 'Account Transfer'];
        
        Document d = new Document(); 
        //d.Name = 'Account.csv'; 
        //d.Body = csvBlob; 
        //d.FolderId = folderList[0].Id;
        //d.Type = 'csv';
        
        //insert d;
    }
}