trigger Fleet_AccountTrigger on Account (before insert, after insert, before update, after update) 
{
    Fleet_AccountTriggerHandler.handle(Trigger.New, Trigger.oldMap, Trigger.newMap, Trigger.operationType);
}