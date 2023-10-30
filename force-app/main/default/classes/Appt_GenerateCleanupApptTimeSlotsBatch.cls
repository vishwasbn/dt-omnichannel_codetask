/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This Batch is subtly different, it uses a default constructor for Scheduled batches that initializes local data lists.  For adhoc processing there is a constructor with pass parameters to initialize the local lists with specific Service Territories, store imports and a user email.  The start method creates a dynamic SOQL query based on the initialization of the lists that occurred in the constructors.  For the default constructor with no pass parameters, start creates a SOQL query to get all ServiceTerritory's that are Active, has a Site Account, the Site Account contains a Store ID AND the Last Slot Generated date has a date that is older than 31 days ago.  For the default constructor with pass parameters, start creates a SOQL query to get all ServiceTerritory's that are Active, AND included in the list of newServiceTerritoryIds.  For the default constructor with pass parameters, if no newServiceTerritoryIds exist in the list, set the LIMIT to 0, which effectively terminates the Batch.
 When the Batch executes, there are two phases, the Generation and the Cleanup.  The Generation of Appointment Time Slots is based on the number of stores, store hours, store capacity, and the resources.  The time slots are generated for the set number of days.  The Cleanup takes the store Ids and queries all Time Slots for those stores with dates before yesterday and deletes them.  There is a set limit on the number of Time slots deleted in each pass due to DML Limits.
 */
public class Appt_GenerateCleanupApptTimeSlotsBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents {
    private final String LOG_CLASS_NAME = 'Appt_GenerateCleanupApptTimeSlotsBatch';

    public static final String LPREFIX = 'Appt_BatchATS: ';
    public static Boolean isTest = false;

    public static final Decimal LIMIT_PERCENT = 0.85;
    public static final Integer MAX_SLOTS_TO_PROCESS = 7000;

    //lookupMaps
    private static Map<Id, Appt_OperatingHoursModel> storeHoursMap;
    private static Map<Id, Appt_OperatingHoursModel> storeCapacityTimeSlotsMap;
    private static Map<String, Map<String, List<Appt_Time_Slot_Capacity__c>>> storeCapacityOverrideMap;
    private static Map<Id, Datetime> storeMaxExistingApptTimeSlotDateMap;
    private static Set<Id> storesToProcessList;
    //private static Set<Id> storeOperatingHoursList; 

    public static Integer apptTimeSlotsNumberOfDays;

    //Automated Store Setup Import variables to track a List of Ids for new Service Territories, processed Store Setup Import Ids, and the User Email that kicked off the process
    private List<String> newServiceTerritoryIds;
    private List<String> processedStoreSetupImportIds;
    private String currentUserEmail;

    public Appt_GenerateCleanupApptTimeSlotsBatch()
    {
        newServiceTerritoryIds = new List<String>();
        processedStoreSetupImportIds = new List<String>();
    }

    public Appt_GenerateCleanupApptTimeSlotsBatch(List<String> newServiceTerritoryIds, List<String> processedStoreSetupImportIds, String currentUserEmail)
    {
        //Constructor used when kicking off this Batch during the Automated Store Setup Import process upon completion of the Appt_StoreSetupServiceTerritoryBatch process
        this.newServiceTerritoryIds = newServiceTerritoryIds;
        this.processedStoreSetupImportIds = processedStoreSetupImportIds;
        this.currentUserEmail = currentUserEmail;
    }

