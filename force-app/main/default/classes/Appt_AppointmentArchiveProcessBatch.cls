/******************************************************************************************************
 * Project : Appointment3.0
 *******************************************************************************************************
 * Business Owner :
 * Purpose        : This Batch queries all the ServiceAppointments and the associated Work Order data that have an archive status of "Processing".  The Batch builds Big Object archive records for each ServiceAppointment record and updates the ServiceAppointment records Archive status to "Completed" (unless there is a failure in which case there is a failure counter and when that count is reached the Archive Status is set to "Failure").  When all the records have been process the Big Objects (a-Master, b-workorder, c, d) are DMLed immediately.  Then the ServiceAppointment records are updated.
 *******************************************************************************************************
 * Version   Date          Updated By            		 	Test        Target        Comments
 * 1.0		06/14/2022    craig.petersen@appsassociates.com
 * 2.0       12/27/2022    prakhar.shukla@capgemini.com   	92%
 ********************************************************************************************************/
public class Appt_AppointmentArchiveProcessBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents {
  final static string LPREFIX = 'LOG Appt_AppointmentArchiveProcessBatch: ';
  public Integer maxRetryCount;

  //Addedd for SO-41
  public static Logger logInstance = Logger.getInstance();

  public final String batchQuery;
  public Appt_AppointmentArchiveProcessBatch() {
    // Updated query with new Appt 3.0 fields
    batchQuery =
      'SELECT id, Archive_Status__c, Archive_Try_Count__c, Status, Work_Order__c, Related_Appointment__c, Work_Order__r.Appt3_Sales_Order_Id__c, Work_Order__r.Account.Appt3_Fleet_Number__c, ' +
      'Work_Order__r.Account.Appt3_Customer_Id__c, Work_Order__r.Account.Appt3_AAA_Membership__c, Work_Order__r.Account.Appt3_Military__c, Work_Order__r.Account.Appt3_Private_Label_Cardholder__c, ' +
      'Work_Order__r.Vehicle__r.Appt3_Fitment_Lift_Id__c, Work_Order__r.Account.Appt3_Company_Name__c, Work_Order__r.Vehicle__r.Appt3_Front_Tire_Size__c, Work_Order__r.Vehicle__r.Appt3_Rear_Tire_Size__c, ' +
      'Work_Order__r.Vehicle__r.Appt3_Front_Tire_Diameter__c, Work_Order__r.Vehicle__r.Appt3_Rear_Tire_Diameter__c, Work_Order__r.Vehicle__r.Appt3_Assembly_Type__c, ' +
      'Work_Order__r.Vehicle__r.Appt3_Color__c, Work_Order__r.Vehicle__r.Appt3_Generic_Vehicle_Category__c, Work_Order__r.Vehicle__r.Appt3_Generic_Vehicle_SubCategory__c, ' +
      'Work_Order__r.Vehicle__r.Appt3_Customer_Vehicle_Id__c, Work_Order__r.Vehicle__r.Appt3_Type_Of_Vehicle__c, Date_String__c, SchedStartTime, ' +
      'Consult_Start_Time__c, Consult_End_Time__c, Back_Office_Start_Time__c, Back_Office_End_Time__c, Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c, ' +
      'Appt_Appointment_Last_Modified_By__c, Appt_Appointment_Last_Modified_Date__c, Appointment_Rescheduled__c, Original_Date_String__c, Original_End_Time_String__c, Original_Start_Time_String__c, ' +
      'Work_Order__r.Account.Appt_Customer_Type__c, Work_Order__r.AccountId, Work_Order__r.Account.POS_Customer_Id__c, Work_Order__r.Account.Hybris_Customer_Id__c, ' +
      'Work_Order__r.Account.GUID__c, Work_Order__r.Source__c, Work_Order__r.Order_Type__c, Work_Order__r.Form_Type__c, Work_Order__r.Form_Number__c, Work_Order__r.Form_Date__c, Work_Order__r.Hybris_Order_Id__c, ' +
      'Work_Order__r.POS_Web_Order_Id__c, Work_Order__r.Layaway_Number__c, Work_Order__r.Quote_Number__c, Work_Order__r.Invoice_Number__c, Work_Order__r.Order_Date__c, ' +
      'Work_Order__r.Appointment_Comments__c, Work_Order__r.Cancel_Reason__c, Work_Order__r.Cancel_Reason_Code__c, Work_Order__r.Vehicle__r.POS_Customer_Vehicle_Id__c, ' +
      'Work_Order__r.Vehicle__r.Hybris_Customer_Vehicle_Id__c, Work_Order__r.Vehicle__r.Vehicle_Type_Other__c, Work_Order__r.Vehicle__r.Vehicle_Manufacture_Year__c, ' +
      'Work_Order__r.Vehicle__r.Vehicle_Make__c, Work_Order__r.Vehicle__r.Vehicle_Model__c, Work_Order__r.Vehicle__r.Vehicle_Id__c, Work_Order__r.Vehicle__r.Trim_Id__c, Work_Order__r.Vehicle__r.Assembly_Id__c' +
      ' FROM ServiceAppointment ' +
      'WHERE Archive_Status__c = \'' +
      Appt_ConstantValues.ARCHIVE_STATUS_PROCESSING +
      '\'';

    System.debug('batchQuery: ' + batchQuery);
    List<Appt_Appointment_Setting__mdt> settings = Appt_SettingUtil.getApptSettings();
    maxRetryCount = Integer.valueOf(
      Appt_SettingUtil.getSettingValue(
        Appt_ConstantValues.ARCHIVE_MAX_ATTEMPTS,
        settings
      )
    );
  } // End of Appt_AppointmentArchiveProcessBatch() - constructor

