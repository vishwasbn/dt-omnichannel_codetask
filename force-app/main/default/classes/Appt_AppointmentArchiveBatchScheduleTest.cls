/******************************************************************************************************
 * Project : Appointment3.0
 *******************************************************************************************************
 * Business Owner : Discount Tire
 * Purpose        : Test class for Appt_AppointmentArchiveBatchSchedule.
 *******************************************************************************************************
 * Version   Date         		 Updated By
 * 1.0       01/13/2023
 ********************************************************************************************************/
@isTest(seeAllData=false)
public with sharing class Appt_AppointmentArchiveBatchScheduleTest {
  final static string LPREFIX = 'LOG Appt_AppointmentArchiveBatchScheduleTest: ';

  @TestSetup
  public static void setupTestData() {
    // User set up Appt3.0
    User pOSUser = Appt_TestUtil.getPosTerminalUser(
      'TestPos',
      'TerminalTestUser'
    );
    pOSUser.User_Store_Id__c = 'RIP05';
    update pOSUser;
    //end
    //-- this will setup a store with 27 days of slots
    List<ServiceAppointment> servAppts = Appt_TestUtil.basicAppointment_StoreConfiguration();
    System.debug(servAppts);

    // progress Appointment to Scheduled
    servAppts[0]
      .Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
    servAppts[1]
      .Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
    // change the appointment time so it passes whenever the test is run
    //    the test will fail in off hours otherwise.
    Datetime currentDatetime = Datetime.now().addDays(-367);
    String dateString = String.valueOf(Date.valueOf(currentDatetime));
    servAppts[0].EarliestStartTime = currentDatetime;
    servAppts[0].DueDate = currentDatetime.addMinutes(20);
    servAppts[1].EarliestStartTime = currentDatetime.addMinutes(20);
    servAppts[1].DueDate = currentDatetime.addMinutes(40);
    servAppts[0].Date_String__c = dateString;
    servAppts[1].Date_String__c = dateString;
    update servAppts;
  }

  @isTest
  static void testFindAppointmentsToArchive() {
    List<ServiceAppointment> servAppts = [
      SELECT
        Id,
        Work_Order__r.Id,
        Status,
        EarliestStartTime,
        DueDate,
        Date_String__c,
        ParentRecordId
      FROM ServiceAppointment
    ];
    System.debug(servAppts);

    // Appt 3.0 change --start
    String workOrderId = servAppts[0].Work_Order__r.Id;
    //Creating WOLI Object record
    WorkOrderLineItem lineItem = new WorkOrderLineItem();
    lineItem.WorkOrderId = workOrderId;
    lineItem.WOM_Article_Description__c = 'Description for testing WOLI';
    lineItem.WOM_Article_Number__c = '0000011111';
    lineItem.WOM_Article_Quantity__c = 5;
    lineItem.WOM_ArticleSize__c = 'Sample Size';
    lineItem.Appt3_Article_Type__c = 'Electronics';
    lineItem.Appt3_Treadwell__c = false;
    insert lineItem;
    // Appt 3.0 change --end

    Test.startTest();
    Appt_AppointmentArchiveBatchSchedule batch = new Appt_AppointmentArchiveBatchSchedule(
      1
    );
    // batch.findAppointmentsToArchive();
    batch.execute(null);
    Test.stopTest();

    System.assertEquals(
      2,
      servAppts.size(),
      'There are not 2 Service Appointments present'
    );

    List<ServiceAppointment> servApptsUpdated = [
      SELECT
        Id,
        Archive_Status__c,
        Status,
        SchedStartTime,
        Date_String__c,
        ParentRecordId
      FROM ServiceAppointment
    ];

    // Since this is a synchronous batch process, Find -> Process -> Delete will result in 0 service appointments
    System.assertEquals(
      0,
      servApptsUpdated.size(),
      'There should not be any serviceAppointments after batch is run.'
    );
  }

  @isTest
  static void testArchiveBatchSetupSchedule() {
    Test.startTest();

    Appt_AppointmentArchiveBatchSchedule.setupSchedule();

    Test.stopTest();

    List<CronTrigger> cronList = [
      SELECT
        Id,
        CronJobDetail.Name,
        CronExpression,
        TimeZoneSidKey,
        TimesTriggered,
        NextFireTime,
        CreatedById
      FROM CronTrigger
      WHERE CronJobDetail.Name LIKE 'Appt_AppointmentArchiveBatchTest%'
      ORDER BY CronJobDetail.Name
    ];

    System.assertEquals(
      2,
      cronList.size(),
      'incorrect number of Scheduled jobs'
    );

    Integer hourIdx = 1;
    Integer seqIdx = 1;
    for (CronTrigger ct : cronList) {
      System.debug(LPREFIX + 'CRON trigger: ' + ct.CronJobDetail.Name);
      String cronStr = (math.mod(hourIdx, 2) > 0)
        ? '0, 1 * * * ?'
        : '0, 16 * * * ?';

      String cronName =
        'Appt_AppointmentArchiveBatchTest ' +
        seqIdx +
        ' at: ' +
        cronStr;
      System.assertEquals(
        cronName,
        ct.CronJobDetail.Name,
        'CRON Expression ' + seqIdx + ' is wrong.'
      );

      if (math.mod(hourIdx, 2) == 0) {
        ++seqIdx;
      }
      ++hourIdx;
    }
  }
  // test method to check archiving and purging process
  @isTest
  static void testWithBulkAppointmentsToArchive() {
    user currentUser = [
      SELECT id, username, LastName, User_Store_Id__c
      FROM user
      WHERE LastName = 'TerminalTestUser' AND FirstName = 'TestPos'
      LIMIT 1
    ];
    Workorder wo = [SELECT id, AccountId FROM workorder LIMIT 1];
    //Creating WOLI Object record
    WorkOrderLineItem lineItem = new WorkOrderLineItem();
    lineItem.WorkOrderId = wo.Id;
    lineItem.WOM_Article_Description__c = 'Description for testing WOLI';
    lineItem.WOM_Article_Number__c = '0000011111';
    lineItem.WOM_Article_Quantity__c = 5;
    lineItem.WOM_ArticleSize__c = 'Sample Size';
    lineItem.Appt3_Article_Type__c = 'Electronics';
    lineItem.Appt3_Treadwell__c = false;
    insert lineItem;

    Account acc = [
      SELECT id, SAP_STORE_ID__c
      FROM Account
      WHERE id = :wo.AccountId
    ];
    WorkType orderWorkType = [SELECT id FROM WorkType LIMIT 1];
    List<Contact> custContacts = [
      SELECT Id
      FROM Contact
      WHERE AccountId = :acc.Id
    ];
    ServiceTerritory servTerr = [SELECT id FROM ServiceTerritory LIMIT 1];
    FSL__Scheduling_Policy__c schedulePolicy = [
      SELECT id
      FROM FSL__Scheduling_Policy__c
      LIMIT 1
    ];

    Integer localTimeZoneOffset = -7;
    Integer appointmentDuration = 20;
    Date currentDate = (Datetime.now().format('u') == '7')
      ? Date.today().addDays(1)
      : Date.today();
    Time apptStartTime = Time.newInstance(8, 0, 0, 0);
    Time apptEndTime = Time.newInstance(8, 20, 0, 0);
    Datetime apptStartDateTime = Datetime.newInstance(
      currentDate,
      apptStartTime
    );
    Datetime apptEndDateTime = Datetime.newInstance(currentDate, apptEndTime);

    System.runAs(currentUser) {
      List<ServiceAppointment> applist = new List<ServiceAppointment>();
      for (integer i = 0; i < 10; i++) {
        apptStartDateTime = Datetime.newInstance(
          currentDate + i,
          apptStartTime
        );
        apptEndDateTime = Datetime.newInstance(currentDate + i, apptEndTime);
        applist.add(
          Appt_TestUtil.getServiceAppointment(
            currentUser.Id,
            wo.Id,
            acc.Id,
            orderWorkType.Id,
            custContacts[0].Id,
            servTerr.Id,
            acc.SAP_STORE_ID__c,
            apptStartDateTime,
            apptEndDateTime,
            localTimeZoneOffset,
            appointmentDuration,
            'Front Room',
            schedulePolicy.Id
          )
        );
      }

      List<serviceappointment> servAppts = [
        SELECT id
        FROM serviceappointment
        WHERE
          status = :Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING
          AND id IN :applist
      ];
      Assert.areEqual(servAppts.size(), 10, 'No ServiceAppointment created');
      // update dates for archive batch process
      List<serviceappointment> updateServAppt = new List<serviceappointment>();
      for (serviceappointment sa : servAppts) {
        sa.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        Datetime currentDatetime = Datetime.now().addDays(-367);
        String dateString = String.valueOf(Date.valueOf(currentDatetime));
        sa.EarliestStartTime = currentDatetime;
        sa.DueDate = currentDatetime.addMinutes(20);
        sa.Date_String__c = dateString;
        updateServAppt.add(sa);
      }
      update updateServAppt;
      //List<ServiceAppointment> totalServApptsBefore = [SELECT Id, Work_Order__r.Id, Status, EarliestStartTime, DueDate, Date_String__c, ParentRecordId FROM ServiceAppointment];

      Test.startTest();
      Appt_AppointmentArchiveBatchSchedule batch = new Appt_AppointmentArchiveBatchSchedule(
        1
      );
      batch.execute(null);
      Test.stopTest();
      // Total number of service appointments with appointment date as 365 days old before archival batch process runs.
      //System.assertEquals(10, totalServApptsBefore.size(), 'There are not 2 Service Appointments present');
      System.assertEquals(
        10,
        servAppts.size(),
        'There are not 2 Service Appointments present'
      );
      List<ServiceAppointment> servApptsUpdated = [
        SELECT
          Id,
          Archive_Status__c,
          Status,
          EarliestStartTime,
          DueDate,
          Date_String__c,
          ParentRecordId
        FROM ServiceAppointment
      ];

      // Since this is a synchronous batch process, Find -> Process -> Delete will result in 0 service appointments
      System.assertEquals(
        0,
        servApptsUpdated.size(),
        'There should not be any serviceAppointments after batch is run.'
      );
    }
  }
}