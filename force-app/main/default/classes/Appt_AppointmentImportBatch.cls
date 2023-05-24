/**
 * @author Apps Associates
 * @date: 6/14/22
 * @description:   Batch Class used to create/find Accounts, Vehicle Assets, Work Orders, and Service Appointments related to the Appointment Imports being processed. The processed Appointment Import records will be updated upon completion of this batch to be linked to their associated Work Order as well as the Import Date.
 */
public class Appt_AppointmentImportBatch implements Database.Batchable<sObject>, Database.RaisesPlatformEvents {
    public static final String LPREFIX = 'Appt_ApptImportBatch: ';
    public static Boolean isTest = false;

    public static final Decimal LIMIT_PERCENT = 0.5;
    public static final Integer MAX_APPOINTMENTS_TO_PROCESS = 200;

    //-- Apex Code to run process in Devloper Console Anonymous Execute window
    //     Database.executeBatch(new Appt_AppointmentImportBatch());
        
    public static Integer maxToProcess {get;set;}

    //--cache Record ID Maps
    private static Map<String, Account> posCustomerAccountMap = new Map<String, Account>();
    private static Map<String, Account> hybrisCustomerAccountMap = new Map<String, Account>();
    private static Map<String, Account> guidCustomerAccountMap = new Map<String, Account>();
    private static Map<String, Asset> posVehicleAssetMap = new Map<String, Asset>();
    private static Map<String, Asset> hybrisVehicleAssetMap = new Map<String, Asset>();
    private static Map<String, AppointmentParams> storeAppointmentParamsMap = new Map<String, AppointmentParams>();
    private static Map<String, String> vehicleTypeCodeMap = new Map<String, String>();

    private static List<Fleet_State_Abbrev__mdt> stateCompareList;

    private static List<Id> insertedAccountIdList;
    private static List<Id> insertedVehAssetIdList;


    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug(LPREFIX +'-- START');

        // Set the stateCompareList, houses the State Name and the abbreviation for the state as well
        stateCompareList = [ SELECT State_Abbrev__c, State_Output__c FROM Fleet_State_Abbrev__mdt];

