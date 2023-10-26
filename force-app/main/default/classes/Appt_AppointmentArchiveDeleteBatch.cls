/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This Batch queries all the ServiceAppointments that have an archive status of "Completed".  The related appointments are checked, if the status is completed for all, the Service Appointment and Work Order is deleted.
 */
public class Appt_AppointmentArchiveDeleteBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents {
  final static string LPREFIX = 'LOG Appt_AppointmentArchiveDeleteBatch: ';

  public final String batchQuery;
  public Appt_AppointmentArchiveDeleteBatch() {
    batchQuery =
      'SELECT Id, Work_Order__c, Related_Appointment__c, Related_Appointment__r.Archive_Status__c, Archive_Status__c, Work_Order__r.AccountId, Work_Order__r.Account.Appt_Archive_Ids__c, Work_Order__r.Account.Appt_Archive_Ids_WO__c FROM ServiceAppointment WHERE Archive_Status__c = ' +
      '\'' +
      Appt_ConstantValues.ARCHIVE_STATUS_COMPLETED +
      '\'';

    System.debug('batchQuery: ' + batchQuery);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    System.debug(LPREFIX + 'start');
    System.debug(LPREFIX + 'batchQuery: ' + batchQuery);
    return Database.getQueryLocator(batchQuery);
  }

  public void execute(
    Database.BatchableContext bc,
    List<ServiceAppointment> scope
  ) {
    System.debug(LPREFIX + 'stat execute');
    Integer failedCount = 0;

    // build account update lists
    Map<String, Account> acctIdMap = new Map<String, Account>(); // store SA ids on Appt_Archive_Ids__c

    // build delete lists
    List<ServiceAppointment> saToDeleteList = new List<ServiceAppointment>();
    List<WorkOrder> woToDeleteList = new List<WorkOrder>();

    // build Id sets to prevent duplicates from being added
    Set<Id> saToDeleteSet = new Set<Id>();
    Set<Id> woToDeleteSet = new Set<Id>();

    for (ServiceAppointment sa : scope) {
      if (
        sa.Related_Appointment__r != null &&
        sa.Related_Appointment__r.Archive_Status__c !=
        Appt_ConstantValues.ARCHIVE_STATUS_COMPLETED
      ) {
        System.debug(
          LPREFIX +
            ' Unable to delete SA and WO with WO Id: ' +
            sa.Work_Order__c +
            '. Related Appointment is not ready to Archive'
        );
        failedCount++;
      } else {
        // Add string big object id to Account
        try {
          getUpdatedArchiveIdsForAccount(sa, acctIdMap);
        } catch (exception e) {
          System.debug(
            LPREFIX +
              'error updating Account Archive Ids (SA.Id: ' +
              sa.Id +
              '): ' +
              e.getMessage()
          );
          //Addedd for SO-41
          Logger logInstance = Logger.getInstance();

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
            Appt_AppointmentArchiveDeleteBatch.class.getName(),
            errDetails
          ); // SO-41 END
        }

        // populate SA and WOs to delete
        saToDeleteSet.add(sa.Id);
        woToDeleteSet.add(sa.Work_Order__c);
      }
    }

    // update account records
    if (acctIdMap.size() > 0) {
      update acctIdMap.values();
    }

    // delete SA records
    if (saToDeleteSet.size() > 0) {
      for (Id saId : saToDeleteSet) {
        saToDeleteList.add(new ServiceAppointment(Id = saId));
        // System.debug('Delete ServiceAppointment: ' + saId);
      }

      delete saToDeleteList;
    }

    // delete WO records
    if (woToDeleteSet.size() > 0) {
      for (Id woId : woToDeleteSet) {
        if (woId != null) {
          woToDeleteList.add(new WorkOrder(Id = woId));
        }
        // System.debug('Delete WorkOrder: ' + woId);
      }

      delete woToDeleteList;
    }

    System.debug(
      LPREFIX +
        ' ' +
        saToDeleteList.size() +
        ' ServiceAppointment records deleted'
    );
    System.debug(
      LPREFIX + ' ' + woToDeleteList.size() + ' WorkOrder records deleted'
    );
    System.debug(
      LPREFIX + ' Unable to delete ' + String.valueOf(failedCount) + ' records'
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

  public static void getUpdatedArchiveIdsForAccount(
    ServiceAppointment sa,
    Map<String, Account> accountIdMap
  ) {
    if (sa.Work_Order__r == null || sa.Work_Order__r.AccountId == null) {
      System.debug(LPREFIX + 'invalid SA - no Acct Id found: ' + sa.Id);
      return;
    }

    // null check for existing stored Archive Ids
    String existingSAIds = (sa.Work_Order__r.Account.Appt_Archive_Ids__c !=
      null)
      ? sa.Work_Order__r.Account.Appt_Archive_Ids__c
      : '';
    String existingWOIds = (sa.Work_Order__r.Account.Appt_Archive_Ids_WO__c !=
      null)
      ? sa.Work_Order__r.Account.Appt_Archive_Ids_WO__c
      : '';

    // Add Archive ServiceAppointmentIds to Account
    if (!accountIdMap.containsKey(sa.Work_Order__r.AccountId)) {
      // first time adding value to map
      String newValueSA = (existingSAIds != '')
        ? existingSAIds + ',' + sa.Id
        : sa.Id;
      String newValueWO = (existingWOIds != '')
        ? existingWOIds + ',' + sa.Work_Order__c
        : sa.Work_Order__c;

      accountIdMap.put(
        sa.Work_Order__r.AccountId,
        new Account(
          Id = sa.Work_Order__r.AccountId,
          Appt_Archive_Ids__c = newValueSA,
          Appt_Archive_Ids_WO__c = newValueWO
        )
      );
    } else {
      // update existing value in map
      Account existingAcct = accountIdMap.get(sa.Work_Order__r.AccountId);

      accountIdMap.get(sa.Work_Order__r.AccountId).Appt_Archive_Ids__c =
        existingAcct.Appt_Archive_Ids__c +
        ',' +
        sa.Id;
      accountIdMap.get(sa.Work_Order__r.AccountId).Appt_Archive_Ids_WO__c =
        existingAcct.Appt_Archive_Ids_WO__c +
        ',' +
        sa.Work_Order__c;
    }
  } // End of getUpdatedArchiveIdsForAccount()

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
  }
}