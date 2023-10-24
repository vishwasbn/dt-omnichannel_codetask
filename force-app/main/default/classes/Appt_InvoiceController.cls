public class Appt_InvoiceController {
    public static String lprefix = 'APT_INVOICE_CONT: ';


    //-- The Invoice Detail API takes one of many types of ID numbers, like hybrisOrderNumber or legacyOrderNumber, which is defined by the idType parameter.
    //--  There are constants setup in Appt_ConstantValues class for the idType param values. HOWEVER, if the type of ID passed is
    //--  invoiceNumber, than invoiceDate date param is also required. The idType param is used to determine which Service method to call. 
    public static Appt_InvoiceDetailModel getInvoiceDetail(String siteId, String id, Integer idType, String invoiceDate)
    {
        System.debug(lprefix+'getInvoiceDetail():ENTRY siteId=' + siteId + ', id='+id+', idType='+idType + ', invoiceDate='+invoiceDate);

        if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_INVOICE_NUMBER && String.isBlank(invoiceDate)) {

            //-- VALIDATION ERROR - invoiceDate must be populated if using invoiceId as ID param
            Appt_InvoiceDetailModel returnDetailModel = new Appt_InvoiceDetailModel();
            returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'If invoiceNumber ID parameter is used, then invoiceDate must contain valid date in format yyyy-mm-dd');
            System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
            return returnDetailModel;

        } else if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_INVOICE_NUMBER) { 
            return Appt_InvoiceService.getInvoiceDetail(siteId, id, invoiceDate);
        } else {
            return Appt_InvoiceService.getInvoiceDetail(siteId, id, idType);
        }
    }
    
    //Appt 3.0 - Pass through method that calls another method to fetch order history details from SAP CAR  
    public static Appt_InvoiceDetailModel getOrderHistoryDetails(String siteId, String salesOrderId, String orderType){	
        System.debug(lprefix+'getOrderHistoryDetails():ENTRY siteId=' + siteId + ', salesOrderId='+salesOrderId);
		return Appt_InvoiceService.getOrderHistoryDetails(siteId, salesOrderId, orderType);
    }
}