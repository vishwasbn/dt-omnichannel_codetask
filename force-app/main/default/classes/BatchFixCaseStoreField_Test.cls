@isTest
public class BatchFixCaseStoreField_Test {
    static testMethod void testBatchJob() {
        Integer caseSize = 200;
        // Create region
        Region__c r = new Region__c(Name = 'TXH');
        insert r;
        
        // Create stores
        List<Store__c> stores = new List<Store__c>();
        for(Integer i = 0; i < caseSize; i++) {
            Store__c s = new Store__c(Name = 'TXH' + i, Region__c = r.Id);
            stores.add(s);
        }
        insert stores;
        
        // Create Cases
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < caseSize; i++) {
            Case c = new Case(Store__c = 'TXH' + i);
            cases.add(c);
        }
        insert cases;
        
        // Check cases before
        cases = [SELECT Store_new__c From Case where Store_new__c != null];
        System.assertEquals(0, cases.size(), 'Should have ' + caseSize + ' cases'); 
        
        Test.startTest();
        BatchFixCaseStoreField b = new BatchFixCaseStoreField();
        database.executebatch(b);
        Test.stopTest();
        
        // Check cases after
        cases = [SELECT Store_new__c From Case where Store_new__c != null];
        System.assertEquals(caseSize, cases.size(), 'Should have ' + caseSize + ' cases');   

    }

    static testMethod void testresponsetimebatchjob() {
        Integer caseSize = 100;
        // Create region
       
        
        // Create Cases
        List<Case> cases = new List<Case>();
        for(Integer i = 0; i < caseSize; i++) {
            Case c = new Case(subject= 'name' + i);
            cases.add(c);
        }
        insert cases;

        set<string> caseidset = new Set<String>();

        List<Case> updatedlist = new List<Case>();
        cases = [select id,Last_Status_Change__c,Time_With_Support__c,Time_With_Customer__c from Case limit 20];
        for(Integer i=0;i< 20;i++){
            cases[i].Last_Status_Change__c = System.now();
            cases[i].Time_With_Customer__c = 12;
            cases[i].Time_With_Support__c = 20;
            caseidset.add(cases[i].id);
            updatedlist.add(cases[i]);
        }

        update updatedlist;
        
        // Check cases before
        cases = [SELECT Store_new__c From Case where Store_new__c != null];
        System.assertEquals(0, cases.size(), 'Should have ' + caseSize + ' cases'); 
        
        Test.startTest();
        BatchFixResponseTimeFields b = new BatchFixResponseTimeFields();
        database.executebatch(b);
        Test.stopTest();
        
        
        cases = [select id from Case where Last_Status_Change__c = null or Time_With_Support__c =null or Time_With_Customer__c = null];
        System.assertEquals(0,cases.size()); 

        cases = [select id from Case where  Time_With_Support__c = 20 and Time_With_Customer__c = 12 and id IN:caseidset];
        System.assertEquals(20,cases.size()); 

        cases = [select id from Case where  Time_With_Support__c = 0.0 and Time_With_Customer__c = 0.0 ];
        System.assertEquals(caseSize-20,cases.size());      
    }
}