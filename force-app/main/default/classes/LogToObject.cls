public without sharing class LogToObject implements LogWriter {

    public void write(List<Logger.Log> logs) {
        List<Log__c> logRecords = new List<Log__c>();

        for (Logger.Log log : logs) {
            logRecords.add(log.toLogObject());
        }

        Database.insert(logRecords, false);
    }

}