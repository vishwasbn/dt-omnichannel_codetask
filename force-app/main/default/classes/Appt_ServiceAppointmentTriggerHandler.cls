public class Appt_ServiceAppointmentTriggerHandler {
    public static String lprefix = 'LOG_ServApptTH:';
    //PT change
    Public static String version_check= 'APPT3.0';
    //---Primary ServiceAppointment Trigger Handler for Appointment
    public static void handle(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug( lprefix + 'Appt ServiceAppointmentTrigger Handler - START');

        switch on triggerEvent 
        {
            when AFTER_INSERT {
                createApptTimeSpotAfterCreateAppointment(oldMap, newMap);
                //APPT3-449
                //to serialize parameters and pass into future method which is used to add woli and then send Platform events.
                serializeParams(oldMap, newMap, triggerEvent, Appt_AppointmentHandler.articlesList, Appt_AppointmentHandler.woid);
                //APPT3-449
                createAppointmentNotifications(oldMap, newMap);
            }
            when BEFORE_UPDATE {
                updateApptReminderFlagIfReschedule(oldMap, newMap);
            }
            when AFTER_UPDATE {
                updateApptTimeSpotAfterUpdateAppointment(oldMap, newMap);
                //APPT3-449
                // to serialize parameters and pass into future method which is used to add woli and then send Platform events.
                serializeParams(oldMap, newMap, triggerEvent, Appt_AppointmentUpdateHandler.articlesList, Appt_AppointmentUpdateHandler.woid);
                //APPT3-449
                updateAppointmentNotifications(oldMap, newMap);
            }
            when BEFORE_DELETE{
                deleteApptTimeSpotBeforeDeleteAppointment(oldMap, newMap);
            }
            when else {
                //do nothing 
            }
        }

        System.debug( lprefix + 'Appt ServiceAppointmentTrigger Handler - END');
    }

    private static void deleteApptTimeSpotBeforeDeleteAppointment(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap) {
        System.debug( lprefix + 'deleteApptTimeSpotBeforeDeleteAppointment() - ENTRY BEFORE DELETE');
        
        List<Appt_Time_Spot__c> deleteSpotList;
        List<Id> deleteApptIdList = new List<Id>();

        //-- Loop through oldMap, which contains Appts to be deleted, to get List of IDs to use in Appt_Time_Spot__c query
        for (ServiceAppointment delAppt: oldMap.values()) {
            deleteApptIdList.add(delAppt.Id);
        }

        if (deleteApptIdList.size() > 0) {
            deleteSpotList = [SELECT Id FROM Appt_Time_Spot__c WHERE Service_Appointment__c in :deleteApptIdList];
        }

        if (deleteSpotList != null && deleteSpotList.size() > 0) {
            System.debug( lprefix + '   About to delete the following '+ deleteSpotList.size() + ' Appt_Time_Spot__c records:'+ deleteSpotList);
            delete deleteSpotList;
            System.debug( lprefix + '   SUCCESSfully deleted the Appt_Time_Spot__c records !!!!!!!!!!');
        }

        System.debug( lprefix + 'deleteApptTimeSpotBeforeDeleteAppointment() - EXIT before delete');
    }

    private static void updateApptTimeSpotAfterUpdateAppointment(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap) {

        List<Id> canceledApptList= new List<Id>();
        List<Appt_Time_Spot__c> newSpotList = new List<Appt_Time_Spot__c>();
        
        for (ServiceAppointment newAppt: newMap.values()) {
            ServiceAppointment oldAppt = oldMap.get(newAppt.Id);
            System.debug( lprefix + 'updateApptTimeSpotAfterUp..()  NEWAPPT Date_String='+newAppt.Date_String__c+', Start_Time_String='+newAppt.Start_Time_String__c+', Status='+newAppt.Status+', Source='+newAppt.Source__c+', Order_Type='+newAppt.Order_Type__c+', Activity_Type='+newAppt.Activity_Type__c);
            System.debug( lprefix + 'updateApptTimeSpotAfterUp..()  OLDAPPT Date_String='+oldAppt.Date_String__c+', Start_Time_String='+oldAppt.Start_Time_String__c+', Status='+oldAppt.Status+', Source='+oldAppt.Source__c+', Order_Type='+oldAppt.Order_Type__c+', Activity_Type='+oldAppt.Activity_Type__c);

            //  check if the date and/or times have changed
            Boolean isRescheduledAppt = isRescheduledAppt(newAppt, oldAppt);
            System.debug( lprefix + '    isRescheduledAppt='+isRescheduledAppt);

            //process Missed, Completed, Canceled Hold or Canceled appointments by deleting the Appt_Time_Spot record of the original appointment
            /*Removed Appt Completed Status Condition from the below condition as a part of Temporary Fix - APPT-1800*/
            if (!String.isBlank(newAppt.Status) && 
                (newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED || newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD || 
                newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED || newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED)) {
                    System.debug( lprefix + '    adding to canceledApptList oldAppt.Id='+oldAppt.Id);
                    canceledApptList.add(oldAppt.Id);
            }

            //TODO - hole here if Canceled updated to Scheduled but with same date and time, thus isRescheduledAppt = false
            //process rescheduled appointments
            if (isRescheduledAppt && !String.isBlank(newAppt.Status) && 
                (newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING || newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED || 
                newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED)) {

                    // setup the old Appt_Time_Spot records for old appointment data/times to be deleted
                    System.debug( lprefix + '    INSIDE RESCHEDULE adding to canceledApptList oldAppt.Id:'+oldAppt.Id);
                    canceledApptList.add(oldAppt.Id);

                    Datetime apptStartDateTime;
                    Datetime apptEndDateTime;
                    List<Appt_Time_Slot__c> foundApptSlots;

                    //-- If the appointment's Selected_Slot_Start_Time_String__c and Selected_Slot_End_Time_String__c are populated, use those times instead of consult and backoffice start and end times.
                    //--  This is because Selected_Slot_Start_Time_String__c and Selected_Slot_End_Time_String__c are set by custom times modal, which if populated are always used to reserve the appt time spot - DTA-503
                    String startTime = null;
                    String endTime = null;
                    if (!String.isBlank(newAppt.Selected_Slot_Start_Time_String__c) && !String.isBlank(newAppt.Selected_Slot_End_Time_String__c)) {
                        startTime = newAppt.Selected_Slot_Start_Time_String__c.trim();
                        endTime = newAppt.Selected_Slot_End_Time_String__c.trim();
                    }

                    // setup new Appt_Time_Spot records to be inserted for new appointment date/times
                    if (newAppt.Activity_Type__c == Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_FRONT) {
                    //-- FRONT ROOM APPOINTMENT

                        //-- if null, set start and end time from Consult_Start_Time__c and Consult_End_Time__c
                        if (startTime == null) {
                            startTime = newAppt.Consult_Start_Time__c;
                        }
                        if (endTime == null) {
                            endTime = newAppt.Consult_End_Time__c;
                        }

                        //-- convert times to store's timezone
                        apptStartDateTime = Appt_AppointmentUtil.convertTime(newAppt.Date_String__c, startTime, Integer.valueOf(newAppt.Timezone_Offset__c));
                        apptEndDateTime = Appt_AppointmentUtil.convertTime(newAppt.Date_String__c, endTime, Integer.valueOf(newAppt.Timezone_Offset__c));

                        foundApptSlots = Appt_AvailabilityHandler.getSlotsFromStartToEndTime(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT, newAppt.Site_Id__c, Date.valueOf(newAppt.Date_String__c), apptStartDateTime, apptEndDateTime);

                    } else if (newAppt.Activity_Type__c == Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_BACK) {
                        //-- BACK ROOM APPOINTMENT

                        //-- if null, set start and end time from Back_Office_Start_Time__c and Back_Office_End_Time__c
                        if (startTime == null) {
                            startTime = newAppt.Back_Office_Start_Time__c;
                        }
                        if (endTime == null) {
                            endTime = newAppt.Back_Office_End_Time__c;
                        }
                        
                        //PT change- Executed only when Custom label(PT_VersionController) is APPT3.0
                        if(system.label.PT_VersionController==version_check){
                            // Appt 3.0 Changes - Start TO Check the Time slot Dates during Reschedule	
                            if(Appt_ConstantValues.isVisionFeature && !String.isBlank(newAppt.Selected_Slot_Start_Time_String__c)) {	
                                
                                if(newAppt.Back_Office_Start_Time__c > newAppt.Selected_Slot_Start_Time_String__c.trim()) {                                	
                                    startTime = newAppt.Back_Office_Start_Time__c;	
                                } else {	
                                    startTime = newAppt.Selected_Slot_Start_Time_String__c.trim();	
                                }	
                                endTime = newAppt.Back_Office_End_Time__c;	
                            } else if (Appt_ConstantValues.isVisionFeature && String.isBlank(newAppt.Selected_Slot_Start_Time_String__c)){	
                                startTime = newAppt.Back_Office_Start_Time__c;	
                                endTime = newAppt.Back_Office_End_Time__c;     	
                            }	
                            // Appt 3.0 Changes - End   
                        }
                        

                        //-- convert times to store's timezone
                        apptStartDateTime = Appt_AppointmentUtil.convertTime(newAppt.Date_String__c, startTime, Integer.valueOf(newAppt.Timezone_Offset__c));
                        apptEndDateTime = Appt_AppointmentUtil.convertTime(newAppt.Date_String__c, endTime, Integer.valueOf(newAppt.Timezone_Offset__c));

                        foundApptSlots = Appt_AvailabilityHandler.getSlotsFromStartToEndTime(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK, newAppt.Site_Id__c, Date.valueOf(newAppt.Date_String__c), apptStartDateTime, apptEndDateTime);

                    } else {
                        System.debug( lprefix + 'WARNING! Unable to determine type of appointment (front or back) with Activity_Type__c=' + newAppt.Activity_Type__c);
                        continue;
                    }

                    if (foundApptSlots != null && foundApptSlots.size() > 0) {
                
                        for (Appt_Time_Slot__c slot: foundApptSlots) {
                            Appt_Time_Spot__c newSpot = new Appt_Time_Spot__c();
                            newSpot.Bucket__c = getBucket(newAppt, slot);
                            newSpot.Appt_Time_Slot__c = slot.Id;
                            newSpot.Service_Appointment__c = newAppt.Id;
                            System.debug( lprefix + '    adding to newSpotList newAppt.Id='+newAppt.Id);
                            newSpotList.add(newSpot);
                        }
                    }
            }
        }

        //delete the spots for those apointments that have been canceled
        deleteSpots(canceledApptList);
        
        // INSERT the new spots for the rescheduled appointments
        if (newSpotList != null && newSpotList.size() > 0) {
            insert newSpotList;
        }

    }


    private static void deleteSpots(List<Id> canceledApptIdList) {
        System.debug( lprefix + 'deleteSpots() ENTRY - canceledApptIdList:'+canceledApptIdList);
        if (canceledApptIdList != null && canceledApptIdList.size() > 0) {
            
            List<Appt_Time_Spot__c> spotsToDelete = [SELECT Id FROM Appt_Time_Spot__c WHERE Service_Appointment__c in :canceledApptIdList];
            delete spotsToDelete;
        }
    }

    private static Boolean isRescheduledAppt(ServiceAppointment newAppt, ServiceAppointment oldAppt) {
        if (newAppt != null && oldAppt != null) {
            if (newAppt.Date_String__c != oldAppt.Date_String__c) { return true; }
            else if (newAppt.Start_Time_String__c != oldAppt.Start_Time_String__c) { return true; }
            else if (newAppt.End_Time_String__c != oldAppt.End_Time_String__c) { return true; }
        }
        return false;
    }

    private static void createApptTimeSpotAfterCreateAppointment(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap) {

        List<Appt_Time_Spot__c> spotsToBeUpdatedList = new List<Appt_Time_Spot__c>();
        Datetime apptStartDateTime;
        Datetime apptEndDateTime;
        List<Appt_Time_Slot__c> foundApptSlots;

        for (ServiceAppointment newAppt: newMap.values()) {

            //only create Appt_Time_Spot__c records for new ServiceAppointments with status = Pending, Scheduled or Confirmed
            if (!String.isBlank(newAppt.Status) && 
                (newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING || newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED || newAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED)) {
            

                //-- If the appointment's Selected_Slot_Start_Time_String__c and Selected_Slot_End_Time_String__c are populated, use those times instead of consult and backoffice start and end times.
                //--  This is because Selected_Slot_Start_Time_String__c and Selected_Slot_End_Time_String__c are set by custom times modal, which if populated are always used to reserve the appt time spot - DTA-503
                String startTime = null;
                String endTime = null;
                if (!String.isBlank(newAppt.Selected_Slot_Start_Time_String__c) && !String.isBlank(newAppt.Selected_Slot_End_Time_String__c)) {
                    startTime = newAppt.Selected_Slot_Start_Time_String__c.trim();
                    endTime = newAppt.Selected_Slot_End_Time_String__c.trim();
                }
                
                if (newAppt.Activity_Type__c == Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_FRONT) {
                    //-- FRONT ROOM APPOINTMENT


                    //-- if null, set start and end time from Consult_Start_Time__c and Consult_End_Time__c
                    if (startTime == null) {
                        startTime = newAppt.Consult_Start_Time__c;
                    }
                    if (endTime == null) {
                        endTime = newAppt.Consult_End_Time__c;
                    }

                    apptStartDateTime = Appt_AppointmentUtil.convertTime(newAppt.Date_String__c, startTime, Integer.valueOf(newAppt.Timezone_Offset__c));
                    apptEndDateTime = Appt_AppointmentUtil.convertTime(newAppt.Date_String__c, endTime, Integer.valueOf(newAppt.Timezone_Offset__c));

                    foundApptSlots = Appt_AvailabilityHandler.getSlotsFromStartToEndTime(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT, newAppt.Site_Id__c, Date.valueOf(newAppt.Date_String__c), apptStartDateTime, apptEndDateTime);

                } else if (newAppt.Activity_Type__c == Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_BACK) {
                    //-- BACK ROOM APOINTMENT


                    //-- if null, set start and end time from Back_Office_Start_Time__c and Back_Office_End_Time__c
                    if (startTime == null) {
                        startTime = newAppt.Back_Office_Start_Time__c;
                    }
                    if (endTime == null) {
                        endTime = newAppt.Back_Office_End_Time__c;
                    }
                   
                    //PT change- Executed only when Custom label(PT_VersionController) is APPT3.0
                    if(system.label.PT_VersionController==version_check){
                        // Appt 3.0 Changes - Start - To Check Time slot selected during create	
                        if(Appt_ConstantValues.isVisionFeature && !String.isBlank(newAppt.Selected_Slot_Start_Time_String__c)) {	
                            if(newAppt.Back_Office_Start_Time__c > newAppt.Selected_Slot_Start_Time_String__c.trim()) {	
                                startTime = newAppt.Back_Office_Start_Time__c;	
                            } else {	
                                startTime = newAppt.Selected_Slot_Start_Time_String__c.trim();	
                            }	
                            endTime = newAppt.Back_Office_End_Time__c;	
                        } else if (Appt_ConstantValues.isVisionFeature && String.isBlank(newAppt.Selected_Slot_Start_Time_String__c)){	
                            startTime = newAppt.Back_Office_Start_Time__c;	
                            endTime = newAppt.Back_Office_End_Time__c;     	
                        }	
                        // Appt 3.0 Changes - End	
                    }
                    apptStartDateTime = Appt_AppointmentUtil.convertTime(newAppt.Date_String__c, startTime, Integer.valueOf(newAppt.Timezone_Offset__c));
                    apptEndDateTime = Appt_AppointmentUtil.convertTime(newAppt.Date_String__c, endTime, Integer.valueOf(newAppt.Timezone_Offset__c));

                    foundApptSlots = Appt_AvailabilityHandler.getSlotsFromStartToEndTime(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK, newAppt.Site_Id__c, Date.valueOf(newAppt.Date_String__c), apptStartDateTime, apptEndDateTime);

                } else {
                    System.debug( lprefix + 'WARNING! Unable to determine type of appointment (front or back) with Activity_Type__c=' + newAppt.Activity_Type__c);
                    continue;
                }

                if (foundApptSlots != null && foundApptSlots.size() > 0) {
                
                    for (Appt_Time_Slot__c slot: foundApptSlots) {
                        Appt_Time_Spot__c newSpot = new Appt_Time_Spot__c();
                        newSpot.Bucket__c = getBucket(newAppt, slot);
                        newSpot.Appt_Time_Slot__c = slot.Id;
                        newSpot.Service_Appointment__c = newAppt.Id;
                        spotsToBeUpdatedList.add(newSpot);
                    }
                }
            }
        }

        insert spotsToBeUpdatedList;

    }
        
    private static String getBucket(ServiceAppointment appt, Appt_Time_Slot__c slot) {
        String frontBackChar;
        String sourceChar;
        String customerTypeChar;

        if (appt.Activity_Type__c == Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_FRONT) {
            frontBackChar = Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR;
        }
        else {
            frontBackChar = Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR;
        }

        //SO 502 - Use the web slot if back room slot availability is 0
        if (appt.Source__c == Appt_ConstantValues.APPOINTMENT_SOURCE_WEB || appt.Source__c == Appt_ConstantValues.APPOINTMENT_SOURCE_CSR || appt.Source__c == Appt_ConstantValues.APPOINTMENT_SOURCE_FILE
            || (appt.Source__c == Appt_ConstantValues.APPOINTMENT_SOURCE_POS && slot.BSR_Available__c == 0)) {
             sourceChar = Appt_ConstantValues.APPOINTMENT_SOURCE_WEB_CHAR;
        }
        else {
            sourceChar = Appt_ConstantValues.APPOINTMENT_SOURCE_STORE_CHAR;
        }
        if(Appt_AppointmentUtil.isFleetCapacityConsolidated() && sourceChar==Appt_ConstantValues.APPOINTMENT_SOURCE_WEB_CHAR 
        && appt.Customer_Type__c == Appt_ConstantValues.CUSTOMER_TYPE_FLEET){
            sourceChar = Appt_ConstantValues.APPOINTMENT_SOURCE_STORE_CHAR;
        }

        if (appt.Customer_Type__c == Appt_ConstantValues.CUSTOMER_TYPE_RETAIL) {
            customerTypeChar = Appt_ConstantValues.APPOINTMENT_SOURCE_CUSTOMER_RETAIL_CHAR;
        }
        else {
            customerTypeChar = Appt_ConstantValues.APPOINTMENT_SOURCE_CUSTOMER_FLEET_CHAR;
        }

        System.debug( lprefix + 'getBucket(): ' + frontBackChar + sourceChar + customerTypeChar);
        return frontBackChar + sourceChar + customerTypeChar;
    }


    // Process to create notificaitons when an appointment is scheduled on create
    // process the service appointment notificaitons in a queuable class to speed up the process
    private static void createAppointmentNotifications(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap) {

        //-- Only engueue new job if not disabled because Appointment Import Process is running
        Boolean isApptImportProcessRunning = Appt_SettingUtil.getSettingBooleanValue('Disable_Notifications_For_Appt_Import_Pr');

        if (!isApptImportProcessRunning) {
            System.enqueueJob(new Appt_ServiceAppointmentQueueable(oldMap,newMap));
        }

    }

    // Process to capture notificaitons that are needed to be sent out when updates are made to a service appointment
    private static void updateAppointmentNotifications(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap) {

        System.debug( lprefix + ' Update SA - notification process');

        Map<id,String> notificaitonMap = new Map<id,String>();
        for (ServiceAppointment updateAppt: newMap.values()) {  

            // Only look at the notificaiton appointment
            if(updateAppt.Notification_Appointment__c == true){              
                ServiceAppointment beforeUpdate = oldMap.get(updateAppt.id);
                System.debug('Old appt status: ' +beforeUpdate.Status);
                System.debug('New appt status: ' +updateAppt.Status);

                // Find appointments that have their status updated to scheduled
                // SA - 23 && SO-347 Additional SERVICE_APPOINTMENT_STATUS_MISSED condition added so that while reschduling Missed appointment, schuled notification record is not created.
                if(updateAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED && beforeUpdate.Status != Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED && beforeUpdate.Status != Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED ){
                    notificaitonMap.put(updateAppt.id, Appt_ConstantValues.NOTIFICATION_APPT_SCHEDULED);
                    continue;
                }

                // Find appointments that have their status updated to canclled
                if(updateAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED && beforeUpdate.Status != Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED){
                    notificaitonMap.put(updateAppt.id, Appt_ConstantValues.NOTIFICATION_APPT_CANCELLED);
                    continue;
                }

                // Find appomntments that have their start or end time change 
                if((updateAppt.SchedStartTime != beforeUpdate.SchedStartTime || updateAppt.SchedEndTime != beforeUpdate.SchedEndTime) && updateAppt.Status == Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED){
                    notificaitonMap.put(updateAppt.id, Appt_ConstantValues.NOTIFICATION_APPT_RESCHEDULED);
                    continue;
                }

            }
            
            
        }

        System.debug( lprefix + ' Update SA - selected notificaitons');
        System.debug(notificaitonMap);

        // send notifications to a future method to be processed
        if(notificaitonMap.size() > 0){
            // Pass notificaiton map and the type of notificaiton 
            Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap, 'TRANSACTION', 'SMS, EMAIL');
        }

    }

    public static void updateApptReminderFlagIfReschedule(Map<Id, ServiceAppointment> oldMap, Map<Id, ServiceAppointment> newMap){
        for(ServiceAppointment newAppt: newMap.values()){
            ServiceAppointment oldAppt = oldMap.get(newAppt.Id); // Get the old appt to compare values

            //  If it is a rescheduled appointment, we will update the reminder sent flag back to false
            if(isRescheduledAppt(newAppt, oldAppt)){
                // If reminder notification sent is true, flip it to false and add it to the update list
                if(newAppt.Reminder_Notification_Sent__c){
                    newAppt.Reminder_Notification_Sent__c = false;
                }
            }
        }
    }

    /*
     * @description : serializeParams method serializes the input parameters and invoke future method.
     * @Param : oldMap, newMap, triggerEvent, articlesList, workOrderId
     * @return : void
     */
    public static void serializeParams(Map<id,ServiceAppointment> oldMap, Map<id,ServiceAppointment> newMap, System.TriggerOperation triggerEvent, List<Appt_CreateAppointmentServiceModel.Articles> articlesList, Id workOrderId){
        System.debug(lprefix+' serializeParams ENTRY');
        String jsonOldMap = JSON.serialize(oldMap);
        String jsonNewMap = JSON.serialize(newMap);
        String jsontriggerEvent = JSON.serialize(triggerEvent);
        String jsonArticleList = JSON.serialize(articlesList);
        if(System.isBatch() || System.isQueueable() || System.isScheduled() || System.isFuture()){
            String strTriggerEvent = (String) JSON.deserialize(jsontriggerEvent, String.class);
            PT_AppointmentEventService.createServiceAppointmentPlatformEvents(oldMap,newMap,strTriggerEvent,workOrderId,articlesList);
        }else{
            asyncCallForAppointments(jsonOldMap, jsonNewMap, jsontriggerEvent, jsonArticleList, workOrderId);
        }
        System.debug(lprefix+' serializeParams EXIT');

    }

    /*
     * @description : asyncCallForAppointments method deserializes the input parameters and invoke PT_AppointmentEventService class to add/remove woli and publish Platform events.
     * @Param : stroldMap, strnewMap, strtriggerEvent, strarticleList, woid
     * @return : void
     */
    @future
    public static void asyncCallForAppointments(String stroldMap, String strnewMap , String strtriggerEvent, String strarticleList, Id woid) {
        System.debug(lprefix+'asyncCallForAppointments ENTRY');
        Map<Id, ServiceAppointment> oldMap = (Map<Id, ServiceAppointment>) JSON.deserialize(stroldMap, Map<Id, ServiceAppointment>.class);
        Map<Id, ServiceAppointment> newMap = (Map<Id, ServiceAppointment>) JSON.deserialize(strnewMap, Map<Id, ServiceAppointment>.class);
        List<Appt_CreateAppointmentServiceModel.Articles> articleList = (List<Appt_CreateAppointmentServiceModel.Articles>) JSON.deserialize(strarticleList, List<Appt_CreateAppointmentServiceModel.Articles>.class);
        String triggerEvent = (String) JSON.deserialize(strtriggerEvent, String.class);
        // send Platform Events 
        PT_AppointmentEventService.createServiceAppointmentPlatformEvents(oldMap,newMap,triggerEvent,woid,articleList);
        System.debug(lprefix+'asyncCallForAppointments EXIT');
    }

}