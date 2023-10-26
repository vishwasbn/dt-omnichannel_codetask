/******************************************************************************************************
 * Project : Appointment3.0
 *******************************************************************************************************
 * Business Owner :
 * Purpose        : Test class for Appt3_AppointmentLogController
 *******************************************************************************************************
 * Version   Date          Updated By            		 Test        Target        Comments
 * 1.0       12/27/2022    prakhar.shukla@capgemini.com   92%
 ********************************************************************************************************/

@isTest(seeAllData=false)
public class Appt3_AppointmentLogControllerTest {
  final static string LPREFIX = 'LOG Appt3_AppointmentLogControllerTest: ';

  @TestSetup
  public static void setupTestData() {
    // for runas()
    User pOSUser = Appt_TestUtil.getPosTerminalUser(
      'TestPos',
      'TerminalTestUser'
    );
    pOSUser.User_Store_Id__c = 'RIP05';
    update pOSUser;
    //-- this will setup a store with 27 days of slots
    FSL.GlobalAPIS.addStatusTransition(
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED
    );
    FSL.GlobalAPIS.addStatusTransition(
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED
    );
    FSL.GlobalAPIS.addStatusTransition(
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED
    );
    FSL.GlobalAPIS.addStatusTransition(
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED
    );
    FSL.GlobalAPIS.addStatusTransition(
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED
    );
    //FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED );
    List<ServiceAppointment> servAppts = Appt_TestUtil.basicAppointment_StoreConfiguration();

    // setting appointment status as cancelled and missed
    servAppts[0]
      .Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED;
    servAppts[1].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED;
    // change the appointment time so it passes whenever the test is run
    // the test will fail in off hours otherwise.
    Datetime currentDatetime = Datetime.now().addDays(-1);
    String dateString = String.valueOf(Date.valueOf(currentDatetime));
    servAppts[0].SchedStartTime = currentDatetime;
    servAppts[0].SchedEndTime = currentDatetime.addMinutes(20);
    servAppts[1].SchedStartTime = currentDatetime.addMinutes(20);
    servAppts[1].SchedEndTime = currentDatetime.addMinutes(40);
    servAppts[0].Date_String__c = dateString;
    servAppts[1].Date_String__c = dateString;
    update servAppts;
  }

