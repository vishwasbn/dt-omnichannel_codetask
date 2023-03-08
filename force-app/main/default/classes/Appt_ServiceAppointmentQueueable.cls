public class Appt_ServiceAppointmentQueueable implements Queueable{
    public static String lprefix = 'LOG_ServiceAppointmentQueueable:';

    Map<Id, ServiceAppointment> oldMap;
    Map<Id, ServiceAppointment> newMap;


    public Appt_ServiceAppointmentQueueable(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap) {
        this.oldMap = oldMap;
        this.newMap = newMap;

    }

    // executable method that will possess the notification ids
    public void execute(QueueableContext context){
        System.debug( lprefix + ' Create SA - notification process');

        Map<id,String> notificaitonMap = new Map<id,String>();
        for (ServiceAppointment newAppt: newMap.values()) {            

            if(newAppt.Status == 'Scheduled' && newAppt.Notification_Appointment__c == true){
                notificaitonMap.put(newAppt.id, 'APPT_SCHEDULED');
            }
        }

        System.debug( lprefix + ' Create SA - selected notificaitons');
        System.debug(notificaitonMap);

        // send notifications to a future method to be processed
        if(notificaitonMap.size() > 0){
            // Pass notificaiton map and the type of notificaiton 
            Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap,'TRANSACTION', 'SMS, EMAIL');
        }              
    }
}