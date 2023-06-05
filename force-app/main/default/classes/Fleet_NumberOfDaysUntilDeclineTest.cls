/**
 Created By : Ritika Sharma
 Creatted Dated : 2/16/2023
 Description : This Batch Test Class is to check NumberOfDaysUntilDecline Batch
**/
@isTest
public class Fleet_NumberOfDaysUntilDeclineTest {
    @isTest
    static void accountCountDaysTest(){
        String CRON_EXP = '0 0 0 15 3 ? ' + Date.today().addYears(1).year();
        list<account> acclist = new list<account>();
        List<RecordType> rtList = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'B2B'];
         DateTime dT = system.now();
        Date todayDate = date.newinstance(dT.year(), dT.month(), dT.day());
        Account testAct = new Account (
            Name = 'ENTERPRISE FLEET',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            ShippingStreet = '9315 OLIVE BLVD',
            ShippingCity = 'SAINT LOUIS',
            ShippingState = 'Missouri',
            ShippingPostalCode = '63132-3211',
            ShippingCountry = 'United States',
            ShippingStateCode = null,
            ShippingCountryCode = 'US',
            Phone = '800-325-8838',
            Fleet_Account_Status__c = 'Pending Additional Information',
            Fleet_AR_App_Status__c ='Pending Additional Information',
            Fleet_Pending_Additional_Info_Date__c= todayDate,
            Fleet_Days_until_Decline__c=1,
            RecordTypeId = rtList[0].Id
           );
        insert testAct;
        testAct.Fleet_Account_Status__c ='Pending Additional Information';
        update testAct;
        acclist.add(testAct);
        acclist = [Select id, Fleet_Account_Status__c, Fleet_AR_App_Status__c,Fleet_Pending_Additional_Info_Date__c, Fleet_Application_Type__c,Fleet_Days_until_Decline__c,Fleet_Credit_App_Status__c,Fleet_NonCredit_App_Status__c from Account where Fleet_Account_Status__c='Pending Additional Information' and  id=:testAct.id];
        //insert accList;

        Test.startTest();
        update accList[0];
        Fleet_NumberOfDaysUntilDecline cLOB = new Fleet_NumberOfDaysUntilDecline();
        Database.QueryLocator ql = cLOB.start(null);
        cLOB.execute(null, accList);
        cLOB.Finish(null);
        //id batchId = Database.executeBatch(cLOB);
        
        
        String jobId = System.schedule('testFleet_NumberOfDaysUntilDeclineScheduledApex', CRON_EXP, new Fleet_NumberOfDaysUntilDecline());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals(Date.today().addYears(1).year()+'-03-15 00:00:00', String.valueOf(ct.NextFireTime));
       
    
        Test.stopTest();
        
    }

}