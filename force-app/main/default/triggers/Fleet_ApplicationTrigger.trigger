trigger Fleet_ApplicationTrigger on Fleet_Application__c (after insert, after update) 
{
    Fleet_ApplicationTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType);
}