/**
 * Log Errors into a Custom Object
 */

public with sharing class Peak_ErrorLogger {

    public static void logError(Exception e){
        // Set up new record
        Peak_Error_Log__c errorLog = new Peak_Error_Log__c();

        // Add properties
        errorLog.Type__c = e.getTypeName();
        errorLog.Message__c = e.getMessage();
        errorLog.Stack_Trace__c = e.getStackTraceString();

        // Insert
        insert errorLog;
    }
}