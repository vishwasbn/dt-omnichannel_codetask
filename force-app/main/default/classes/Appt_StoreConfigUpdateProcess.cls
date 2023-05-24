public without sharing class Appt_StoreConfigUpdateProcess {

    // Setup working variables to make the required updates
    public static Set<String> selectedDays = new Set<String>();
    public static Appt_UpdateStoreConfig config = new Appt_UpdateStoreConfig();
    public static List<Appt_Time_Slot_Capacity__c> existingSlotConfigList = new List<Appt_Time_Slot_Capacity__c>();
    public static List<Appt_Time_Slot_Capacity__c> updateSlotConfigList = new List<Appt_Time_Slot_Capacity__c>();
    public static List<Appt_Capacity_Update_History__c> auditList = new List<Appt_Capacity_Update_History__c>();
    public static List<Appt_Time_Slot__c> existingApptTimeSlots = new List<Appt_Time_Slot__c>();
    public static List<Appt_Time_Slot__c> updateApptTimeSlots = new List<Appt_Time_Slot__c>();
    public static Integer timeZoneOffset;
    public static dateTime effectiveDate;
    public static Set<String> resourceTypeSet = new Set<String>();        

    public static final String FRONTROOM = Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT;
    public static final String BACKROOM = Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK;

    // main process thread that runs the logic required to make the updates broken up in to sub functions to make the code easier to understand
    public static Boolean updateStoreProcess(Appt_UpdateStoreConfig newConfig){
        System.debug('Start updateStore');

        System.debug(newConfig);
        System.debug(newConfig.effectiveDate);
        System.debug(newConfig.selectedDays);
        System.debug(newConfig.ApptTimeSlotCapacities);
        System.debug(newConfig.serviceTerritory);

        Boolean success =  true;
        config = newConfig;

        getSelectedDays(); // creates a set of date strings to filter on
        getExistingSlotConfigs(); // gets all Appt_Time_Slot_Capacity__c for the days selected
        getOperatingHoursTimezoneOffset(); // gets the stores operating hours timezone offset
        setEffectiveDate(); // converts the string date to a datetime for time slot query
        createUpdateAndAuditRecords(); // creates a list of Appt_Capacity_Update_History__c record and Appt_Time_Slot_Capacity__c records for insert and update        
        getExistingTimeSlots(); // gets all existing time slots that are eligible based on the effective date
        setUpdateApptTimeSlotList(); // captures the timeslots to be updated and makes the correct updates
        makeDLMUpdates();

        for(Appt_Time_Slot__c slot :updateApptTimeSlots){
            System.debug(slot.Start_Time__c.addHours(timeZoneOffset).format('EEEE'));
            System.debug(slot);        
        }                            

        System.debug('End updateStore');
        return success;
    }

    // capture the selected days to be updated
    public static void getSelectedDays(){     
        System.debug('Start getSelectedDays');   
        for(Appt_UpdateStoreConfig.SelectedDay day: config.selectedDays){              
            selectedDays.add(day.selectedDay);                                    
        }
        System.debug('Selected Days: '+selectedDays);
        System.debug('End getSelectedDays');  
    }

    // gets all the slot configurations that match the selection requirements (filters on store and days selected)
    public static void getExistingSlotConfigs(){
        System.debug('Start getExistingSlotConfigs'); 
        System.debug('Service Territory id' + config.serviceTerritory); 
        System.debug('selected days' + selectedDays); 


        existingSlotConfigList = [SELECT 
                            id, 
                            Start_Time__c, 
                            End_Time__c,
                            Day_of_Week__c,
                            BSF_Capacity__c,
                            BSR_Capacity__c, 
                            BWF_Capacity__c, 
                            BWR_Capacity__c, 
                            FSF_Capacity__c, 
                            FSR_Capacity__c, 
                            FWF_Capacity__c, 
                            FWR_Capacity__c,
                            Service_Territory__r.Site_Account__r.SAP_STORE_ID__c 
                            FROM Appt_Time_Slot_Capacity__c 
                            WHERE Service_Territory__c = :config.serviceTerritory 
                            AND Day_of_Week__c IN :selectedDays];
        System.debug(existingSlotConfigList);
        System.debug(existingSlotConfigList.size());
        System.debug('After getExistingSlotConfigs'); 
    }

    // loops through all existing Appt_Time_Slot_Capacity__c records and parses out the records for update
    public static void createUpdateAndAuditRecords(){
        System.debug('Start createUpdateAndAuditRecords');

        for(Appt_Time_Slot_Capacity__c slot: existingSlotConfigList){
            //System.debug('timeSlot ' +slot);
            checkAndSetSlot(slot);
        }

        System.debug('Config List size: ' + config.ApptTimeSlotCapacities.size());
        System.debug('Config Days List size: ' + selectedDays.size());
        System.debug('Update list: ' + updateSlotConfigList);
        System.debug('Audit list size: ' + auditList.size());
        System.debug('Update list size: ' + updateSlotConfigList.size());
        System.debug('Audit list: ' + auditList);        
        System.debug('End createUpdateAndAuditRecords');
    }

    // looks for a matching configured timeslot and then creates the Appt_Capacity_Update_History__c record and adds 
    // the existingSlot record to the update list with the required updated configurations
    public static void checkAndSetSlot(Appt_Time_Slot_Capacity__c existingSlot){   
        //System.debug('Start checkAndSetSlot');   
        for(Appt_Time_Slot_Capacity__c updateSlot : config.ApptTimeSlotCapacities){
            
            if(updateSlot.Start_Time__c == existingSlot.Start_Time__c && updateSlot.End_Time__c == existingSlot.End_Time__c){
                 
                createAuditRecord(existingSlot,updateSlot);
                createCapacityUpdateRecord(existingSlot,updateSlot);
                break;
            }
        }       
    }

    // creates an audit record with the before and after values
    public static void createAuditRecord(Appt_Time_Slot_Capacity__c existingSlot, Appt_Time_Slot_Capacity__c updateSlot){
        //System.debug('Start createAuditRecord');
        Appt_Capacity_Update_History__c newAuditRecord = new Appt_Capacity_Update_History__c();
                newAuditRecord.Before_Back_Store_Fleet__c = existingSlot.BSF_Capacity__c;
                newAuditRecord.Before_Back_Store_Retail__c = existingSlot.BSR_Capacity__c;
                newAuditRecord.Before_Back_Web_Fleet__c = existingSlot.BWF_Capacity__c;
                newAuditRecord.Before_Back_Web_Retail__c = existingSlot.BWR_Capacity__c;
                newAuditRecord.Before_Front_Store_Fleet__c = existingSlot.FSF_Capacity__c;
                newAuditRecord.Before_Front_Store_Retail__c = existingSlot.FSR_Capacity__c;
                newAuditRecord.Before_Front_Web_Fleet__c = existingSlot.FWF_Capacity__c;
                newAuditRecord.Before_Front_Web_Retail__c = existingSlot.FWR_Capacity__c;
                newAuditRecord.After_Back_Store_Fleet__c = updateSlot.BSF_Capacity__c;
                newAuditRecord.After_Back_Store_Retail__c = updateSlot.BSR_Capacity__c;
                newAuditRecord.After_Back_Web_Fleet__c = updateSlot.BWF_Capacity__c;
                newAuditRecord.After_Back_Web_Retail__c = updateSlot.BWR_Capacity__c;
                newAuditRecord.After_Front_Store_Fleet__c = updateSlot.FSF_Capacity__c;
                newAuditRecord.After_Front_Store_Retail__c = updateSlot.FSR_Capacity__c;
                newAuditRecord.After_Front_Web_Fleet__c = updateSlot.FWF_Capacity__c;
                newAuditRecord.After_Front_Web_Retail__c = updateSlot.FWR_Capacity__c;
                newAuditRecord.Start_Time__c = existingSlot.Start_Time__c;
                newAuditRecord.End_Time__c = existingSlot.End_Time__c;
                newAuditRecord.Day_of_Week__c = existingSlot.Day_of_Week__c;
                newAuditRecord.Service_Territory__c = config.serviceTerritory;                
                newAuditRecord.User__c = UserInfo.getUserId();                
                newAuditRecord.Effective_Date__c = date.newinstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day());             
                
                auditList.add(newAuditRecord);
                //System.debug('audit-'+newAuditRecord);
    }

    // Updates the existing slot capacities to match the configured updates and adds it to the update list
    public static void createCapacityUpdateRecord(Appt_Time_Slot_Capacity__c existingSlot, Appt_Time_Slot_Capacity__c updateSlot){
        existingSlot.BSF_Capacity__c = updateSlot.BSF_Capacity__c;
        existingSlot.BSR_Capacity__c = updateSlot.BSR_Capacity__c;
        existingSlot.BWF_Capacity__c = updateSlot.BWF_Capacity__c;
        existingSlot.BWR_Capacity__c = updateSlot.BWR_Capacity__c;
        existingSlot.FSF_Capacity__c = updateSlot.FSF_Capacity__c;
        existingSlot.FSR_Capacity__c = updateSlot.FSR_Capacity__c;
        existingSlot.FWF_Capacity__c = updateSlot.FWF_Capacity__c; 
        existingSlot.FWR_Capacity__c = updateSlot.FWR_Capacity__c;
        updateSlotConfigList.add(existingSlot);
        //System.debug('audit-'+existingSlot);
    }

    // get the timezone offset for the store
    public static void getOperatingHoursTimezoneOffset(){
        System.debug('Start getOperatingHoursTimezoneOffset');
        timeZoneOffset = Appt_AppointmentUtil.getTimeZoneOffset(existingSlotConfigList[0].Service_Territory__r.Site_Account__r.SAP_STORE_ID__c);
        System.debug('TimeZone Offset: ' +timeZoneOffset);
        System.debug('End getOperatingHoursTimezoneOffset');
    }

    // set effective date with timezone offset
    public static void setEffectiveDate(){
        System.debug('Start setEffectiveDate');
        System.debug(config.effectiveDate);
        System.debug('year '+config.effectiveDate.substringBefore('-'));
        System.debug('month '+config.effectiveDate.substringBetween('-', '-'));
        System.debug('day '+config.effectiveDate.right(2));

        String stringDay = config.effectiveDate.right(2);
        if(stringDay.contains('-')){
            stringDay = stringDay.right(1);
        }

        Integer year = Integer.valueOf(config.effectiveDate.substringBefore('-'));
        Integer day = Integer.valueOf(stringDay);
        Integer month = Integer.valueOf(config.effectiveDate.substringBetween('-', '-'));
        effectiveDate = datetime.newInstance(year, month, day);
        
        System.debug(effectiveDate);
        System.debug('End setEffectiveDate'); 

    }

    // gets all existing time slots that start time is greater or equal to the effective date
    public static void getExistingTimeSlots(){
        System.debug('Start getExistingTimeSlots');
        System.debug('get Effective date' + effectiveDate);

        existingApptTimeSlots = [SELECT 
                            id, 
                            Start_Time__c, 
                            End_Time__c, 
                            BSF_Capacity__c,
                            BSR_Capacity__c, 
                            BWF_Capacity__c, 
                            BWR_Capacity__c, 
                            FSF_Capacity__c, 
                            FSR_Capacity__c, 
                            FWF_Capacity__c, 
                            FWR_Capacity__c, 
                            Type__c  
                            FROM Appt_Time_Slot__c 
                            WHERE Service_Territory__c = :config.serviceTerritory 
                            AND Start_Time__c >= :effectiveDate
                            ORDER BY Start_Time__c ASC];

        System.debug('Time Slots: ' + existingApptTimeSlots);
        System.debug('Time Slot size: ' + existingApptTimeSlots.size());
        System.debug('End getExistingTimeSlots');
    }

    public static void setUpdateApptTimeSlotList(){
        System.debug('Start setUpdateApptTimeSlotList');
        for(Appt_Time_Slot__c timeSlot :existingApptTimeSlots){
            Datetime dtStartTime = timeSlot.Start_Time__c.addHours(timeZoneOffset);
            Datetime dtEndTime = timeSlot.End_Time__c.addHours(timeZoneOffset);
            Time startTime = dtStartTime.timeGMT();
            Time endTime = dtEndTime.timeGMT();
            String dayOfWeek = timeSlot.Start_Time__c.addHours(timeZoneOffset).format('EEEE');
            checkToAddTimeSlotToUpdateList(timeSlot.Type__c, timeSlot, startTime, endTime, dayOfWeek);
        }
        System.debug('Update Time Slots: ' + updateApptTimeSlots);
        System.debug('Update Time slots size: ' + updateApptTimeSlots.size());
        System.debug('End setUpdateApptTimeSlotList');
    }

    // checks for a timeslot update match and makes the correct update and then adds it to the update list
    public static void checkToAddTimeSlotToUpdateList(String frontOrBack, Appt_Time_Slot__c timeSlot, Time startTime, Time endTime, String dayOfWeek){        
        // Checks for time slot to be in a selected day of the week
        if(selectedDays.contains(dayOfWeek)){
            // Loop through all configurations checking for matches
            for(Appt_Time_Slot_Capacity__c updateSlot : config.ApptTimeSlotCapacities){
                // check for a time match               
                if(updateSlot.Start_Time__c == startTime && updateSlot.End_Time__c == endTime){
                    // make front room updates
                    if(frontOrBack == FRONTROOM){   
                        //if(!isThereResourceAbsenceForSlot(blockOutListFront, timeSlot)){                            
                            timeSlot.FSF_Capacity__c = updateSlot.FSF_Capacity__c;
                            timeSlot.FSR_Capacity__c = updateSlot.FSR_Capacity__c;
                            timeSlot.FWF_Capacity__c = updateSlot.FWF_Capacity__c; 
                            timeSlot.FWR_Capacity__c = updateSlot.FWR_Capacity__c;
                            updateApptTimeSlots.add(timeSlot);
                        //}                                        
                        break;
                    }
                    // make back room updates
                    if(frontOrBack == BACKROOM){
                        //if(!isThereResourceAbsenceForSlot(blockOutListBack, timeSlot)){
                            timeSlot.BSF_Capacity__c = updateSlot.BSF_Capacity__c;
                            timeSlot.BSR_Capacity__c = updateSlot.BSR_Capacity__c;
                            timeSlot.BWF_Capacity__c = updateSlot.BWF_Capacity__c;
                            timeSlot.BWR_Capacity__c = updateSlot.BWR_Capacity__c;
                            updateApptTimeSlots.add(timeSlot);
                        //}                        
                        break;
                    }
                }
            } 
        }        
    }
    

    // complete dml for this proccess
    public static void makeDLMUpdates(){
        if(auditList.size() > 0){insert auditList;} // insert audit records with before and after values       
        if(updateApptTimeSlots.size() > 0){update updateApptTimeSlots;} // update Appt_Time_Slot__c after effective date without a blocked out resource absence
        if(updateSlotConfigList.size() > 0){update updateSlotConfigList;} // update Appt_Time_Slot_Capacity__c config records     
    }

}