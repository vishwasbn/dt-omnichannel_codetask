@isTest
private class LogPruneQueueableText {
    
    @testSetup static void setupData() {
        List<Log__c> logList = new List<Log__c>();
        for(Integer i=0; i<201; i++){
            Log__c logObj =new Log__c();
            logList.add(logObj);
        }
        insert logList;
    }
        
    static testMethod void  LogPruneQueueableTest(){
        List<Log__c> logList = [SELECT Id FROM Log__c LIMIT 500];
        LogPruneQueueable Logp = new LogPruneQueueable(System.today());
        system.enqueueJob(Logp);
    }
}