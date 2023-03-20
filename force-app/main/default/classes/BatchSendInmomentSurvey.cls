global class BatchSendInmomentSurvey implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global String surveyType;
    
    global BatchSendInmomentSurvey(String surveyType)
    {
        this.surveyType = surveyType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,Exit__c,Onboarding__c,Post_Visit__c,Relationship__c, Survey_Response__c FROM Contact where Exit__c = true or Onboarding__c = true or Post_Visit__c = true or Relationship__c = true' ;
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> contactList) {
        
        for(Contact rec : contactList)
        {
            if(rec.Survey_Response__c != null)
            {
                String body = rec.Survey_Response__c.split('\n\n')[0];
                Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(body);
                Boolean succeeded = (Boolean) m.get('succeeded');
                
                if(succeeded == false)
                {
                    if(rec.Exit__c && surveyType == '3')
                        InmomentAPIUtility.sendInmomentSurvey(rec.Id, '3', 'Exit');
                    if(rec.Onboarding__c && surveyType == '1')
                        InmomentAPIUtility.sendInmomentSurvey(rec.Id, '1', 'Onboarding');
                    if(rec.Post_Visit__c && surveyType == '4')
                        InmomentAPIUtility.sendInmomentSurvey(rec.Id, '4', 'Post Visit');
                    if(rec.Relationship__c && surveyType == '2')
                        InmomentAPIUtility.sendInmomentSurvey(rec.Id, '2', 'Relationship');
                }
            }
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        // to do
    }
}