  public Database.QueryLocator start(Database.BatchableContext bc) {
    System.debug(LPREFIX + 'start');
    System.debug(LPREFIX + 'batchQuery: ' + batchQuery);
    return Database.getQueryLocator(batchQuery);
  } // End of start()

  public void execute(
    Database.BatchableContext bc,
    List<ServiceAppointment> scope
  ) {
    System.debug(LPREFIX + 'start execute');
    // Appt 3.0 - Appt3-140 change -start
    List<id> workOrderId = new List<id>();
    //List of work order ids from service appointments above
    for (ServiceAppointment s : scope) {
      workOrderId.add(s.Work_Order__c);
    }

    //Creating Map of work order id and related WorkOrderLineItems
    Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(
      [
        SELECT
          Id,
          (
            SELECT
              Id,
              WOM_Article_Number__c,
              Appt3_Article_Type__c,
              WOM_Article_Description__c,
              WOM_Article_Quantity__c,
              WOM_ArticleSize__c,
              Appt3_Treadwell__c
            FROM WorkOrderLineItems
            WHERE RecordType.DeveloperName = 'Appt3_Appointment_Articles'
          )
        FROM WorkOrder
        WHERE Id IN :workOrderId
      ]
    );
    // Appt 3.0 - Appt3-140 change -end

    // 0. Create Lists
    List<ServiceAppointment> saToUpdateList = new List<ServiceAppointment>(); // update Archive Status, and count
    List<Appt_Archive_a__b> masterArchiveList = new List<Appt_Archive_a__b>(); // primary archive object with limited Indexes
    List<Appt_Archive_b__b> woArchiveList = new List<Appt_Archive_b__b>(); // copy of master object with work order index
    List<Appt_Archive_c__b> dateArchiveList = new List<Appt_Archive_c__b>(); // copy of master object with date index
    List<Appt_Archive_d__b> logArchiveList = new List<Appt_Archive_d__b>(); // copy of master with index on Site, SchedStartTime, Status, Id

    System.debug(
      LPREFIX +
        ' ' +
        scope.size() +
        ' SA Records found in Archive Status "Processing"'
    );
    Integer processedCount = scope.size();

    for (ServiceAppointment sa : scope) {
      // process service appointments
      if (sa.Archive_Try_Count__c >= maxRetryCount) {
        // If try count > max # of tries, set change the status to failed
        saToUpdateList.add(
          new ServiceAppointment(
            Id = sa.Id,
            Archive_Status__c = Appt_ConstantValues.ARCHIVE_STATUS_FAILED
          )
        );
      } else {
        try {
          buildArchiveRecords(
            sa,
            woMap.get(sa.Work_Order__c).WorkOrderLineItems,
            masterArchiveList,
            woArchiveList,
            dateArchiveList,
            logArchiveList
          );

          // update try count and status for all successfully built items
          // ---TODO: Set try count and complete later if possible---
          saToUpdateList.add(
            new ServiceAppointment(
              Id = sa.Id,
              Archive_Status__c = Appt_ConstantValues.ARCHIVE_STATUS_COMPLETED,
              Archive_Try_Count__c = (sa.Archive_Try_Count__c != null)
                ? sa.Archive_Try_Count__c + 1
                : 0
            )
          );
        } catch (exception e) {
          //Added loging message for SO-41
          String errDetails = 'Cause: ' + e.getCause() + '\n';
          errDetails = errDetails + 'LineNumber: ' + e.getLineNumber() + '\n';
          errDetails =
            errDetails +
            'Stack trace: ' +
            e.getStackTraceString() +
            '\n';
          errDetails = errDetails + 'Message: ' + e.getMessage();
          logInstance.Log(
            LPREFIX,
            Appt_AppointmentArchiveProcessBatch.class.getName(),
            errDetails
          );

          // update try count for all failed records
          System.debug(
            LPREFIX +
              ' error processing big object records for sa: ' +
              sa.Id +
              '; ' +
              e.getMessage()
          );
          System.debug('Cause: ' + e.getCause());
          System.debug('Line number: ' + e.getLineNumber());
          System.debug('Stack trace: ' + e.getStackTraceString());
          saToUpdateList.add(
            new ServiceAppointment(
              Id = sa.Id,
              Archive_Try_Count__c = (sa.Archive_Try_Count__c != null)
                ? sa.Archive_Try_Count__c + 1
                : 0
            )
          );
        }
      }
    }

    // 2. Insert Archive Records
    if (masterArchiveList.size() > 0) {
      Database.SaveResult[] masterSr = (Test.isRunningTest())
        ? (List<Database.SaveResult>) JSON.deserialize(
            '[{"success":true,"id":"0013000000abcde"}]',
            List<Database.SaveResult>.class
          )
        : Database.insertImmediate(masterArchiveList);
      handleSr(masterSR);
    }
    if (woArchiveList.size() > 0) {
      Database.SaveResult[] woSr = (Test.isRunningTest())
        ? (List<Database.SaveResult>) JSON.deserialize(
            '[{"success":true,"id":"0013000000abcde"}]',
            List<Database.SaveResult>.class
          )
        : Database.insertImmediate(woArchiveList);
      handleSr(woSr);
    }
    if (dateArchiveList.size() > 0) {
      Database.SaveResult[] dateSr = (Test.isRunningTest())
        ? (List<Database.SaveResult>) JSON.deserialize(
            '[{"success":true,"id":"0013000000abcde"}]',
            List<Database.SaveResult>.class
          )
        : Database.insertImmediate(dateArchiveList);
      handleSr(dateSr);
    }
    if (logArchiveList.size() > 0) {
      Database.SaveResult[] logSr = (Test.isRunningTest())
        ? (List<Database.SaveResult>) JSON.deserialize(
            '[{"success":true,"id":"0013000000abcde"}]',
            List<Database.SaveResult>.class
          )
        : Database.insertImmediate(logArchiveList);
      handleSr(logSr);
    }

    // 3.  Update max attempt records, complete statuses and try count
    // may need to make a future call
    if (saToUpdateList.size() > 0) {
      try {
        update saToUpdateList;
      } catch (exception e) {
        //Added loging message for SO-41
        String errDetails = 'Cause: ' + e.getCause() + '\n';
        errDetails = errDetails + 'LineNumber: ' + e.getLineNumber() + '\n';
        errDetails =
          errDetails +
          'Stack trace: ' +
          e.getStackTraceString() +
          '\n';
        errDetails = errDetails + 'Message: ' + e.getMessage();
        logInstance.Log(
          LPREFIX,
          Appt_AppointmentArchiveProcessBatch.class.getName(),
          errDetails
        );
        System.debug(
          'unable to update maxAttemptSA records: ' + e.getMessage()
        );
      }
    }

    System.debug(
      LPREFIX + ' Total Records Found in status "Processing": ' + processedCount
    );
    System.debug(
      LPREFIX +
        'master Archive Objects records attempted to create: ' +
        masterArchiveList.size()
    );
    System.debug(
      LPREFIX +
        ' ServiceAppointments updated with try count and status: ' +
        saToUpdateList.size()
    );

    // LIMIT statistics gathering
    System.debug(LPREFIX + ' Limits:');
    String jstr = JSON.serialize(Job_Util.getLimitListSnapshot());
    List<String> jlist = jstr.Split('},');
    for (String obj : jList) {
      System.debug('Limits: ' + obj);
    }

    System.debug(LPREFIX + 'stop execute');
  } // End of execute()

