/**
 * This is a trigger sample for using CaseTriggerHandler
 * Ideally, only one trigger on each Object, if in your org, there is
 * already a Case trigger, please use the CaseTriggerHandler in it directly
 * to avoid multiple triggers on the same object
 */
trigger CaseTrigger on Case (after insert, after update,before insert) {

    try{
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
    catch(Exception ex){
        Logger logInstance = Logger.getInstance();
        logInstance.log('Case_trigger', 'CaseTrigger', ex);
    }
    

}