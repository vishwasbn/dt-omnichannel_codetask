trigger Fleet_LeadTrigger on Lead (before insert, after insert, before update, after update) 
{
    System.debug('FLEET_LTRIGGER: Fleet_LeadTrigger on Lead (before insert) ENTRY');
    Fleet_LeadTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType);
    System.debug('FLEET_LTRIGGER: Fleet_LeadTrigger on Lead (before insert) DONE');
}