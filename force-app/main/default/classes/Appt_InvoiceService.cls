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

}