@isTest
public class Fleet_LeadTriggerTest {  

    @testSetup static void createTestClassData() {

    }
    @isTest
     static void createLeads() {
        Lead l = new Lead(LastName='Satya',State__c='New');
         insert l;
    }
}