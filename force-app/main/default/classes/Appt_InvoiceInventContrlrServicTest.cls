@IsTest
public class Appt_InvoiceInventContrlrServicTest {

    @IsTest
    public static void getInventoryTest() {

        
        
        
        
        Test.startTest();
        Appt_InventoryModel invError =  Appt_InventoryController.getInventory('2132', '70951');

        Appt_InventoryService.isTest = true;
        //Appt_InventoryModel invEmpty =  Appt_InventoryController.getInventory('2132', '70951');
        //System.assert(invEmpty.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR, 'Expecting invResult.status to be Error');

        Appt_InventoryService.testPayload = Appt_InventoryModelTest.getJSON();
        Appt_InventoryModel invError2 =  Appt_InventoryController.getInventory(' ', '70951');
        System.assert(invError2.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR, 'Expecting invResult.status to be Error');

        Appt_InventoryModel invResult =  Appt_InventoryController.getInventory('2132', '70951');

        Test.stopTest();

        System.assert(invResult != null, 'Expecting invResult to not be null');
        System.assert(invResult.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS, 'Expecting invResult.status to be Success');

    }

    @IsTest
    public static void getInvoiceDetailTest() {

        Appt_InvoiceService.isTest = true;
        Appt_InvoiceService.testPayload = Appt_InvoiceDetailModelTest.getJSON();
        
        
        Test.startTest();

        Appt_InvoiceDetailModel invResult = Appt_InvoiceController.getInvoiceDetail('0001023', '3420625', Appt_ConstantValues.INVOICE_ID_TYPE_INVOICE_NUMBER, '2020-07-24');
        Appt_InvoiceDetailModel invError = Appt_InvoiceController.getInvoiceDetail('0001023', '3420625', Appt_ConstantValues.INVOICE_ID_TYPE_INVOICE_NUMBER, '');
        Appt_InvoiceDetailModel invError4 = Appt_InvoiceController.getInvoiceDetail('0001023', ' ', Appt_ConstantValues.INVOICE_ID_TYPE_INVOICE_NUMBER, '2020-07-24');

        Appt_InvoiceDetailModel invResultHyb = Appt_InvoiceController.getInvoiceDetail('1055', '606007747', Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER, null);
        Appt_InvoiceDetailModel invResultLeg = Appt_InvoiceController.getInvoiceDetail('1007', '0023859161', Appt_ConstantValues.INVOICE_ID_TYPE_LEGACY_ORDER_NUMBER, null);
        Appt_InvoiceDetailModel invResultLay = Appt_InvoiceController.getInvoiceDetail('0000001007', '1007107148', Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER, null);
        Appt_InvoiceDetailModel invError2 = Appt_InvoiceController.getInvoiceDetail('0000001007', '1007107148', 7, null);
        Appt_InvoiceDetailModel invError3 = Appt_InvoiceController.getInvoiceDetail(null, '', Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER, null);

        Test.stopTest();

        System.assert(invResult != null, 'Expecting invResult to not be null');
        System.assert(invResult.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS, 'Expecting invResult.status to be Success');

        System.assert(invError.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR, 'Expecting invError.status to be Error');
        System.assert(invError2.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR, 'Expecting invError2.status to be Error');
        System.assert(invError3.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR, 'Expecting invError3.status to be Error');
        System.assert(invError4.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR, 'Expecting invError4.status to be Error');

        System.assert(invResultHyb.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS, 'Expecting invResult.status to be Success');
        System.assert(invResultLeg.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS, 'Expecting invResult.status to be Success');
        System.assert(invResultLay.status == Appt_ConstantValues.RESPONSE_STATUS_SUCCESS, 'Expecting invResult.status to be Success');

    }
    
}