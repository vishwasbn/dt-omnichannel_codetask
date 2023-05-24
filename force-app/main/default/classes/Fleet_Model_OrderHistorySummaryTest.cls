@isTest
public class Fleet_Model_OrderHistorySummaryTest {

    @testSetup static void setupData() {
        
    }
    
    @isTest static void getInvoiceIdTest() {
        List<Fleet_Model_TransactionDetails> transactionDetails = new List<Fleet_Model_TransactionDetails>();
        List<Fleet_Model_Vehicle> vehicles = new List<Fleet_Model_Vehicle>();
        List<Fleet_CarSummaryModel> carSummaries = new List<Fleet_CarSummaryModel>();
        List<Fleet_CarSummaryModel.OrderHistorySummary> ordrSummaries = new List<Fleet_CarSummaryModel.OrderHistorySummary>();
        
        Fleet_Model_TransactionDetails trans1 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001029485');
        transactionDetails.add(trans1);
        
        Fleet_Model_Vehicle vehII = new Fleet_Model_Vehicle(1984, 'ISUZU', 'IMARK');
        vehicles.add(vehII);
        
        String json = getJSON();
		Fleet_CarSummaryModel carObj = Fleet_CarSummaryModel.parse(json);
        System.debug(carObj.responseSummary.orderHistorySummary);
        ordrSummaries = carObj.responseSummary.orderHistorySummary;
        //carSummaries.add(carObj);
        
        Test.startTest();
        Fleet_Model_OrderHistorySummary obj = new Fleet_Model_OrderHistorySummary();
        obj.getVehicle();
        obj.getVehicles();
        obj.setVehicles(vehicles);
        obj.setTransactionDetails(transactionDetails);
        obj.getTransactionDetails();
        obj.getTransactionType();
        obj.setTransactionType('Sales');
        obj.getTotalAmount();
        obj.setTotalAmount(400.00);
        obj.getSiteId();
        obj.setSiteId('0000001002');
        obj.getBusinessdayDate();
        obj.setBusinessdayDate('2019-10-09');
        obj.getIsCertificateAllowed();
        obj.setIsCertificateAllowed(false);
        obj.getStoreName();
        obj.setStoreName('TestStoreName');
        obj.getInvoiceId();
        Fleet_Model_OrderHistorySummary.build(ordrSummaries);
        Test.stopTest();
    }
    
    public static string getJSON(){
        String json = '{'+
		'  \"responseSummary\": {'+
		'    \"orderHistorySummary\": ['+
		'      {'+
		'        \"transactionType\": \"Sales\",'+
		'        \"totalAmount\": 2413.66,'+
		'        \"siteId\": \"0000001002\",'+
		'        \"businessdayDate\": \"2015-04-27\",'+
		'        \"isCertificateAllowed\": true,'+
		'        \"vehicle\": ['+
		'          {'+
		'            \"year\": \"2007\",'+
		'            \"make\": \"MAZDA\",'+
		'            \"model\": \"3\"'+
		'          }'+
		'        ],'+
		'        \"transactionDetails\": ['+
		'          {'+
		'            \"name\": \"TRANSNUMBER\",'+
		'            \"value\": \"00000000000001006318\"'+
		'          }'+
		'        ]'+
		'      },'+
		'      {'+
		'        \"transactionType\": \"Sales\",'+
		'        \"totalAmount\": 2413.66,'+
		'        \"siteId\": \"0000001002\",'+
		'        \"businessdayDate\": \"2015-04-22\",'+
		'        \"isCertificateAllowed\": true,'+
		'        \"vehicle\": ['+
		'          {'+
		'            \"year\": \"2007\",'+
		'            \"make\": \"MAZDA\",'+
		'            \"model\": \"3\"'+
		'          }'+
		'        ],'+
		'        \"transactionDetails\": ['+
		'          {'+
		'            \"name\": \"TRANSNUMBER\",'+
		'            \"value\": \"00000000000001006276\"'+
		'          }'+
		'        ]'+
		'      },'+
		'      {'+
		'        \"transactionType\": \"Sales\",'+
		'        \"totalAmount\": 2413.66,'+
		'        \"siteId\": \"0000001002\",'+
		'        \"businessdayDate\": \"2015-04-07\",'+
		'        \"isCertificateAllowed\": true,'+
		'        \"vehicle\": ['+
		'          {'+
		'            \"year\": \"2007\",'+
		'            \"make\": \"MAZDA\",'+
		'            \"model\": \"3\"'+
		'          }'+
		'        ],'+
		'        \"transactionDetails\": ['+
		'          {'+
		'            \"name\": \"TRANSNUMBER\",'+
		'            \"value\": \"00000000000001006048\"'+
		'          }'+
		'        ]'+
		'      }'+
		'    ]'+
		'  }'+
		'}';
		return json;
    }
}