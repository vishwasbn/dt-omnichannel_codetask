@IsTest
public class Appt_InvoiceDetailModelTest {
    
    static testMethod void testParse() {
        String json = getJSON();

        Fleet_CarDetailModel obj = Fleet_CarDetailModel.parse(json);
        System.assert(obj != null);
    }

    public static String getJSON()
    {
        String json = '{'+
        '\"responseDetail\": {'+
        '\"orderHistoryDetails\": ['+
        '{'+
        '\"siteId\": 1958,'+
        '\"totalAmount\": 1070.92,'+
        '\"businessdayDate\": \"2020-07-30\",'+
        '\"invoiceNumber\": \"00000000000001187373\",'+
        '\"addressLine1\": \"9315 OLIVE BLVD\",'+
        '\"addressLine2\": \"\",'+
        '\"city\": \"SAINT LOUIS\",'+
        '\"state\": \"MO\",'+
        '\"zipCode\": \"63132\",'+
        '\"county\": \"\",'+
        '\"workPhone\": \"8003258838\",'+
        '\"arCustomerAccountNumber\": \"29894\",'+
        '\"arCustomerAccountName\": \"ENTERPRISE FLEET MANAGEME\",'+
        '\"taxId\": \"\",'+
        '\"taxAmount\": 99.92,'+
        '\"discountAmount\": 0.00,'+
        '\"employeeName\": \"JAMES SPENCE\",'+
        '\"timeStamp\": \"2020-07-30 12:03\",'+
        '\"tenderDetails\": ['+
        '{'+
        '\"tenderTypeCode\": \"ZARC\",'+
        '\"tenderAmount\": 1070.92'+
        '}'+
        '],'+
        '\"transactionDetails\": ['+
        '{'+
        '\"name\": \"TRANSNUMBER\",'+
        '\"value\": \"00000000000001187373\"'+
        '}'+
        '],'+
        '\"lineItems\": ['+
        '{'+
        '\"articleNumber\": \"000000000000012345\",'+
        '\"retailQuantity\": 4.000,'+
        '\"storeSize\": \"LT265 /70 R17 121S E1 RWL\",'+
        '\"storeDescription\": \"BFG ALL TERRAIN T/A KO2\",'+
        '\"actualUnit_price\": 220.00,'+
        '\"fet\": 0.00,'+
        '\"totalSalesAmount\": 880.00,'+
        '\"vehicleMake\": \"CHEVROLET\",'+
        '\"vehicleModel\": \"SILVERADO 2500\",'+
        '\"vehicleYear\": \"2018\",'+
        '\"mileage\": \"090304\",'+
        '\"poNumber\": \"*22651872A6492\",'+
        '\"discounts\": ['+
        ''+
        ']'+
        '},'+
        '{'+
        '\"articleNumber\": \"000000000000080017\",'+
        '\"retailQuantity\": 0.000,'+
        '\"storeSize\": \"CERTIFICATES FOR\",'+
        '\"storeDescription\": \"REFUND, REPLACEMENT\",'+
        '\"actualUnit_price\": 35.25,'+
        '\"fet\": 0.00,'+
        '\"totalSalesAmount\": 0.00,'+
        '\"vehicleMake\": \"CHEVROLET\",'+
        '\"vehicleModel\": \"SILVERADO 2500\",'+
        '\"vehicleYear\": \"2018\",'+
        '\"mileage\": \"090304\",'+
        '\"poNumber\": \"\",'+
        '\"discounts\": ['+
        ''+
        ']'+
        '},'+
        '{'+
        '\"articleNumber\": \"000000000000080075\",'+
        '\"retailQuantity\": 4.000,'+
        '\"storeSize\": \"STATE REQUIRED\",'+
        '\"storeDescription\": \"TIRE FEE\",'+
        '\"actualUnit_price\": 0.25,'+
        '\"fet\": 0.00,'+
        '\"totalSalesAmount\": 1.00,'+
        '\"vehicleMake\": \"CHEVROLET\",'+
        '\"vehicleModel\": \"SILVERADO 2500\",'+
        '\"vehicleYear\": \"2018\",'+
        '\"mileage\": \"090304\",'+
        '\"poNumber\": \"\",'+
        '\"discounts\": ['+
        ''+
        ']'+
        '},'+
        '{'+
        '\"articleNumber\": \"000000000000080224\",'+
        '\"retailQuantity\": 4.000,'+
        '\"storeSize\": \"WASTE TIRE\",'+
        '\"storeDescription\": \"DISPOSAL FEE\",'+
        '\"actualUnit_price\": 2.50,'+
        '\"fet\": 0.00,'+
        '\"totalSalesAmount\": 10.00,'+
        '\"vehicleMake\": \"CHEVROLET\",'+
        '\"vehicleModel\": \"SILVERADO 2500\",'+
        '\"vehicleYear\": \"2018\",'+
        '\"mileage\": \"090304\",'+
        '\"poNumber\": \"\",'+
        '\"discounts\": ['+
        ''+
        ']'+
        '},'+
        '{'+
        '\"articleNumber\": \"000000000000080219\",'+
        '\"retailQuantity\": 4.000,'+
        '\"storeSize\": \"INSTALLATION &\",'+
        '\"storeDescription\": \"LIFE OF TIRE MAINTENANCE\",'+
        '\"actualUnit_price\": 20.00,'+
        '\"fet\": 0.00,'+
        '\"totalSalesAmount\": 80.00,'+
        '\"vehicleMake\": \"CHEVROLET\",'+
        '\"vehicleModel\": \"SILVERADO 2500\",'+
        '\"vehicleYear\": \"2018\",'+
        '\"mileage\": \"090304\",'+
        '\"poNumber\": \"\",'+
        '\"discounts\": ['+
        ''+
        ']'+
        '},'+
        '{'+
        '\"articleNumber\": \"000000000000045426\",'+
        '\"retailQuantity\": 4.000,'+
        '\"storeSize\": \"DIL VS20 TQ12 T10 SNAP-IN\",'+
        '\"storeDescription\": \"TPMS RBK VALVE KIT VS-20\",'+
        '\"actualUnit_price\": 0.00,'+
        '\"fet\": 0.00,'+
        '\"totalSalesAmount\": 0.00,'+
        '\"vehicleMake\": \"CHEVROLET\",'+
        '\"vehicleModel\": \"SILVERADO 2500\",'+
        '\"vehicleYear\": \"2018\",'+
        '\"mileage\": \"090304\",'+
        '\"poNumber\": \"\",'+
        '\"discounts\": ['+
        ''+
        ']'+
        '}'+
        '],'+
        '\"arFields\": {'+
        '\"driverName\": \"TAYLOR\",'+
        '\"companyName\": \"ENSITE USA\",'+
        '\"streetAdd\": \"3100 SOUTH GESSNIR ROAD SWEET 400\",'+
        '\"arVehicleYear\": \"2018\",'+
        '\"arVehicleMake\": \"Chevrolet\",'+
        '\"arVehicleModel\": \"Silverado 2500HD\",'+
        '\"arLicensePlateNumber\": \"K2M 3621\",'+
        '\"arLicensePlateState\": \"KS\",'+
        '\"vin\": \"1GC1KUEG5JF262445\",'+
        '\"arMileage\": \"90304\",'+
        '\"fleetCardNumber\": \"407\",'+
        '\"stockNumber\": \"\",'+
        '\"unitNumber\": \"22PWHF\",'+
        '\"fleetNumber\": \"\",'+
        '\"fleetCardExpDt\": \"0000-00-00\",'+
        '\"id_JobNumber\": \"\",'+
        '\"arDriverLicense\": \"\",'+
        '\"arCity\": \"HOUSTON\",'+
        '\"arState\": \"TEXAS\",'+
        '\"arZip\": \"77063\"'+
        '}'+
        '}'+
        ']'+
        '}'+
        '}';

        return json;
    }
}