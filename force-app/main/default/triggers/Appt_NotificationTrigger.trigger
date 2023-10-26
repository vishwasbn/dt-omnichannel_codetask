trigger Appt_NotificationTrigger on Notification__c (before update) {
    System.debug( 'Appt_NotificationTrigger - GO');
    Appt_NotificationTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType);
}