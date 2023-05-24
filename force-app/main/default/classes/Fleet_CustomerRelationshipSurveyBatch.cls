global class Fleet_CustomerRelationshipSurveyBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Id recordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        String status = 'Customer';
        return Database.getQueryLocator( 
            'SELECT id, Name, SAP_Created_Date__c, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Relationship__c FROM Account WHERE RecordTypeId =: recordTypeId AND SAP_Created_Date__c != null AND Fleet_Primary_Contact__c != null AND Inactive__c = false AND Fleet_Account_Status__c =: status'
        );
    }
    
    public void execute(Database.BatchableContext bc, List<Account> accRecords){
        List<Contact> conListRelationFalse = new List<Contact>();
        List<Contact> conListRelationTrue = new List<Contact>();
        for(Account acc : accRecords){
            Boolean isAniversary;
            Date todayDate = System.today();
            isAniversary = acc.SAP_Created_Date__c.month() == todayDate.month() && acc.SAP_Created_Date__c.day() == todayDate.day();
            
            if(isAniversary){
                InmomentAPIUtility.sendInmomentSurvey(acc.Fleet_Primary_Contact__c, '2', 'Relationship');
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        system.debug('FINISH');
    }
    
    global void execute(SchedulableContext sc) {
        Fleet_CustomerRelationshipSurveyBatch cAB = new Fleet_CustomerRelationshipSurveyBatch(); 
        database.executebatch(cAB, 1);
    }
}