public class Appt_InvoiceService extends Appt_BaseIntegrationService {
    public static String lprefix = 'APT_INVOICE_SERV: ';

    public static Boolean isTest = false;
    public static String testPayload = '';

    //---Get the Invoice Details - Need to provide Invoice Id, along with the Side Id and the Invoice Business Date
    public static Appt_InvoiceDetailModel getInvoiceDetail(String siteId, String invoiceId, String invoiceDate) {
        System.debug( lprefix + 'getInvoiceDetail() ENTRY -  SiteId=' + siteId + ', InvoiceId=' + invoiceId + ', invoiceDate=' + invoiceDate);

        Appt_InvoiceDetailModel returnDetailModel = new Appt_InvoiceDetailModel();

        //-- validate params aren't blank or null
        if (String.isBlank(invoiceId) || String.isBlank(siteId) || String.isBlank(invoiceDate)) {
            returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'One or more required params for getInvoiceDetail() are null or blank. SiteId=' + siteId + ', InvoiceId=' + invoiceId + ', invoiceDate=' + invoiceDate);
            System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
            return returnDetailModel;
        }

        //-- validate format of invoiceBusinessDate string to be yyyy-mm-dd
        try {
            Date validDate = Date.valueOf(invoiceDate);
            System.debug('validDate: ' + validDate);
        } catch(Exception e) {
            System.debug( lprefix + '    invoiceDate string param is invlaid because: ' + e.getMessage());
            returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'invoiceDate parameter is invalid date string. invoiceDate=' + invoiceDate);
            System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
            return returnDetailModel;
        }

        //-- pad the siteId to be 10 chars and invoiceId to be 20 chars
        String paddedSiteId = siteId.leftPad(10,'0');
        String paddedInvId = invoiceId.leftPad(20,'0');

        //-- If here then params are valid, build endpoint URL
        String endUrl = BaseIntegrationUtil.getSettingValue( Appt_ConstantValues.INTEGRATION_SETTING_INVOICE_DETAILS_URL, Appt_ConstantValues.INTEGRATION_SETTING_SYSTEM_APPOINTMENT);
        endUrl += '?siteId=' + paddedSiteId + '&invoiceNumber=' + paddedInvId + '&invoiceDate=' + invoiceDate;
        System.debug( lprefix + '    APPT Invoice Detail Integration endUrl: ' + endUrl);

        Int_Message__c intMsg = new Int_Message__c(Type__c=Int_Values.TYPE_INVOICE_DETAIL_INVOICE_NUMBER, Status__c=Int_Values.STATUS_PENDING, Url__c=endUrl);

        String body = '';
        if (isTest)
        {
            body = testPayload;
        }
        else 
        {
            HttpRequest req = buildAppointmentHttpReq( endUrl);
            System.debug( lprefix + 'HttpRequest: '+req);

            body = BaseIntegrationUtil.getRequestBody(req, intMsg);
            System.debug( lprefix + 'Request Body: '+body);
            upsert intMsg;
            
            if (body == null || body == '')
            {
                returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR, 'Request for Invoice Detail FAILED');
                System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
                return returnDetailModel;
            } 
        }

        //using Appt_InvoiceDetailModel for Appointment invoice detail since fields are same
        returnDetailModel = Appt_InvoiceDetailModel.parse(body);
        returnDetailModel.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;

        System.debug(lprefix+'getInvoiceDetail():EXIT - return Appt_InvoiceDetailModel:' + returnDetailModel);
        System.debug(lprefix+'getInvoiceDetail():EXIT - serialized:' + JSON.serialize(returnDetailModel));
        return returnDetailModel;
    }


    //---Get the Invoice Details with params siteId and one of the possible ID params, determined by idType param
    public static Appt_InvoiceDetailModel getInvoiceDetail(String siteId, String id, Integer idType) {
        System.debug( lprefix + 'getInvoiceDetail() ENTRY -  SiteId= ' + siteId + ', id=' + id + ', idType='+idType);

        Appt_InvoiceDetailModel returnDetailModel = new Appt_InvoiceDetailModel();

        //-- validate params aren't blank or null
        if (String.isBlank(id) || String.isBlank(siteId)) {
            returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'One or more required ID params for getInvoiceDetail() are null or blank. SiteId:' + siteId + ', id:' + id);
            System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
            return returnDetailModel;
        }

        //-- pad the siteId to be 10 chars 
        String paddedSiteId = siteId.leftPad(10,'0');

        String endUrl;
        String idParamName;

        //-- determine name of ID parameter from idType  
        //Appt 3.0 - Added condition for MDM Sales Order Id at the end
        if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER) idParamName = Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER_PARAM_NAME;
        else if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_LEGACY_ORDER_NUMBER) idParamName = Appt_ConstantValues.INVOICE_ID_TYPE_LEGACY_ORDER_NUMBER_PARAM_NAME;
        else if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER) idParamName = Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER_PARAM_NAME;
        else if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER) idParamName = Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER_PARAM_NAME;

        if (String.isBlank(idParamName)) {

            //-- VALIDATION ERROR - unable to determine ID param, return error
            returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'UNKNOWN type of ID parameter with idType=' + idType);
            System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
            return returnDetailModel;

        } else {
            endUrl = BaseIntegrationUtil.getSettingValue( Appt_ConstantValues.INTEGRATION_SETTING_INVOICE_DETAILS_URL, Appt_ConstantValues.INTEGRATION_SETTING_SYSTEM_APPOINTMENT);
            endUrl += '?siteId=' + paddedSiteId + '&' + idParamName + '=' + id;
            System.debug( lprefix + '    APPT Invoice Detail Integration endUrl: ' + endUrl);
        }

        Int_Message__c intMsg = new Int_Message__c(Type__c=Int_Values.TYPE_INVOICE_DETAIL_HYBRIS_NUMBER, Status__c=Int_Values.STATUS_PENDING, Url__c=endUrl);

        String body = '';

        if (isTest)
        {
            body = testPayload;
        }
        else 
        {
            HttpRequest req = buildAppointmentHttpReq( endUrl);
            System.debug( lprefix + 'HttpRequest: '+req);

            body = BaseIntegrationUtil.getRequestBody(req, intMsg);
            System.debug( lprefix + 'Request Body: '+body);
            upsert intMsg;
            
            if (body == null || body == '')
            {
                returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR, 'Request for Invoice Detail FAILED');
                System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
                return returnDetailModel;
            } 
        }

        //using Appt_InvoiceDetailModel for Appointment invoice detail since fields are same
        returnDetailModel = Appt_InvoiceDetailModel.parse(body);
        returnDetailModel.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;

        System.debug(lprefix+'getInvoiceDetail():EXIT - return Appt_InvoiceDetailModel:' + returnDetailModel);
        return returnDetailModel;
    }


    /*
     *   Bulk methods for batch processing 
     */

    //---Get the Invoice Details - Need to provide Invoice Id, along with the Side Id and the Invoice Business Date
    public static Appt_InvoiceDetailModel getInvoiceDetailBulk(String siteId, String invoiceId, String invoiceDate, List<Int_Message__c> intMsgList) {
        System.debug( lprefix + 'getInvoiceDetailBulk() ENTRY -  SiteId=' + siteId + ', InvoiceId=' + invoiceId + ', invoiceDate=' + invoiceDate);

        Appt_InvoiceDetailModel returnDetailModel = new Appt_InvoiceDetailModel();

        //-- validate params aren't blank or null
        if (String.isBlank(invoiceId) || String.isBlank(siteId) || String.isBlank(invoiceDate)) {
            returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'One or more required params for getInvoiceDetail() are null or blank. SiteId=' + siteId + ', InvoiceId=' + invoiceId + ', invoiceDate=' + invoiceDate);
            System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
            return returnDetailModel;
        }

        //-- validate format of invoiceBusinessDate string to be yyyy-mm-dd
        try {
            Date validDate = Date.valueOf(invoiceDate);
            System.debug('validDate: ' + validDate);
        } catch(Exception e) {
            System.debug( lprefix + '    invoiceDate string param is invlaid because: ' + e.getMessage());
            returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'invoiceDate parameter is invalid date string. invoiceDate=' + invoiceDate);
            System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
            return returnDetailModel;
        }

        //-- pad the siteId to be 10 chars and invoiceId to be 20 chars
        String paddedSiteId = siteId.leftPad(10,'0');
        String paddedInvId = invoiceId.leftPad(20,'0');

        //-- If here then params are valid, build endpoint URL
        String endUrl = BaseIntegrationUtil.getSettingValue( Appt_ConstantValues.INTEGRATION_SETTING_INVOICE_DETAILS_URL, Appt_ConstantValues.INTEGRATION_SETTING_SYSTEM_APPOINTMENT);
        endUrl += '?siteId=' + paddedSiteId + '&invoiceNumber=' + paddedInvId + '&invoiceDate=' + invoiceDate;
        System.debug( lprefix + '    APPT Invoice Detail Integration endUrl: ' + endUrl);

        Int_Message__c intMsg = new Int_Message__c(Type__c=Int_Values.TYPE_INVOICE_DETAIL_INVOICE_NUMBER, Status__c=Int_Values.STATUS_PENDING, Url__c=endUrl);

        String body = '';
        if (isTest)
        {
            body = testPayload;
        }
        else 
        {
            HttpRequest req = buildAppointmentHttpReq( endUrl);
            System.debug( lprefix + 'HttpRequest: '+req);

            body = BaseIntegrationUtil.getRequestBody(req, intMsg);
            System.debug( lprefix + 'Request Body: '+body);
            intMsgList.add( intMsg );
            
            if (body == null || body == '')
            {
                returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR, 'Request for Invoice Detail FAILED');
                System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
                return returnDetailModel;
            } 
        }

        //using Appt_InvoiceDetailModel for Appointment invoice detail since fields are same
        returnDetailModel = Appt_InvoiceDetailModel.parse(body);
        returnDetailModel.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;

        System.debug(lprefix+'getInvoiceDetail():EXIT - return Appt_InvoiceDetailModel:' + returnDetailModel);
        return returnDetailModel;
    }


    //---Get the Invoice Details with params siteId and one of the possible ID params, determined by idType param
    public static Appt_InvoiceDetailModel getInvoiceDetailBulk(String siteId, String id, Integer idType, List<Int_Message__c> intMsgList) {
        System.debug( lprefix + 'getInvoiceDetailBulk() ENTRY -  SiteId= ' + siteId + ', id=' + id + ', idType='+idType);

        Appt_InvoiceDetailModel returnDetailModel = new Appt_InvoiceDetailModel();

        //-- validate params aren't blank or null
        if (String.isBlank(id) || String.isBlank(siteId)) {
            returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'One or more required ID params for getInvoiceDetail() are null or blank. SiteId:' + siteId + ', id:' + id);
            System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
            return returnDetailModel;
        }

        //-- pad the siteId to be 10 chars 
        String paddedSiteId = siteId.leftPad(10,'0');

        String endUrl;
        String idParamName;

        //-- determine name of ID parameter from idType  
        if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER) idParamName = Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER_PARAM_NAME;
        else if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_LEGACY_ORDER_NUMBER) idParamName = Appt_ConstantValues.INVOICE_ID_TYPE_LEGACY_ORDER_NUMBER_PARAM_NAME;
        else if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER) idParamName = Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER_PARAM_NAME;
        else if (idType == Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER) idParamName = Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER_PARAM_NAME;

        if (String.isBlank(idParamName)) {

            //-- VALIDATION ERROR - unable to determine ID param, return error
            returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'UNKNOWN type of ID parameter with idType=' + idType);
            System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
            return returnDetailModel;

        } else {
            endUrl = BaseIntegrationUtil.getSettingValue( Appt_ConstantValues.INTEGRATION_SETTING_INVOICE_DETAILS_URL, Appt_ConstantValues.INTEGRATION_SETTING_SYSTEM_APPOINTMENT);
            endUrl += '?siteId=' + paddedSiteId + '&' + idParamName + '=' + id;
            System.debug( lprefix + '    APPT Invoice Detail Integration endUrl: ' + endUrl);
        }

        Int_Message__c intMsg = new Int_Message__c(Type__c=Int_Values.TYPE_INVOICE_DETAIL_HYBRIS_NUMBER, Status__c=Int_Values.STATUS_PENDING, Url__c=endUrl);

        String body = '';

        if (isTest)
        {
            body = testPayload;
        }
        else 
        {
            HttpRequest req = buildAppointmentHttpReq( endUrl);
            System.debug( lprefix + 'HttpRequest: '+req);

            body = BaseIntegrationUtil.getRequestBody(req, intMsg);
            System.debug( lprefix + 'Request Body: '+body);
            intMsgList.add( intMsg );
            
            if (body == null || body == '')
            {
                returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR, 'Request for Invoice Detail FAILED');
                System.debug( lprefix + '    ERROR - returnErrorModel: ' + returnDetailModel);
                return returnDetailModel;
            } 
        }

        //using Appt_InvoiceDetailModel for Appointment invoice detail since fields are same
        returnDetailModel = Appt_InvoiceDetailModel.parse(body);
        returnDetailModel.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;

        System.debug(lprefix+'getInvoiceDetail():EXIT - return Appt_InvoiceDetailModel:' + returnDetailModel);
        return returnDetailModel;
    }
    
    //Appt 3.0 - Get the order history details based on the universal sales order id
    public static Appt_InvoiceDetailModel getOrderHistoryDetails(String siteId, String salesOrderId, String orderType) {	
        System.debug( lprefix + 'getOrderHistoryDetails() ENTRY -  siteId='+siteId+ ' salesOrderId='+salesOrderId);
        String body = '';
        Appt_InvoiceDetailModel.OrderHistoryDetails orderHistoryDetails = new Appt_InvoiceDetailModel.OrderHistoryDetails();
        Appt_InvoiceDetailModel.ResponseDetail responseDetail = new Appt_InvoiceDetailModel.ResponseDetail();
        orderHistoryDetails.lineItems = new List<Appt_InvoiceDetailModel.LineItems>();
        responseDetail.orderHistoryDetails = new List<Appt_InvoiceDetailModel.OrderHistoryDetails>();        
        Appt3_OrderHistoriesModelRequest orderHistoriesRequest = new Appt3_OrderHistoriesModelRequest();
        Appt_InvoiceDetailModel returnDetailModel = new Appt_InvoiceDetailModel();
        orderHistoriesRequest.orderCollection = new List<Appt3_OrderHistoriesModelRequest.OrderCollection>();
        Appt3_OrderHistoriesModelResponse orderHistoriesResponse = new Appt3_OrderHistoriesModelResponse();
        List<Appt_InvoiceDetailModel.LineItems> lineItemResponse = new List<Appt_InvoiceDetailModel.LineItems>();
        Appt3_OrderHistoriesModelRequest.OrderItem oItem = new Appt3_OrderHistoriesModelRequest.OrderItem();
        Appt3_OrderHistoriesModelRequest.OrderCollection oCollection = new Appt3_OrderHistoriesModelRequest.OrderCollection();
        String endUrl = BaseIntegrationUtil.getSettingValue( Appt_ConstantValues.INTEGRATION_SETTING_ORDER_HISTORIES_URL, Appt_ConstantValues.INTEGRATION_SETTING_SYSTEM_APPOINTMENT);
        System.debug( lprefix + 'APPT Consolidated Order Histories Integration endUrl: ' + endUrl);
        Int_Message__c intMsg = new Int_Message__c(Type__c=Int_Values.TYPE_ORDER_HISTORIES, Status__c=Int_Values.STATUS_PENDING, Url__c=endUrl);
        //Form the request body
        oItem.orderId = salesOrderId;
        oCollection.orderItem = oItem;
        orderHistoriesRequest.siteId = siteId;
        orderHistoriesRequest.orderType = orderType;
        orderHistoriesRequest.orderCollection.add(oCollection);
        if (isTest) {
            body = testPayload;
        } else {
            HttpRequest req = buildAppointmentHttpReq(endUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            body = JSON.serialize(orderHistoriesRequest);
            System.debug( lprefix + 'request Body: '+body);
            req.setBody(body);
            body = BaseIntegrationUtil.getRequestBody(req, intMsg);
            System.debug( lprefix + 'Response Body: '+body);
            upsert intMsg;
            
            if (body == null || body == '') {
                returnDetailModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR, 'Request for getting invoices in a order history call FAILED' + orderHistoriesRequest);
                return returnDetailModel;
            }
        }

        orderHistoriesResponse = Appt3_OrderHistoriesModelResponse.parse(body);
        //Convert universal sales order id response to keep it consistent with other sales order response model
        if (orderHistoriesResponse != null && orderHistoriesResponse.orderDetailCollection.size() > 0) {
            for (Appt3_OrderHistoriesModelResponse.OrderDetailCollection oh : orderHistoriesResponse.orderDetailCollection) {
                Appt_InvoiceDetailModel.LineItems lineItem = new Appt_InvoiceDetailModel.LineItems();
                lineItem.articleType = oh.orderDetailItem.typeCodeDescription;
                lineItem.articleNumber = oh.orderDetailItem.articleNumber;
                lineItem.storeSize = oh.orderDetailItem.storeSize;
                lineItem.storeDescription = oh.orderDetailItem.storeDescription;
                lineItem.retailQuantity = oh.orderDetailItem.retailQuantity;
                orderHistoryDetails.lineItems.add(lineItem);
            }
            if(!orderHistoryDetails.lineItems.isEmpty()) {
                responseDetail.orderHistoryDetails.add(orderHistoryDetails);
                returnDetailModel.responseDetail = responseDetail;
            }
        }
        returnDetailModel.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;
        return returnDetailModel;
    }
}