  // test method to get all the appointments
  @isTest
  static void testGetAppointments() {
    user posUser = [
      SELECT id, email, User_Store_Id__c
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    List<ServiceAppointment> servAppts = [
      SELECT
        Id,
        Status,
        Start_Time_String__c,
        Original_Date_String__c,
        Original_Start_Time_String__c,
        Appointment_Rescheduled__c,
        SchedStartTime,
        Date_String__c,
        ParentRecordId,
        Site_Id__c
      FROM ServiceAppointment
    ];
    System.assertEquals(
      false,
      servAppts[0].Appointment_Rescheduled__c,
      'Appointment is rescheduled, reset the original appointment date and time strings'
    );
    System.assertEquals(
      false,
      servAppts[1].Appointment_Rescheduled__c,
      'Appointment is rescheduled, reset the original appointment date and time strings'
    );
    String siteId = servAppts[0].Site_Id__c;
    String startDate = String.valueOf(System.Today() - 10);
    String endDate = String.valueOf(System.Today() + 1);
    List<String> appointmentStatuses = new List<String>{
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED
    };
    Boolean rescheduleFilter = null;
    String testResult;
    System.runAs(posUser) {
      Test.startTest();
      testResult = Appt3_AppointmentLogController.getAppointments(
        siteId,
        startDate,
        endDate,
        appointmentStatuses,
        rescheduleFilter
      );
      Test.stopTest();
      System.assertNotEquals(null, testResult, 'testResult is null');
      System.assertEquals(
        true,
        testResult.containsIgnoreCase('"Sam Spade"'),
        'Result string does not contain an appointment with fullName as Sam Spade'
      );
    }
  }

  // Negative Scenario- test method to check exception is being thrown when we pass null in date
  @isTest
  static void testNullDateGetAppointments() {
    user posUser = [
      SELECT id, email, User_Store_Id__c
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    List<ServiceAppointment> servAppts = [
      SELECT
        Id,
        Status,
        Start_Time_String__c,
        Original_Date_String__c,
        Original_Start_Time_String__c,
        Appointment_Rescheduled__c,
        SchedStartTime,
        Date_String__c,
        ParentRecordId,
        Site_Id__c
      FROM ServiceAppointment
    ];
    System.assertEquals(
      false,
      servAppts[0].Appointment_Rescheduled__c,
      'Appointment is rescheduled, reset the original appointment date and time strings'
    );
    System.assertEquals(
      false,
      servAppts[1].Appointment_Rescheduled__c,
      'Appointment is rescheduled, reset the original appointment date and time strings'
    );
    String siteId = servAppts[0].Site_Id__c;
    String startDate = null;
    String endDate = null;
    List<String> appointmentStatuses = new List<String>{
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED
    };
    Boolean rescheduleFilter = null;
    string testResult;
    Boolean exceptionOccurred = false;
    System.runAs(posUser) {
      try {
        Test.startTest();
        testResult = Appt3_AppointmentLogController.getAppointments(
          siteId,
          startDate,
          endDate,
          appointmentStatuses,
          rescheduleFilter
        );
        Test.stopTest();
      } catch (Exception e) {
        exceptionOccurred = true;
      }
      System.assertEquals(
        true,
        exceptionOccurred,
        'An Exception was not thrown'
      );
    }
  }

  // test method to check for rescheduled appointments
  @isTest
  static void testGetAppointmentsRescheduled() {
    user posUser = [
      SELECT id, email, User_Store_Id__c
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    List<ServiceAppointment> servAppts = [
      SELECT
        Id,
        Status,
        Start_Time_String__c,
        Original_Date_String__c,
        Original_Start_Time_String__c,
        Appointment_Rescheduled__c,
        SchedStartTime,
        Date_String__c,
        ParentRecordId,
        Site_Id__c
      FROM ServiceAppointment
    ];
    String siteId = servAppts[0].Site_Id__c;
    String startDate = String.valueOf(System.Today() - 10);
    String endDate = String.valueOf(System.Today() + 1);
    List<String> appointmentStatuses = new List<String>{
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED
    };
    Boolean rescheduleFilterTrue = true;
    Boolean rescheduleFilterFalse = false;
    System.runAs(posUser) {
      string testResult1;
      string testResult2;
      Test.startTest();
      testResult1 = Appt3_AppointmentLogController.getAppointments(
        siteId,
        startDate,
        endDate,
        appointmentStatuses,
        rescheduleFilterTrue
      );
      testResult2 = Appt3_AppointmentLogController.getAppointments(
        siteId,
        startDate,
        endDate,
        appointmentStatuses,
        rescheduleFilterFalse
      );
      Test.stopTest();
      System.assertEquals('[]', testResult1, 'Result is blank');
      System.assertNotEquals(null, testResult2, 'testResult2 is null');
      System.assertEquals(
        true,
        testResult2.containsIgnoreCase('"Sam Spade"'),
        'Result string does not contain an appointment with fullName as Sam Spade'
      );
    }
  }

  // test method to validates we are getting right count of appointments according to filters
  @isTest
  static void testFilterCounts() {
    user posUser = [
      SELECT id, email, User_Store_Id__c
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    List<ServiceAppointment> servAppts = [
      SELECT
        Id,
        Status,
        Start_Time_String__c,
        Original_Date_String__c,
        Original_Start_Time_String__c,
        Appointment_Rescheduled__c,
        SchedStartTime,
        Date_String__c,
        ParentRecordId,
        Site_Id__c
      FROM ServiceAppointment
    ];
    String siteId = servAppts[0].Site_Id__c;
    String startDate = String.valueOf(System.Today() - 10);
    String endDate = String.valueOf(System.Today() + 1);
    List<String> appointmentStatuses = new List<String>{
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED,
      Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED
    };
    Appt3_AppointmentLogController.ReturnCountsModel recordCounts;

    System.runAs(posUser) {
      Test.startTest();
      recordCounts = Appt3_AppointmentLogController.getFilterCounts(
        siteId,
        startDate,
        endDate,
        appointmentStatuses
      );
      Test.stopTest();
      System.assertEquals(
        2,
        recordCounts.rescheduledCountMap.get('false'),
        'Returned count does not match actual record counts'
      );
    }
  }
}