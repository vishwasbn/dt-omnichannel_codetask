@isTest
public class Appt_AppointmentListPageControllerTest 
{
    @TestSetup
    static void setupData()
    {
        List<ServiceAppointment> appts = Appt_TestUtil.basicAppointment_storeConfiguration();
        appts = Appt_TestUtil.basicFleetAppointment_StoreConfiguration();
        for (ServiceAppointment sa: appts)
        {
            System.debug('ServAppt: ' + sa);
            sa.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        }
        update appts;

        System.assertEquals(4, appts.size(), 'There are not 4 Service Appointments present (tag 1)');
    }

    @isTest 
    static void checkMethods()
    {
        System.debug('Appt_AppointmentListPageControllerTest::checkMethods start');

        // Get the Record Id for Account Site type
        Id apptRecType = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Site').getRecordTypeId();
        // the the Site Accounts
        List<Account> acctList = [ SELECT Id, SAP_STORE_ID__c FROM Account WHERE RecordTypeId =:apptRecType ];
        System.debug('checkMethods-SiteAccounts: ' + acctList.size());
        System.debug('checkMethods-SiteAccount: ' + acctList[0]);

        // pass parameters are SiteId and LOCAL Time for date string
        String apptListPg = Appt_AppointmentListPageController.getAppointmentListBySiteId( acctList[0].SAP_STORE_ID__c, Datetime.now().format('yyyy-MM-dd') );
        Appt_AppointmentListPageController.getAppointmentListBySiteId( acctList[1].SAP_STORE_ID__c, Datetime.now().format('yyyy-MM-dd') );
        System.debug('checkMethods-ApptList: ' + apptListPg);

        // System.debug('Appointment List: ' + apptListPg);
        System.assert(String.isNotBlank(apptListPg), 'Appointment List is blank');


        Appt_AppointmentsPageContainerController.ReturnModel rtnModel = (Appt_AppointmentsPageContainerController.ReturnModel) JSON.deserialize(apptListPg, Appt_AppointmentsPageContainerController.ReturnModel.class);
        System.debug('checkMethods-rtnModel: ' + rtnModel);

        List<Appt_UpdateAppointmentServiceModel> appointmentList = (List<Appt_UpdateAppointmentServiceModel>) JSON.deserialize(rtnModel.optionalModel, List<Appt_UpdateAppointmentServiceModel>.class);
        System.debug('checkMethods-appointmentList: ' + appointmentList);

        String invDetailListJson1 = Appt_AppointmentListPageController.getOrderData((JSON.serialize(appointmentList[0]))); 
        System.debug('checkMethods-invDetailListJson1: ' + invDetailListJson1);
        System.assertEquals('[]', invDetailListJson1, 'unexpected response from invoice api');

        appointmentList[0].hybrisOrderId = null;
        appointmentList[0].invoiceNumber = '12345';

        String formNumberString = Appt_AppointmentListPageController.getMappedFormNumber('BOPIS', 'posWebOrderId', 'layawayNumber', 'invoiceNumber', 'quoteNumber');
        System.assertEquals('posWebOrderId', formNumberString, 'BOPIS form number incorrect');

        String invDetailListJson2 = Appt_AppointmentListPageController.getOrderData((JSON.serialize(appointmentList[0]))); 
        System.debug('checkMethods-invDetailListJson2: ' + invDetailListJson2);
        System.assertEquals('[]', invDetailListJson2, 'unexpected response from invoice api');

        appointmentList[0].invoiceNumber = null;
        appointmentList[0].quoteNumber = '12345';

        formNumberString = Appt_AppointmentListPageController.getMappedFormNumber('ServiceAppointment', 'posWebOrderId', 'layawayNumber', 'invoiceNumber', 'quoteNumber');
        System.assertEquals('posWebOrderId', formNumberString, 'ServiceAppointment form number incorrect');

        String invDetailListJson3 = Appt_AppointmentListPageController.getOrderData((JSON.serialize(appointmentList[0]))); 
        System.debug('checkMethods-invDetailListJson3: ' + invDetailListJson3);
        System.assertEquals('[]', invDetailListJson3, 'unexpected response from invoice api');

        appointmentList[0].quoteNumber = null;
        appointmentList[0].layawayNumber = '12345';

        formNumberString = Appt_AppointmentListPageController.getMappedFormNumber('Layaway', 'posWebOrderId', 'layawayNumber', 'invoiceNumber', 'quoteNumber');
        System.assertEquals('layawayNumber', formNumberString, 'layawayNumber form number incorrect');

        String invDetailListJson4 = Appt_AppointmentListPageController.getOrderData((JSON.serialize(appointmentList[0]))); 
        System.debug('checkMethods-invDetailListJson4: ' + invDetailListJson4);
        System.assertEquals('[]', invDetailListJson4, 'unexpected response from invoice api');

        formNumberString = Appt_AppointmentListPageController.getMappedFormNumber('Invoice', 'posWebOrderId', 'layawayNumber', 'invoiceNumber', 'quoteNumber');
        System.assertEquals('invoiceNumber', formNumberString, 'invoiceNumber form number incorrect');

        formNumberString = Appt_AppointmentListPageController.getMappedFormNumber('Quote', 'posWebOrderId', 'layawayNumber', 'invoiceNumber', 'quoteNumber');
        System.assertEquals('quoteNumber', formNumberString, 'quoteNumber form number incorrect');

        formNumberString = Appt_AppointmentListPageController.getMappedFormNumber('Default', 'posWebOrderId', 'layawayNumber', 'invoiceNumber', 'quoteNumber');
        System.assertEquals('', formNumberString, 'quoteNumber form number incorrect');

        List<Appt_InvoiceDetailModel.LineItems> invDetailList3 = (List<Appt_InvoiceDetailModel.LineItems>) JSON.deserialize(invDetailListJson3, List<Appt_InvoiceDetailModel.LineItems>.class);

        // System.debug('Appointment Invoice Detail List: ' + invDetailList);
        System.assert( (invDetailList3 != null), 'Appointment List Page is incorrect');

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

        String onHandFor = Appt_AppointmentListPageController.getOnHandForLineItems(acctList[0].SAP_STORE_ID__c, JSON.serialize(lineItm));
        System.debug('checkMethods-onHandFor: ' + onHandFor);
        System.assertEquals('Failed to retrieve', onHandFor, 'unexpected response from inventory api');
         
        String onHandFor1 = Appt_AppointmentListPageController.getOnHandForLineItems(null, null);
        System.debug('checkMethods-onHandFor: ' + onHandFor1);
        
        List<Appt_InvoiceDetailModel.LineItems> itemList = new List<Appt_InvoiceDetailModel.LineItems>();
        itemList.add(lineItm);

        Appt_AppointmentListPageController.mapArticleTypeToServiceForLineItems(itemList);
        System.assertEquals('TIRES', lineItm.articleType, 'Tires replacement is incorrect');
        lineItm.articleType = 'ZWHL';

        Appt_AppointmentListPageController.mapArticleTypeToServiceForLineItems(itemList);
        System.assertEquals('WHEELS', lineItm.articleType, 'Tires replacement is incorrect');
        /**
        lineItm.articleType = 'Merch';
        lineItm.articleNumber = '000000000000080400';
        Appt_AppointmentListPageController.mapArticleTypeToServiceForLineItems(itemList);
        System.assertEquals('ROTO/BALANCE', lineItm.articleType, 'Tires replacement is incorrect');
        lineItm.articleNumber = '000000000000080222';
        
        Appt_AppointmentListPageController.mapArticleTypeToServiceForLineItems(itemList);
        System.assertEquals('FREE LABOR', lineItm.articleType, 'Tires replacement is incorrect');
        lineItm.articleNumber = '000000000000084802';
        
        Appt_AppointmentListPageController.mapArticleTypeToServiceForLineItems(itemList);
        System.assertEquals('LABOR', lineItm.articleType, 'Tires replacement is incorrect');
        lineItm.articleNumber = '000000000000012345';

        Appt_AppointmentListPageController.mapArticleTypeToServiceForLineItems(itemList);
        System.assertEquals('', lineItm.articleType, 'Tires replacement is incorrect');

        */

        List<ServiceAppointment> apptList = [SELECT Id, Work_Order__r.Order_Date__c, Work_Order__r.CreatedDate FROM ServiceAppointment];
        apptList[0].Work_Order__r.Order_Date__c = null;

        // cleared the Order_Date__c, so it is returning created date, which is GMT ... this may be wrong
        String orderDate = Appt_AppointmentListPageController.getOrderDate(apptList[0]);
        System.debug('checkMethods-orderDate: ' + orderDate);
        System.assertEquals(Datetime.now().formatGMT('yyyy-MM-dd'), orderDate, 'getOrderDate is incorrect');

        System.debug('Appt_AppointmentListPageControllerTest::checkMethods end');
    }    

}