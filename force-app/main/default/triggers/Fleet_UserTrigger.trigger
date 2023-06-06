trigger Fleet_UserTrigger on User (before insert,after update, after insert,before update) 
{   
    Fleet_UserTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType, Trigger.New);
    
    Fleet_SpecialistUserTriggerHandler.handle(Trigger.operationType);
}