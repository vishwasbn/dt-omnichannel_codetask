//---This class was generated from http://json2apex.herokuapp.com/ using data returned from CAR
public class Fleet_CarSummaryModel {

	public class Vehicle {
		public String year;
		public String make;
		public String model;
	}

	public class OrderHistorySummary {
		public String transactionType;
		public Double totalAmount;
		public String siteId;
		public String businessdayDate;
		public Boolean isCertificateAllowed;
		public List<Vehicle> vehicle;
		public List<TransactionDetails> transactionDetails;
		public String poNumber;
		public String vinNumber;
	}

	public ResponseSummary responseSummary;

	public class TransactionDetails {
		public String name;
		public String value;
	}

	public class ResponseSummary {
		public List<OrderHistorySummary> orderHistorySummary;
	}

	
	public static Fleet_CarSummaryModel parse(String json) {
		return (Fleet_CarSummaryModel) System.JSON.deserialize(json, Fleet_CarSummaryModel.class);
	}
}