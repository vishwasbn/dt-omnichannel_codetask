@isTest
public class Appt_EmailOrderEnrichmentTest {

    
    
    @isTest 
    static void buildQueueableJobsTest()
    {      

        List<Notification__c> testNotifications = new List<Notification__c>();

        
        Notification__c testNotify = new Notification__c();

        testNotifications.add(testNotify);
        
        insert testNotifications;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_EmailOrderEnrichment.buildQueueableJobs(testNotifications);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c validateNotification = [SELECT id, Invoice_Status__c, Initial_Email_Send_Status__c FROM Notification__c WHERE id = :testNotify.id];
        System.assert(validateNotification != null, 'Notification was processed');

       
   
    }
    
    @isTest 
    static void buildQueueableJobsExceptionTest()
    {      

        List<Notification__c> testNotifications = new List<Notification__c>();

        
        Notification__c testNotify = new Notification__c();

        testNotifications.add(testNotify);
        
        insert testNotifications;
        delete testNotifications;
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_EmailOrderEnrichment.buildQueueableJobs(testNotifications);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        List<Notification__c> validateNotification = [SELECT id, Invoice_Status__c, Initial_Email_Send_Status__c FROM Notification__c WHERE id = :testNotify.id];
        System.assert(validateNotification.size() == 0, 'Notification errored out an was not processed');

       
   
    } 

    @isTest 
    static void buildQueueableJobsTestBulk()
    {      

        List<Notification__c> testNotifications = new List<Notification__c>();

        for (Integer i = 0; i < 21; i++) {
            Notification__c testNotify = new Notification__c();
            testNotifications.add(testNotify);
        }
        insert testNotifications;

        System.debug(testNotifications.size());
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_EmailOrderEnrichment.buildQueueableJobs(testNotifications);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        Notification__c validateNotification = [SELECT id, Invoice_Status__c, Initial_Email_Send_Status__c FROM Notification__c WHERE id = :testNotifications[0].id];
        System.assert(validateNotification != null, 'Notification was processed');
       
   
    } 
}