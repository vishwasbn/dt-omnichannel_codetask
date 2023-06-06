trigger Fleet_OpportunityTrigger on Opportunity (before insert, after insert, before update, after update) {

    System.debug('FLEET_OTRIGGER: Fleet_OpportunityTrigger on Opportunity (before insert, after insert, before update, after update) ENTRY');
    Fleet_OpportunityTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType);
    System.debug('FLEET_OTRIGGER: Fleet_OpportunityTrigger on Opportunity (before insert, after insert, before update, after update) DONE');

}