        // Returns a List of Fleet_Application__c's that are in the pending Status
        return Database.getQueryLocator('SELECT Id, CreatedDate, Name, POS_Web_Order_ID__c, Vehicle_Type__c, Model__c, Hybris_Customer_Vehicle_ID__c, Mobile_Phone_Area_Code__c, ' 
        +'Form_Date__c, Legacy_Appointment_ID__c, Home_Phone_Number__c, Appointment_Date__c, POS_Customer_ID__c, Layaway_Number__c, Zipcode__c, POS_Customer_Vehicle_ID__c, Hybris_Customer_ID__c, '
        +'Quote_Number__c, Start_Time__c, Email_Address__c, Customer_Type__c, Mobile_Phone_Number__c, GUID__c, City__c, Address_Line_1__c, Site_ID__c, State__c, Last_Name__c, First_Name__c, '
        +'Hybris_Order_ID__c, Work_Phone_Number__c, Vehicle_ID__c, Year__c, Trim_ID__c, Assembly_ID__c, Form_Number__c, Form_Type__c, Make__c, End_Time__c, Home_Phone_Area_Code__c, Country__c, '
        +'Work_Phone_Area_Code__c, Appointment_Status__c, Address_Line_2__c, Import_Date__c, Import_Status__c '
        +'FROM Appt_Appointment_Import__c WHERE Import_Status__c = \'' +Appt_ConstantValues.APPOINTMENT_IMPORT_STATUS_PENDING +'\' ORDER BY CreatedDate');
    }

    //---Process to execute the Scheduled job
    public void execute(Database.BatchableContext bc, List<Appt_Appointment_Import__c> scope)
    {
        System.debug(LPREFIX +'execute() -- START');
        
        Integer numberPendingImportsProcessed = processPendingAppointmentImports(scope);

        System.debug(LPREFIX +'execute() -- Done with appt import processing. Processed ' +numberPendingImportsProcessed +' imports');

        // Print the limits to the debug console
        System.debug('DML LIMITS: ' +checkLimit('DML', Limits.getLimitDMLStatements(), Limits.getDMLStatements(), true));
        System.debug('QUERY LIMITS: ' +checkLimit('Queries', Limits.getLimitQueries(), Limits.getQueries(), true));
        System.debug('CPU LIMITS: ' +checkLimit('CPU', Limits.getLimitQueries(), Limits.getQueries(), true));

        System.debug(LPREFIX +'execute() -- END');
    }

    public void finish(Database.BatchableContext bc){
        Id batchId = bc.getJobId();
        System.debug( LPREFIX + '::finish: batchId: ' + batchId);
        //---Checking final status of the Job
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClassID, JobItemsProcessed, TotalJobItems, JobType, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchId];
        System.debug( LPREFIX + 'apexJob: ' + apexJob);
    }  


    //-- main method to loop through and process this chunk of Pending appointment imports
    public static Integer processPendingAppointmentImports(List<Appt_Appointment_Import__c> appImportList) {
        System.debug(LPREFIX + 'processPendingAppointmentImports() ENTRY');

        List<Appt_Appointment_Import__c> apptImportsToUpdateList = new List<Appt_Appointment_Import__c>();

        List<Appt_Appointment_Import__c> apptImportList = prepApptImportBatchData(appImportList);

        if (apptImportList == null || apptImportList.size() == 0) {
            System.debug(LPREFIX + 'No Pending Appt_Appointment_Import__c records found, returning 0----------------');
            return 0;
        } else {
            System.debug(LPREFIX + apptImportList.size() + ' Pending Appt_Appointment_Import__c records found to process <<<<<<<<<<<');
        }

        //-- setup lists to hold objects for bulk save
        Map<String, AccountWrapper> accountsBulkSaveMap = new Map<String, AccountWrapper>();
        Map<String, VehAssetWrapper> vehiclesBulkSaveMap = new Map<String, VehAssetWrapper>();
        List<WorkOrderWrapper> workOrdersBulkSaveList = new List<WorkOrderWrapper>();
        List<ServiceAppointmentWrapper> servApptBulkSaveList = new List<ServiceAppointmentWrapper>();
        List<AppointmentImportWrapper> apptImportBulkSaveList = new List<AppointmentImportWrapper>();


        //-- Loop through list of import appointments 
        for (Appt_Appointment_Import__c apptImp: apptImportList) {

            //-- process the import, resulting in Work Order Id (service appointment) being returned
            try {
                processAppointmentImport(apptImp, accountsBulkSaveMap, vehiclesBulkSaveMap, workOrdersBulkSaveList, ServApptBulkSaveList, apptImportBulkSaveList);

            } catch(Exception e) {
                //-- setup appointment import record to be updated as ERROR
                System.debug(LPREFIX + '  ERROR processeing Service Appointment with legacy appointment_ID='+apptImp.Legacy_Appointment_ID__c);
                System.debug(LPREFIX + '  ERROR message='+e.getMessage()+':'+e.getStackTraceString());
                Appt_Appointment_Import__c processedImport = new Appt_Appointment_Import__c(id = apptImp.Id);
                processedImport.Import_Status__c = Appt_ConstantValues.APPOINTMENT_IMPORT_STATUS_ERROR;
                processedImport.Import_Error_Message__c = e.getMessage();
                processedImport.Import_Date__c = Datetime.now();
                apptImportsToUpdateList.add(processedImport);
            }
            
            if (!areLimitsOk()) break;
        }

        //-- Save and link all of the records stored on Maps and Lists
        insertAccounts(accountsBulkSaveMap);
        insertVehAssets(vehiclesBulkSaveMap);
        insertWorkOrders(workOrdersBulkSaveList);
        insertServiceAppointments(ServApptBulkSaveList);


        //-- Loop through apptImportBulkSaveList and update the Appt_Appointment_Import__c records that were processed 
        for (AppointmentImportWrapper apptImpWrap: apptImportBulkSaveList) {
            Appt_Appointment_Import__c processedImport = new Appt_Appointment_Import__c(id = apptImpWrap.apptImp.Id);
            processedImport.Import_Status__c = Appt_ConstantValues.APPOINTMENT_IMPORT_STATUS_IMPORTED;
            processedImport.Appointment_Work_Order__c = apptImpWrap.woWrap.wrkOrder.Id;
            processedImport.Import_Date__c = Datetime.now();
            processedImport.Import_Error_Message__c = '';
            apptImportsToUpdateList.add(processedImport);
        }

        //-- UPDATE the Appt_Appointment_Import__c appointment import records that were successfully imported
        System.debug(LPREFIX + '   about to update '+apptImportsToUpdateList.size()+' successfully imported Appt_Appointment_Import__c records');
        update apptImportsToUpdateList;
        System.debug(LPREFIX + '   SUCCESSFULLY UPDATED apptImportsToUpdateList');

        System.debug(LPREFIX + 'processPendingAppointmentImports() EXIT - numberPendingProcessed=' + apptImportsToUpdateList.size());
        return apptImportsToUpdateList.size();
    }


    private static List<ServiceAppointment> insertServiceAppointments(List<ServiceAppointmentWrapper> ServApptBulkSaveList) {
        System.debug(LPREFIX + 'insertServiceAppointments() ENTRY - ServApptBulkSaveList.size()='+ServApptBulkSaveList.size());

        List<ServiceAppointment> sas = new List<ServiceAppointment>();
        ServiceAppointment sa;
        for(ServiceAppointmentWrapper saWrap: ServApptBulkSaveList) {
            sa = saWrap.servAppt;
            sa.Work_Order__c = saWrap.woWrap.wrkOrder.Id;
            sa.ParentRecordId = saWrap.woWrap.wrkOrder.Id;
            sas.add(sa);
        }

        insert sas;
        System.debug(LPREFIX + 'successfully INSERTED ' + sas.size() + ' ServiceAppointment records');

        return sas;
    }


    private static List<WorkOrder> insertWorkOrders(List<WorkOrderWrapper> workOrdersBulkSaveList) {
        System.debug(LPREFIX + 'insertWorkOrders() ENTRY - workOrdersBulkSaveList.size()='+workOrdersBulkSaveList.size());

        List<WorkOrder> wos = new List<WorkOrder>();
        WorkOrder wo;
        for(WorkOrderWrapper woWrap: workOrdersBulkSaveList) {

            wo = woWrap.wrkOrder;
            wo.AccountId = woWrap.acntWrap.acnt.Id;
            wo.ContactId = woWrap.acntWrap.acnt.PersonContactId;
            wo.Vehicle__c = woWrap.vehAssetWrap.vehAsset.Id;
            wos.add(wo);
        }

        insert wos;
        System.debug(LPREFIX + 'successfully INSERTED '+ wos.size() + ' WorkOrder records');

        return wos;
    }


    private static List<Asset> insertVehAssets(Map<String, VehAssetWrapper> vehiclesBulkSaveMap) {
        System.debug(LPREFIX + 'insertVehAssets() ENTRY - vehiclesBulkSaveMap.size()='+vehiclesBulkSaveMap.size());

        List<Asset> vehs = new List<Asset>();
        Asset veh;
        for(VehAssetWrapper vehWrap: vehiclesBulkSaveMap.values()) {

            //-- if the veh asset in the wrapper class has an Id, then it is already in DB, so skip adding it
            if (String.isBlank(vehWrap.vehAsset.Id)) {
                veh = vehWrap.vehAsset;
                veh.accountId = vehWrap.acntWrap.acnt.Id;
                veh.ContactId = vehWrap.acntWrap.acnt.PersonContactId;
                veh.Name = 'Imported Service Appointment Vehicle';
                vehs.add(veh);
            }
        }

        //-- since the Assets might already be in the DB, do an upsert
        insert vehs;
        System.debug(LPREFIX + 'successfully INSERTED ' + vehs.size() + ' Asset records');

        //-- put inserted veh assets in Asset Maps as well as insertedVehAssetIds List for next chunk of imports
        for (Asset savedVeh: vehs) {
            if (!String.isBlank(savedVeh.POS_Customer_Vehicle_ID__c)) posVehicleAssetMap.put(savedVeh.POS_Customer_Vehicle_ID__c, savedVeh);
            if (!String.isBlank(savedVeh.Hybris_Customer_Vehicle_ID__c)) hybrisVehicleAssetMap.put(savedVeh.Hybris_Customer_Vehicle_ID__c, savedVeh);
            insertedVehAssetIdList.add(savedVeh.Id);
        }

        return vehs;
    }


    private static List<Account> insertAccounts(Map<String, AccountWrapper> accountsBulkSaveMap) {
        System.debug(LPREFIX + 'insertAccounts() ENTRY - accountsBulkSaveMap.size()='+accountsBulkSaveMap.size());

        List<Account> accounts = new List<Account>();
        for(AccountWrapper acntWrap: accountsBulkSaveMap.values()) {

            if (acntWrap.acnt != null && String.isBlank(acntWrap.acnt.Id)) {
                accounts.add(acntWrap.acnt);
            }
        }

        //-- since the Accounts might already be in the DB, do an upsert
        //-- Database.insert code below is to debug accounts that are erroring out
        List<Database.SaveResult> saveResults = Database.insert(accounts, false);
        for (Integer i = 0; i < saveResults.size(); i++) {

            if (saveResults[i].isSuccess()) {
            } else {
                // found error
                System.debug('   Account insert ERROR -------');
                String errors = '';
                if (saveResults[i].errors != null) {
                    for (Database.Error err : saveResults[i].errors) {
                        errors += err.getMessage() + '\r\n';
                    }
                    System.debug(LPREFIX + 'insertAccounts() - Warning!, got ERROR inserting Account on index='+i+' , error:'+ errors);
                }
                Account errorA = accounts.get(i);
                if (errorA != null) {
                    System.debug(LPREFIX + '  errored account:guid='+errorA.GUID__c+', posId='+errorA.POS_Customer_Id__c+', hId='+errorA.Hybris_Customer_Id__c);
                }
            }
        }


        System.debug(LPREFIX + 'successfully INSERTED (upserted) ' + accounts.size() + ' Account records');

        //-- put inserted accounts in account Maps as well as in insertedVehAssetIds List for next chunk of imports
        for (Account acnt: accounts) {
            if (!String.isBlank(acnt.POS_Customer_ID__c)) posCustomerAccountMap.put(acnt.POS_Customer_ID__c, acnt);
            if (!String.isBlank(acnt.Hybris_Customer_Id__c)) hybrisCustomerAccountMap.put(acnt.Hybris_Customer_Id__c, acnt);
            if (!String.isBlank(acnt.GUID__c))  guidCustomerAccountMap.put(acnt.GUID__c, acnt);
            insertedAccountIdList.add(acnt.Id);
        }

        return accounts;
    }


    //-- Process the objects for the import row, adding records to Maps or Lists for bulk save in calling method. AppointmentParams for this import row to be used in calling method 
    public static void processAppointmentImport(Appt_Appointment_Import__c apptImport, Map<String, AccountWrapper> accountsBulkSaveMap, Map<String, VehAssetWrapper> vehiclesBulkSaveMap, List<workOrderWrapper> workOrdersBulkSaveList, List<ServiceAppointmentWrapper> servApptBulkSaveList, List<AppointmentImportWrapper> apptImportBulkSaveList) {
        System.debug(LPREFIX + '------------------ processAppointmentImport() ENTRY - siteId='+apptImport.Site_ID__c+', Legacy_Appointment_ID='+apptImport.Legacy_Appointment_ID__c+', Appointment_Date='+apptImport.Appointment_Date__c+', Start_Time='+apptImport.Start_Time__c+', End_Time='+apptImport.End_Time__c);

        //-- validate Appt_Appointment_Import__c, exception will be thrown if any validation errors, caught in calling method
        validateAppointmentImport(apptImport);


        //-- get the FSL records associated with the store, such as WorkType (for back room), ServiceResource (for back room), Scheduling Policy, etc..
        AppointmentParams apptParams = getAppointmentStoreParameters(apptImport);

        //-- Find on map or create customer account for the appointment
        AccountWrapper acntWrap = getAppointmentAccount(apptImport, accountsBulkSaveMap);

        VehAssetWrapper vehAssetWrap = getAppointmentVehAsset(apptImport, acntWrap, vehiclesBulkSaveMap);

        WorkOrderWrapper woWrap = createApptWorkOrder(apptImport, vehAssetWrap, apptParams, workOrdersBulkSaveList);

        createServiceAppointment(apptImport, woWrap, apptParams, servApptBulkSaveList);

        //-- add the Appt_Appointment_Import__c to List for bulf update in calling method
        AppointmentImportWrapper apptImpWrap = new AppointmentImportWrapper();
        apptImpWrap.woWrap = woWrap;
        apptImpWrap.apptImp = apptImport;
        apptImportBulkSaveList.add(apptImpWrap);

        System.debug(LPREFIX + 'processAppointmentImport() EXIT');
    }


    //-- create and insert ServiceAppointment recod
    private static ServiceAppointmentWrapper createServiceAppointment(Appt_Appointment_Import__c apptImport, WorkOrderWrapper woWrap, AppointmentParams apptParams, List<ServiceAppointmentWrapper> servApptBulkSaveList) {

        // construct DateTime for ConsultStartTime and ConsultEndTime in GMT
        Datetime startDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(apptImport.Appointment_Date__c), apptImport.Start_Time__c, apptParams.timeZoneOffset);
        Datetime endDateTime = Appt_AppointmentUtil.convertTime(String.valueOf(apptImport.Appointment_Date__c), apptImport.End_Time__c, apptParams.timeZoneOffset);

        // create and save BACK ROOM service appointment
        ServiceAppointment sa = new ServiceAppointment();
        //-- all imported appointments to be Back Room, per DT requirements
        sa.Activity_Type__c = Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_BACK;
        sa.EarliestStartTime = startDateTime;
        sa.SchedStartTime = startDateTime;
        sa.DueDate = endDateTime;
        sa.SchedEndTime = endDateTime;
        sa.Duration = Appt_AppointmentUtil.minutesBetweenDatetimes(startDateTime, endDateTime);
        sa.Start_Time_String__c = apptImport.Start_Time__c;
        sa.End_Time_String__c = apptImport.End_Time__c;
        sa.Original_Date_String__c = String.valueOf(apptImport.Appointment_Date__c);
        sa.Original_Start_Time_String__c = apptImport.Start_Time__c;
        sa.Original_End_Time_String__c = apptImport.End_Time__c;
        sa.ServiceTerritoryId = apptParams.ServiceTerritoryId;
        sa.Date_String__c = apptImport.Appointment_Date__c;
        sa.Status = apptParams.appointmentStatus;
        sa.DurationType = Appt_ConstantValues.WORK_ORDER_DURATION_TYPE;
        //-- hard code customerType = Retail, according to DT requirements
        sa.Customer_Type__c = Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        //-- hard code source to File, per DT requirements
        sa.Source__c = Appt_ConstantValues.APPOINTMENT_SOURCE_FILE;
        sa.Site_Id__c = apptImport.Site_ID__c;
        sa.Timezone_Offset__c = apptParams.timeZoneOffset;

        //-- use code value in Form_Type field to determine Order_Type picklist value, per Taral on 4/19/21 in Appointment Cutover testing meeting
        String orderType = Appt_AppointmentUtil.getOrderTypeFromFormType(apptImport.Form_Type__c);
        sa.Order_Type__c = String.isBlank(orderType) ? null : orderType;
        
        sa.FSL__Schedule_over_lower_priority_appointment__c = true;
        sa.Priority__c = 1;

        //-- Set the owner of the ServiceAppointment to be the Store's record owner user (like POS user) so that the store can see all of its Service Appointment
        //--  records, but only the stores' Service Appointment records - DTA-353
        if (!String.isBlank(apptParams.appointmentRecordOwnerId)) sa.OwnerId = apptParams.appointmentRecordOwnerId;


        ServiceAppointmentWrapper saWrap = new ServiceAppointmentWrapper(sa, woWrap);
        saWrap.apptParams = apptParams;
        servApptBulkSaveList.add(saWrap);

        return saWrap;
    }


    //-- create and insert WorkOrder, which is the main parent ServiceAppointment recod
    private static WorkOrderWrapper createApptWorkOrder(Appt_Appointment_Import__c apptImport, VehAssetWrapper vehAssetWrap, AppointmentParams apptParams, List<workOrderWrapper> workOrdersBulkSaveList) {

        WorkOrder wo = new WorkOrder();
        wo.ServiceTerritoryId = apptParams.ServiceTerritoryId;
        wo.WorkTypeId = apptParams.backroomWorkTypeId; 

        //-- had code source to File, per DT requirements
        wo.Source__c = Appt_ConstantValues.APPOINTMENT_SOURCE_FILE;

        //-- use code value in Form_Type field to determine Order_Type picklist value, per Taral on 4/19/21 in Appointment Cutover testing meeting
        String orderType = Appt_AppointmentUtil.getOrderTypeFromFormType(apptImport.Form_Type__c);
        wo.Order_Type__c = String.isBlank(orderType) ? null : orderType;

        wo.Form_Type__c = apptImport.Form_Type__c;
        wo.Form_Number__c = apptImport.Form_Number__c;
        wo.Form_Date__c = !String.isBlank(apptImport.Form_Date__c) ? Date.valueOf(apptImport.Form_Date__c) : null;
        wo.Hybris_Order_Id__c = apptImport.Hybris_Order_ID__c;
        wo.POS_Web_Order_Id__c = apptImport.POS_Web_Order_ID__c;
        wo.Layaway_Number__c = apptImport.Layaway_Number__c;
        wo.Quote_Number__c = apptImport.Quote_Number__c;
        wo.Legacy_Appointment_Id__c = apptImport.Legacy_Appointment_ID__c;

        //-- Set the owner of the WorkOrder to be the Store's record owner user (like POS user) so that the store can see all of its Service Appointment
        //--  records, but only the stores' Service Appointment records - DTA-353
        if (!String.isBlank(apptParams.appointmentRecordOwnerId)) wo.OwnerId = apptParams.appointmentRecordOwnerId;

        WorkOrderWrapper woWrap = new WorkOrderWrapper(wo, vehAssetWrap.acntWrap, vehAssetWrap); 
        workOrdersBulkSaveList.add(woWrap);

        return woWrap;
    }


    //-- get vehicle Asset from cache map or, if not found, insert new vehicel Asset
    private static VehAssetWrapper getAppointmentVehAsset(Appt_Appointment_Import__c apptImport, AccountWrapper accountWrap, Map<String, VehAssetWrapper> vehiclesBulkSaveMap) {
        
        //-- 1, check on vehiclesBulkSaveMap in case this veh Asset has already been processed. If found, return the cached VehAssetWrapper
        VehAssetWrapper vehAssetWrap = vehiclesBulkSaveMap.get(apptImport.POS_Customer_Vehicle_ID__c+'|'+apptImport.Hybris_Customer_Vehicle_ID__c);
        if (vehAssetWrap != null) {
            return vehAssetWrap;
        }

        //-- 2. check on posVehicleIdAssetIdMap for cached veh Asset from SOQL lookup in populateIdMaps()
        Asset veh = posVehicleAssetMap.get(apptImport.POS_Customer_Vehicle_ID__c);

        //-- 3. if not found above, check on hybrisVehicleAssetMap for cached veh Asset from SOQL lookup in populateIdMaps()
        if (veh == null) {
            veh = hybrisVehicleAssetMap.get(apptImport.Hybris_Customer_Vehicle_ID__c);
            //System.debug(LPREFIX + '333333 veh:'+veh);
        }

        if (veh == null) {

            //-- 4. existing vehicle not found, create and insert a new vehicle Asset record
            Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
            
            veh = new Asset(RecordTypeId = vehRecordTypeId);
            //veh.Name = apptImport.Year__c + ' ' + apptImport.Make__c + ' ' + apptImport.Model__c;
            veh.Name = 'Service Appointment Vehicle';
            veh.POS_Customer_Vehicle_Id__c = apptImport.POS_Customer_Vehicle_ID__c;
            veh.Hybris_Customer_Vehicle_Id__c = apptImport.Hybris_Customer_Vehicle_ID__c;
            veh.Vehicle_Manufacture_Year__c = apptImport.Year__c;
            veh.Vehicle_Make__c = apptImport.Make__c;
            veh.Vehicle_Model__c = apptImport.Model__c;
            veh.Assembly_Id__c = apptImport.Assembly_ID__c;
            veh.Vehicle_Id__c = apptImport.Vehicle_ID__c;
            veh.Trim_Id__c = apptImport.Trim_ID__c;
            if (!String.isBlank(apptImport.Vehicle_Type__c)) {
                String vehTypeString = vehicleTypeCodeMap.get(apptImport.Vehicle_Type__c.trim());
                if (!String.isBlank(vehTypeString)) veh.Vehicle_Type__c = vehTypeString;
            }  
        }

        vehAssetWrap = new VehAssetWrapper(veh, accountWrap);

        //-- put on vehiclesBulkSaveMap so that upcoming Imports can access it
        vehiclesBulkSaveMap.put(apptImport.POS_Customer_Vehicle_ID__c+'|'+apptImport.Hybris_Customer_Vehicle_ID__c, vehAssetWrap);

        return vehAssetWrap;
    }


    //-- get customer Account from cache map or, if not found, insert new Account
    private static AccountWrapper getAppointmentAccount(Appt_Appointment_Import__c apptImport, Map<String, AccountWrapper> accountsBulkSaveMap) {

        //-- 1. check on accountsBulkSaveMap in case this account has already been processed. If found, return the cached AccountWrapper
        AccountWrapper wrappedAccount = accountsBulkSaveMap.get(apptImport.POS_Customer_ID__c+'|'+apptImport.Hybris_Customer_ID__c+'|'+apptImport.GUID__c);
        if (wrappedAccount != null) {
            return wrappedAccount;
        }

        //-- 2. check on posCustomerIdAccountIdMap for cached account from SOQL lookup in populateIdMaps()
        Account custAccount = posCustomerAccountMap.get(apptImport.POS_Customer_ID__c);

        //-- 3. check on hybrisCustomerAccountMap for cached account from SOQL lookup in populateIdMaps()
        if (custAccount == null) {
            custAccount = hybrisCustomerAccountMap.get(apptImport.Hybris_Customer_ID__c);
        }

        //-- 4. check on guidCustomerAccountMap for cached account from SOQL lookup in populateIdMaps()
        if (custAccount == null) {
            custAccount = guidCustomerAccountMap.get(apptImport.GUID__c);
        }

        if (custAccount == null) {

            //-- 5. account ID not found on Maps,  create and insert a new Person Account record
            Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

            custAccount = new Account(RecordTypeId = personAccountRecordTypeId);
            if (!String.isBlank(apptImport.Hybris_Customer_ID__c)) custAccount.Hybris_Customer_Id__c = apptImport.Hybris_Customer_ID__c.trim();
            else custAccount.Hybris_Customer_Id__c = null;

            if (!String.isBlank(apptImport.POS_Customer_ID__c)) custAccount.POS_Customer_Id__c = apptImport.POS_Customer_ID__c.trim();
            else custAccount.POS_Customer_Id__c = null;

            if (!String.isBlank(apptImport.GUID__c)) custAccount.GUID__c = apptImport.GUID__c.trim();
            else custAccount.GUID__c = null;

            custAccount.FirstName = apptImport.First_Name__c;
            custAccount.LastName = apptImport.Last_Name__c;
            if (!String.isBlank(apptImport.Email_Address__c)) {
                custAccount.Email__c = apptImport.Email_Address__c;
                custAccount.PersonEmail = apptImport.Email_Address__c;
            }
            if (!String.isBlank(apptImport.Home_Phone_Area_Code__c) && !String.isBlank(apptImport.Home_Phone_Number__c) && apptImport.Home_Phone_Area_Code__c.trim().length() == 3 && apptImport.Home_Phone_Number__c.trim().length() == 7) {
                custAccount.PersonHomePhone = apptImport.Home_Phone_Area_Code__c.trim() + apptImport.Home_Phone_Number__c.trim();
            }
            if (!String.isBlank(apptImport.Mobile_Phone_Area_Code__c) && !String.isBlank(apptImport.Mobile_Phone_Number__c) && apptImport.Mobile_Phone_Area_Code__c.trim().length() == 3 && apptImport.Mobile_Phone_Number__c.trim().length() == 7) {
                custAccount.PersonMobilePhone = apptImport.Mobile_Phone_Area_Code__c.trim() +  apptImport.Mobile_Phone_Number__c.trim();
            }
            if (!String.isBlank(apptImport.Work_Phone_Area_Code__c) && !String.isBlank(apptImport.Work_Phone_Number__c) && apptImport.Work_Phone_Area_Code__c.trim().length() == 3 && apptImport.Work_Phone_Number__c.trim().length() == 7) {
                custAccount.Phone = apptImport.Work_Phone_Area_Code__c.trim() +  apptImport.Work_Phone_Number__c.trim();
            }

            if (!String.isBlank(apptImport.Address_Line_1__c) && !String.isBlank(apptImport.Address_Line_2__c)) custAccount.put('ShippingStreet', apptImport.Address_Line_1__c + '\n' + apptImport.Address_Line_2__c);
            else if (!String.isBlank(apptImport.Address_Line_1__c)) custAccount.put('ShippingStreet', apptImport.Address_Line_1__c);
            custAccount.put('ShippingCity', apptImport.City__c);
            if (!String.isBlank(apptImport.State__c) && apptImport.State__c.trim().length() < 4) {
                custAccount.put('ShippingState', Fleet_Util.convertTwoDigitStateToFullName(apptImport.State__c.trim(), stateCompareList));
            } else {
                custAccount.put('ShippingState', apptImport.State__c);
            }
            custAccount.put('ShippingPostalCode', apptImport.Zipcode__c);

            custAccount.put('ShippingCountry', apptImport.Country__c);
            
            //-- hard code customerType = Retail, according to DT requirements
            custAccount.Appt_Customer_Type__c = Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        }

        wrappedAccount = new AccountWrapper(custAccount);

        //-- put on accountsBulkSaveMap so that upcoming Imports can access it
        accountsBulkSaveMap.put(apptImport.POS_Customer_ID__c+'|'+apptImport.Hybris_Customer_ID__c+'|'+apptImport.GUID__c, wrappedAccount);
    
        return wrappedAccount;
    }

    //-- validate the appointment Import data, exception will be thrown if any validation errors
    private static void validateAppointmentImport(Appt_Appointment_Import__c apptImport) {

        if (String.isBlank(apptImport.Site_ID__c)) throw new Appt_AppointmentException('BAD REQUEST - a valid Site_ID is required', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));

        if (String.isBlank(apptImport.Appointment_Date__c)) throw new Appt_AppointmentException('BAD REQUEST - a valid Appointment_Date is required', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));
        else {
            try {
                Date.valueOf(apptImport.Appointment_Date__c);
            } catch (Exception e) {
                throw new Appt_AppointmentException('BAD REQUEST - a valid Appointment_Date in format yyy-MM-dd is required', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));
            }
        }

        if (String.isBlank(apptImport.Start_Time__c) || apptImport.Start_Time__c.trim().length() != 4) throw new Appt_AppointmentException('BAD REQUEST - a valid Start_Time in format mmss (4 numeric digits) is required', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));

        if (String.isBlank(apptImport.End_Time__c) || apptImport.End_Time__c.trim().length() != 4) throw new Appt_AppointmentException('BAD REQUEST - a valid End_Time in format mmss (4 numeric digits) is required', Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST));
    }

    //-- get essential data about a site Serv iceTerritory, such as Work Type, Scheduling Policy, Service Resource, etc..
    private static AppointmentParams getAppointmentStoreParameters(Appt_Appointment_Import__c apptImport) {

        AppointmentParams apptParams = storeAppointmentParamsMap.get(apptImport.Site_ID__c.trim());

        if (apptParams != null) {

            Date apptDate = Date.valueOf(apptImport.Appointment_Date__c);

            //--get timezone offset for the store site on the date of the appointment
            apptParams.timeZoneOffset = Appt_AppointmentUtil.getTimeZoneOffset(apptImport.Site_ID__c.trim(), apptDate);

            //-- figure out if the appointment is in past or future 
            if (apptDate <= Date.today()) apptParams.isFutureAppointment = false;
            else apptParams.isFutureAppointment = true;

            if (apptParams.isFutureAppointment) System.debug(LPREFIX + '!!!!!!!! Appointment is FUTURE - Legacy_Appointment_ID:'+apptImport.Legacy_Appointment_ID__c    );

            //-- figure out status from CSV file codes, or if blank figure out status based on if past appt (Completed) or future appt (Scheduled)
            if (String.isBlank(apptImport.Appointment_Status__c)) {

                if (apptParams.isFutureAppointment) apptParams.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
                //--if past appointment and status column blank, set status = CANCELLED, per Taral on 4/19/21 in Appointment Cutover testing meeting
                else apptParams.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED;

            } else {
                if (apptImport.Appointment_Status__c.trim() == Appt_ConstantValues.IMPORT_APPOINTMENT_STATUS_CODE_CANCELED) {
                    apptParams.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED;
                } else if (apptImport.Appointment_Status__c.trim() == Appt_ConstantValues.IMPORT_APPOINTMENT_STATUS_CODE_MISSED) {
                    apptParams.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED;
                } else {
                    apptParams.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED;
                }
            }

        } else {
            throw new Appt_AppointmentException('NOT FOUND - ServiceTerritory (store) not found for siteID='+apptImport.Site_ID__c, Integer.valueOf(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_NOT_FOUND));
        }

        System.debug(LPREFIX + 'AppointmentParams() EXIT - apptParams='+apptParams);
        return apptParams;
    }
    

    //-- load cache Maps for this chunk of appointment imports
    private static void populateIdMaps(Set<String> posCustomerIdList, Set<String> hybrisCustomerIdList, Set<String> guidCustomerIdList, Set<String> posVehicleIdList, Set<String> hybrisVehicleIdList, Set<String> storeSiteIdList) {
        System.debug(LPREFIX + 'populateIdMaps() ENTRY');
        if (posCustomerIdList != null) System.debug(LPREFIX + 'posCustomerIdList size='+posCustomerIdList.size()+' :'+posCustomerIdList);
        if (hybrisCustomerIdList != null) System.debug(LPREFIX + 'hybrisCustomerIdList size='+hybrisCustomerIdList.size()+' :'+hybrisCustomerIdList);
        if (guidCustomerIdList != null) System.debug(LPREFIX + 'guidCustomerIdList size='+guidCustomerIdList.size()+' :'+guidCustomerIdList);
        if (posVehicleIdList != null) System.debug(LPREFIX + 'posVehicleIdList size='+posVehicleIdList.size()+' :'+posVehicleIdList);
        if (hybrisVehicleIdList != null) System.debug(LPREFIX + 'hybrisVehicleIdList size='+hybrisVehicleIdList.size()+' :'+hybrisVehicleIdList);
        if (storeSiteIdList != null) System.debug(LPREFIX + 'storeSiteIdList size='+storeSiteIdList.size()+' :'+storeSiteIdList);

        if (insertedAccountIdList == null) insertedAccountIdList = new List<id>();
        System.debug(LPREFIX + 'insertedAccountIdList size='+insertedAccountIdList.size()+' :'+insertedAccountIdList);

        if (insertedVehAssetIdList == null) insertedVehAssetIdList = new List<id>();
        System.debug(LPREFIX + 'insertedVehAssetIdList size='+insertedVehAssetIdList.size()+' :'+insertedVehAssetIdList);

        Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();

        //-- hard code for now - TODO REMOVE HARD CODING
        vehicleTypeCodeMap.put('PAS', 'Passenger');
        vehicleTypeCodeMap.put('LT', 'Light Truck');
        vehicleTypeCodeMap.put('COM', 'Commercial');
        vehicleTypeCodeMap.put('EQP', 'Equipment');
        vehicleTypeCodeMap.put('TLR', 'Trailer');

        //-- retrieve Accounts by posCustomerIdList
        if (posCustomerIdList != null && posCustomerIdList.size() > 0) {

            List<Account> posAccounts = [SELECT Id, PersonContactId, POS_Customer_ID__c, Hybris_Customer_Id__c, GUID__c FROM Account 
                                        WHERE POS_Customer_ID__c IN :posCustomerIdList OR Id IN :insertedAccountIdList];
            System.debug(LPREFIX + '    POST SOQL,  posAccounts:' + posAccounts);

            if (posAccounts != null && posAccounts.size() > 0) {
                for (Account pAcnt: posAccounts) {
                    //System.debug(LPREFIX + '    puting on posCustomerAccountMap  POS_Customer_ID__c=' + pAcnt.POS_Customer_ID__c + ', account Id = '+pAcnt.Id);
                    if (!String.isBlank(pAcnt.POS_Customer_ID__c)) posCustomerAccountMap.put(pAcnt.POS_Customer_ID__c.trim(), pAcnt);
                }
                System.debug(LPREFIX + '    put ' + posAccounts.size() + ' retrieved Accounts in posCustomerAccountIdMap');
            }
        }

        //-- retrieve Accounts by hybrisCustomerIdList
        if (hybrisCustomerIdList != null && hybrisCustomerIdList.size() > 0) {
            List<Account> hybrisAccounts = [SELECT Id, PersonContactId, Hybris_Customer_Id__c, POS_Customer_ID__c, GUID__c FROM Account 
                                            WHERE Hybris_Customer_Id__c IN :hybrisCustomerIdList OR Id IN :insertedAccountIdList];

            if (hybrisAccounts != null && hybrisAccounts.size() > 0) {
                for (Account hAcnt: hybrisAccounts) {
                    if (!String.isBlank(hAcnt.Hybris_Customer_Id__c)) hybrisCustomerAccountMap.put(hAcnt.Hybris_Customer_Id__c.trim(), hAcnt);
                }
                System.debug(LPREFIX + '    put ' + hybrisAccounts.size() + ' retrieved Accounts in hybrisCustomerAccountIdMap');
            }
        }

        //-- retrieve Accounts by guidCustomerIdList
        if (guidCustomerIdList != null && guidCustomerIdList.size() > 0) {
            List<Account> guidAccounts = [SELECT Id, PersonContactId, GUID__c, Hybris_Customer_Id__c, POS_Customer_ID__c FROM Account 
                                        WHERE GUID__c IN :guidCustomerIdList OR Id IN :insertedAccountIdList];

            if (guidAccounts != null && guidAccounts.size() > 0) {
                for (Account gAcnt: guidAccounts) {
                    System.debug(LPREFIX + '    puting on guidCustomerAccountMap  GUID__c=' + gAcnt.GUID__c + ', account Id = '+gAcnt.Id);
                    if (!String.isBlank(gAcnt.GUID__c)) guidCustomerAccountMap.put(gAcnt.GUID__c.trim(), gAcnt);
                }
                System.debug(LPREFIX + '    put ' + guidAccounts.size() + ' retrieved Account IDs in guidCustomerAccountMap');
            }
        }

        //-- retrieve vehicle Assets by posVehicleIdList
        if (posVehicleIdList != null && posVehicleIdList.size() > 0) {
            List<Asset> pAssets = [SELECT Id, POS_Customer_Vehicle_ID__c, Hybris_Customer_Vehicle_ID__c, Name FROM Asset 
                                WHERE (POS_Customer_Vehicle_ID__c IN :posVehicleIdList OR Id IN :insertedVehAssetIdList) AND RecordTypeId = :vehRecordTypeId];

            if (pAssets != null && pAssets.size() > 0) {
                for (Asset pAsset: pAssets) {
                    if (!String.isBlank(pAsset.POS_Customer_Vehicle_ID__c)) posVehicleAssetMap.put(pAsset.POS_Customer_Vehicle_ID__c.trim(), pAsset);
                }
                //System.debug(LPREFIX + '    put ' + pAssets.size() + ' retrieved Asset IDs in posVehicleAssetMap');
            }
        }

        //-- retrieve vehicle Assets by hybrisVehicleIdList
        if (hybrisVehicleIdList != null && hybrisVehicleIdList.size() > 0) {
            List<Asset> hAssets = [SELECT Id, Hybris_Customer_Vehicle_ID__c, POS_Customer_Vehicle_ID__c, Name FROM Asset 
                                WHERE (Hybris_Customer_Vehicle_ID__c IN :hybrisVehicleIdList OR Id IN :insertedVehAssetIdList) AND RecordTypeId = :vehRecordTypeId];

            if (hAssets != null && hAssets.size() > 0) {
                for (Asset hAsset: hAssets) {
                    if (!String.isBlank(hAsset.Hybris_Customer_Vehicle_ID__c)) hybrisVehicleAssetMap.put(hAsset.Hybris_Customer_Vehicle_ID__c.trim(), hAsset);
                }
            }
        }

        //-- retrieve FSL metadata about the store (ServiceTerritry via the ServiceTerritoryMember)
        if (storeSiteIdList != null && storeSiteIdList.size() > 0) {
            AppointmentParams siteApptParams;
            List<ServiceTerritoryMember> servTerritoryList = [SELECT ServiceTerritoryId, ServiceResourceId, ServiceTerritory.Scheduling_Policy__c, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, ServiceTerritory.Back_Appointment_Work_Type__c, ServiceTerritory.Appt_Record_Owner__c
                        FROM ServiceTerritoryMember WHERE ServiceTerritory.Site_Account__r.SAP_STORE_ID__c IN :storeSiteIdList AND ServiceResource.Type__c = :Appt_ConstantValues.SERVICE_RESOURCE_TYPE_BACK];

            if (servTerritoryList != null && servTerritoryList.size() > 0) {
                for (ServiceTerritoryMember servTerritory: servTerritoryList) {

                    //loop through siteAppointmentParamsList, build AppointmentParams object, and put on Map with siteId as key
                    siteApptParams = new AppointmentParams();
                    siteApptParams.serviceTerritoryId = servTerritory.ServiceTerritoryId;
                    siteApptParams.schedulingPolicyId = servTerritory.ServiceTerritory.Scheduling_Policy__c;
                    siteApptParams.backroomWorkTypeId = servTerritory.ServiceTerritory.Back_Appointment_Work_Type__c;
                    siteApptParams.backroomServiceResourceId = servTerritory.ServiceResourceId;
                    siteApptParams.appointmentRecordOwnerId = servTerritory.ServiceTerritory.Appt_Record_Owner__c;

                    storeAppointmentParamsMap.put(servTerritory.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, siteApptParams);
                }
            }
        }

        System.debug(LPREFIX + 'populateIdMaps() EXIT');
    }

    //-- get next batch of Appt_Appointment_Import__c records to process, loop through them to build cache Maps and to set status to In Progress
    private static List<Appt_Appointment_Import__c> prepApptImportBatchData(List<Appt_Appointment_Import__c> apptImportList) {
        System.debug(LPREFIX + 'prepApptImportBatchData() ENTRY');

        //-- Sets containing unique IDs in the Import batch, to be used to build cache Maps
        Set<String> hybrisCustomerIdList = new Set<String>();
        Set<String> posCustomerIdList = new Set<String>();
        Set<String> guidCustomerIdList = new Set<String>();
        Set<String> hybrisVehicleIdList = new Set<String>();
        Set<String> posVehicleIdList = new Set<String>();
        Set<String> storeSiteIdList = new Set<String>();

        if (apptImportList != null) System.debug(LPREFIX + ' Appt_Appointment_Import__c SOQL - number RETRIEVED = '+apptImportList.size());



        //-- loop through result once to update import records to be status = In Progress, as well as create Hybris, POS and Guid ID Lists
        for (Appt_Appointment_Import__c appt: apptImportList) {

            //populate ID Lists to be used to query existing accounts and vehicle assets
            if (!String.isBlank(appt.Hybris_Customer_ID__c)) hybrisCustomerIdList.add(appt.Hybris_Customer_ID__c.trim());
            if (!String.isBlank(appt.POS_Customer_ID__c)) posCustomerIdList.add(appt.POS_Customer_ID__c.trim());
            if (!String.isBlank(appt.GUID__c)) guidCustomerIdList.add(appt.GUID__c.trim());
            if (!String.isBlank(appt.Hybris_Customer_Vehicle_ID__c)) hybrisVehicleIdList.add(appt.Hybris_Customer_Vehicle_ID__c.trim());
            if (!String.isBlank(appt.POS_Customer_Vehicle_ID__c)) posVehicleIdList.add(appt.POS_Customer_Vehicle_ID__c.trim());
            if (!String.isBlank(appt.Site_ID__c)) storeSiteIdList.add(appt.Site_ID__c.trim());
        }

        //-- Setup cache Maps
        populateIdMaps(posCustomerIdList, hybrisCustomerIdList, guidCustomerIdList, posVehicleIdList, hybrisVehicleIdList, storeSiteIdList);

        System.debug(LPREFIX + 'prepApptImportBatchData() EXIT');
        return apptImportList;
    }

    //---Check the Limits
    public static Boolean areLimitsOk()
    {
        if (!checkLimit('DML', Limits.getLimitDMLStatements(), Limits.getDMLStatements(), false)) {
            System.debug( LPREFIX + 'WARNING! DML Limits are NOT OK: ' + checkLimit('DML', Limits.getLimitDMLStatements(), Limits.getDMLStatements(), true));
            return false;
        }
        if (!checkLimit('Queries', Limits.getLimitQueries(), Limits.getQueries(), false)) {
            System.debug( LPREFIX + 'WARNING! Queries Limits are NOT OK: ' + checkLimit('Queries', Limits.getLimitQueries(), Limits.getQueries(), true));
            return false;
        }
        if (!checkLimit('CPU', Limits.getLimitCpuTime(), Limits.getCpuTime(),false)) {
            System.debug( LPREFIX + 'WARNING! CPU Limits are NOT OK: ' + checkLimit('CPU', Limits.getLimitCpuTime(), Limits.getCpuTime(), true));
            return false;
        }
        
        return true;
    }
    

    //---Check a single limit value
    public static boolean checkLimit(String limitName, Integer limitLimit, Integer limitValue) {
        return checkLimit(limitName, limitLimit, limitValue, false);
    }
    public static boolean checkLimit(String limitName, Integer limitLimit, Integer limitValue, Boolean logLimit)
    {
        if (logLimit) System.debug( LPREFIX + ' checkLimit() ENTRY for ' + limitName + ', limitLimit:' + limitLimit + ' current limitValue: ' + limitValue);
        if (limitValue > (LIMIT_PERCENT * limitLimit))
        {
            System.debug( LPREFIX + 'WARNING!' + limitName + ' limit too close for, limit is:' + limitLimit + ' current value is: ' + limitValue);
            return false;
        }
        return true;
    }


    private class AccountWrapper {
        Account acnt;

        public AccountWrapper(Account acnt) {
            this.acnt = acnt;
        }
    }

    private class VehAssetWrapper {
        AccountWrapper acntWrap;
        Asset vehAsset;

        public VehAssetWrapper(Asset vehAsset, AccountWrapper acntWrap) {
            this.vehAsset = vehAsset;
            this.acntWrap = acntWrap;
        }
    }

    private class WorkOrderWrapper {
        AccountWrapper  acntWrap;
        VehAssetWrapper vehAssetWrap;
        WorkOrder wrkOrder;

        public workOrderWrapper(WorkOrder wrkOrder, AccountWrapper  acntWrap, VehAssetWrapper vehAssetWrap) {
            this.wrkOrder = wrkOrder;
            this.acntWrap = acntWrap;
            this.vehAssetWrap = vehAssetWrap;
        }
    }

    private class ServiceAppointmentWrapper {
        workOrderWrapper woWrap;
        ServiceAppointment servAppt;
        AppointmentParams apptParams;

        public ServiceAppointmentWrapper(ServiceAppointment servAppt, workOrderWrapper woWrap) {
            this.servAppt = servAppt;
            this.woWrap = woWrap;
        }
    }

    private class AppointmentImportWrapper {
        Appt_Appointment_Import__c apptImp;
        workOrderWrapper woWrap;
    }


    private class AppointmentParams {
        Id serviceTerritoryId;
        Id schedulingPolicyId;
        Id backroomWorkTypeId;
        Id backroomServiceResourceId;
        Integer timeZoneOffset = 0;
        Boolean isFutureAppointment = false;
        String appointmentStatus;
        String appointmentRecordOwnerId; 
    }
}