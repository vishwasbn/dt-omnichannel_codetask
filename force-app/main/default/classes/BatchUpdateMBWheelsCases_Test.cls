@isTest
public class BatchUpdateMBWheelsCases_Test {
	static testMethod void testBatchJob() {
        Case c = new Case(Subject = 'Test');
        insert c;
        EmailMessage em = new EmailMessage(ParentId = c.id);
        insert em;
        
        Test.startTest();
        BatchUpdateMBWheelsCases b = new BatchUpdateMBWheelsCases();
        database.executebatch(b);
        Test.stopTest();         
    }    
}