  // Appt 3.0 - Appt3-140 change - we have added a new argument 'List<WorkOrderLineItem> wo' in this method to include new fields from Work Order Line Item object in this archive process
  // this method makes new records for big objects
  private static void buildArchiveRecords(
    ServiceAppointment sa,
    List<WorkOrderLineItem> wo,
    List<Appt_Archive_a__b> masterArchiveList,
    List<Appt_Archive_b__b> woArchiveList,
    List<Appt_Archive_c__b> dateArchiveList,
    List<Appt_Archive_d__b> logArchiveList
  ) {
    // Convert SA records to Master Big O
    Appt_ArchivePayloadModel saArchiveModel = new Appt_ArchivePayloadModel(
      sa,
      wo
    );
    String jsonModel = JSON.serialize(saArchiveModel);

    // create master archive
    masterArchiveList.add(
      new Appt_Archive_a__b(
        Date_String__c = sa.Date_String__c,
        Hybris_Customer_Id__c = sa.Work_Order__r.Account.Hybris_Customer_Id__c,
        Id__c = sa.Id,
        Payload__c = jsonModel,
        SchedStartTime__c = sa.SchedStartTime,
        Site_Id__c = saArchiveModel.siteId,
        Status__c = sa.Status,
        Work_Order__c = sa.Work_Order__c
      )
    );

    // create woArchiveList
    // indexes requried: work order, id
    if (sa.Work_Order__c != null) {
      woArchiveList.add(
        new Appt_Archive_b__b(
          Id__c = sa.Id,
          Work_Order__c = sa.Work_Order__c,
          Payload__c = jsonModel
        )
      );
    }

    // create dateArchiveList
    // indexes required: date string, hybris customer id, id
    if (
      sa.Date_String__c != null &&
      sa.Work_Order__r.Account.Hybris_Customer_Id__c != null
    ) {
      dateArchiveList.add(
        new Appt_Archive_c__b(
          Id__c = sa.Id,
          Hybris_Customer_Id__c = sa.Work_Order__r.Account.Hybris_Customer_Id__c,
          Date_String__c = sa.Date_String__c,
          Payload__c = jsonModel
        )
      );
    }

    // create logArchiveList
    // indexes required: siteId, SchedStartTime, Status, Id
    if (
      saArchiveModel.siteId != null &&
      sa.SchedStartTime != null &&
      sa.Status != null
    ) {
      logArchiveList.add(
        new Appt_Archive_d__b(
          Id__c = sa.Id,
          Site_Id__c = saArchiveModel.siteId,
          SchedStartTime__c = sa.SchedStartTime,
          Status__c = sa.Status,
          Payload__c = jsonModel
        )
      );
    }
  } // End of buildArchiveRecords()

