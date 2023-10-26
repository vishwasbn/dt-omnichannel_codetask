public class Appt_AvailabilityHandler {
    
    public static String lprefix = 'Appt_AvailH: ';

    //Calculate and return the available time slots bt work type for a site
    public static Appt_SiteAvailabilityModel calculateAvailableTimes(Appt_GetAvailabilityServiceModel availModel){

        // 0. Validate the parameters in the model. If not valid, return model which will contain error codes and message
        if (validateModelParams(availModel) == false) {
            Appt_SiteAvailabilityModel returnModel = new Appt_SiteAvailabilityModel();
            returnModel.setError(availModel.statusCode, availModel.message);
            return returnModel;
        }

        System.debug( lprefix + 'calculateAvailableTimes() ENTRY - siteId='+availModel.siteId+', startDate='+availModel.startDate+', endDate='+availModel.endDate);
         
        //start timer for performance loging
        DateTime startTimeAll = Datetime.now(); 
        DateTime startTimePart = Datetime.now(); 

        //  1. get Time Zon Offset for the store's timezone on the date of the availModel.startDate param (Web Users will have the time zone of the Integration User)
        //LIMIT NOTE: 1 SOQL query
        Appt_TimeZoneModel timeModel = Appt_AppointmentUtil.getTimeZoneAndOffset(availModel.siteId, availModel.startDate);
        if (timeModel == null || timeModel.timeZoneOffset == 0 || String.isBlank(timeModel.timeZone)) {
            // return error because we couldn't get timezoneoffset, probably because service territory couldn't be found for the siteId
            Appt_SiteAvailabilityModel returnModel = new Appt_SiteAvailabilityModel();
            returnModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_NOT_FOUND, 'Unable to retrieve the ServiceTerritory as well as timezone and timezoneoffset with siteId='+availModel.siteId);
            return returnModel;
        } else {
            availModel.timeZoneOffset = timeModel.timeZoneOffset;
            availModel.timeZone = timeModel.timeZone;
        }

        System.debug( lprefix + 'T1 timezone offset: ' + Fleet_IntegrationUtil.getDuration(startTimePart, Datetime.now()) + ' ms');
        //Int_Values.addTiming('AvailHandler.TimeZone',startTimePart, Datetime.now());

        //  2. caluclate work types and durations needed to find the right slots
        startTimePart = Datetime.now(); 
        Appt_workTypeModel wrkTypModel = calculateWorkType(availModel);
        if (wrkTypModel != null && wrkTypModel.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR) {
            // return error because we couldn't calculate the work type and duration
            Appt_SiteAvailabilityModel returnModel = new Appt_SiteAvailabilityModel();
            returnModel.setError(wrkTypModel.statusCode, wrkTypModel.message);
            return returnModel;
        }

        System.debug( lprefix + 'T2 calculate WorkType: ' + Fleet_IntegrationUtil.getDuration(startTimePart, Datetime.now()) + ' ms');
        //Int_Values.addTiming('AvailHandler.CalcWorkType',startTimePart, Datetime.now());

        // Setup some  properties used in logic
        startTimePart = Datetime.now(); 
        Integer maxSlotsToQuery = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_MAX_SLOTS_TO_QUERY));
        Integer webApptLeadTime = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_WEB_APPOINTMENT_LEAD_TIME));
    
        String fleetRetailChar;
        if (availModel.customerType == Appt_ConstantValues.CUSTOMER_TYPE_FLEET) fleetRetailChar = Appt_ConstantValues.APPOINTMENT_SOURCE_CUSTOMER_FLEET_CHAR;
        else fleetRetailChar = Appt_ConstantValues.APPOINTMENT_SOURCE_CUSTOMER_RETAIL_CHAR;

        String storeWebChar;
        if (availModel.source == Appt_ConstantValues.APPOINTMENT_SOURCE_STORE || availModel.source == Appt_ConstantValues.APPOINTMENT_SOURCE_POS) storeWebChar = Appt_ConstantValues.APPOINTMENT_SOURCE_STORE_CHAR;
        else storeWebChar = Appt_ConstantValues.APPOINTMENT_SOURCE_WEB_CHAR;
        /*Added as part of SO-856: Consolidate Fleet Buckets Start*/
        if(fleetRetailChar==Appt_ConstantValues.APPOINTMENT_SOURCE_CUSTOMER_FLEET_CHAR 
        && Appt_AppointmentUtil.checkConsolidateFleetCapacityFlag())
        {
            storeWebChar=Appt_ConstantValues.APPOINTMENT_SOURCE_STORE_CHAR;
        }
        /*Added as part of SO-856: Consolidate Fleet Buckets End*/

       
        //--- Calculate the time today in Store's Timezone that will be within the "window" for making Web Slots available to the Store (Web Appointment Lead Time).  
        //--- Add store's timezone offset to the current GMT datetime to get store's current date and time
        //-- IF the source = WEB, then add webApptLeadTime minutes to the current time
        DateTime todayCutoffTime;
        if (availModel.source == Appt_ConstantValues.APPOINTMENT_SOURCE_WEB) {
            todayCutoffTime = DateTime.now().addMinutes(webApptLeadTime);
        } else {
            todayCutoffTime = DateTime.now();
        }

        System.debug(lprefix+'        todayCutoffTime='+todayCutoffTime+' for source ='+ availModel.source);
        System.debug( lprefix + 'T3 calculate getting settings: ' + Fleet_IntegrationUtil.getDuration(startTimePart, Datetime.now()) + ' ms');
        //Int_Values.addTiming('AvailHandler.CalcGetSettings',startTimePart, Datetime.now());

        //--- 3. Get all availble time slots for the site and dates in future
        startTimePart = Datetime.now(); 
        String soql = 'SELECT Type__c, IsFrontUnavailable__c, isBackUnavailable__c, BSF_Available__c, BSR_Available__c, BWF_Available__c, BWR_Available__c, '+
                    'FSF_Available__c, FSR_Available__c, FWF_Available__c,  FWR_Available__c, Start_Time__c, End_Time__c, Date__c FROM Appt_Time_Slot__c '+
                    'WHERE Service_Territory__r.IsActive = true AND Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = \'' + availModel.siteId + '\' AND Date__c >= '+ String.valueOf(availModel.startDate) +
                    ' AND Date__c <= ' + String.valueOf(availModel.endDate) + ' AND Start_Time__c >= ' + todayCutoffTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String orderBySOQL = ' ORDER BY Start_Time__c ASC LIMIT '+ maxSlotsToQuery;
        String dynamicWhereSOQL = '';

        //build dynamic portion of where clause if front or back only
        if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT) {
            dynamicWhereSOQL = ' AND Type__c = \'' + Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT + '\' AND IsFrontUnavailable__c = false';
        } else if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK) {
            dynamicWhereSOQL = ' AND Type__c = \'' + Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK + '\' AND isBackUnavailable__c = false';

        }
        System.debug(lprefix+'       SOQL= '+soql + dynamicWhereSOQL + orderBySOQL); //DEBUG LOG

        //--- EXECUTE SOQL ----
        List<Appt_Time_Slot__c> allTimeSlots = (List<Appt_Time_Slot__c>)Database.query(soql + dynamicWhereSOQL + orderBySOQL);
        //System.debug(lprefix+'       POST SOQL allTimeSlots='+allTimeSlots); //DEBUG LOG

        Integer foundRecords = (allTimeSlots != null) ? allTimeSlots.size() : 0;
        if(Appt_AppointmentUtil.checkConsolidateFleetCapacityFlag() && foundRecords>0)
        {
            /*Added as part of SO-856: Consolidate Fleet Buckets Start*/
            allTimeSlots=(List<Appt_Time_Slot__c>)Appt_AppointmentUtil.ConsolidateFleetCapacities(allTimeSlots);
            /*Added as part of SO-856: Consolidate Fleet Buckets End*/
        }
        System.debug( lprefix + 'T4 SOQL: ' + Fleet_IntegrationUtil.getDuration(startTimePart, Datetime.now()) + ' ms, Found ' + foundRecords + ' records');
        Int_Values.addTiming('AvailHandler.calcAvailTimes.TimeslotSOQL',startTimePart, Datetime.now());

        //--- 4. Primary logic to calculate availability. (NO SOQL, memory only)
        startTimePart = Datetime.now(); 
        Appt_SiteAvailabilityModel returnModel = getAvailabilityModel(allTimeSlots, wrkTypModel, storeWebChar, fleetRetailChar, todayCutoffTime, availModel.timeZoneOffset, availModel.timeZone);
        System.debug( lprefix + 'T4 GetAvailabilityModel: ' + Fleet_IntegrationUtil.getDuration(startTimePart, Datetime.now()) + ' ms');
        Int_Values.addTiming('AvailHandler.calcAvailTimes.GetAvailabilityModel',startTimePart, Datetime.now());

        //--- 5. Set response status = success
        returnModel.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;

        System.debug( lprefix + 'T-All: ' + Fleet_IntegrationUtil.getDuration(startTimeAll, Datetime.now()) + ' ms');
        Int_Values.addTiming('AvailHandler.calcAvailTimes.All',startTimeAll, Datetime.now());

        System.debug(lprefix+'calculateAvailableTimes() EXIT: ');
        return returnModel;
    }

    // validate important parameters on model and if errors found, set error code and message on model and return FALSE
    public static Boolean validateModelParams(Appt_GetAvailabilityServiceModel availModel) {

        //if apptModel param is null throw exception
        if (availModel == null) {
            availModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'availModel parameter is null');   //This is null pointer exception.
            return false;
        }

        if (String.isBlank(availModel.siteId)) {
            availModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'siteId parameter is blank or null, siteId='+availModel.siteId);
            return false;
        }

        if (availModel.startDate == null || availModel.endDate ==  null || availModel.startDate > availModel.endDate) {
            availModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'startDate and endDate are both required and startDate cannot be greater then endDate');
            return false;
        }

        if (availModel.startDate < Date.today()) {
            availModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'startDate must be greater then or equal to today');
            return false;
        }

        //if here, then parameters passed validation
        return true;
    }
    
    //---Primay method to get Available time slots
    public static Appt_SiteAvailabilityModel getAvailabilityModel( List<Appt_Time_Slot__c> allTimeSlots, Appt_workTypeModel wrkTypModel, String storeWebChar, String fleetRetailChar, DateTime webCutoffTime, Integer timeZoneOffset, String timeZone)
    {
        Datetime methodTime = Datetime.now();
        Appt_SiteAvailabilityModel avModel = new Appt_SiteAvailabilityModel();
        avModel.timeZone = timeZone;
    
        if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT) {

            //---Get the Front Appointments
            List<Appt_Time_Slot__c> frontList = getAvailableSlots(allTimeSlots, Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR, storeWebChar, fleetRetailChar, webCutoffTime, timeZoneOffset, avModel);
            System.debug(lprefix+'        getAvailabilityModel() - frontList: ' + frontList.size()  + ' records');

        } else if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK) {

            //---Get the Back Appointments
            List<Appt_Time_Slot__c> backList = getAvailableSlots(allTimeSlots, Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR, storeWebChar, fleetRetailChar, webCutoffTime, timeZoneOffset, avModel);
            System.debug(lprefix+'        getAvailabilityModel() - backList: ' + backList.size() + ' records');

        } else {
             List<Appt_Time_Slot__c> bothList = getAvailableSlots(allTimeSlots, Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR+''+Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR, storeWebChar, fleetRetailChar, webCutoffTime, timeZoneOffset, avModel);
             System.debug(lprefix+'        getAvailabilityModel() - bothList: ' + bothList.size()  + ' records');
        }
        
        System.debug( lprefix + 'M:getAvailabilityModel(): ' + Fleet_IntegrationUtil.getDuration(methodTime, Datetime.now()) + ' ms');
        return avModel;
    }
    
    //---Add a time Slot to the return Model
    public static void addTimeSlotsToModel( Appt_SiteAvailabilityModel avModel, Appt_Time_Slot__c frontSlot, Appt_Time_Slot__c backSlot)
    {
        String slotDayString = '';
        
        //---Get the current day
        if (frontSlot != null)
        {
             slotDayString = '' + String.valueOf(frontSlot.Date__c); 
        } else if (frontSlot == null && backSlot != null) slotDayString = '' + String.valueOf(backSlot.Date__c);
            
        //--Create the days list if null
        if (avModel.days == null)
        {
             avModel.days = new List<Appt_SiteAvailabilityModel.Days>();
             avModel.daysMap = new Map<String, Appt_SiteAvailabilityModel.Days>();
        }
        
        Appt_SiteAvailabilityModel.Days selDay = avModel.daysMap.get(slotDayString);
        
        //---Create a new one if not fond and add to the Model
        if (selDay == null)
        {
            selDay = new Appt_SiteAvailabilityModel.Days();
            selDay.scheduleDate = slotDayString; 
            Datetime dt = Datetime.valueOf(slotDayString + ' 00:00:00');
            selDay.year = String.valueOf(dt.year());
            selDay.month = String.valueOf(dt.month());
            selDay.day = String.valueOf(dt.day());
            selDay.dayOfWeek = dt.format('EEEE');

            avModel.days.add( selDay);
            avModel.daysMap.put( slotDayString, selDay); 
        }   
        
        //---Create the time slots list if null
        if (selDay.timeSlots == null) selDay.timeSlots = new List<Appt_SiteAvailabilityModel.TimeSlots>();
        
        Appt_SiteAvailabilityModel.TimeSlots newSlot = new Appt_SiteAvailabilityModel.TimeSlots();
        
        if (frontSlot != null)
        {
            //System.debug(lprefix+'addTimeSlotsToModel() frontSlot:'+frontSlot); //DEBUG LOG
            newSlot.consultStartTime = '' + frontSlot.Start_Time__c.format('HHmm', avModel.timeZone);
            newSlot.consultEndTime = '' + frontSlot.End_Time__c.format('HHmm', avModel.timeZone);
            newSlot.consultDuration = String.valueOf(Appt_AppointmentUtil.minutesBetweenDatetimes(frontSlot.Start_Time__c, frontSlot.End_Time__c));
            //System.debug(lprefix+'  for timeZone='+ avModel.timeZone + ' adding frontSlot:'+newSlot); //DEBUG LOG
        }
        
        if (backSlot != null)
        {
            //System.debug(lprefix+'addTimeSlotsToModel() backSlot:'+backSlot); //DEBUG LOG
            newSlot.backOfficeStartTime = '' + backSlot.Start_Time__c.format('HHmm', avModel.timeZone);
            newSlot.backOfficeEndTime = '' + backSlot.End_Time__c.format('HHmm', avModel.timeZone);
            newSlot.backOfficeDuration = String.valueOf(Appt_AppointmentUtil.minutesBetweenDatetimes(backSlot.Start_Time__c, backSlot.End_Time__c));
            //System.debug(lprefix+' for timeZone='+ avModel.timeZone + ' adding backSlot:'+newSlot); //DEBUG LOG
        }
       
        selDay.timeSlots.add(newSlot);
    } 
    
    //---Logic to calculate available slots (Either Front or Back).  This takes into account the 'Web Lead Time' for Store and Web
    public static List<Appt_Time_Slot__c> getAvailableSlots( List<Appt_Time_Slot__c> allTimeSlots, String frontBackChar, String storeWebChar, String fleetRetailChar, 
                                                            DateTime webCutoffTime, Integer timeZoneOffset, Appt_SiteAvailabilityModel avModel)
    {
        Datetime methodTime = Datetime.now();
        List<Appt_Time_Slot__c> returnList = new List<Appt_Time_Slot__c>();    
        
        //---The current field to check
        String currentCheckField = frontBackChar + storeWebChar + fleetRetailChar + '_Available__c';
        
        
        /*Added as part of SO-856: Consolidate Fleet Buckets Start*/
        //Check if the consolidate fleet flag is true, then if it is front, send the FSF_Available__c. If back, send the BSF_Available__c
        
        if(Appt_AppointmentUtil.checkConsolidateFleetCapacityFlag() && fleetRetailChar==Appt_ConstantValues.APPOINTMENT_SOURCE_CUSTOMER_FLEET_CHAR)
        {
            if(frontBackChar==Appt_ConstantValues.APPOINTMENT_SOURCE_CUSTOMER_FLEET_CHAR)
            currentCheckField='FSF_Available__c';
            else {
                currentCheckField='BSF_Available__c';
            }
            
        }
        /*Added as part of SO-856: Consolidate Fleet Buckets End*/

        
        //---The web field to check (for the Web Cutoff)
        String webCheckField = frontBackChar + Appt_ConstantValues.APPOINTMENT_SOURCE_WEB_CHAR + fleetRetailChar + '_Available__c';
        
        //SO-481
        Map<String, Appt_Time_Slot__c> backMap = new Map<String, Appt_Time_Slot__c>();
        List<Appt_Time_Slot__c> frontList = new List<Appt_Time_Slot__c>();
        
        //---Scan for the matching availability
        for (Appt_Time_Slot__c currSlot: allTimeSlots) 
        {
            //---Only check slot if this is front type Appt_Time_Slot and we're checking for FRONT, or if this is back type Appt_Time_Slot and we're checking for BACK
            //SO-481
            if ((currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT && frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR)
                || (currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK && frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR)
                || ((currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT || currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK) &&
                        (frontBackChar != Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR && frontBackChar != Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR)) ) {
        					
                            //SO-481
                            if(currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT){
                                currentCheckField = Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR + storeWebChar + fleetRetailChar + '_Available__c';
                                webCheckField = Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR + Appt_ConstantValues.APPOINTMENT_SOURCE_WEB_CHAR + fleetRetailChar + '_Available__c';
                            }
                            else {
                                 currentCheckField = Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR + storeWebChar + fleetRetailChar + '_Available__c';
                                webCheckField = Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR + Appt_ConstantValues.APPOINTMENT_SOURCE_WEB_CHAR + fleetRetailChar + '_Available__c';
                            }
                            
                //---Check if it is today using current date at Store's timezone
                Datetime now = System.now().addHours(timeZoneOffset);
                System.debug(lprefix+'getAvailableSlots() - currSlot.Date__c='+currSlot.Date__c+', currSlot:'+currSlot); //DEBUG LOG
                System.debug(lprefix+'System.now().addHours(timeZoneOffset)='+now); //DEBUG LOG
                if (currSlot.Date__c == now.date())
                {
                    if (storeWebChar == Appt_ConstantValues.APPOINTMENT_SOURCE_STORE_CHAR)
                    {
                        if (isSlotAvailable(currSlot,currentCheckField))
                        {
                            returnList.add(currSlot);
                            if (avModel == null)
                            {
                                returnList.add(currSlot);
                            }
                            else
                            {
                                if(frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR || frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR) {
                                	addTimeSlotsToModel(avModel, (frontBackChar == 'F' ? currSlot : null), (frontBackChar == 'B' ? currSlot : null));
                                }
                            }
                            //SO-481
                            if(currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK) {
                                backMap.put('' + currSlot.Start_Time__c, currSlot);
                            }
                            else {
                                frontList.add(currSlot);
                            }
                        }
                        else
                        {
                            //---If Store value is not available, then check if there is any Web availability within the cutoff window
                            if (currSlot.Start_Time__c < webCutoffTime)
                            {
                                if (isSlotAvailable(currSlot, webCheckField))
                                {
                                    if (avModel == null)
                                    {
                                        returnList.add(currSlot);
                                    }
                                    else
                                    {
                                        if(frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR || frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR)
                                        {
                                            addTimeSlotsToModel(avModel, (frontBackChar == 'F' ? currSlot : null), (frontBackChar == 'B' ? currSlot : null));
                                        }
                                    }
                                    //SO-481
                                    if (currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK){
                                        backMap.put('' + currSlot.Start_Time__c, currSlot);
                                    }
                                    if (currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT){
                                        frontList.add(currSlot);
                                    }
                                }
                            }
                        }
                    }
                    
                    if (storeWebChar == Appt_ConstantValues.APPOINTMENT_SOURCE_WEB_CHAR)
                    {
                        //---Web Slots must be after the web cutoff time
                        if (currSlot.Start_Time__c >= webCutoffTime)
                        {
                            if (isSlotAvailable(currSlot, currentCheckField))
                            {
                                if (avModel == null)
                                {
                                    returnList.add(currSlot);
                                }
                                else
                                {
                                    if(frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR || frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR)
                                    {
                                        addTimeSlotsToModel(avModel, (frontBackChar == 'F' ? currSlot : null), (frontBackChar == 'B' ? currSlot : null));
                                    }
                                }
                                //SO-481
                                if (currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK){
                                    backMap.put('' + currSlot.Start_Time__c, currSlot);
                                }
                                if (currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT){
                                    frontList.add(currSlot);
                                }
                            }
                        }
                    }
                }
                else
                {   
                    if (isSlotAvailable(currSlot, currentCheckField))
                    {
                        if (avModel == null)
                        {
                            returnList.add(currSlot);
                        }
                        else
                        {
                            if(frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR || frontBackChar == Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR)
                            {
                                addTimeSlotsToModel(avModel, (frontBackChar == 'F' ? currSlot : null), (frontBackChar == 'B' ? currSlot : null));
                            }
                        }
                        //SO-481
                        if (currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK){
                            backMap.put('' + currSlot.Start_Time__c, currSlot);
                        }
                        if (currSlot.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT){
                            frontList.add(currSlot);
                        }
                    }
                }
            }
        }
        
        //SO-481
        if(frontBackChar != Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR && frontBackChar != Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR)
        {
            for (Appt_Time_Slot__c frontSlot : frontList) 
            {
                String key = '' + frontSlot.End_Time__c;   //---This creates to a String, this assumes that the date is included in the String
                //System.debug(lprefix+'        checking on backMap for cooresponding frontslot, key='+key+', currSlot:'+frontSlot);
                
                Appt_Time_Slot__c backSlot = backMap.get(key);
                if (backSlot != null) addTimeSlotsToModel( avModel, frontSlot, backSlot);
            }
        }

        System.debug( lprefix + 'M:getAvailableSlots(): ' + Fleet_IntegrationUtil.getDuration(methodTime, Datetime.now()) + ' ms');
        return returnList;
    }

    
    //---Note:  Concrete field check may be slightly faster than abstract method above, however, this may make a difference in the long run
    
    //---Check if the slot is available, reading the value from the selected field
    private static Boolean isSlotAvailable(Appt_Time_Slot__c selectedSlot, String fieldToCheck)
    {
        if (selectedSlot != null) System.debug(lprefix+'isSlotAvailable() ENTRY - startTime='+selectedSlot.Start_Time__c+', fieldToCheck='+fieldToCheck);  //DEBUG LOG - comment out

        if (selectedSlot == null) throw new Appt_AppointmentException('System Error - selectedSlot is null in isSlotAvailable()', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR));
        if (String.isBlank(fieldToCheck)) throw new Appt_AppointmentException('System Error - fieldToCheck is blank or null in isSlotAvailable()', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR));

        //-- CHECK WEB appointment availability 
        if (fieldToCheck == 'BWR_Available__c') return (selectedSlot.BWR_Available__c > 0 && !selectedSlot.isBackUnavailable__c);
        else if (fieldToCheck == 'BWF_Available__c') return (selectedSlot.BWF_Available__c > 0 && !selectedSlot.isBackUnavailable__c);
        else if (fieldToCheck == 'FWR_Available__c') return (selectedSlot.FWR_Available__c > 0 && !selectedSlot.IsFrontUnavailable__c);
        else if (fieldToCheck == 'FWF_Available__c') return (selectedSlot.FWF_Available__c > 0 && !selectedSlot.IsFrontUnavailable__c);

        //-- CHECK POS/STORE appointment availability 
        //-- if this is POS/Store appointment and we are within web cutoff time, include WEB availability in check
        if (Appt_AppointmentUtil.isInWebCutoffTime(selectedSlot.Start_Time__c)) {

            //--  In web cutoff time
            if (fieldToCheck == 'BSR_Available__c') return ((selectedSlot.BSR_Available__c > 0 || selectedSlot.BWR_Available__c > 0 ) && !selectedSlot.isBackUnavailable__c);
            else if (fieldToCheck == 'BSF_Available__c') return ((selectedSlot.BSF_Available__c > 0 || selectedSlot.BWF_Available__c > 0) && !selectedSlot.isBackUnavailable__c);
            else if (fieldToCheck == 'FSR_Available__c') return ((selectedSlot.FSR_Available__c > 0 || selectedSlot.FWR_Available__c > 0) && !selectedSlot.IsFrontUnavailable__c);
            else if (fieldToCheck == 'FSF_Available__c') return ((selectedSlot.FSF_Available__c > 0 || selectedSlot.FWF_Available__c > 0 ) && !selectedSlot.IsFrontUnavailable__c);

        } else {

            //-- NOT IN web cutoff time
            if (fieldToCheck == 'BSR_Available__c') return (selectedSlot.BSR_Available__c > 0 && !selectedSlot.isBackUnavailable__c);
            else if (fieldToCheck == 'BSF_Available__c') return (selectedSlot.BSF_Available__c > 0 && !selectedSlot.isBackUnavailable__c);
            else if (fieldToCheck == 'FSR_Available__c') return (selectedSlot.FSR_Available__c > 0 && !selectedSlot.IsFrontUnavailable__c);
            else if (fieldToCheck == 'FSF_Available__c') return (selectedSlot.FSF_Available__c > 0 && !selectedSlot.IsFrontUnavailable__c);
        }

        //-- If we are here then something went wrong
        throw new Appt_AppointmentException('System Error - Unable to check slot availability in isSlotAvailable() for fieldToCheck =' + fieldToCheck, Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR));
    }

    public static Appt_Time_Slot__c getTimeSlotBySite(String type, String siteId, Date appointmentDate, Datetime startTime) {
        System.debug(lprefix+'getTimeSlotBySite() ENTRY - type='+type+'. siteId='+siteId+', date='+appointmentDate+', startTime='+startTime);
        Appt_Time_Slot__c returnSlot;

        DateTime startTimeAll = Datetime.now(); 

        List<Appt_Time_Slot__c> foundSlots = [SELECT Type__c, BSF_Available__c, BSR_Available__c, BWF_Available__c, BWR_Available__c, FSF_Available__c, 
            FSR_Available__c, FWF_Available__c,  FWR_Available__c, Start_Time__c, End_Time__c, Date__c, IsFrontUnavailable__c, isBackUnavailable__c FROM Appt_Time_Slot__c 
            WHERE Type__c = :type AND Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :siteId AND Date__c = :appointmentDate AND Start_Time__c = :startTime LIMIT 1];
        System.debug(lprefix+'        foundSlots:'+foundSlots);

        if (foundSlots != null && foundSlots.size() > 0 && Appt_AppointmentUtil.checkConsolidateFleetCapacityFlag()) {
            /*Added as part of SO-856: Consolidate Fleet Buckets Start*/
            foundSlots=(List<Appt_Time_Slot__c>)Appt_AppointmentUtil.ConsolidateFleetCapacities(foundSlots);
            /*Added as part of SO-856: Consolidate Fleet Buckets End*/
            returnSlot = foundSlots.get(0);
        }

        Int_Values.addTiming('AvailHandler.getTimeSlotBySite',startTimeAll, Datetime.now());

        System.debug(lprefix+'getTimeSlotBySite() EXIT - returnSlot='+returnSlot);
        return returnSlot;
    }

    //-- this method will return all front or back slots that are contained fully within a start and end time. so if start = 11:59 and end = 12:41, the 12-12:20 and 12:20-12:40 slots are returned
    public static List<Appt_Time_Slot__c> getSlotsFromStartToEndTime(String type, String siteId, Date appointmentDate, Datetime startTime, Datetime endTime) {
        System.debug(lprefix+'getSlotsFromStartToEndTime() ENTRY - type='+type+'. siteId='+siteId+', date='+appointmentDate+', startTime='+startTime+', endTime='+endTime);

        DateTime startTimeAll = Datetime.now(); 
        //Appt 3.0 - Added Query to consume time slots based on custom time extension.
        List<Appt_Time_Slot__c> returnSlots;
        if (Appt_ConstantValues.isVisionFeature && type == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK) {
            returnSlots =[SELECT Type__c, BSF_Available__c, BSR_Available__c, 
                          BWF_Available__c, BWR_Available__c, 
                          FSF_Available__c, FSR_Available__c, 
                          FWF_Available__c,  FWR_Available__c,
                          Start_Time__c, 
                          End_Time__c, 
                          Date__c, IsFrontUnavailable__c, 
                          isBackUnavailable__c FROM Appt_Time_Slot__c WHERE Type__c = :type AND Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :siteId AND Date__c = :appointmentDate AND ((Start_Time__c >= :startTime AND End_Time__c <= :endTime) OR (Start_Time__c < :endTime AND End_Time__c >= :endTime) OR (Start_Time__c <= :startTime AND End_Time__c > :startTime))];
            System.debug(returnSlots +'myreturnslots');
                } else {
                    /*Modified as part of SO-856: Consolidate Fleet Buckets Added fleet capacity fields*/
                    returnSlots = [SELECT Type__c, BSF_Available__c, BSR_Available__c, BWF_Available__c, BWR_Available__c, FSF_Available__c, 
                                   FSR_Available__c, FWF_Available__c,  FWR_Available__c, Start_Time__c, End_Time__c, Date__c, IsFrontUnavailable__c, isBackUnavailable__c, 
                                   BSF_Capacity__c, FSF_Capacity__c, FWF_Capacity__c, BWF_Capacity__c FROM Appt_Time_Slot__c 
                                   WHERE Type__c = :type AND Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :siteId AND Date__c = :appointmentDate 
                                   AND (Start_Time__c >= :startTime AND End_Time__c <= :endTime)];
        }
        System.debug(lprefix+'  POST SOQL returnSlots:'+returnSlots);   //TODO - DEBUG - COMMENT OUT 

        if (returnSlots != null && Appt_AppointmentUtil.checkConsolidateFleetCapacityFlag()) 
        {
            /*Added as part of SO-856: Consolidate Fleet Buckets Start*/
            returnSlots=(List<Appt_Time_Slot__c>)Appt_AppointmentUtil.ConsolidateFleetCapacities(returnSlots);
            /*Added as part of SO-856: Consolidate Fleet Buckets End*/
        System.debug(lprefix+'getTimeSlotBySite() EXIT - number of returned Slot = '+returnSlots.size());
        }
        else System.debug(lprefix+'getTimeSlotBySite() EXIT - number of returned Slot = 0');

        Int_Values.addTiming('AvailHandler.getSlotsFromStartToEndTime',startTimeAll, Datetime.now());

        return returnSlots;
    }
    
    //Figure out what Work Type duration as well as type (back, front, both) is appropriate for the appointment
    public static Appt_workTypeModel calculateWorkType(Appt_GetAvailabilityServiceModel availModel){
        Appt_workTypeModel returnWorkType = new Appt_workTypeModel();

        DateTime startTimeAll = Datetime.now();

        if (availModel == null || String.isBlank(availModel.orderType) || String.isBlank(availModel.source)) {
            returnWorkType.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'required availModel, orderType or source parameter is null or blank');
            return returnWorkType;
        }
        System.debug(lprefix+'calculateWorkType() ENTRY - orderType='+availModel.orderType+', source='+availModel.source);

        // Get Custom Metadata to use to calulcate the work types
        List<Appt_Appointment_Slot_Calc_Setting__mdt> workTypeCalcs = [SELECT Order_Type__c, Source__c, Product_Items__c, Type__c, MasterLabel FROM Appt_Appointment_Slot_Calc_Setting__mdt 
                                                                    WHERE Order_Type__c = :availModel.orderType AND Source__c = :availModel.source];
        System.debug(lprefix+'       Retrieved Work Type Calculation metadata, workTypeInfo:'+workTypeCalcs);
        //SO-495
        Boolean  setWorkTypeasBoth = false;
        if (workTypeCalcs != null && workTypeCalcs.size() == 1) {

            returnWorkType.type = workTypeCalcs.get(0).Type__c;

            // Check for articles, and if present use type from any matching Product_Items__c in metadata. Otherwise use metadata type__c
            if (!String.isBlank(workTypeCalcs.get(0).Product_Items__c)) {
                List<String> productList = workTypeCalcs.get(0).Product_Items__c.split(',');

                if (productList != null && productList.size() > 0) {

                    List<String> types = new List<String>();

                    for (String productItem: productList) {
                        //productItem metadata has format 'articleId:type', with type being Front, Back or Both. For example '98911:Back'
                        List<String> productAndType = productItem.split(':');
                        String articleId = productAndType.get(0);
                        String type = productAndType.get(1);

                        // if the articeId/productId is a match, then put it's cooresponding type on the temporary storage list
                        if (availModel.isProductInItemList(articleId)) {
                            types.add(type);
                           //if type is both  then set the work type as Both below using this flag
                            if(type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH) {
                                setWorkTypeasBoth = true;
                            }
                       }

                    }

                    // Scan through list of types and set largest on model IF AND ONLY IF all items/articles are matches.
                    //  If there are items/articles in the list that do not match, meaning non-product items, then do not use product item type.
                    if (productList.size() == availModel.numberOfItems() || setWorkTypeasBoth) {
                        if (types.contains(Appt_ConstantValues.WORK_TYPE_TYPE_BOTH) || (types.contains(Appt_ConstantValues.WORK_TYPE_TYPE_FRONT) && types.contains(Appt_ConstantValues.WORK_TYPE_TYPE_BACK))) {
                            returnWorkType.type = Appt_ConstantValues.WORK_TYPE_TYPE_BOTH;
                        } else {
                            // to get here, types must only contain one type of types, even if multiple types

                            if (types.size() > 0) returnWorkType.type = types.get(0);
                        }
                    } else if (availModel.numberOfItems() == 0) {
                        //This is situation where the cusom metadata for work type has Product Items, however inbound parameters don't have any items in model items list
                        // According to Appointment Matrix , this results in "Nothing in the List, Articles Array is Empty = Always Back Room
                        returnWorkType.type = Appt_ConstantValues.WORK_TYPE_TYPE_BACK;
                    }
                } 
            }
            
            // Use returnWorkType.type to set front and back durations
            if (returnWorkType.type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT) {
                returnWorkType.frontOfficeDuration = Appt_ConstantValues.WORK_TYPE_DURATION_FRONT_DEFAULT;
                returnWorkType.backOfficeDuration = 0;

            } else if (returnWorkType.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK) {
                returnWorkType.frontOfficeDuration = 0;
                returnWorkType.backOfficeDuration = Appt_ConstantValues.WORK_TYPE_DURATION_BACK_DEFAULT;

            } else if (returnWorkType.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH) {
                returnWorkType.frontOfficeDuration = Appt_ConstantValues.WORK_TYPE_DURATION_FRONT_DEFAULT;
                returnWorkType.backOfficeDuration = Appt_ConstantValues.WORK_TYPE_DURATION_BACK_DEFAULT;
            }

        } else {
            //If we couldn't retrieve a single workTypeCalcs metadata record, then return error as we don't have the info we need to caluclate
            returnWorkType.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'Unable to rerieve Appt_Appointment_Slot_Calc_Setting__mdt metadata necessary to calulcation Work Types with orderType='+availModel.orderType);
            return returnWorkType;
        }

        returnWorkType.source = availModel.source;
        returnWorkType.customerType = availModel.customerType;
        returnWorkType.OrderType = availModel.orderType;

        Int_Values.addTiming('AvailHandler.calculateWorkType',startTimeAll, Datetime.now());

        System.debug(lprefix+'calculateWorkType() EXIT - returnWorkType:'+returnWorkType);
        return returnWorkType;
    }

    //get all appt time slots for a site
    public static List<Appt_Time_Slot__c> getTimeSlotsBySite(String siteId, Date startdate, Date endDate) {
        System.debug(lprefix+'getTimeSlotsBySite() ENTRY - siteId=' + siteId + ',startdate=' + startdate + ', endDate=' + endDate);

        if (String.isBlank(siteId)) throw new Appt_AppointmentException('BAD REQUEST - siteId parameter is null or blank', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));
        if (startdate == null || endDate ==  null || endDate < startdate)  throw new Appt_AppointmentException('BAD REQUEST - startDate and/or endDate parameter is null or endDate is less then startStart', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));

        List<Appt_Time_Slot__c> returnSlots = [SELECT Name, BSF_Capacity__c, BSF_Available__c, BSR_Capacity__c, BSR_Available__c, BWF_Capacity__c, BWF_Available__c,
                                                BWR_Capacity__c, BWR_Available__c, FSF_Capacity__c, FSF_Available__c, FSR_Capacity__c, FSR_Available__c, 
                                                FWF_Capacity__c, FWF_Available__c, FWR_Capacity__c, FWR_Available__c, Start_Time__c, End_Time__c, Date__c,
                                                Service_Territory__r.Site_Account__r.SAP_STORE_ID__c, IsFrontUnavailable__c, isBackUnavailable__c, Type__c FROM Appt_Time_Slot__c 
                                                WHERE Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :siteId AND Date__c >= :startdate AND Date__c <= :endDate ORDER BY Start_Time__c];

        System.debug(lprefix+'getTimeSlotsBySite() EXIT - returnSlots:' + returnSlots);
        /*Added as part of SO-856: Consolidate Fleet Buckets Start*/
        if(returnSlots!=null && returnSlots.size()>0 && Appt_AppointmentUtil.checkConsolidateFleetCapacityFlag())
        returnSlots=(List<Appt_Time_Slot__c>)Appt_AppointmentUtil.ConsolidateFleetCapacities(returnSlots);
        /*Added as part of SO-856: Consolidate Fleet Buckets End*/
        return returnSlots;
    }

    public static Boolean checkAvailability(Appt_GetAvailabilityServiceModel availModel){ 

        return checkAvailability(availModel, null);

    }
    
    //Check if a specific appointment slot is available. Used to confirm availability before creating or updating appointment
    public static Boolean checkAvailability(Appt_GetAvailabilityServiceModel availModel, Appt_workTypeModel WorkTypeModelParam){
        System.debug(lprefix+'checkAvailability() ENTRY - siteId='+availModel.siteId + ', appointmentDate='+availModel.appointmentDate+', consultStartTime='+availModel.consultStartTime+', backOfficeStartTime='+availModel.backOfficeStartTime);

        //start timer for performance loging
        DateTime startTimeAll = Datetime.now(); 

        //if availModel param is null throw exception
        if (availModel == null || availModel.appointmentDate == null) throw new Appt_AppointmentException('BAD REQUEST - availModel or appointmentDate parameter is null', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));

        //  1. If not already known, get Time Zon Offset for the store's timezone (Web Users will have the time zone of the Integration User)
        //LIMIT NOTE: 1 SOQL query
        if (availModel.timeZoneOffset == null || availModel.timeZoneOffset == 0) {
            availModel.timeZoneOffset = Appt_AppointmentUtil.getTimeZoneOffset(availModel.siteId, availModel.appointmentDate);
            //validate we have offset
            if (availModel.timeZoneOffset == null || availModel.timeZoneOffset == 0) {
                throw new Appt_AppointmentException('BAD REQUEST - could not retrieve timeZoneOffset for siteId='+availModel.siteId, Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));
            }
        }

        //  2. If not passed in param, caluclate work types and durations needed to find the right slots, otherwise use the model param
        Appt_workTypeModel wrkTypModel;
        if (WorkTypeModelParam != null && !String.isBlank(WorkTypeModelParam.type)) wrkTypModel = WorkTypeModelParam;
            else wrkTypModel = calculateWorkType(availModel);

        // Get the Appt_Time_Slot(s) for the appointment
        Appt_Time_Slot__c frontTimeSlot;
        Appt_Time_Slot__c backTimeSlot;
        Datetime startDateTime;

        Boolean returnIsAvailable = false;
        Datetime currentDatetimeGMT = Datetime.now();

        // In each IF, Valiate we have correct necessary front or back start times per Work Type, before proceeding with slot check logic below.
        if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_FRONT) {

            // FRONT - validate consultStartTime
            if (String.isBlank(availModel.consultStartTime)) throw new Appt_AppointmentException('BAD REQUEST - consultStartTime is required for Front Room Appointment ', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));
            
            startDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(availModel.appointmentDate), availModel.consultStartTime, availModel.timeZoneOffset);

            //DTA-221 - ensure that slot start time isn't in the past or current time at store
            if (startDateTime <= currentDatetimeGMT)  throw new Appt_AppointmentException('BAD REQUEST - Appointment start time cannot be in the past or at current time in the store', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));

            System.debug(lprefix+'FRONT With timeZoneOffset='+availModel.timeZoneOffset + 'got startDateTime='+startDateTime);
            frontTimeSlot = getTimeSlotBySite(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT, availModel.siteId, availModel.appointmentDate, startDateTime);
            returnIsAvailable = isSlotAvailable(frontTimeSlot, availModel.getBucketField(Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR));

        } else if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BACK) {
            
            // BACK - validate backOfficeStartTime
            if (String.isBlank(availModel.backOfficeStartTime)) throw new Appt_AppointmentException('BAD REQUEST - backOfficeStartTime is required for Back Room Appointment ', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));

            startDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(availModel.appointmentDate), availModel.backOfficeStartTime, availModel.timeZoneOffset);

            //DTA-221 - ensure that slot start time isn't in the past or current time at store
            if (startDateTime <= currentDatetimeGMT)  throw new Appt_AppointmentException('BAD REQUEST - Appointment start time cannot be in the past or at current time in the store', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));

            System.debug(lprefix+'BACK With timeZoneOffset='+availModel.timeZoneOffset + 'got startDateTime='+startDateTime);
            backTimeSlot = getTimeSlotBySite(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK, availModel.siteId, availModel.appointmentDate, startDateTime);
            returnIsAvailable = isSlotAvailable(backTimeSlot, availModel.getBucketField(Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR));

        } else if (wrkTypModel.type == Appt_ConstantValues.WORK_TYPE_TYPE_BOTH) {

            // BOTH - validate consultStartTime and backOfficeStartTime
            if (String.isBlank(availModel.consultStartTime) || String.isBlank(availModel.backOfficeStartTime)) throw new Appt_AppointmentException('BAD REQUEST - consultStartTime and backOfficeStartTime are required for Front and Back Room Appointment ', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));

            startDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(availModel.appointmentDate), availModel.consultStartTime, availModel.timeZoneOffset);

            //DTA-221 - ensure that slot start time isn't in the past or current time at store
            if (startDateTime <= currentDatetimeGMT)  throw new Appt_AppointmentException('BAD REQUEST - Appointment start time cannot be in the past or at current time in the store', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));

            System.debug(lprefix+'FRONT With timeZoneOffset='+availModel.timeZoneOffset + ' got startDateTime='+startDateTime);
            frontTimeSlot = getTimeSlotBySite(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT, availModel.siteId, availModel.appointmentDate, startDateTime);
            System.debug(backTimeSlot + '--FrontTimeSlotVandana');

            startDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(availModel.appointmentDate), availModel.backOfficeStartTime, availModel.timeZoneOffset);
            System.debug(lprefix+'BACK With timeZoneOffset='+availModel.timeZoneOffset + ' got startDateTime='+startDateTime);
            backTimeSlot = getTimeSlotBySite(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK, availModel.siteId, availModel.appointmentDate, startDateTime);
            System.debug(backTimeSlot + '--backTimeSlotVandana');

            // return true only if both slots are availble
            if (isSlotAvailable(frontTimeSlot, availModel.getBucketField(Appt_ConstantValues.APPOINTMENT_TYPE_FRONT_CHAR)) && isSlotAvailable(backTimeSlot, availModel.getBucketField(Appt_ConstantValues.APPOINTMENT_TYPE_BACK_CHAR))) {
                returnIsAvailable = true;
            }
        }

        Int_Values.addTiming('AvailHandler.Specific',startTimeAll, Datetime.now());

        System.debug(lprefix+'checkAvailability() EXIT - returnIsAvailable:'+returnIsAvailable);
        return returnIsAvailable;
    }
}