trigger Appt_BatchApexErrorTrigger on BatchApexErrorEvent (after insert) {

    List<appt_BatchProcessError__c > logErrors = new List<appt_BatchProcessError__c >();
    
    for(BatchApexErrorEvent event : Trigger.New){
        logErrors.add(new appt_BatchProcessError__c  (AsyncApexJobId__c = event.AsyncApexJobId, Records__c = event.JobScope, StackTrace__c = event.StackTrace, Message__c = event.Message, Phase__c = event.Phase));
    }
    
    insert logErrors;
}