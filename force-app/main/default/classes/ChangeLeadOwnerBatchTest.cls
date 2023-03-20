@isTest
public class ChangeLeadOwnerBatchTest {
    @isTest
    static void UpdateLeadTest(){
        Integer year = System.Today().year() + 1; // 2022-12-22 Code fix added to ensure CRON_EXP is not referring to a past year/date
        String CRON_EXP = '0 0 0 15 3 ? '+ year;
        List<Lead> leadList = new List<Lead>();
        Lead l = new Lead(
            LastName='leadLN', 
            Company='company', 
            Status = 'Open - Not Contacted', 
            LeadSource='Web', 
            isLeadAssigned__c=true,               
            country__c = 'United States',
            State__c = 'Alaska',
            Selectedcity__c = 'Adak',
            Fleet_Purchase_Product__c = 'Resale',
            Fleet_Specialist_Id__c = null           
        );
        leadList.add(l);
        insert leadList;

        Test.startTest();
        ChangeLeadOwnerBatch cLOB = new ChangeLeadOwnerBatch();
        Database.QueryLocator ql = cLOB.start(null);
        cLOB.execute(null, leadList);
        cLOB.Finish(null);
        //id batchId = Database.executeBatch(cLOB);
        
        
        String jobId = System.schedule('testChangeLeadOwnerScheduledApex', CRON_EXP, new ChangeLeadOwnerBatch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals(year+'-03-15 00:00:00', String.valueOf(ct.NextFireTime));
        //System.assertNotEquals(false, [SELECT id, isLeadAssigned__c FROM lead WHERE id = :leadList[0].Id].isLeadAssigned__c);
    
        Test.stopTest();
        
    }
}