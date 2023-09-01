//
// Generated by JSON2Apex http://json2apex.herokuapp.com/
//

@IsTest
public class Appt_ArchivePayloadModelTest {
	
	static testMethod void testParse() {
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
		'            \"backOfficeStartTime\": \"0920\",'+
		'            \"backOfficeEndTime\": \"0940\",'+
		'            \"originalDateString\": \"2021-02-15\",'+
		'            \"originalEndTimeString\": \"0920\",'+
		'            \"originalStartTimeString\": \"0900\",'+
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
		'            \"cancelreasonText\": null,'+
		'            \"lastModifiedByName\": \"Mulesoft user\",'+
		'            \"lastModifiedDate\": \"2021-02-08T18:45:06.000Z\",'+
		'            \"cancelReasonCode\": null,'+
        '            \"apptLastModifiedBy\": \"Mulesoft user\",'+
		'            \"apptLastModifiedDate\": \"2021-02-08T18:45:06.000Z\"'+
		'        }';
		Appt_ArchivePayloadModel obj = Appt_ArchivePayloadModel.parse(json);
		System.assert(obj != null);
	}
}