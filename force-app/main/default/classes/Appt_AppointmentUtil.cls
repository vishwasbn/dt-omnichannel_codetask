public class Appt_AppointmentUtil {
    
    public static String lprefix = 'Appt_AUtil: ';    

    //---Returns number of hours to add to adjust for a store's time zone on today's date
    public static Integer getTimeZoneOffset(String siteId) {
        return getTimeZoneOffset(siteId, Datetime.now());
    }

    //---Returns number of hours to add to adjust for a store's time zone on a certain date
    public static Integer getTimeZoneOffset(String siteId, Datetime dt) {
        //System.debug('---Start getTimeZoneOffset()---');  //DEBUG

        //-- Validate params, return null if not properly populated
        if (String.isBlank(siteId)) return null;
        if (dt == null) return null;
        
        try {
            // 1. Get Time Zone of a Store
            List<ServiceTerritory> getStoreTimeZone = [
                SELECT Id, OperatingHours.TimeZone, Site_Account__c
                FROM ServiceTerritory 
                WHERE Site_Account__r.SAP_STORE_ID__c = :siteId 
                limit 1];
            //System.debug(lprefix+ 'getStoreTimeZone: ' + getStoreTimeZone);  //DEBUG

            TimeZone storeTimeZone = null;
            if(getStoreTimeZone.size() > 0 && getStoreTimeZone[0].OperatingHours != null) {
                storeTimeZone = Timezone.getTimeZone(getStoreTimeZone[0].OperatingHours.TimeZone);
            }
            //System.debug(lprefix + ' timeZone: ' + storeTimeZone);

            // 2. Get # of hours between a store's time zone and UTC time on date passed in param
            Integer timeOffset = storeTimeZone.getOffset(dt);
            timeOffset = timeOffset / (1000 * 60 * 60); // convert ms to hours

            //System.debug('Off Set to return: ' + timeOffset);
            return timeOffset;
        } catch (Exception e) {
            System.debug(lprefix + ' Unable to calculate time zone offset : ' + e.getMessage());
            return null;
        }
        
    }

    //---Returns number of hours to add to adjust for a store's time zone on today's date
    public static Integer getTimeZoneOffset(TimeZone storeTimeZone, Datetime dt) {
            // 2. Get # of hours between a store's time zone and UTC time on date passed in param
            Integer timeOffset = storeTimeZone.getOffset(dt);
            timeOffset = timeOffset / (1000 * 60 * 60); // convert ms to hours

            //System.debug('Off Set to return: ' + timeOffset);
            return timeOffset;
    }

    //---Returns model containing the store's timezone and timezoneoffset  on today's date
    public static Appt_TimeZoneModel getTimeZoneAndOffset(String siteId) {
        return getTimeZoneAndOffset(siteId, Datetime.now());
    }

    //---Returns model containing the store's timezone and timezoneoffset  on a certain date
    public static Appt_TimeZoneModel getTimeZoneAndOffset(String siteId, Datetime dt) {
        //System.debug('getTimeZoneAndOffset() ENTRY - siteId='+siteId);
        if (siteId == null || siteId == '') return null;

        Appt_TimeZoneModel returnModel = new Appt_TimeZoneModel();
        
        try {
            // 1. Get Time Zone of a Store
            List<ServiceTerritory> getStoreTimeZone = [
                SELECT Id, OperatingHours.TimeZone, Site_Account__c
                FROM ServiceTerritory 
                WHERE Site_Account__r.SAP_STORE_ID__c = :siteId 
                limit 1];
            //System.debug(lprefix+ '   SOQL getStoreTimeZone: ' + getStoreTimeZone);

            TimeZone storeTimeZone = null;
            if(getStoreTimeZone.size() > 0 && getStoreTimeZone[0].OperatingHours != null) {
                storeTimeZone = Timezone.getTimeZone(getStoreTimeZone[0].OperatingHours.TimeZone);
                returnModel.timeZone = getStoreTimeZone[0].OperatingHours.TimeZone;
            }
            //System.debug(lprefix + '  returnModel.timeZone=' + returnModel.timeZone);

            // 2. Get # of hours between a store's time zone and UTC time
            Integer timeOffset = storeTimeZone.getOffset(dt);
            timeOffset = timeOffset / (1000 * 60 * 60); // convert ms to hours

            
            returnModel.timeZoneOffset = timeOffset;
            System.debug('   returnModel.timeZoneOffset = ' + returnModel.timeZoneOffset);
            return returnModel;
        } catch (Exception e) {
            System.debug(lprefix + ' Unable to calculate time zone offset : ' + e.getMessage());
            return null;
        }
        
    }


    public static Datetime convertTime(String dateString, String timeString, Integer offset) {
        //System.debug('---Start ConvertTime()--- dateString: ' + dateString + ' timeString: ' + timeString + ' offset: ' + offset);  //DEBUG
        
        try {
            List<String> appointmentDateList = dateString.split('-');
            if (appointmentDateList.size() != 3 || timeString.length() != 4) {
                System.debug(' ERROR, returning null - appointmentDateList: ' + appointmentDateList + ' timeString: ' + timeString);
                return null;
            }

            // get date and time values
            //System.debug('     appointmentDateList: ' + appointmentDateList); //DEBUG
            Integer year = Integer.valueOf(appointmentDateList[0]);
            Integer month = Integer.valueOf(appointmentDateList[1]);
            Integer day = Integer.valueOf(appointmentDateList[2]);
            Integer hour = Integer.valueOf(timeString.substring(0,2));
            Integer minute = Integer.valueOf(timeString.substring(2));
            //System.debug('parsed date: ' + year + ':' + month + ':' + day);  //DEBUG
            //System.debug('parsed time: ' + hour + ':' + minute);  //DEBUG

            Datetime dtGMTwOffset = Datetime.newInstanceGmt(year, month, day, (hour - offset), minute, 0);
            //System.debug('return datetime: ' + dtGMTwOffset);   //DEBUG

            return dtGMTwOffset;
        } catch (Exception e) {
            System.debug(lprefix + ' Invalid date/time formatting or invalid offset: ' + e.getMessage());
            return null;
        } 
    }

    public static String formatTimeHHmm(Time tm) {
        if (tm != null) {
            String hour = String.valueOf(tm.hour());
            hour = hour.length() == 2 ? hour : '0'+hour;
            String minute = String.valueOf(tm.minute());
            minute = minute.length() == 2 ? minute : '0'+minute;
            return hour + minute;
        }
        return null;
    }

    public static Integer minutesBetweenDatetimes(Datetime startTime, Datetime endTime) {
        if (startTime != null && endTime != null) {
            return Integer.valueOf((endTime.getTime() - startTime.getTime()) / 60000);
        }
        return null;
    }

    public static Datetime convertTime(Datetime appointmentDateTime, Integer offset) {
        System.debug('---Start ConvertTime(DateTime)---');
        System.debug('dateTime: ' +appointmentDateTime + ' offset: ' + offset);

        try {
            // get date and time values
            Integer year = appointmentDateTime.year();
            Integer month = appointmentDateTime.month();
            Integer day = appointmentDateTime.day();
            Integer hour = appointmentDateTime.hour();
            Integer minute = appointmentDateTime.minute();
            //System.debug('parsed date: ' + year + ':' + month + ':' + day);
            //System.debug('parsed time: ' + hour + ':' + minute);

            Datetime dtGMTwOffset = Datetime.newInstanceGmt(year, month, day, (hour - offset), minute, 0);
            System.debug('dtgmtwoffset: ' + dtGMTwOffset);
            
            return dtGMTwOffset;

        } catch (Exception e) {
            System.debug(lprefix + ' Invalid appointment Date Time or offset: ' + e.getMessage());
            return null;
        }
    }

    //-- lookup full state name for state abreviation code
    public static String convertToFullStateName(String stateAbrev) {
        System.debug('convertToFullStateName() ENTRY - stateAbrev='+stateAbrev);
        String stateName;

        if (!String.isBlank(stateAbrev)) {
            //imports the list of states for comparison/conversion
            List<Fleet_State_Abbrev__mdt> stateCompareList = [ SELECT State_Abbrev__c, State_Output__c FROM Fleet_State_Abbrev__mdt];
            stateName = Fleet_Util.convertTwoDigitStateToFullName(stateAbrev, stateCompareList);
        }
        System.debug('convertToFullStateName() EXIT - stateName='+stateName);
        return stateName;
    }


    //-- lookup the country for the state. Return default country (Unites States) if no country found
    public static String getCountryByState(String state) {
        System.debug('getCountryByState() ENTRY - stateAbrev='+state);
        String returnCountry;
        List<Fleet_State_Abbrev__mdt> countries;

        if (!String.isBlank(state)) {

            //query Fleet_State_Abbrev__mdt to get country for the state abreviation
            countries = [ SELECT Country__c FROM Fleet_State_Abbrev__mdt 
                            WHERE State_Abbrev__c = :state];

            if (countries != null && countries.size() > 0) {
                returnCountry = countries.get(0).Country__c;

            } else {

                 //-- Did NOT get any results, so try by full state name
                countries = [ SELECT Country__c FROM Fleet_State_Abbrev__mdt 
                                WHERE State_Output__c = :state];

                if (countries != null && countries.size() > 0) {
                    returnCountry = countries.get(0).Country__c;
                } 
            }
        }

        //-- Since Country__c field was recently added, there could be states without country set. If country still unknown, set to default country
        if (String.isBlank(returnCountry)) returnCountry = Appt_ConstantValues.ADDRESS_DEFAULT_COUNTRY;

        System.debug('getCountryByState() EXIT - returnCountry='+returnCountry);
        return returnCountry;
    }


    // sets an appointments priority to be lower so FSL won't throw an error for duplicate appointments if the slot is still available
    //@future
    public static void updateFLSPriority(id appointmentId, String updateStatus)
    {   
        Boolean setLowerPriority = true;
        
        ServiceAppointment myAppointment = [SELECT 
                                            id, 
                                            status, 
                                            SchedStartTime,
                                            SchedEndTime,
                                            Work_Order__r.ServiceTerritoryId, 
                                            FSL__Schedule_over_lower_priority_appointment__c,
                                            Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c,
                                            Priority__c,
                                            Activity_Type__c
                                            FROM ServiceAppointment 
                                            WHERE id = :appointmentId];     
                                            
        //if (myAppointment != null) System.debug(lprefix+'updateFLSPriority() - ServiceAppointment:'+myAppointment.SchedStartTime+'|'+myAppointment.SchedEndTime+'|'+myAppointment.status);  //TODO REMOVE DEBUG

        // if lower priority should be set make the update to the appointment
        if(setLowerPriority && myAppointment != null){

            myAppointment.FSL__Schedule_over_lower_priority_appointment__c = false;
            myAppointment.Priority__c = 2;
            if(!String.isBlank(updateStatus)){
                myAppointment.status = updateStatus;
            }                    
            //System.debug(lprefix+'  before update:'+myAppointment.SchedStartTime+'|'+myAppointment.SchedEndTime+'|'+myAppointment.status);  //TODO REMOVE DEBUG
            update myAppointment;
            //System.debug(lprefix+'  after update:'+myAppointment.SchedStartTime+'|'+myAppointment.SchedEndTime+'|'+myAppointment.status);  //TODO REMOVE DEBUG

        }
        
        System.debug(lprefix+' updateFLSPriority() EXIT - myAppointment:'+ myAppointment);
    }

    // returns 12 hour time string with am or pm
    public static String getFormattedTimeString(String timeString) {
        if (timeString != null && timeString.length() == 4) {
            Integer hourInt = Integer.valueOf(timeString.subString(0,2));
            String hour = '';
            String ampm = '';
            // set fmpm and 12 hour time
            if (hourInt >= 12) {
                hourInt = hourInt != 12 ? hourInt - 12 : 12;
                ampm = 'PM';
            } 
            // time is probably am
            else {
                ampm = 'AM';
            }
        
            // convert hours to string
            if (hourInt < 10) hour = '0'+String.valueOf(hourInt);
            if (hourInt >= 10) hour = String.valueOf(hourInt);
            
            // set the minutes
            String minute = timeString.subString(2);

            return hour+':'+minute + ' ' + ampm;
        }
        return null;
    }


    // This method will accept a front office or back office appointment ids and will assign the resource to the appoint via the AssignedResource
    public static void assignAppointmentToResource(id frontOfficeResourceId, id frontOfficeAppointmentId, id backOfficeResourceId, id backOfficeAppointmentId, String siteId, String type){
        System.debug(lprefix+ '   Start appointment assignment to resource for siteId='+siteId+ ', frontOfficeAppointmentId='+frontOfficeAppointmentId+', backOfficeAppointmentId='+backOfficeAppointmentId+', frontOfficeResourceId='+frontOfficeResourceId+', backOfficeResourceId='+backOfficeResourceId);
        List<AssignedResource> assignList = new List<AssignedResource>();

        DateTime startTimePart = Datetime.now();
        
        if(((frontOfficeResourceId == null || backOfficeResourceId == null) && type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH) || 
            (backOfficeResourceId == null && type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK) || 
            (frontOfficeResourceId == null && type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT)){

                List<ServiceTerritoryMember> siteAppointmentInfo = [SELECT  ServiceResourceId, 
                                                                        ServiceResource.Type__c, 
                                                                        ServiceTerritory.Front_Appointment_Work_Type__c, 
                                                                        ServiceTerritory.Back_Appointment_Work_Type__c 
                                                                        FROM ServiceTerritoryMember 
                                                                        WHERE ServiceTerritory.Site_Account__r.SAP_STORE_ID__c = :siteId];
                System.debug(lprefix+ '   SOQL QUERY: Service Territory Member info ' +siteAppointmentInfo );
                //loop through list to populate frontroom and backroom service resource ids
                for (ServiceTerritoryMember info: siteAppointmentInfo) {
                    System.debug(info.ServiceResource.Type__c);
                    if (info.ServiceResource.Type__c == Appt_ConstantValues.SERVICE_RESOURCE_TYPE_FRONT) {                    
                        frontOfficeResourceId = info.ServiceResourceId;
                    } else if (info.ServiceResource.Type__c == Appt_ConstantValues.SERVICE_RESOURCE_TYPE_BACK) {                    
                        backOfficeResourceId = info.ServiceResourceId;
                    }
                }
                System.debug(lprefix+ '   front office ' +frontOfficeResourceId );
                System.debug(lprefix+ '   back office ' +backOfficeResourceId );

        }

        // Check for a front office appointment
        if(frontOfficeResourceId != null && frontOfficeAppointmentId != null){
            AssignedResource newAssignment = new AssignedResource(ServiceResourceId = frontOfficeResourceId, ServiceAppointmentId = frontOfficeAppointmentId);
            assignList.add(newAssignment);
        }

        // Check for a back office appointment
        if(backOfficeResourceId != null && backOfficeAppointmentId != null){
            AssignedResource newAssignment = new AssignedResource(ServiceResourceId = backOfficeResourceId, ServiceAppointmentId = backOfficeAppointmentId);
            assignList.add(newAssignment);
        }
        
        // assign appointment to a resource
        insert assignList;
        
        Int_Values.addTiming('ApptUtil.AssgnApptRes',startTimePart, Datetime.now());

        System.debug(lprefix+ ' created assignments: '+assignList);
        System.debug(lprefix+ '   End appointment assignment to resource');
    }

    //-- this method will calculate if we are withint the web cutoff time, which is usually 2 hours from current time
    public static Boolean isInWebCutoffTime(Datetime startTime) {
        if (startTime == null) return null;
        
        Integer webApptLeadTime = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_WEB_APPOINTMENT_LEAD_TIME));
        Datetime todayCutoffTime = DateTime.now().addMinutes(webApptLeadTime);
        return startTime <= todayCutoffTime;
    }

    public static ServiceAppointment getServiceAppointment(Id saId) {
        return [SELECT status, Date_String__c, SchedStartTime, SchedEndTime, Duration, Start_Time_String__c, End_Time_String__c, Consult_Start_Time__c, Consult_End_Time__c, Back_Office_Start_Time__c, Back_Office_End_Time__c 
        FROM ServiceAppointment WHERE Id = :saId];
    }

    //-- Form Type column (In CSV) to Order Type field mapping values, as defined by Taral on 4/19/21 in Appointment Cutover testing meeting
    public static String getOrderTypeFromFormType(String formType) {
        if (String.isBlank(formType)) return null;
        else if (formType.trim() == Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_QUO) return Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_QUO;
        else if (formType.trim() == Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_WEB) return Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_WEB;
        else if (formType.trim() == Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_LAY) return Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_LAY;
        else if (formType.trim() == Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_BOP) return Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_BOP;
        else if (formType.trim() == Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_INV) return Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_INV;
        else return null;
    }
}