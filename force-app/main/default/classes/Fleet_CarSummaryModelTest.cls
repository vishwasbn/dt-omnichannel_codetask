//---This class was generated from http://json2apex.herokuapp.com/ using data returned from CAR
@IsTest
public class Fleet_CarSummaryModelTest {
	
	static testMethod void testParse() 
	{
		
		String json = getJSON();
		Fleet_CarSummaryModel obj = Fleet_CarSummaryModel.parse(json);
		System.assert(obj != null);
	}

	public static string getJSON()
	{
		String json = '{'+
		'  \"responseSummary\": {'+
		'    \"orderHistorySummary\": ['+
		'      {'+
		'        \"transactionType\": \"1101\",'+
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
		'        ],'+
        '      \"poNumber\": \"No customer PO2\",'+
        '      \"vinNumber\": \"123456\"'+
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
		'        ],'+
        '      \"poNumber\": \"No customer PO2\",'+
        '      \"vinNumber\": \"123456\"'+
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
		'        ],'+
        '      \"poNumber\": \"No customer PO2\",'+
        '      \"vinNumber\": \"123456\"'+
		'      }'+
		'    ]'+
		'  }'+
		'}';
		return json;
	}
}