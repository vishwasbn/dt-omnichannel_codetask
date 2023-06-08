//
// Generated by JSON2Apex http://json2apex.herokuapp.com/
//

@IsTest
public class Appt_CreateAppointmentResponseTest {
	
	static testMethod void testParse() {
		String json = '{ \"status\": \"success\", \"message\": \"appointment scheduled\", \"siteId\": \"1045\", \"hybrisOrderId\": \"W010743695\", \"posCustomerId\": \"W010743695\", \"hybrisCustomerId\": \"9987000226\", \"appointmentId\": \"08p3F0000004vAXQAY\", \"appointmentStatus\": \"scheduled\", \"textOptIn\": false, \"emailAddressOptIn\": true, \"appointmentDate\": \"2021-01-02\", \"consultAppointmentId\": \"08p3F0000004vAXQAY\", \"consultStartTime\": \"1240\", \"consultEndTime\": \"1300\", \"consultDuration\": \"20\", \"backOfficeAppointmentId\": \"08q3F0000004QB8QAM\", \"backOfficeStartTime\": \"1300\", \"backOfficeEndTime\": \"1320\", \"backOfficeDuration\": \"20\" }';
		Appt_CreateAppointmentResponse obj = Appt_CreateAppointmentResponse.parse(json);
		System.assert(obj != null);
	}
}