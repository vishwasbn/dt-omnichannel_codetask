/**
 * This is a trigger sample for using CaseStatusChangeTriggerHandler
 * Ideally, only one trigger on each Object, if in your org, there is
 * already a Case trigger, please use the CaseStatusChangeTriggerHandler in it directly
 * to avoid multiple triggers on the same object
 */
trigger CaseStatusChangeTrigger on Case (after insert, after update,before insert) {

    if(Trigger.isInsert && Trigger.isAfter){
        CaseTriggerHandler.OnAfterInsert(Trigger.new);
    } 
    if(Trigger.isInsert && Trigger.isBefore){
        CaseTriggerHandler.OnBeforeInsert(Trigger.new);
    }
    else if (Trigger.isUpdate && Trigger.isAfter) {
        CaseTriggerHandler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
    }

}