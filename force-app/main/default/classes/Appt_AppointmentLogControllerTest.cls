@isTest(seeAllData = false)
public without sharing class Appt_AppointmentLogControllerTest {
    
    @TestSetup
    public static void setupTestData(){

        //-- this will setup a store with 27 days of slots
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED);
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED );
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED);
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED );
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED);
        //FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED ); //commenting since next line method create the same status transition
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();

        System.debug(servAppts);

        // progress Appointment to Scheduled & Confirmed
        servAppts[0].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED;
        servAppts[1].Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED;
        // change the appointment time so it passes whenever the test is run
        //    the test will fail in off hours otherwise.
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

    static testMethod void testGetAppointments() {
        List<ServiceAppointment> servAppts = [
            SELECT Id, Status, Start_Time_String__c, Original_Date_String__c, 
            Original_Start_Time_String__c, Appointment_Rescheduled__c, SchedStartTime, 
            Date_String__c, ParentRecordId, Site_Id__c
            FROM ServiceAppointment
        ];
        System.debug(servAppts);
        System.debug(servAppts[0].Appointment_Rescheduled__c);
        System.assertEquals(false, servAppts[0].Appointment_Rescheduled__c, 'Appointment is rescheduled, reset the original appointment date and time strings');
        System.assertEquals(false, servAppts[1].Appointment_Rescheduled__c, 'Appointment is rescheduled, reset the original appointment date and time strings');

        String siteId = servAppts[0].Site_Id__c;
        String startDate = String.valueOf(System.Today() - 10);
        String endDate = String.valueOf(System.Today() + 1);
        List<String> appointmentStatuses = new List<String>{ 
            Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED,
            Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED,
            Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED
        };
        Boolean rescheduleFilter = null;

        String testResult = '';
        Test.startTest();
        testResult = Appt_AppointmentLogController.getAppointments(siteId, startDate, endDate, appointmentStatuses, rescheduleFilter);
        Test.stopTest();

        Appt_AppointmentLogController.Appt_ArchiveLogContainer container = (Appt_AppointmentLogController.Appt_ArchiveLogContainer) JSON.deserialize(testResult, Appt_AppointmentLogController.Appt_ArchiveLogContainer.class);

        System.assert(container != null && container.loggedAppointments != null);
    }

    static testMethod void testGetAppointmentsRescheduled() {
        List<ServiceAppointment> servAppts = [
            SELECT Id, Status, Start_Time_String__c, Original_Date_String__c, 
            Original_Start_Time_String__c, Appointment_Rescheduled__c, SchedStartTime, 
            Date_String__c, ParentRecordId, Site_Id__c
            FROM ServiceAppointment
        ];        
        System.debug(servAppts);

        // set appointment to rescheduled
        Date originalDate = Date.valueOf(servAppts[0].Date_String__c)-1;
        servAppts[0].Original_Date_String__c = String.valueOf(originalDate);
        servAppts[0].Original_Start_Time_String__c = servAppts[0].Start_Time_String__c;

        servAppts[1].Original_Date_String__c = String.valueOf(originalDate);
        servAppts[1].Original_Start_Time_String__c = servAppts[0].Start_Time_String__c;
        update servAppts;

        String siteId = servAppts[0].Site_Id__c;
        String startDate = String.valueOf(System.Today() - 10);
        String endDate = String.valueOf(System.Today() + 1);
        List<String> appointmentStatuses = new List<String>{ 
            Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED,
            Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED,
            Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED
        };
        Boolean rescheduleFilter = true;

        String testResult = '';
        Test.startTest();
        testResult = Appt_AppointmentLogController.getAppointments(siteId, startDate, endDate, appointmentStatuses, rescheduleFilter);
        Test.stopTest();
    }

    static testMethod void testGetArchiveAppointmentModel() {
        String json = '{'+
		'            \"storageType\": null,'+
		'            \"appointmentId\": \"0WO55000000yFdHGAU\",'+
		'            \"appointmentStatus\": \"Pending\",'+
		'            \"relatedAppointmentId\": null,'+
		'            \"salesforceAppointmentId\": \"08p55000000Km0lAAC\",'+
		'            \"salesforceAcccountId\": null,'+
		'            \"posCustomerId\": null,'+
		'            \"hybrisCustomerId\": null,'+
		'            \"siteId\": \"1235\",'+
		'            \"source\": \"WEB\",'+
		'            \"orderType\": \"ROPIS\",'+
		'            \"appointmentDate\": \"2021-02-15\",'+
		'            \"consultStartTime\": null,'+
		'            \"consultEndTime\": null,'+
        '            \"originalDateString\": \"2021-02-15\",'+
		'            \"originalEndTimeString\": \"0920\",'+
		'            \"originalStartTimeString\": \"0900\",'+
		'            \"backOfficeStartTime\": \"0920\",'+
		'            \"backOfficeEndTime\": \"0940\",'+
		'            \"formType\": null,'+
		'            \"formNumber\": \"546884\",'+
		'            \"formDate\": \"2021-01-02\",'+
		'            \"hybrisOrderId\": null,'+
		'            \"posWebOrderId\": null,'+
		'            \"layawayNumber\": null,'+
		'            \"quoteNumber\": null,'+
		'            \"invoiceNumber\": null,'+
		'            \"orderDate\": \"2020-12-31\",'+
		'            \"customerGuid\": null,'+
		'            \"customerType\": \"Retail\",'+
		'            \"salesforceContactId\": null,'+
		'            \"firstName\": null,'+
		'            \"lastName\": null,'+
		'            \"emailAddress\": null,'+
		'            \"mobilePhoneNumber\": null,'+
		'            \"homePhoneNumber\": null,'+
		'            \"workPhoneNumber\": null,'+
		'            \"address1\": \"123 Right Here Ln\",'+
		'            \"address2\": null,'+
		'            \"zipCode\": \"85310\",'+
		'            \"city\": \"Glendale\",'+
		'            \"state\": \"Arizona\",'+
		'            \"country\": \"US\",'+
		'            \"textOptIn\": null,'+
		'            \"emailOptIn\": null,'+
		'            \"posCustomerVehicleId\": null,'+
		'            \"hybrisCustomerVehicleId\": null,'+
		'            \"vehicleType\": null,'+
		'            \"year\": \"2016\",'+
		'            \"make\": \"Ford\",'+
		'            \"model\": \"Escape\",'+
		'            \"vehicleId\": \"10382\",'+
		'            \"trimId\": \"1470\",'+
		'            \"assemblyId\": \"C\",'+
		'            \"recipientContactId\": \"0035500001A1GEyAAN\",'+
		'            \"recipientFirstName\": \"Jack\",'+
		'            \"recipientLastName\": \"Thomas\",'+
		'            \"recipientEmail\": \"jackthomas@none.com\",'+
		'            \"recipientPhone\": \"602-555-5555\",'+
		'            \"comments\": \"Some comments about the order or appointment\",'+
		'            \"cancelReason\": null,'+
		'            \"cancelReasonText\": null,'+
        '            \"cancelReasonCode\": null,'+
        '            \"apptRescheduled\": true,'+
		'            \"lastModifiedByName\": \"Mulesoft user\",'+
		'            \"lastModifiedDate\": \"2021-02-08T18:45:06.000Z\",'+
        '            \"apptLastModifiedBy\": \"Mulesoft user\",'+
		'            \"apptLastModifiedDate\": \"2021-02-08T18:45:06.000Z\"'+
		'        }';
		Appt_ArchivePayloadModel obj = Appt_ArchivePayloadModel.parse(json);

        Appt_AppointmentLogController.Appt_AppointmentLogWrapper apptLogWrapper = null;
        Test.startTest();
        apptLogWrapper = new Appt_AppointmentLogController.Appt_AppointmentLogWrapper(obj);
        Test.stopTest();

        System.assert(apptLogWrapper != null);


    }
}