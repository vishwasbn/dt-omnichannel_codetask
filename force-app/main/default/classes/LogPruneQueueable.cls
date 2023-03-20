// Ignores CRUD/FLS/Sharing so that pruning of log files happens regardless of user permissions.
public without sharing class LogPruneQueueable implements Queueable {

    private Datetime pruneStartDate;
    private Integer maxToDeleteInTransaction = 200;

    public LogPruneQueueable(Datetime pruneStartDate) {
        this.pruneStartDate = pruneStartDate;
    }

    public void execute(QueueableContext context) {
        List<Log__c> logs = [SELECT Id FROM Log__c WHERE CreatedDate <= :this.pruneStartDate LIMIT :this.maxToDeleteInTransaction];
        delete logs;

        // If the number of logs deleted is equal to the max to delete in a transaction,
        // queue up a new instance of the queueable with the same parameters. Eventually
        // it will be less than this number and the loop will exit.
        if (logs.size() == maxToDeleteInTransaction) {
            LogPruneQueueable lpq = new LogPruneQueueable(this.pruneStartDate);
            //if (!Test.isRunningTest()) {
               // System.enqueueJob(lpq);
            //}
        }
    }

}