  public static void handleSR(Database.SaveResult[] srList) {
    // handle success and failures
    for (Database.SaveResult sr : srList) {
      if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug(
          'Successfully inserted big object. Record ID: ' + sr.getId()
        );
      } else {
        for (Database.Error err : sr.getErrors()) {
          System.debug(
            LPREFIX +
              ' handleSave Result - The following error has occurred.' +
              err.getStatusCode() +
              ': ' +
              err.getMessage()
          );
          System.debug(LPREFIX + ' Error on recordId: ' + sr.getId());
        }
      }
    }
  } // End of handleSR()

  public void finish(Database.BatchableContext context) {
    Id batchId = context.getJobId();
    System.debug(LPREFIX + '::finish: batchId: ' + batchId);

    //---Checking final status of the Job
    AsyncApexJob apexJob = [
      SELECT
        Id,
        Status,
        ApexClassID,
        JobItemsProcessed,
        TotalJobItems,
        JobType,
        CompletedDate,
        ExtendedStatus
      FROM AsyncApexJob
      WHERE Id = :batchId
    ];
    System.debug(LPREFIX + 'apexJob: ' + apexJob);

    // Call the deleteBatch as the last step in the archiving process
    Database.executeBatch(new Appt_AppointmentArchiveDeleteBatch());
  }
}