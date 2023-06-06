/**
 * Test for Peak_ErrorLogger
 */
@isTest
public with sharing class Peak_ErrorLoggerTest {

    @isTest
    public static void testLogError() {

        // Set a bad ID
        String fakeIdString = '123';

        // New contact
        Contact newContact = new Contact();

        // Try assigning User Id to a Contact insert, that'll fail!
        try {
            newContact.Id = fakeIdString;
            insert newContact;
        } catch (Exception e){
            // Log error
            Peak_ErrorLogger.logError(e);
        }

        // Now query Peak_Error_Log__c for that stack trace!
        List<Peak_Error_Log__c> errorLogs = [Select Name, Type__c, Message__c, Stack_Trace__c from Peak_Error_Log__c];

        // Assert it's found and properties exist
        system.assertEquals(errorLogs.size(),1);
        system.assert(errorLogs[0].Type__c != null);
        system.assert(errorLogs[0].Stack_Trace__c != null);
        system.assert(errorLogs[0].Message__c != null);
    }

}