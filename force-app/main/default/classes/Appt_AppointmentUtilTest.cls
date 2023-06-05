@isTest(SeeAllData=false)
public class Appt_AppointmentUtilTest {

    @testSetup
    static void setupData() {

        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        System.debug('servAppts: ' + servAppts.size());
    }

    @isTest 
    static void checkDateTimeFunctions()
    {
        List<ServiceAppointment> servAppts = [SELECT Id, Status, SchedStartTime, SchedEndTime, Site_Id__c, ParentRecordId, Date_String__c, Start_Time_String__c, Timezone_Offset__c FROM ServiceAppointment];

        Integer timeZone = Appt_AppointmentUtil.getTimeZoneOffset( servAppts[0].Site_Id__c , DateTime.parse('06/01/2021, 12:00 AM'));

        // System.debug('timeZone: ' + timeZone);
        System.assertEquals(-4, timeZone, 'the timezone is incorrect');

        Integer timeZoneSite = Appt_AppointmentUtil.getTimeZoneOffset( servAppts[0].Site_Id__c );

        // System.debug('timeZone: ' + timeZone);
        System.assertEquals(-4, timeZoneSite, 'the site timezone is incorrect');        

        Appt_TimeZoneModel tzModel = Appt_AppointmentUtil.getTimeZoneAndOffset( servAppts[0].Site_Id__c );

        System.debug('timeZone Model: ' + tzModel);
        System.assertEquals('America/New_York', tzModel.timeZone, 'the timezone is incorrect');
        System.assertEquals(-4, tzModel.timeZoneOffset, 'the timezone offset is incorrect');

        Datetime dtResult = Appt_AppointmentUtil.convertTime(servAppts[0].Date_String__c, servAppts[0].Start_Time_String__c, timeZone);

        // System.debug('Datetime: ' + dtResult);
        // System.debug('Formatted: ' + dtResult.formatGMT('yyyy-MM-dd HH:mm:ss'));

        System.assertEquals( Datetime.now().format('yyyy-MM-dd') + ' 12:00:00', dtResult.formatGMT('yyyy-MM-dd HH:mm:ss'), 'string datetime conversion is incorrect');

        String timeStr = Appt_AppointmentUtil.formatTimeHHmm( Time.newInstance( dtResult.hour(), dtResult.minute(), dtResult.second(), 0) );
        // System.debug('Time Format: ' + timeStr );
        System.assertEquals('0500', timeStr, 'formatted time string is incorrect');

        Integer duration = Appt_AppointmentUtil.minutesBetweenDatetimes( servAppts[0].SchedStartTime, servAppts[0].SchedEndTime );
        // System.debug('Duration: ' + duration );
        System.assertEquals(20, duration, 'minutesBetweenDatetimes is incorrect');

        Datetime dtResult2 = Appt_AppointmentUtil.convertTime( servAppts[0].SchedStartTime, timeZone);
        // System.debug('Datetime: ' + dtResult2);
        System.assertEquals( Datetime.now().format('yyyy-MM-dd') + ' 12:00:00', dtResult2.formatGMT('yyyy-MM-dd HH:mm:ss'), 'datetime conversion is incorrect');

        String stateName = Appt_AppointmentUtil.convertToFullStateName('AZ');
        // System.debug('stateName: ' + stateName);
        System.assertEquals('Arizona', stateName, 'convertToFullStateName result incorrect');

        System.debug('Status: ' + servAppts[0].Status);
        Appt_AppointmentUtil.updateFLSPriority(servAppts[0].Id, 'Scheduled');

        servAppts = [SELECT Id, Status, SchedStartTime, SchedEndTime, Site_Id__c, ParentRecordId, Date_String__c, Start_Time_String__c, Timezone_Offset__c FROM ServiceAppointment];
        System.debug('Appointments: ' + servAppts.size());

        System.assertEquals('Scheduled', servAppts[0].Status, 'Appointment Status is incorrect');

        String hourTime = Appt_AppointmentUtil.getFormattedTimeString( servAppts[0].Start_Time_String__c );
        // System.debug('12HourTime: ' + hourTime);
        System.assertEquals('08:00 AM', hourTime, '12 Hour AM time is incorrect');

        hourTime = Appt_AppointmentUtil.getFormattedTimeString( '1400' );
        System.assertEquals('02:00 PM', hourTime, '12 Hour PM time is incorrect');

        // Testing out the getAppointmentServiceModel with valid view json string
        String result2 = Appt_AppointmentsPageContainerController.getAppointmentServiceModel(Appt_PageContainerControllerTest.createNewPosStringWithAction('VIEW'));
        Appt_UpdateAppointmentServiceModel apptModel = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(result2, Appt_UpdateAppointmentServiceModel.class);

        Appt_AppointmentUtil.assignAppointmentToResource( apptModel.frontroomServiceResourceId, servAppts[0].Id, apptModel.backroomServiceResourceId, servAppts[1].Id, servAppts[0].Site_Id__c, Appt_ConstantValues.WORK_TYPE_TYPE_BACK);

        Boolean cTime = Appt_AppointmentUtil.isInWebCutoffTime(Datetime.now());
        System.assertEquals(true, cTime, 'Cutoff time is incorrect');

        Integer webApptLeadTime = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_WEB_APPOINTMENT_LEAD_TIME));
        webApptLeadTime += 5;

        cTime = Appt_AppointmentUtil.isInWebCutoffTime(Datetime.now().addMinutes(webApptLeadTime));
        System.assertEquals(false, cTime, 'Cutoff time is incorrect');

    }

    @isTest 
    static void checkFunctions()
    {
        String countryString = Appt_AppointmentUtil.getCountryByState('AZ');
        System.assertEquals('United States', countryString, 'US state country response incorrect');

        countryString = Appt_AppointmentUtil.getCountryByState('QC');
        System.assertEquals('Canada', countryString, 'Canada state country response incorrect');

        countryString = Appt_AppointmentUtil.getCountryByState('ZZ');
        System.assertEquals('United States', countryString, 'fake country response incorrect');

        String orderTypeString = Appt_AppointmentUtil.getOrderTypeFromFormType(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_QUO);
        System.assertEquals(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_QUO, orderTypeString, 'QUO mapping incorrect');

        orderTypeString = Appt_AppointmentUtil.getOrderTypeFromFormType(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_WEB);
        System.assertEquals(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_WEB, orderTypeString, 'WEB mapping incorrect');

        orderTypeString = Appt_AppointmentUtil.getOrderTypeFromFormType(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_LAY);
        System.assertEquals(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_LAY, orderTypeString, 'LAY mapping incorrect');

        orderTypeString = Appt_AppointmentUtil.getOrderTypeFromFormType(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_BOP);
        System.assertEquals(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_BOP, orderTypeString, 'BOP mapping incorrect');

        orderTypeString = Appt_AppointmentUtil.getOrderTypeFromFormType(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_INV);        
        System.assertEquals(Appt_ConstantValues.IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_INV, orderTypeString, 'INV mapping incorrect');
    }

}