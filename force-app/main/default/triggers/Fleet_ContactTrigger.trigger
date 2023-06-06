trigger Fleet_ContactTrigger on Contact (after insert, after update, before delete) 
{
 if(!Test.isRunningTest()) {
       Fleet_ContactTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType);
 }
 
}