    public Database.QueryLocator start(Database.BatchableContext context)
    {
        apptTimeSlotsNumberOfDays = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_NUMBER_DAYS_APPT_TIME_SLOTS));
        Datetime maxDate = Date.today().addDays(apptTimeSlotsNumberOfDays);

        //Build the Service Territory query based on the Automated Store Setup Import variables having values or not
        String query = 'SELECT Id, Name, ParentTerritoryId, ParentTerritory.OperatingHoursId, OperatingHoursId, OperatingHours.TimeZone, Front_Time_Slot_Configuration__c, Back_Time_Slot_Configuration__c, ParentTerritory.Front_Time_Slot_Configuration__c, ParentTerritory.Back_Time_Slot_Configuration__c, Site_Account__c, Site_Account__r.SAP_STORE_ID__c, Date_Last_Slot_Generated__c FROM ServiceTerritory ';
        if (newServiceTerritoryIds.isEmpty() && processedStoreSetupImportIds.isEmpty() && String.isBlank(currentUserEmail)) {
            //If running this batch outside of the Automated Store Setup, then return active Service Territories that are mapped to Site Accounts (query used with the old Scheduled Job)
            query += 'WHERE IsActive = true AND Site_Account__c != null AND Site_Account__r.SAP_STORE_ID__c != null AND Date_Last_Slot_Generated__c != null AND Date_Last_Slot_Generated__c < ' + maxDate.format('yyyy-MM-dd') + ' ORDER BY Date_Last_Slot_Generated__c';
        } else if (!newServiceTerritoryIds.isEmpty()) {
            //If there are new Service Territories created as a result of the Automated Store Setup process, then return those records
            query += 'WHERE IsActive = true AND Id IN :newServiceTerritoryIds';
        } else {
            //If there are no new Service Territories created as a result of the Automated Store Setup process, then return 0 records
            query += 'LIMIT 0';
        }
        return Database.getQueryLocator(query);
    }

    //---Process to execute the Batch job
    public void execute(Database.BatchableContext bc, List<Object> scope)
    {
        System.debug('Start Appt_GenerateCleanupApptTimeSlotsBatch execute: ' + scope.size());

        processGenerateUpcomingApptTimeSlots((List<ServiceTerritory>)scope);

        Set<Id> storeIdSet = new Set<Id>();
        for (ServiceTerritory store : (List<ServiceTerritory>)scope) {
            storeIdSet.add( store.Id );
        }
        processCleanupPastApptTimeSlotsAndSpots(storeIdSet);

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug('End Appt_GenerateCleanupApptTimeSlotsBatch execute');
    }

    public void finish(Database.BatchableContext context)
    {
        //Check if there are any related Store Setup Import records that need to be updated and then possibly send a Summary Email (if this Batch was kicked off during the Automated Store Setup process)
        checkForRelatedStoreSetupImportsAndProcess();

        Id batchId = context.getJobId();
        System.debug( LPREFIX + '::finish: batchId: ' + batchId);

        //---Checking final status of the Job
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClassID, JobItemsProcessed, TotalJobItems, JobType, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchId];
        System.debug( LPREFIX + 'apexJob: ' + apexJob);
    }

    public static void processGenerateUpcomingApptTimeSlots(List<ServiceTerritory> activeStores) {
        System.debug(LPREFIX + 'processGenerateUpcomingApptTimeSlots() ENTRY');

        apptTimeSlotsNumberOfDays = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_NUMBER_DAYS_APPT_TIME_SLOTS));

        //System.debug(LPREFIX + '    POST SOQL activeStores:'+activeStores);

        if (activeStores != null && activeStores.size() > 0) {
            System.debug(LPREFIX + '   RETRIEVED ' +activeStores.size()+' active stores (Service Territory) with related Site Accounts -------------------------------');

            if (storesToProcessList == null) storesToProcessList = new Set<Id>();

            //--Loop through once to get list of store's siteIds to process, as well as their OperatingHours Ids
            for (ServiceTerritory store: activeStores) {
                
                System.debug(LPREFIX + '   STORE: ' +store.Name + '|' + store.Site_Account__r.SAP_STORE_ID__c + '|' +store.Id + '|' + store.Date_Last_Slot_Generated__c);
                storesToProcessList.add(store.Id);

            }
        } else {
            System.debug(LPREFIX + 'Appt_GenerateCleanupApptTimeSlotsBatch() NO STORES FOUND, EXITING!------------------------------- ');
            return;
        }
        
        populateOpHoursLookupMaps();
        populateCapacityOverrideMap();
        populateMaxExistingApptTimeSlotDateMap();
                       
        List<Appt_Time_Slot__c> slotsToInsert = new List<Appt_Time_Slot__c>();
        List<ServiceTerritory> storeUpdateList = new List<ServiceTerritory>();
        
        for (ServiceTerritory store: activeStores) {
        
            //---This has NO SOQL and NO DML
            generateFutureApptTimeSlotsforStore(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT, store, slotsToInsert);
            Datetime lastSlotDate = generateFutureApptTimeSlotsforStore(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK, store, slotsToInsert);
            
            //-- Update Date_Last_Slot_Generated__c on ServiceTerritory if a date is returned from generateFutureApptTimeSlotsforStore. 
            //    If null returned, then something went wrong and we weren't able to generate slots for the store
            if (lastSlotDate != null) {
                ServiceTerritory updateStore = new ServiceTerritory(Id=store.Id);
                updateStore.Date_Last_Slot_Generated__c = date.newinstance(lastSlotDate.year(), lastSlotDate.month(), lastSlotDate.day()); 
                storeUpdateList.add( updateStore);
            }
            
            if (slotsToInsert.size() > MAX_SLOTS_TO_PROCESS) {
                System.debug(LPREFIX + 'WARNING! slotsToInsert.size() > MAX_SLOTS_TO_PROCESS - Existing batch without inserting slots!');
                break;
            }
        }

        System.debug(LPREFIX + '!!!! slotsToInsert:'+slotsToInsert + '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'); //DEBUG
        System.debug(LPREFIX + '!!!! storeUpdateList:'+storeUpdateList); //DEBUG

        //-- INSERT SLOTS
        System.debug(LPREFIX + '   about to insert slotsToInsert with '+slotsToInsert.size()+' Appt_Time_Slot records');
        insert slotsToInsert;
        System.debug(LPREFIX + '   SUCCESSFULLY INSERTED slotsToInsert that span ' + activeStores.size() + ' stores');

        //-- UPDATE STORES
        System.debug(LPREFIX + '   about to update storeUpdateList with '+storeUpdateList.size()+' ServiceTerritory records');
        update storeUpdateList;
        System.debug(LPREFIX + '   SUCCESSFULLY UPDATED storeUpdateList');

        System.debug(LPREFIX + 'Appt_GenerateCleanupApptTimeSlotsBatch() EXIT');
    }

    public static Datetime generateFutureApptTimeSlotsforStore(String type, ServiceTerritory store, List<Appt_Time_Slot__c> slotsToInsert) {
        System.debug(LPREFIX + 'generateFutureApptTimeSlotsforStore() ENTRY - type:'+type+', # slotsToInsert = '+slotsToInsert.size() + '------------------------------------------------');  //DEBUG
        System.debug(LPREFIX + '      STORE:'+store);  //DEBUG
        
        StoreParams storeData = getStoreParams(type, store);

        if (storeData != null) {
            // Loop numDaysToPopulate times to create the Appt_Time_Slot records for the store
            System.debug(LPREFIX + '    numDaysToPopulate='+storeData.numDaysToPopulate + ', maxSlotDate = '+storeData.maxSlotDate);

            if (storeData.numDaysToPopulate > 0) {
                for(Integer i=0; i < storeData.numDaysToPopulate; i++){

                    // First date to create is one day later than existing slot max date
                    storeData.maxSlotDate = storeData.maxSlotDate.addDays(1);
                    
                    generateSlotsForStoreAndDay(storeData, store, slotsToInsert);
                    
                    //store.LastAvailabiltyCacl = datetimeltomday
                    if (slotsToInsert.size() > MAX_SLOTS_TO_PROCESS) return storeData.maxSlotDate;  
                }
            }
        } else {
            System.debug(LPREFIX + 'WARNING! Skipping store because cannot obtain necessary storeData, siteId='+store.Site_Account__r.SAP_STORE_ID__c);
            return null;
        }
        

        //System.debug(LPREFIX + 'generateFutureApptTimeSlotsforStore() EXIT - return maxSlotDate='+storeData.maxSlotDate);  //DEBUG
        return storeData.maxSlotDate;
    }

    private static void generateSlotsForStoreAndDay(StoreParams storeData, ServiceTerritory store, List<Appt_Time_Slot__c> slotsToInsert) {
        //System.debug(LPREFIX + 'generateSlotsForStoreAndDay() ENTRY - storeData:'+storeData); //DEBUG  
        String dayOfWeek = storeData.maxSlotDate.formatGMT('EEEE');

        System.debug(LPREFIX + '+++++++++ DAY being processed, DOW='+dayOfWeek + ', Date=' + storeData.maxSlotDate + ', DetGMT='+storeData.maxSlotDate.dateGMT());
        system.debug(' STORE HOUR MAP ===========***** >>>>>>>'+storeData);
        // Get store hours Slot and List of capacity Slots for the day of the week
        storeData.storeHoursSlot = storeData.storeHours.storeHoursPerWeekDayMap.get(dayOfWeek);
        storeData.capacitySlots = storeData.storeCapacitySlots.capacitySlotsPerWeekDayMap.get(dayOfWeek);
        storeData.timeZoneOffset = Appt_AppointmentUtil.getTimeZoneOffset( Timezone.getTimeZone( store.OperatingHours.TimeZone ), storeData.maxSlotDate);
        //System.debug('timeZoneOffset = ' + storeData.timeZoneOffset + ' for date ' + storeData.maxSlotDate + ' and Store with siteId=' + store.Site_Account__r.SAP_STORE_ID__c);  //DEBUG

        //-- convert store hours open and close times to GMT
        Datetime openTimeGMT = Appt_AppointmentUtil.convertTime(String.valueOf(storeData.maxSlotDate.dateGmt()), Appt_AppointmentUtil.formatTimeHHmm(storeData.storeHoursSlot.StartTime), storeData.timeZoneOffset);
        Datetime closeTimeGMT = Appt_AppointmentUtil.convertTime(String.valueOf(storeData.maxSlotDate.dateGmt()), Appt_AppointmentUtil.formatTimeHHmm(storeData.storeHoursSlot.EndTime), storeData.timeZoneOffset);

        //System.debug(LPREFIX + '>>>>>>>>>>>> openTimeGMT='+openTimeGMT+', closeTimeGMT='+closeTimeGMT); //DEBUG 

        if (storeData.capacitySlots != null && storeData.capacitySlots.size() > 0) {

            Appt_Time_Slot__c apptTimeSlot;
            
            // Loop through the capacitySlots
            for (TimeSlot capSlot: storeData.capacitySlots) {

                storeData.capOverriseSlot = getOverrideSlot(storeData.storeOverridesMap.get(dayOfWeek), storeData.storeHoursSlot, capSlot);
                storeData.useCapOverride = storeData.capOverriseSlot != null;

                //-- convert slot start and end times to GMT
                storeData.apptTime = Appt_AppointmentUtil.convertTime(String.valueOf(storeData.maxSlotDate.dateGmt()), Appt_AppointmentUtil.formatTimeHHmm(capSlot.StartTime), storeData.timeZoneOffset);
                Datetime endTime = Appt_AppointmentUtil.convertTime(String.valueOf(storeData.maxSlotDate.dateGmt()),Appt_AppointmentUtil.formatTimeHHmm(capSlot.EndTime), storeData.timeZoneOffset);
            
                //System.debug(LPREFIX + '>>>>>>>>>>>> openTimeGMT='+openTimeGMT+', storeData.apptTime='+storeData.apptTime+', endTime='+endTime+', closeTimeGMT='+closeTimeGMT+', useCapOverride='+storeData.useCapOverride); //DEBUG 

                //-- only create slots if the capacity slot falls inside of the store's store hours OperatingHours open and close times
                if (storeData.apptTime >= openTimeGMT && endTime <= closeTimeGMT) {

                    apptTimeSlot = new Appt_Time_Slot__c();

                    apptTimeSlot.Service_Territory__c = store.Id;
                    apptTimeSlot.Start_Time__c = storeData.apptTime; // Setting start and end time
                    apptTimeSlot.End_Time__c = endTime;
                    apptTimeSlot.Date__c = Date.newInstance(storeData.apptTime.year(), storeData.apptTime.month(), storeData.apptTime.day());
                    apptTimeSlot.Type__c = storeData.isFrontSlot ? Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT : Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK;

                    
                    
                    
                    //--- Set buckets depending on Front or Back, as well as useCapOverride boolean. If back, set front buckets to 0, and vise versa.
                    if (storeData.isFrontSlot) {
                        apptTimeSlot.FSF_Capacity__c = storeData.useCapOverride ? storeData.capOverriseSlot.FSF_Capacity__c : capSlot.FSF_Capacity__c;
                        apptTimeSlot.FSR_Capacity__c = storeData.useCapOverride ? storeData.capOverriseSlot.FSR_Capacity__c : capSlot.FSR_Capacity__c;
                        apptTimeSlot.FWF_Capacity__c = storeData.useCapOverride ? storeData.capOverriseSlot.FWF_Capacity__c : capSlot.FWF_Capacity__c;
                        apptTimeSlot.FWR_Capacity__c = storeData.useCapOverride ? storeData.capOverriseSlot.FWR_Capacity__c : capSlot.FWR_Capacity__c;
                        apptTimeSlot.BSF_Capacity__c = 0;
                        apptTimeSlot.BSR_Capacity__c = 0;
                        apptTimeSlot.BWF_Capacity__c = 0;
                        apptTimeSlot.BWR_Capacity__c = 0;

                        //-- check if there is a resource absence in place for this Appt_Time_Slot__c
                        if (isThereResourceAbsenceForSlot(storeData, apptTimeSlot)) {
                            apptTimeSlot.IsFrontUnavailable__c = true;
                            //System.debug(LPREFIX + '>>>>>>>>> Setting apptTimeSlot.IsFrontUnavailable__c = TRUE <<<<<<<<<<'); //DEBUG  
                        }
                    }
                    if (storeData.isBackSlot) {
                        apptTimeSlot.BSF_Capacity__c = storeData.useCapOverride ? storeData.capOverriseSlot.BSF_Capacity__c : capSlot.BSF_Capacity__c;
                        apptTimeSlot.BSR_Capacity__c = storeData.useCapOverride ? storeData.capOverriseSlot.BSR_Capacity__c : capSlot.BSR_Capacity__c;
                        apptTimeSlot.BWF_Capacity__c = storeData.useCapOverride ? storeData.capOverriseSlot.BWF_Capacity__c : capSlot.BWF_Capacity__c;
                        apptTimeSlot.BWR_Capacity__c = storeData.useCapOverride ? storeData.capOverriseSlot.BWR_Capacity__c : capSlot.BWR_Capacity__c;
                        apptTimeSlot.FSF_Capacity__c = 0;
                        apptTimeSlot.FSR_Capacity__c = 0;
                        apptTimeSlot.FWF_Capacity__c = 0;
                        apptTimeSlot.FWR_Capacity__c = 0;

                        //-- check if there is a resource absence in place for this Appt_Time_Slot__c
                        if (isThereResourceAbsenceForSlot(storeData, apptTimeSlot)) {
                            apptTimeSlot.isBackUnavailable__c = true;
                            //System.debug(LPREFIX + '>>>>>>>>> Setting apptTimeSlot.isBackUnavailable__c = TRUE <<<<<<<<<<'); //DEBUG  
                        }
                    }          
                } else {
                    apptTimeSlot = null;
                }    
                
                if (apptTimeSlot != null) {
                    //System.debug(LPREFIX + ' !!!! apptTimeSlot:'+apptTimeSlot);   //DEBUG    
                    slotsToInsert.add(apptTimeSlot);
                }

                // reset for next loop
                storeData.capOverriseSlot = null;
                storeData.useCapOverride = false;
            }
        }

    }

    private static Boolean isThereResourceAbsenceForSlot(StoreParams storeData, Appt_Time_Slot__c apptTimeSlot) {
        //System.debug(LPREFIX + 'isThereResourceAbsenceForSlot() ENTRY - apptTimeSlot:'+apptTimeSlot +', storeData:'+storeData);  //DEBUG
        Boolean returnBoolean = false;

        if (apptTimeSlot != null && storeData != null && storeData.storeAbsences != null && storeData.storeAbsences.size() > 0) {
            for (ResourceAbsence resAbs: storeData.storeAbsences) {

                //-- check if the capSlot falls inside start and end of a ResourceAbsence, and if so return TRUE
                if (resAbs.Start <= apptTimeSlot.Start_Time__c && resAbs.End >= apptTimeSlot.End_Time__c) {
                    returnBoolean = true;
                    break;
                }
            }
        }

        //System.debug(LPREFIX + 'isThereResourceAbsenceForSlot() EXIT - returnBoolean='+returnBoolean);  //DEBUG
        return returnBoolean;
    }

    private static StoreParams getStoreParams(String type, ServiceTerritory store) {
        System.debug(LPREFIX + 'getStoreParams() ENTRY - type:'+type +', store:'+store);  //DEBUG

        StoreParams returnInfo = new StoreParams();
        returnInfo.serviceTerritoryId = store.Id;
        returnInfo.slotType = type;

        //-- validations
        if (storeHoursMap == null) {
            // No Store Hours OperatingHours found, log warning and return from method as this Store (ServiceTerritory) isn't configured correctly
            System.debug(LPREFIX + 'WARNING! getStoreParams() - storeHoursMap == null, returning null');
            return null;
        }
        if (storeCapacityTimeSlotsMap == null) {
            // No bucket capicity OperatingHours found, log warning and return from method as this Store (ServiceTerritory) isn't configured correctly
            System.debug(LPREFIX + 'WARNING! getStoreParams() - storeCapacityTimeSlotsMap == null, returning null');
            return null;
        }

        // 1. get Store Hours Operating Hours
        returnInfo.storeHours = storeHoursMap.get(store.OperatingHoursId);

        // 2. get any store overrides (Appt_Time_Slot_Capacity__c), which can be blank
        returnInfo.storeOverridesMap = storeCapacityOverrideMap != null ? storeCapacityOverrideMap.get(store.Id) : new Map<String, List<Appt_Time_Slot_Capacity__c>>() ;
        if (returnInfo.storeOverridesMap == null) returnInfo.storeOverridesMap = new Map<String, List<Appt_Time_Slot_Capacity__c>>();

        // 3. get the bucket capacity time slots OperatingHours for FRONT or for BACK depending on type param
        if (type == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT) {

            //-- FRONT SLOT -------
            returnInfo.isFrontSlot = true;
            returnInfo.isBackSlot = false;

            //-- get FRONT bucket capacity time slots OperatingHours
            returnInfo.storeCapacitySlots = storeCapacityTimeSlotsMap.get(store.Front_Time_Slot_Configuration__c);
            // make sure we have bucket capacity time slots OperatingHours.
            if (returnInfo.storeCapacitySlots == null || returnInfo.storeCapacitySlots.type != Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY) {
                returnInfo.storeCapacitySlots = storeCapacityTimeSlotsMap.get(store.ParentTerritory.Front_Time_Slot_Configuration__c);
            }
            //  If store does NOT have bucket capacity time slots OperatingHours, check parent Territory
            if (returnInfo.storeCapacitySlots == null || returnInfo.storeCapacitySlots.type != Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY) {

                // No bucket capacity time slots OperatingHours found, log warning and return from method as this Store (ServiceTerritory) isn't configured correctly
                System.debug(LPREFIX + 'WARNING! Unable to get FRONT bucket capacity time slots OperatingHours for siteId='+store.Site_Account__r.SAP_STORE_ID__c);
                return null;
            }
        } else if (type == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK) {

            //-- BACK SLOT -------
            returnInfo.isFrontSlot = false;
            returnInfo.isBackSlot = true;

            //-- get BACK bucket capacity time slots OperatingHours
            returnInfo.storeCapacitySlots = storeCapacityTimeSlotsMap.get(store.Back_Time_Slot_Configuration__c);
            // make sure we have bucket capacity time slots OperatingHours.
            if (returnInfo.storeCapacitySlots == null || returnInfo.storeCapacitySlots.type != Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY) {
                returnInfo.storeCapacitySlots = storeCapacityTimeSlotsMap.get(store.ParentTerritory.Back_Time_Slot_Configuration__c);
            }
            //  If store does NOT have bucket capacity time slots OperatingHours, check parent Territory
            if (returnInfo.storeCapacitySlots == null || returnInfo.storeCapacitySlots.type != Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY) {

                // No bucket capacity time slots OperatingHours found, log warning and return from method as this Store (ServiceTerritory) isn't configured correctly
                System.debug(LPREFIX + 'WARNING! Unable to get BACK bucket capacity time slots OperatingHours for siteId='+store.Site_Account__r.SAP_STORE_ID__c);
                return null;
            }
        } else {
            System.debug(LPREFIX + 'WARNING! getStoreParams() - type param does not contain proper value to determine if FRONT or BACK. type='+type);
            return null;
        }

        //--get any resource absences for the store
        returnInfo.storeAbsences = getResourceAbsences(store.Id, type);

        // Figure out how many days of Appt_Time_Slots need to be created for the store, probably only 1 day
        if (storeMaxExistingApptTimeSlotDateMap != null) returnInfo.maxSlotDate = storeMaxExistingApptTimeSlotDateMap.get(store.Id);
        if (returnInfo.maxSlotDate == null || returnInfo.maxSlotDate < Date.today()) returnInfo.maxSlotDate =  Date.today();
        returnInfo.numberDaysSlotsExisting = Date.today().daysBetween(returnInfo.maxSlotDate.dateGmt());
        returnInfo.numDaysToPopulate = apptTimeSlotsNumberOfDays - returnInfo.numberDaysSlotsExisting;
        returnInfo.timeZoneOffset = Appt_AppointmentUtil.getTimeZoneOffset( Timezone.getTimeZone( store.OperatingHours.TimeZone ), returnInfo.maxSlotDate);
        System.debug('STORE timeZoneOffset = ' + returnInfo.timeZoneOffset + ' for date ' + returnInfo.maxSlotDate + ' and Store with siteId=' + store.Site_Account__r.SAP_STORE_ID__c);

        System.debug(LPREFIX + 'getStoreParams() EXIT - returnInfo:'+returnInfo);
        return returnInfo;
    }

    //-- Get any existing ResourceAbsence records for the store for either FRONT or BACK
    private static List<ResourceAbsence> getResourceAbsences(Id serviceTerritoryId, String type) {
        System.debug(LPREFIX + 'getResourceAbsences() ENTRY - serviceTerritoryId='+serviceTerritoryId);

        if (String.isBlank(serviceTerritoryId)) return null;

        List<ResourceAbsence> returnList;

        //-- SOQL to get Resource Absences for the service resource IDs retrieved in previos SOQL
        // LIMIT: 1 SOQL per Store
        List<ResourceAbsence> absences = [SELECT Id, Start, End, ResourceId, Resource.Type__c FROM ResourceAbsence 
                    WHERE Start > :Datetime.now() AND Resource.Type__c = :type AND ResourceId IN (
                    SELECT ServiceResourceId FROM ServiceTerritoryMember  WHERE ServiceTerritoryId = :serviceTerritoryId)];

        if (absences != null && absences.size() > 0) {

            returnList = new List<ResourceAbsence>();

            for (ResourceAbsence abs: absences) {
                returnList.add(abs);
            }
        }

        System.debug(LPREFIX + 'getResourceAbsences() EXIT - returnList:'+returnList);
        return returnList;
    }

    
    //---Get the Override slot if there is one for the day of the week
    private static Appt_Time_Slot_Capacity__c getOverrideSlot(List<Appt_Time_Slot_Capacity__c> storeOverrides, TimeSlot storeHoursSlot, TimeSlot capSlot) {
        //System.debug(LPREFIX + 'getOverrideSlot() ENTRY - storeOverrides:'+storeOverrides);  //DEBUG

        //- if stores override list null exit immediately
        if (storeOverrides == null || storeOverrides.size() == 0) return null;

        //System.debug(LPREFIX + 'capSlot:'+capSlot);  //DEBUG
        //System.debug(LPREFIX + 'storeHoursSlot:'+storeHoursSlot);  //DEBUG
        
        Appt_Time_Slot_Capacity__c capOverriseSlot = null;
    
        // make sure capacity slot falls within the store's store hours 
        if (capSlot.StartTime >= storeHoursSlot.StartTime && capSlot.StartTime <= storeHoursSlot.EndTime) {

            //System.debug(LPREFIX + 'INSIDE STORE HOURS IF');   //DEBUG
            
            // If not null, Loop through storeOverrides List to see if a capacity overrise exists for the day of week and time of day.
            if (storeOverrides != null && storeOverrides.size() > 0) {
                for (Appt_Time_Slot_Capacity__c capOverride: storeOverrides) {
                    if (capOverride.Day_of_Week__c == capSlot.DayOfWeek && capSlot.StartTime >= capOverride.Start_Time__c && capSlot.EndTime <= capOverride.End_Time__c) {
                        capOverriseSlot = capOverride;
                        //---Only the first Overide matching the time slot will be used
                        //System.debug(LPREFIX + '    MATCH!!! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');   //DEBUG
                        break;
                    }
                    //System.debug(LPREFIX + '    NO MATCH ====');   //DEBUG
                }
            }
        }
                            
        //System.debug(LPREFIX + 'getOverrideSlot() EXIT - capOverriseSlot:'+capOverriseSlot);  //DEBUG
        return capOverriseSlot;
    }

    private static void populateMaxExistingApptTimeSlotDateMap() {
        //System.debug(LPREFIX + 'populateMaxExistingApptTimeSlotDateMap() ENTRY');

        // LIMIT: 1 SOQL per batch run
        List<AggregateResult> maxStoreSlotList = [SELECT Service_Territory__c, MAX(Date__c)maxDate FROM Appt_Time_Slot__c 
                WHERE Service_Territory__c IN :storesToProcessList AND End_Time__c >= TODAY GROUP BY Service_Territory__c];

        if (maxStoreSlotList != null && maxStoreSlotList.size() > 0) {
            for (AggregateResult maxSlot: maxStoreSlotList) {

                if (storeMaxExistingApptTimeSlotDateMap == null) storeMaxExistingApptTimeSlotDateMap = new Map<Id, Datetime>();
                storeMaxExistingApptTimeSlotDateMap.put((Id)maxSlot.get('Service_Territory__c'), (Datetime)maxSlot.get('maxDate'));
            }
        }
        System.debug(LPREFIX + 'populateMaxExistingApptTimeSlotDateMap() EXIT - storeMaxExistingApptTimeSlotDateMap:'+storeMaxExistingApptTimeSlotDateMap);
    }

    private static void populateCapacityOverrideMap() {
        //System.debug(LPREFIX + 'populateCapacityOverrideMap() ENTRY');

        Id serviceTerritoryId;
        String dayOfWeek;
        List<Appt_Time_Slot_Capacity__c> storeOverrides;
        Map<String, List<Appt_Time_Slot_Capacity__c>> dayOfWeekStoreOverrideMap;
        
        // LIMIT: 1 SOQL per batch run
        List<Appt_Time_Slot_Capacity__c> capacityOverrides = [SELECT  BSF_Capacity__c, BSR_Capacity__c, BWR_Capacity__c, BWF_Capacity__c, 
            FSF_Capacity__c, FSR_Capacity__c, FWF_Capacity__c, FWR_Capacity__c, Day_of_Week__c, End_Time__c, Start_Time__c, Service_Territory__c  
            FROM Appt_Time_Slot_Capacity__c WHERE Service_Territory__c IN :storesToProcessList ORDER BY Service_Territory__c, Day_of_Week__c, Start_Time__c];

        if (capacityOverrides != null && capacityOverrides.size() > 0) {
            /*Added as part of SO-856: Consolidate Fleet Buckets Start*/
            if(Appt_AppointmentUtil.isFleetCapacityConsolidated())
            {
                capacityOverrides=(List<Appt_Time_Slot_Capacity__c>)Appt_AppointmentUtil.consolidateFleetCapacities(capacityOverrides);
                System.debug('capacityOverrides>>>>'+capacityOverrides);
            }
            /*Added as part of SO-856: Consolidate Fleet Buckets End*/
            //System.debug(LPREFIX + '   ------Capacity Override LOOP with '+capacityOverrides.size()+' items in list------');   //DEBUG

            Integer count = 0;
            Boolean lastRecord = false;
            if (storeCapacityOverrideMap == null) storeCapacityOverrideMap = new Map<String, Map<String, List<Appt_Time_Slot_Capacity__c>>>();

             //-- loop through list and build Map with serviceTerritoryId as key
            for (Appt_Time_Slot_Capacity__c capOverride: capacityOverrides) {
                
                count++;
                if (count == capacityOverrides.size()) lastRecord = true;
                //System.debug(LPREFIX + count + '  loop+++++++++++++++++++= lastRecord='+lastRecord+':'+capOverride);   //DEBUG

                //-- FIRST LOOP - SETUP
                if (serviceTerritoryId == null) {

                    // FIRST TIME through loop, create storeOverrides List for the day of week
                    serviceTerritoryId = capOverride.Service_Territory__c;
                    storeOverrides = new List<Appt_Time_Slot_Capacity__c>();

                    //-- instantiate map for day of the week in the Appt_Time_Slot_Capacity__c
                    dayOfWeek = capOverride.Day_of_Week__c;
                    dayOfWeekStoreOverrideMap = new Map<String, List<Appt_Time_Slot_Capacity__c>>();
                    //System.debug(LPREFIX + '    FIRST loop:'+dayOfWeek+':'+serviceTerritoryId);   //DEBUG

                }

                //--PROCESS LOOP - if different store this loop
                if (serviceTerritoryId != capOverride.Service_Territory__c) {

                    // This is DIFFERENT STORE, so add to Map
                    dayOfWeekStoreOverrideMap.put(dayOfWeek, storeOverrides);
                    //System.debug(LPREFIX + '    NEW STORE loop, put on map:'+dayOfWeek+':'+storeOverrides);   //DEBUG
                    storeCapacityOverrideMap.put(serviceTerritoryId, dayOfWeekStoreOverrideMap);
                    //System.debug(LPREFIX + '    NEW STORE, put on storeCapacityOverrideMap:'+serviceTerritoryId+':'+dayOfWeekStoreOverrideMap);   //DEBUG

                    //crate new list for next store
                    serviceTerritoryId = capOverride.Service_Territory__c;
                    storeOverrides = new List<Appt_Time_Slot_Capacity__c>();
                    storeOverrides.add(capOverride);

                    //-- instantiate map for day of the week in the Appt_Time_Slot_Capacity__c
                    dayOfWeek = capOverride.Day_of_Week__c;
                    dayOfWeekStoreOverrideMap = new Map<String, List<Appt_Time_Slot_Capacity__c>>();
                    //dayOfWeekStoreOverrideMap.put(dayOfWeek, storeOverrides);
                    //System.debug(LPREFIX + '    NEW STORE loop, setup new map:'+serviceTerritoryId+'--'+dayOfWeek+':'+storeOverrides);   //DEBUG

                    //--PROCESS LOOP - same store
                } else {
                    //-- This is SAME STORE, figure out if same or different day of the week
                    if (capOverride.Day_of_Week__c != dayOfWeek) {

                        //-- DIFFERENT DayOfWeek, add List to Map for DayOfWeek and instantiate new List
                        dayOfWeekStoreOverrideMap.put(dayOfWeek, storeOverrides);
                        //System.debug(LPREFIX + '    NEW DAY loop, put on map:'+dayOfWeek+':'+storeOverrides);   //DEBUG
                        storeOverrides = new List<Appt_Time_Slot_Capacity__c>();
                        dayOfWeek = capOverride.Day_of_Week__c;

                        //System.debug(LPREFIX + '    NEW DAY :'+dayOfWeek);   //DEBUG
                    } 

                    //-- same store, put on LIST
                    storeOverrides.add(capOverride);

                    //System.debug(LPREFIX + '    --SAME STORE loop:'+dayOfWeek+':'+storeOverrides);   //DEBUG
                }

                //-- LAST LOOP - clean up
                if (lastRecord) {
                    // This is last override, so add to Map
                    dayOfWeekStoreOverrideMap.put(dayOfWeek, storeOverrides);
                    //System.debug(LPREFIX + '    NEW DAY loop, put on map:'+dayOfWeek+':'+storeOverrides);   //DEBUG

                    storeCapacityOverrideMap.put(serviceTerritoryId, dayOfWeekStoreOverrideMap);
                    //System.debug(LPREFIX + '    LAST ROW loop, put on storeCapacityOverrideMap:'+serviceTerritoryId+':'+dayOfWeekStoreOverrideMap);   //DEBUG
                }
            }
        }

        //-- TODO REMOVE or COMENT OUT BELOW loop which is only for logging -----------
        if (storeCapacityOverrideMap != null) {
            for (String storeId: storeCapacityOverrideMap.keySet()) {
                System.debug(LPREFIX + 'storeId:'+storeId);
                Map<String, List<Appt_Time_Slot_Capacity__c>> dayOfWeekStoreOverrideMp = storeCapacityOverrideMap.get(storeId);
                
                    if (dayOfWeekStoreOverrideMp != null) {
                        for (String day: dayOfWeekStoreOverrideMp.keySet()) {
                            System.debug(LPREFIX + 'day:'+day);
                            List<Appt_Time_Slot_Capacity__c> lst = dayOfWeekStoreOverrideMp.get(day);
                            if (lst != null) {
                                for (Appt_Time_Slot_Capacity__c cap: lst) {
                                    System.debug(LPREFIX + 'Appt_Time_Slot_Capacity__c:'+cap);
                                }
                            }
                        }
                    }
            }
        }

        System.debug(LPREFIX + 'populateCapacityOverrideMap() EXIT - storeCapacityOverrideMap:'+storeCapacityOverrideMap);
    }


    private static void populateOpHoursLookupMaps() {
        //System.debug(LPREFIX + 'populateOpHoursLookupMaps() ENTRY');

        Id currentOperatingHoursId;
        Appt_OperatingHoursModel currentOpHour;

        // LIMIT: 1 SOQL per batch run
        List<TimeSlot> allTimeSlots = [SELECT OperatingHoursId, DayOfWeek, StartTime, EndTime, OperatingHours.Name, OperatingHours.TimeZone, 
            OperatingHours.Type__c, BSF_Capacity__c, BSR_Capacity__c, BWF_Capacity__c, BWR_Capacity__c, FSF_Capacity__c, FSR_Capacity__c, FWF_Capacity__c, FWR_Capacity__c 
            FROM TimeSlot 
            WHERE OperatingHours.Type__c = :Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS OR OperatingHours.Type__c = :Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY 
            ORDER BY OperatingHoursId, DayOfWeek, StartTime ];

        Integer count = 0;
        Boolean lastRecord = false;


        if (allTimeSlots != null && allTimeSlots.size() > 0) {

            if (storeHoursMap == null) storeHoursMap = new Map<Id, Appt_OperatingHoursModel>();
            if (storeCapacityTimeSlotsMap == null) storeCapacityTimeSlotsMap = new Map<Id, Appt_OperatingHoursModel>();

            for (TimeSlot slot: allTimeSlots) {

                count++;
                if (count == allTimeSlots.size()) lastRecord = true;

                // identify if this is same OperatingHours or new one, and process accordingly
                if (currentOperatingHoursId == null) {

                    //first time through loop, create Appt_OperatingHoursModel
                    currentOperatingHoursId = slot.OperatingHoursId;
                    currentOpHour = new Appt_OperatingHoursModel(slot.OperatingHoursId, slot.OperatingHours.Type__c);
                    currentOpHour.addTimeSlot(slot);
                }

                if (currentOperatingHoursId != slot.OperatingHoursId) {

                    // If in here, then this is a new OperatingHours record, so save current Appt_OperatingHoursModel to map and instantiate new Appt_OperatingHoursModel object
                    if (currentOpHour.type == Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS) {

                        storeHoursMap.put(currentOperatingHoursId, currentOpHour);
                        //System.debug('  PUT following on storeHoursMap, currentOpHour:'+currentOpHour);  //DEBUG

                    } else if (currentOpHour.type == Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY) {

                        storeCapacityTimeSlotsMap.put(currentOperatingHoursId, currentOpHour);
                        //System.debug('  PUT following on storeCapacityTimeSlotsMap, currentOpHour:'+currentOpHour);  //DEBUG
                    }
                    
                    //now create Appt_OperatingHoursModel
                    currentOperatingHoursId = slot.OperatingHoursId;
                    currentOpHour = new Appt_OperatingHoursModel(slot.OperatingHoursId, slot.OperatingHours.Type__c);
                    currentOpHour.addTimeSlot(slot);

                } else {

                    // Same OperatingHours record, so add Slot to current Appt_OperatingHoursModel object
                    currentOpHour.addTimeSlot(slot);
                }

                if (lastRecord) {
                    // last row, put on map
                    if (currentOpHour.type == Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS) {

                        storeHoursMap.put(currentOperatingHoursId, currentOpHour);
                        //System.debug('  PUT following on storeHoursMap, currentOpHour:'+currentOpHour);  //DEBUG

                    } else if (currentOpHour.type == Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY) {
                        
                        storeCapacityTimeSlotsMap.put(currentOperatingHoursId, currentOpHour);
                        //System.debug('  PUT following on storeCapacityTimeSlotsMap, currentOpHour:'+currentOpHour);  //DEBUG
                    }
                }
            }
        }

        if (storeHoursMap != null) {
            System.debug('  storeHoursMap.size()='+storeHoursMap.size()+', storeHoursMap:'+storeHoursMap);  //DEBUG
        } else {
            System.debug('  storeHoursMap = NULL !!!!!!!!!!!!!!!!!!!!!!!!!!!!');  //DEBUG
        }

        if (storeCapacityTimeSlotsMap != null) {
            System.debug('  storeCapacityTimeSlotsMap.size()='+storeCapacityTimeSlotsMap.size()+', storeCapacityTimeSlotsMap:'+storeCapacityTimeSlotsMap);  //DEBUG
        } else {
            System.debug('  storeCapacityTimeSlotsMap = NULL !!!!!!!!!!!!!!!!!!!!!!!!!!!!');  //DEBUG
        }
        System.debug(LPREFIX + 'populateOpHoursLookupMaps() EXIT');
    }

    // This is autonomous, it is used by LWC
    @AuraEnabled
    public static String generateAllSlotsForStore(String serviceTerritoryId) {
        System.debug(LPREFIX + 'generateAllSlotsForStore() ENTRY - serviceTerritoryId='+serviceTerritoryId);

        if (String.isBlank(serviceTerritoryId)) return JSON.serialize(new ResultWrapper(serviceTerritoryId, 'serviceTerritoryId is blank or null', Appt_ConstantValues.RESPONSE_STATUS_ERROR));

        apptTimeSlotsNumberOfDays = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_NUMBER_DAYS_APPT_TIME_SLOTS));

        ServiceTerritory store;
        List<Appt_Time_Slot__c> slotsToInsert = new List<Appt_Time_Slot__c>();
        if (storesToProcessList == null) storesToProcessList = new Set<Id>();
        //if (storeOperatingHoursList == null) storeOperatingHoursList = new Set<Id>();

        //-- get store data
        // LIMIT: 1 SOQL per Action Button
        List<ServiceTerritory> stores = [SELECT Id, Name, ParentTerritoryId, ParentTerritory.OperatingHoursId, OperatingHoursId, OperatingHours.TimeZone, Front_Time_Slot_Configuration__c, Back_Time_Slot_Configuration__c, 
                ParentTerritory.Front_Time_Slot_Configuration__c, ParentTerritory.Back_Time_Slot_Configuration__c, Site_Account__c, Site_Account__r.SAP_STORE_ID__c
                FROM ServiceTerritory WHERE IsActive = TRUE AND Id = :serviceTerritoryId];
                
        if (stores != null && stores.size() == 1) {
            store = stores.get(0);
            storesToProcessList.add(store.Id);
            //storeOperatingHoursList.add(store.OperatingHoursId);
            //storeOperatingHoursList.add(store.Front_Time_Slot_Configuration__c);
            //storeOperatingHoursList.add(store.Back_Time_Slot_Configuration__c);
        } else {
            if (stores == null || stores.size() == 0) return JSON.serialize(new ResultWrapper(serviceTerritoryId, 'Unable to retrieve ServiceTerritory record with serviceTerritoryId. Please ensure that the ServiceTerritory is configured correctly. serviceTerritoryId='+serviceTerritoryId, Appt_ConstantValues.RESPONSE_STATUS_ERROR));
            else return JSON.serialize(new ResultWrapper(serviceTerritoryId, 'Retrieved more than one ServiceTerritory record with serviceTerritoryId. Please ensure that the ServiceTerritory is configured correctly. serviceTerritoryId='+serviceTerritoryId, Appt_ConstantValues.RESPONSE_STATUS_ERROR));
        }
        
        //-- If any, get capacity overrides for the store
        populateCapacityOverrideMap();
        populateOpHoursLookupMaps();
        populateMaxExistingApptTimeSlotDateMap();


        //---This has NO SOQL and NO DML
        generateFutureApptTimeSlotsforStore(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT, store, slotsToInsert);
        Datetime lastSlotDate = generateFutureApptTimeSlotsforStore(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK, store, slotsToInsert);

        //-- INSERT SLOTS
        System.debug(LPREFIX + '   about to insert slotsToInsert with '+slotsToInsert.size()+' Appt_Time_Slot records for serviceTerritoryId:'+serviceTerritoryId);
        insert slotsToInsert;
        System.debug(LPREFIX + '   SUCCESSFULLY INSERTED slotsToInsert');

        //-- Update Date_Last_Slot_Generated__c on ServiceTerritory if a date is returned from generateFutureApptTimeSlotsforStore. 
        //    If null returned, then something went wrong and we weren't able to generate slots for the store
        if (lastSlotDate != null) {
            ServiceTerritory updateStore = new ServiceTerritory(Id=store.Id);
            updateStore.Date_Last_Slot_Generated__c = date.newinstance(lastSlotDate.year(), lastSlotDate.month(), lastSlotDate.day()); 
            update updateStore;

            //Update Time Slot Creation Status on related Store Setup Import if it exists and is not already marked as Complete
            List<Store_Setup_Import__c> incompleteStoreSetupImportList = [SELECT Id FROM Store_Setup_Import__c WHERE Service_Territory__c = :store.Id AND Time_Slot_Creation_Status__c != :Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED];
            if (!incompleteStoreSetupImportList.isEmpty()) {
                Store_Setup_Import__c incompleteStoreSetupImport = incompleteStoreSetupImportList[0];
                incompleteStoreSetupImport.Time_Slot_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED;
                incompleteStoreSetupImport.Time_Slot_Creation_Message__c = '';
                update incompleteStoreSetupImport;
            }
        }   
        
        //-- build SUCCESS ResultWrapper to return
        ResultWrapper result = new ResultWrapper();
        result.dateMaxSlot = lastSlotDate;
        result.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;
        result.recordId = serviceTerritoryId;
        
        System.debug(LPREFIX + 'generateAllSlotsForStore() EXIT - ResultWrapper:'+result);
        return JSON.serialize(result);
    }

    public static void processCleanupPastApptTimeSlotsAndSpots( Set<Id> storeIdSet ) {
        System.debug(LPREFIX + 'processCleanupPastApptTimeSlotsAndSpots() ENTRY');

        Integer slotsToDelete = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_SLOT_GENERATOR_MAX_NUMBER_OF_SLOTS_TO_DELETE));

        Date yesterday = Date.today().addDays(-1);

        List<Appt_Time_Slot__c> pastSlotsToDelete = [SELECT Id FROM Appt_Time_Slot__c WHERE Service_Territory__c IN: storeIdSet AND Date__c <= :yesterday LIMIT: slotsToDelete];

        if (pastSlotsToDelete != null && pastSlotsToDelete.size() > 0) {
            System.debug(LPREFIX + 'SOQL with WHERE Date__c <= '+yesterday+' resulted in following number of past Appt_Time_Slot__c retrieved: '+pastSlotsToDelete.size());

            System.debug(LPREFIX + ' About to delete following past Appt_Time_Slot__c records: '+pastSlotsToDelete);
            delete pastSlotsToDelete;
            System.debug(LPREFIX + ' SUCCESSFULLY DELETED '+ pastSlotsToDelete.size() +' past Appt_Time_Slot__c records equal to or older then yesterday='+yesterday);


        } else {
            System.debug(LPREFIX + 'WARNING! processCleanupPastApptTimeSlotsAndSpots() - SOQL with WHERE Date__c <= '+yesterday+' resulted in NO Appt_Time_Slot__c FOUND, pastSlotsToDelete: '+pastSlotsToDelete);
        }

        System.debug(LPREFIX + 'processCleanupPastApptTimeSlotsAndSpots() EXIT');
    }

    //Method to check if there are any related Store Setup Import records that need to be updated and if a Summary Email needs to be sent
    private void checkForRelatedStoreSetupImportsAndProcess() {
        if (!newServiceTerritoryIds.isEmpty()) {
            //If new Service Territory records were generated during the Automated Store Setup Import process, then update Time Slot Creation Status on the related Store Setup Imports
            Map<String, Store_Setup_Import__c> serviceTerritoryIdToStoreSetupImportMap = new Map<String, Store_Setup_Import__c>();
            for (Store_Setup_Import__c ssi : [SELECT Id, Service_Territory__c FROM Store_Setup_Import__c WHERE Service_Territory__c IN :newServiceTerritoryIds]) {
                serviceTerritoryIdToStoreSetupImportMap.put(ssi.Service_Territory__c, ssi);
            }

            List<Store_Setup_Import__c> storeSetupImportsToUpdate = new List<Store_Setup_Import__c>();
            for (ServiceTerritory st : [SELECT Id, Date_Last_Slot_Generated__c FROM ServiceTerritory WHERE Id IN :newServiceTerritoryIds]) {
                if (serviceTerritoryIdToStoreSetupImportMap.containsKey(st.Id)) {
                    Store_Setup_Import__c ssi = serviceTerritoryIdToStoreSetupImportMap.get(st.Id);
                    if (st.Date_Last_Slot_Generated__c != null) {
                        //If Date Last Slot Generated is set, then set Time Slot Creation Status on the related Store Setup Import to Complete since the Time Slots were created successfully
                        ssi.Time_Slot_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED;
                    } else {
                        //If Date Last Slot Generated is null, then set Time Slot Creation Status on the related Store Setup Import to Error since the Time Slots were not created successfully
                        ssi.Time_Slot_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR;
                        ssi.Time_Slot_Creation_Message__c = 'Time Slots were not successfully generated for this Store Setup Import. Please retry using the "Generate Appointment Slots" button on the Service Territory Detail Page.';
                    }
                    storeSetupImportsToUpdate.add(ssi);
                }
            }

            if (!storeSetupImportsToUpdate.isEmpty()) {
                update storeSetupImportsToUpdate;
            }
        }

        if (String.isNotBlank(currentUserEmail)) {
            //If the Email of the User that kicked off the Automated Store Setup Import process is provided, then prepare and send the Automated Store Setup Import Summary Email

            //Count number of successes and errors based on the related Store Setup Imports
            Integer numSetupSuccesses = 0;
            Integer numUserSetupErrors = 0;
            Integer numServiceTerritorySetupErrors = 0;
            Integer numTimeSlotSetupErrors = 0;
            for (Store_Setup_Import__c ssi : [SELECT Id, Store_Creation_Status__c, Time_Slot_Creation_Status__c, User_Creation_Status__c  FROM Store_Setup_Import__c WHERE Id IN :processedStoreSetupImportIds]) {
                if (ssi.User_Creation_Status__c.equalsIgnoreCase(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED) && ssi.Store_Creation_Status__c.equalsIgnoreCase(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED) && ssi.Time_Slot_Creation_Status__c.equalsIgnoreCase(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED)) {
                    numSetupSuccesses++;
                } else if (ssi.User_Creation_Status__c.equalsIgnoreCase(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR)) {
                    numUserSetupErrors++;
                } else if (ssi.Store_Creation_Status__c.equalsIgnoreCase(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR)) {
                    numServiceTerritorySetupErrors++;
                } else if (ssi.Time_Slot_Creation_Status__c.equalsIgnoreCase(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR)) {
                    numTimeSlotSetupErrors++;
                }
            }

            //Create Single Email Message for the Automated Store Setup Import Summary Email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String> { currentUserEmail });
            mail.setSubject('Automated Store Setup Import Summary');

            //Build the body of the Automated Store Setup Import Summary Email
            String body = '<span style="font-weight: bold;">Store Setup Imports:</span> ' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/o/Store_Setup_Import__c/list">Recently Viewed</a>';
            body += '</br></br>\r\n';
            body += '<span style="font-weight: bold;">Number of Successes:</span> ' + numSetupSuccesses;
            body += '</br>\r\n';
            body += '<span style="font-weight: bold;">Number of User Setup Errors:</span> ' + numUserSetupErrors;
            body += '</br>\r\n';
            body += '<span style="font-weight: bold;">Number of Service Territory Setup Errors:</span> ' + numServiceTerritorySetupErrors;
            body += '</br>\r\n';
            body += '<span style="font-weight: bold;">Number of Time Slot Setup Errors:</span> ' + numTimeSlotSetupErrors;
            if (numUserSetupErrors > 0 || numServiceTerritorySetupErrors > 0 || numTimeSlotSetupErrors > 0) {
                body += '</br></br>\r\n';
                body += '<span>Please review the Error Messages on the Store Setup Import records and/or generated Error Logs.</span>';
            }
            mail.setHtmlBody(body);

            //Attempt to send the Automated Store Setup Import Summary Email, if it fails then log the error
            try {
                if (!Test.isRunningTest()) {
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
                }
            } catch (Exception ex) {
                Logger logInstance = Logger.getInstance(true);
                logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'Failed to send Automated Store Setup Import Summary');
                logInstance.finalize();
            }
        }
    }

    private class StoreParams {
        
        public Id serviceTerritoryId;
        public String slotType;
        public Map<String, List<Appt_Time_Slot_Capacity__c>> storeOverridesMap;
        public Appt_OperatingHoursModel storeHours;
        public Appt_OperatingHoursModel storeCapacitySlots;
        public Datetime maxSlotDate;
        public Integer numberDaysSlotsExisting;
        public Integer numDaysToPopulate;
        public Datetime apptTime;
        public List<TimeSlot> capacitySlots;
        public TimeSlot storeHoursSlot;
        public Integer durationMinutes;
        public Boolean useCapOverride = false;
        public Appt_Time_Slot_Capacity__c capOverriseSlot;
        public TimeSlot slotToUse;
        public Integer timeZoneOffset;
        public Boolean isFrontSlot = false;
        public Boolean isBackSlot = false;
        public List<ResourceAbsence> storeAbsences;
    }

    public class ResultWrapper{
        public string recordId;
        public string message;
        public string status; // 'success' or 'error'
        public Datetime dateMaxSlot;

        public ResultWrapper() {} 

        public ResultWrapper(String recordId, String message, String status) {
            this.recordId = recordId;
            this.message = message;
            this.status = status;
        }
    }
}

// SELECT Id, start, end FROM ResourceAbsence where ResourceId in ( 
// SELECT ServiceResourceId from ServiceTerritoryMember  where ServiceTerritoryId = '0HhL00000000RRAKA2')