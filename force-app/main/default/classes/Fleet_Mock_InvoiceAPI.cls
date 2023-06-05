/**
 * Class used to mock the CAR invoice APIs. Used by Test Classes to setup test data.
 */
public class Fleet_Mock_InvoiceAPI {

    public static String lprefix = 'FLEET_MOCK: ';

    /**
     * mock of invoice detail API call, will be used by Test coverage classes for test data setup
     */
    public static String mockInvoiceDetailAPI() {
        String responseJSON;
        List<Fleet_Model_OrderHistoryDetails> returnList = new List<Fleet_Model_OrderHistoryDetails>();

        responseJSON = JSON.serialize(returnList);
        System.debug(lprefix+'mockInvoiceDetailAPI():responseJSON = ' + responseJSON);
        return responseJSON;
    }


    /**
     * mock of invoice summary API call, will be used by Test coverage classes for test data setup
     */
    public static String mockInvoiceSummaryAPI() {

        String responseJSON;

        Fleet_Model_Vehicle vehII = new Fleet_Model_Vehicle(1984, 'ISUZU', 'IMARK');
        Fleet_Model_Vehicle vehFF = new Fleet_Model_Vehicle(2018, 'FORD', 'F250');
        Fleet_Model_Vehicle vehFT = new Fleet_Model_Vehicle(2014, 'FORD', 'TAURUS');
        Fleet_Model_Vehicle vehTX = new Fleet_Model_Vehicle(2020, 'TESLA', 'MODEL X');
        Fleet_Model_Vehicle vehFF1 = new Fleet_Model_Vehicle(2013, 'FORD', 'F150');
        Fleet_Model_TransactionDetails trans1 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001029485');
        Fleet_Model_TransactionDetails trans2 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001029475');
        Fleet_Model_TransactionDetails trans3 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001029474');
        Fleet_Model_TransactionDetails trans4 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001029388');
        Fleet_Model_TransactionDetails trans5 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001029383');
        Fleet_Model_TransactionDetails trans6 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001029377');
        Fleet_Model_TransactionDetails trans7 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001028388');
        Fleet_Model_TransactionDetails trans8 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001028389');
        Fleet_Model_TransactionDetails trans9 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001028490');
        Fleet_Model_TransactionDetails trans10 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001028555');
        Fleet_Model_TransactionDetails trans11 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001028666');
        Fleet_Model_TransactionDetails trans12 = new Fleet_Model_TransactionDetails('TRANSNUMBER', '00000000000001028669');

        Fleet_Model_OrderHistorySummary invSummary1 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList1 = new List<Fleet_Model_Vehicle>();
        vehList1.add(vehFT);
        List<Fleet_Model_TransactionDetails> transList1 = new List<Fleet_Model_TransactionDetails>();
        transList1.add(trans1);
        invSummary1.setTransactionType('Sales');
        invSummary1.setTotalAmount(393.91);
        invSummary1.setSiteId('0000001002');
        invSummary1.setBusinessdayDate('2019-10-09');
        invSummary1.setIsCertificateAllowed(false);
        invSummary1.setVehicles(vehList1);
        invSummary1.setTransactionDetails(transList1);

        Fleet_Model_OrderHistorySummary invSummary2 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList2 = new List<Fleet_Model_Vehicle>();
        vehList2.add(vehFF);
        vehList2.add(vehFT);
        List<Fleet_Model_TransactionDetails> transList2 = new List<Fleet_Model_TransactionDetails>();
        transList2.add(trans2);
        transList2.add(trans3);
        invSummary2.setTransactionType('Sales');
        invSummary2.setTotalAmount(1150.62);
        invSummary2.setSiteId('0000001002');
        invSummary2.setBusinessdayDate('2019-10-16');
        invSummary2.setIsCertificateAllowed(true);
        invSummary2.setVehicles(vehList2);
        invSummary2.setTransactionDetails(transList2);

        Fleet_Model_OrderHistorySummary invSummary3 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList3 = new List<Fleet_Model_Vehicle>();
        vehList3.add(vehFT);
        List<Fleet_Model_TransactionDetails> transList3 = new List<Fleet_Model_TransactionDetails>();
        transList3.add(trans4);
        invSummary3.setTransactionType('Sales');
        invSummary3.setTotalAmount(2495.10);
        invSummary3.setSiteId('0000001002');
        invSummary3.setBusinessdayDate('2019-10-15');
        invSummary3.setIsCertificateAllowed(true);
        invSummary3.setVehicles(vehList3);
        invSummary3.setTransactionDetails(transList3);

        Fleet_Model_OrderHistorySummary invSummary4 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList4 = new List<Fleet_Model_Vehicle>();
        vehList4.add(vehFF);
        List<Fleet_Model_TransactionDetails> transList4 = new List<Fleet_Model_TransactionDetails>();
        transList4.add(trans5);
        invSummary4.setTransactionType('Sales');
        invSummary4.setTotalAmount(70.29);
        invSummary4.setSiteId('0000001002');
        invSummary4.setBusinessdayDate('2019-10-15');
        invSummary4.setIsCertificateAllowed(true);
        invSummary4.setVehicles(vehList4);
        invSummary4.setTransactionDetails(transList4);

        Fleet_Model_OrderHistorySummary invSummary5 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList5 = new List<Fleet_Model_Vehicle>();
        vehList5.add(vehII);
        List<Fleet_Model_TransactionDetails> transList5 = new List<Fleet_Model_TransactionDetails>();
        transList5.add(trans6);
        invSummary5.setTransactionType('Sales');
        invSummary5.setTotalAmount(4370.25);
        invSummary5.setSiteId('0000001003');
        invSummary5.setBusinessdayDate('2017-06-16');
        invSummary5.setIsCertificateAllowed(false);
        invSummary5.setVehicles(vehList5);
        invSummary5.setTransactionDetails(transList5);

        Fleet_Model_OrderHistorySummary invSummary6 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList6 = new List<Fleet_Model_Vehicle>();
        vehList6.add(vehTX);
        List<Fleet_Model_TransactionDetails> transList6 = new List<Fleet_Model_TransactionDetails>();
        transList6.add(trans7);
        invSummary6.setTransactionType('Sales');
        invSummary6.setTotalAmount(123.45);
        invSummary6.setSiteId('0000001003');
        invSummary6.setBusinessdayDate('2017-06-15');
        invSummary6.setIsCertificateAllowed(false);
        invSummary6.setVehicles(vehList6);
        invSummary6.setTransactionDetails(transList6);

        Fleet_Model_OrderHistorySummary invSummary7 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList7 = new List<Fleet_Model_Vehicle>();
        vehList7.add(vehFF1);
        List<Fleet_Model_TransactionDetails> transList7 = new List<Fleet_Model_TransactionDetails>();
        transList7.add(trans8);
        invSummary7.setTransactionType('Sales');
        invSummary7.setTotalAmount(2001.79);
        invSummary7.setSiteId('0000001003');
        invSummary7.setBusinessdayDate('2017-05-16');
        invSummary7.setIsCertificateAllowed(true);
        invSummary7.setVehicles(vehList7);
        invSummary7.setTransactionDetails(transList7);

        Fleet_Model_OrderHistorySummary invSummary8 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList8 = new List<Fleet_Model_Vehicle>();
        vehList8.add(vehTX);
        List<Fleet_Model_TransactionDetails> transList8 = new List<Fleet_Model_TransactionDetails>();
        transList8.add(trans9);
        invSummary8.setTransactionType('Sales');
        invSummary8.setTotalAmount(1111.25);
        invSummary8.setSiteId('0000001002');
        invSummary8.setBusinessdayDate('2016-06-16');
        invSummary8.setIsCertificateAllowed(false);
        invSummary8.setVehicles(vehList8);
        invSummary8.setTransactionDetails(transList8);

        Fleet_Model_OrderHistorySummary invSummary9 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList9 = new List<Fleet_Model_Vehicle>();
        vehList9.add(vehII);
        List<Fleet_Model_TransactionDetails> transList9 = new List<Fleet_Model_TransactionDetails>();
        transList9.add(trans10);
        invSummary9.setTransactionType('Sales');
        invSummary9.setTotalAmount(3370.23);
        invSummary9.setSiteId('0000001002');
        invSummary9.setBusinessdayDate('2015-03-16');
        invSummary9.setIsCertificateAllowed(true);
        invSummary9.setVehicles(vehList9);
        invSummary9.setTransactionDetails(transList9);

        Fleet_Model_OrderHistorySummary invSummary10 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList10 = new List<Fleet_Model_Vehicle>();
        vehList10.add(vehFF);
        List<Fleet_Model_TransactionDetails> transList10 = new List<Fleet_Model_TransactionDetails>();
        transList10.add(trans11);
        invSummary10.setTransactionType('Sales');
        invSummary10.setTotalAmount(444.25);
        invSummary10.setSiteId('0000001003');
        invSummary10.setBusinessdayDate('2013-01-11');
        invSummary10.setIsCertificateAllowed(false);
        invSummary10.setVehicles(vehList10);
        invSummary10.setTransactionDetails(transList10);

        Fleet_Model_OrderHistorySummary invSummary11 = new Fleet_Model_OrderHistorySummary();
        List<Fleet_Model_Vehicle> vehList11 = new List<Fleet_Model_Vehicle>();
        vehList11.add(vehFT);
        List<Fleet_Model_TransactionDetails> transList11 = new List<Fleet_Model_TransactionDetails>();
        transList11.add(trans12);
        invSummary11.setTransactionType('Sales');
        invSummary11.setTotalAmount(1234.79);
        invSummary11.setSiteId('0000001003');
        invSummary11.setBusinessdayDate('2017-05-01');
        invSummary11.setIsCertificateAllowed(true);
        invSummary11.setVehicles(vehList11);
        invSummary11.setTransactionDetails(transList11);

        List<Fleet_Model_OrderHistorySummary> returnList = new List<Fleet_Model_OrderHistorySummary>();
        returnList.add(invSummary1);
        returnList.add(invSummary2);
        returnList.add(invSummary3);
        returnList.add(invSummary4);
        returnList.add(invSummary5);
        returnList.add(invSummary6);
        returnList.add(invSummary7);
        returnList.add(invSummary8);
        returnList.add(invSummary9);
        returnList.add(invSummary10);
        returnList.add(invSummary11);


        responseJSON = JSON.serialize(returnList);
        System.debug(lprefix+'mockInvoiceSummaryAPI():responseJSON = ' + responseJSON);
        return responseJSON;
    }
}