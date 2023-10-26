/*
 *******************************************************************************************************
 * Test Class: Appt3_AppointmentListPageControllerTest
 * Dependencies (Other) : Appt3_AppointmentListPageController
 *
 *******************************************************************************************************
 * Version   Date          Updated By           	 		Test          Target        Comments
 *                                               			Coverage      Release
 *
 * 1.0       26/12/2022   abhishek.pandey@discounttire.com   91%
 *******************************************************************************************************
 */

@isTest
public class Appt3_AppointmentListPageControllerTest {
  @TestSetup
  static void setupData() {
    User pOSUser = Appt_TestUtil.getPosTerminalUser(
      'TestPos',
      'TerminalTestUser'
    ); // new changes
    List<ServiceAppointment> appts = Appt_TestUtil.basicAppointment_storeConfiguration();
    for (ServiceAppointment sa : appts) {
      System.debug('ServAppt: ' + sa);
      sa.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
    }
    update appts;

    System.assertEquals(
      2,
      appts.size(),
      'There are not 2 Service Appointments present (tag 1)'
    );
  }

  @isTest
  static void testRequestParsing() {
    String request = '{\"siteCollection\":[{\"siteItem\":{\"siteId\":\"1023\",\"articleCollection\":[{\"articleItem\":{\"articleId\":\"000000000000011863\",\"onHand\":\"2.000\",\"reserved\":\"11.000\",\"onOrder\":\"0.000\",\"available\":\"-9.000\"}}]}}]}';
    Appt3_InventoriesModelRequest parsedReq = Appt3_InventoriesModelRequest.parse(
      request
    );
    System.assertEquals(1, parsedReq.siteCollection.size(), 'There is 1 site');
  }
  @IsTest
  static void getAppointmentListBySiteIdTestForException() {
    user currentUser = [
      SELECT id
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    System.runAs(currentUser) {
      Test.startTest();

      String result = Appt3_AppointmentListPageController.getAppointmentListBySiteId(
        '1284',
        Datetime.now().formatGMT('yyyy-MM-dd')
      );

      Test.stopTest();
      System.assert(
        result.contains(Appt_ConstantValues.RESPONSE_STATUS_ERROR),
        'Exception sets error code'
      );
    }
  }

  @isTest
  static void getOrderDateTest() {
    List<ServiceAppointment> apptList = [
      SELECT Id, Work_Order__r.Order_Date__c, Work_Order__r.CreatedDate
      FROM ServiceAppointment
    ];
    apptList[0].Work_Order__r.Order_Date__c = null;
    String orderDate = Appt3_AppointmentListPageController.getOrderDate(
      apptList[0]
    );
    System.debug('checkMethods-orderDate: ' + orderDate);
    System.assertEquals(
      Datetime.now().formatGMT('yyyy-MM-dd'),
      orderDate,
      'getOrderDate is incorrect'
    );
    apptList[0].Work_Order__r = null;
    String emptyOrderDate = Appt3_AppointmentListPageController.getOrderDate(
      apptList[0]
    );
    System.assert(String.isEmpty(emptyOrderDate), 'date is empty');
  }
  //added a test method
  @isTest
  static void getOrderDataTestException() {
    Appt_UpdateAppointmentServiceModel model = new Appt_UpdateAppointmentServiceModel();
    model.layawayNumber = '1111';
    user currentUser = [
      SELECT id
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    System.runAs(currentUser) {
      Test.startTest();
      try {
        String result = Appt3_AppointmentListPageController.getOrderData(null);
      } catch (AuraHandledException ex) {
        system.debug('eror' + ex.getMessage());
        System.assert(
          ex.getMessage().contains('Script-thrown exception'),
          'Script parsing will throw error'
        );
      }
    }
  }

  @isTest
  static void getOrderDataTestCases() {
    Appt_UpdateAppointmentServiceModel model = new Appt_UpdateAppointmentServiceModel();
    model.layawayNumber = '1111';
    user currentUser = [
      SELECT id
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    System.runAs(currentUser) {
      Test.startTest();
      String result = Appt3_AppointmentListPageController.getOrderData(
        JSON.serialize(model)
      );
      System.assert(result.contains('[]'), 'layawaynumer result is empty');
      model.layawayNumber = null;
      model.quoteNumber = 'Q123';
      String result1 = Appt3_AppointmentListPageController.getOrderData(
        JSON.serialize(model)
      );
      System.assert(result1.contains('[]'), 'quoteNumber result is empty');
      model.layawayNumber = null;
      model.quoteNumber = null;
      model.invoiceNumber = 'TestInvoice';
      String result3 = Appt3_AppointmentListPageController.getOrderData(
        JSON.serialize(model)
      );
      System.assert(result3.contains('[]'), 'invoiceNumber result is empty');
      model.layawayNumber = null;
      model.quoteNumber = null;
      model.invoiceNumber = null;
      model.hybrisOrderId = '1234';
      String result4 = Appt3_AppointmentListPageController.getOrderData(
        JSON.serialize(model)
      );
      System.assert(result4.contains('[]'), 'hybrisOrderId result is empty');
      model.layawayNumber = null;
      model.quoteNumber = null;
      model.invoiceNumber = null;
      model.hybrisOrderId = null;
      model.salesOrderId = '111';
      model.orderType = 'Store Order';
      String result5 = Appt3_AppointmentListPageController.getOrderData(
        JSON.serialize(model)
      );
      System.assert(result5.contains('[]'), 'salesOrderId result is empty');
      model.salesOrderId = '111';
      model.orderType = 'Service Appointment';
      String result6 = Appt3_AppointmentListPageController.getOrderData(
        JSON.serialize(model)
      );
      System.assert(result6.contains('[]'), 'salesOrderId result is empty');
      Test.stopTest();
    }
  }

  @IsTest
  static void checkMethods() {
    System.debug('Appt3_AppointmentListPageControllerTest::checkMethods start');

    // Get the Record Id for Account Site type
    Id apptRecType = Schema.getGlobalDescribe()
      .get('Account')
      .getDescribe()
      .getRecordTypeInfosByName()
      .get('Site')
      .getRecordTypeId();
    // the the Site Accounts
    List<Account> acctList = [
      SELECT Id, SAP_STORE_ID__c
      FROM Account
      WHERE RecordTypeId = :apptRecType
    ];
    System.debug('checkMethods-SiteAccounts: ' + acctList.size());
    System.debug('checkMethods-SiteAccount: ' + acctList[0]);
    // pass parameters are SiteId and LOCAL Time for date string
    String apptListPg = Appt3_AppointmentListPageController.getAppointmentListBySiteId(
      '1236',
      Datetime.now().format('yyyy-MM-dd')
    );
    System.debug('checkMethods-ApptList: ' + apptListPg);
    String apptListPgone = Appt3_AppointmentListPageController.getAppointmentListBySiteId(
      '',
      Datetime.now().format('yyyy-MM-dd')
    );
    // System.debug('Appointment List: ' + apptListPg);
    System.assert(String.isNotBlank(apptListPg), 'Appointment List is blank');
    Appt_AppointmentsPageContainerController.ReturnModel rtnModel = (Appt_AppointmentsPageContainerController.ReturnModel) JSON.deserialize(
      apptListPg,
      Appt_AppointmentsPageContainerController.ReturnModel.class
    );
    System.debug('checkMethods-rtnModel: ' + rtnModel);
    List<Appt_UpdateAppointmentServiceModel> appointmentList = (List<Appt_UpdateAppointmentServiceModel>) JSON.deserialize(
      rtnModel.optionalModel,
      List<Appt_UpdateAppointmentServiceModel>.class
    );
    System.debug('checkMethods-appointmentList: ' + appointmentList);
    String invDetailListJson1 = Appt3_AppointmentListPageController.getOrderData(
      (JSON.serialize(appointmentList[0]))
    );
    System.debug('checkMethods-invDetailListJson1: ' + invDetailListJson1);
    System.assertEquals(
      '[]',
      invDetailListJson1,
      'unexpected response from invoice api'
    );
    String orderType = Appt3_AppointmentListPageController.getOrderType(
      'ServiceAppointment'
    );
    System.assertEquals(
      'Service Appointment',
      orderType,
      'Order Type is Service Appointment'
    );
    String storeOrderType = Appt3_AppointmentListPageController.getOrderType(
      'StoreOrder'
    );
    System.assertEquals(
      'Store Order',
      storeOrderType,
      'Order Type is Store Order'
    );
    String invDetailListJson3 = Appt3_AppointmentListPageController.getOrderData(
      (JSON.serialize(appointmentList[0]))
    );
    System.debug('checkMethods-invDetailListJson3: ' + invDetailListJson3);
    System.assertEquals(
      '[]',
      invDetailListJson3,
      'unexpected response from invoice api'
    );
    appointmentList[0].quoteNumber = null;
    appointmentList[0].layawayNumber = '12345';
    List<Appt_InvoiceDetailModel.LineItems> invDetailList3 = (List<Appt_InvoiceDetailModel.LineItems>) JSON.deserialize(
      invDetailListJson3,
      List<Appt_InvoiceDetailModel.LineItems>.class
    );
    System.assert(
      (invDetailList3 != null),
      'Appointment List Page is incorrect'
    );
    Appt_InvoiceDetailModel.LineItems lineItm = new Appt_InvoiceDetailModel.LineItems();
    lineItm.articleNumber = '000000000000011236';
    lineItm.articleType = 'ZTIR';
    lineItm.retailQuantity = 4.000;
    lineItm.storeSize = '205  /50   R16    87W SL BSW';
    lineItm.storeDescription = 'SNT  SENTURY         UHP';
    lineItm.actualUnit_price = 57.00;
    lineItm.fet = 0.00;
    lineItm.totalSalesAmount = 228.00;
    lineItm.vehicleMake = 'HONDA';
    lineItm.vehicleModel = 'PRELUDE';
    lineItm.vehicleYear = '2001';
    lineItm.mileage = '119696';
    lineItm.poNumber = '';

    List<Appt_InvoiceDetailModel.LineItems> lineItemList = new List<Appt_InvoiceDetailModel.LineItems>();
    lineItemList.add(lineItm);

    try {
      Appt3_AppointmentListPageController.getOnHandForLineItems(
        acctList[0].SAP_STORE_ID__c,
        JSON.serialize(lineItm),
        false
      );
      System.assert(false);
    } catch (AuraHandledException ex) {
      System.assert(
        ex.getMessage().contains('Script-thrown exception'),
        'Script parsing will throw error'
      );
    }
    Appt_InventoryService.isTest = true;
    Appt_InventoryService.testPayload = '{\"siteCollection\":[{\"siteItem\":{\"siteId\":\"1023\",\"articleCollection\":[{\"articleItem\":{\"articleId\":\"000000000000011863\",\"onHand\":\"2.000\",\"reserved\":\"11.000\",\"onOrder\":\"0.000\",\"available\":\"-9.000\"}}]}}]}';
    user currentUser = [
      SELECT id
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    System.runAs(currentUser) {
      Test.startTest();
      String onHandFor = Appt3_AppointmentListPageController.getOnHandForLineItems(
        acctList[0].SAP_STORE_ID__c,
        JSON.serialize(lineItemList),
        true
      );
      Test.stopTest();
      System.debug('checkMethods-onHandFor: ' + onHandFor);
    }

  }

  public class OnHandForLineItemsHttpCalloutMock implements HttpCalloutMock {
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest request) {
      // Create a fake response
      HttpResponse response = new HttpResponse();
      response.setHeader('Content-Type', 'application/json');
      response.setBody(
        '{\"siteCollection\":[{\"siteItem\":{\"siteId\":\"1023\",\"articleCollection\":[{\"articleItem\":{\"articleId\":\"000000000000011863\",\"onHand\":\"2.000\",\"reserved\":\"11.000\",\"onOrder\":\"0.000\",\"available\":\"-9.000\"}}]}}]}'
      );
      response.setStatusCode(200);
      return response;
    }
  }

  @isTest
  static void testOnHandByMock() {
    // Set the mock callout mode

    Test.setMock(
      HttpCalloutMock.class,
      new onHandForLineItemsHttpCalloutMock()
    );
    BaseIntegrationUtil.bearerToken = 'testTokenDT';
    Appt_InvoiceDetailModel.LineItems lineItm = new Appt_InvoiceDetailModel.LineItems();
    lineItm.articleNumber = '000000000000011236';
    lineItm.articleType = 'ZTIR';
    lineItm.retailQuantity = 4.000;
    lineItm.storeSize = '205  /50   R16    87W SL BSW';
    lineItm.storeDescription = 'SNT  SENTURY         UHP';
    lineItm.actualUnit_price = 57.00;
    lineItm.fet = 0.00;
    lineItm.totalSalesAmount = 228.00;
    lineItm.vehicleMake = 'HONDA';
    lineItm.vehicleModel = 'PRELUDE';
    lineItm.vehicleYear = '2001';
    lineItm.mileage = '119696';
    lineItm.poNumber = '';
    List<Appt_InvoiceDetailModel.LineItems> lineItemList = new List<Appt_InvoiceDetailModel.LineItems>();
    lineItemList.add(lineItm);
    user currentUser = [
      SELECT id
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    System.runAs(currentUser) {
      Test.startTest();
      String onHandForResponse = Appt3_AppointmentListPageController.getOnHandForLineItems(
        '1023',
        JSON.serialize(lineItemList),
        false
      );
      System.assert(
        onHandForResponse.contains(lineItm.vehicleYear),
        'Vehicle year not matched'
      );
      System.assert(
        onHandForResponse.contains(lineItm.vehicleMake),
        'Vehicle make not matched'
      );
      System.assert(
        onHandForResponse.contains(lineItm.vehicleModel),
        'Vehicle Model not matched'
      );
      Test.stopTest();
    }
  }

  //Test for Universl Sales order Id
  @isTest
  static void testRequestOrderHistories() {
    string request = '{ \"siteId\": \"1434\", \"orderCollection\": [ { \"orderItem\": { \"orderId\": \"56000010\" } }, { \"orderItem\": { \"orderId\": \"56000021\" } } ] }';
    Appt3_OrderHistoriesModelRequest parsedReq = Appt3_OrderHistoriesModelRequest.parse(
      request
    );
    System.assertEquals(parsedReq.siteId, '1434', 'SiteId not matching');
    System.assertEquals(parsedReq.OrderCollection.size(), 2, 'Order size is 2');
  }
  public class TestResponseOrderHistoriesHttpCalloutMock implements HttpCalloutMock {
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest request) {
      // Create a fake response
      HttpResponse response = new HttpResponse();
      response.setHeader('Content-Type', 'application/json');
      response.setBody(
        '{ \"orderDetailCollection\": [ { \"orderDetailItem\": { \"orderId\": \"56000010\", \"articleNumber\": \"10000002221\", \"articleType\": \"ZWHL\", \"retailQuantity\": 4, \"storeSize\": \"19X8 5-114.30 40SL TSW CRTHG\", \"storeDescription\": \"TSW CRTHG\", \"siteId\": \"1434\" } }, { \"orderDetailItem\": { \"orderId\": \"56000010\", \"articleNumber\": \"10000001221\", \"articleType\": \"ZWHL\", \"retailQuantity\": 4, \"storeSize\": \"19X8 5-114.30 40SL TSW CRTHG\", \"storeDescription\": \"TSW CRTHG\", \"siteId\": \"1434\" } }, { \"orderDetailItem\": { \"orderId\": \"56000021\", \"articleNumber\": \"10000002222\", \"articleType\": \"ZWHL\", \"retailQuantity\": 5, \"storeSize\": \"19X8 5-114.30 40SL TSW CRTHG\", \"storeDescription\": \"TSW CRTHG\", \"siteId\": \"1434\" } } ] }'
      );
      response.setStatusCode(200);
      return response;
    }
  }

  @isTest
  static void getOrderDataTestByMock() {
    Test.setMock(
      HttpCalloutMock.class,
      new TestResponseOrderHistoriesHttpCalloutMock()
    );
    BaseIntegrationUtil.bearerToken = 'testTokenDT';
    Appt_InvoiceDetailModel.OrderHistoryDetails orderHistoryDetails = new Appt_InvoiceDetailModel.OrderHistoryDetails();
    Appt_UpdateAppointmentServiceModel model = new Appt_UpdateAppointmentServiceModel();
    model.salesOrderId = '5644364';
    model.siteId = '1234';
    user currentUser = [
      SELECT id
      FROM user
      WHERE LastName = 'TerminalTestUser'
      LIMIT 1
    ];
    System.runAs(currentUser) {
      Test.startTest();
      String response = Appt3_AppointmentListPageController.getOrderData(
        JSON.serialize(model)
      );
      System.debug('ResponeData--->' + response);
      System.assert(
        response.contains('\"storeDescription\":\"TSW CRTHG\"'),
        'store description missing'
      );
      System.assert(
        response.contains('\"storeSize\":\"19X8 5-114.30 40SL TSW CRTHG\"'),
        'store size missing'
      );
      //System.assert(response.contains('\"articleType\":\"ZWHL\"'), 'articleType missing');
      System.assert(
        response.contains('\"articleNumber\":\"10000002221\"'),
        'articleNumber missing'
      );

      Test.stopTest();
    }

  }
}