/**
 * This service class will contain code that will interface with mulsoft Invoice experience APIs.
 * In addition, this class will contain mock API methods to use for Test Coverage, as well as development.
 */
public class Fleet_InvoiceService {
    public static String lprefix = 'FLEET_INV_SERVICE: ';

    public static Boolean isTest = false;
    public static String testPayload = '{}';
    public static List<Int_Message__c> intMessages = new List<Int_Message__c>();

    //---Get the Invoice Details - Need to provide Invoice Id, along with the Side Id and the Invoice Business Date
    public static Fleet_Model_OrderHistoryDetails getInvoiceDetail(String invoiceId, String siteId, Date invoiceBusinessDate) 
    {
        System.debug( lprefix + 'Request for Invoice Detail for InvoiceId:' + invoiceId + ' SiteId: ' + siteId + ' Inv Business Date: ' + invoiceBusinessDate);

        DateTime dt = DateTime.newInstance(invoiceBusinessDate.year(), invoiceBusinessDate.month(),invoiceBusinessDate.day());
        String dateStr = dt.format('yyyy-MM-dd');

        String endUrl = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_INVOICE_DETAILS_URL);
        endUrl += invoiceId +  '?businessDayDate=' + dateStr + '&siteId=' + siteId;
        
        Int_Message__c intMsg = new Int_Message__c(Type__c=Int_Values.TYPE_CAR_LIST, Status__c=Int_Values.STATUS_PENDING, Url__c=endUrl);

        String body = '';

        if (isTest)
        {
            body = testPayload;
        }
        else 
        {
            HttpRequest req = buildCARHttpReq( endUrl);

            body = Fleet_IntegrationUtil.getRequestBody(req, intMsg);
            upsert intMsg;
            
            if (body == null || body == '')
            {
                System.debug( lprefix + 'Request for Invoice Detail FAILED');
                return null;
            } 
        }

        Fleet_CarDetailModel detailModel = Fleet_CarDetailModel.parse(body);
        System.debug( lprefix + 'Parsed' + detailModel);     
        
        Fleet_Model_OrderHistoryDetails retItem;

        if ( (detailModel.responseDetail != null) &&
             (detailModel.responseDetail.orderHistoryDetails != null) &&
             (detailModel.responseDetail.orderHistoryDetails.size() > 0) ) 
        {
            retItem = Fleet_Model_OrderHistoryDetails.build(detailModel.responseDetail.orderHistoryDetails[0]);
            System.debug( lprefix + 'Converted' + retItem);  
        }

        System.debug( lprefix + 'Request for Invoice Detail SUCCESS');

        return retItem;
    }
    
    //---Build the CAR Http Request
    public static HttpRequest buildCARHttpReq(String endUrl)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:FleetExperienceAPI' + endUrl);
        req.setMethod('GET');
        req.setHeader('dtSourceSystem', Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_DT_SOURCE_SYSTEM));  
        req.setHeader('dtSourceSubsystem', Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_DT_SOURCE_SUBSYSTEM) );  

        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);

        req.setHeader('dtRequestIdentifier', guid);  
        
        return req;
    }

    public static void testCallDetail()
    {
        String invoiceId = '00000000000001187373';
        Date busDayDate = Date.newInstance(2020, 7, 30);
        String siteId = '0000001958';
        getInvoiceDetail(invoiceId, siteId, busDayDate);
    }

    public static void testCallSummary()
    {
        String sapID = '29894';
        Date startDate = Date.newInstance(2020, 4, 24);
        Date endDate = Date.newInstance(2020, 10, 24);
        getInvoiceSummary(sapID, startDate, endDate);
    }

    public static void testCallSearch()
    {
        String sapID = '29894';
        Date startDate = Date.newInstance(2020, 4, 24);
        Date endDate = Date.newInstance(2020, 10, 24);
        searchInvoiceSummary(sapID, startDate, endDate, '1029387', 'Test Vin Number', 'No Po number');
    }

    //---Get the Invoice History, Need to provide the SAP Account Id, and the start and end date range
    public static List<Fleet_Model_OrderHistorySummary> searchInvoiceSummary(String sapAccountId, Date startDate, Date endDate, String invoiceId, string vinNumberSearch, string poNumberSearch) 
    {
        List<Fleet_Model_OrderHistorySummary> returnVal = new List<Fleet_Model_OrderHistorySummary>();

        //---Search for a Set
        List<Fleet_Model_OrderHistorySummary> summList = getInvoiceSummary( sapAccountId, startDate, endDate);
        system.debug('vinNumberSearch:: '+vinNumberSearch + 'poNumberSearch::' + poNumberSearch);

        if (summList != null && summList.size() > 0)
        {
            //---Search for the Invoice Number
            for (Fleet_Model_OrderHistorySummary summRow : summList)
            {
                String rowInvoiceId = summRow.getInvoiceId();
                String rowVinNumber = summRow.getVinNumber();
                String rowPoNumber = summRow.getPoNumber();

                if(invoiceId == null){
                    invoiceId='';
                }
                if(vinNumberSearch == null){
                    vinNumberSearch='';
                }
                if(poNumberSearch == null){
                    poNumberSearch='';
                }
                if(rowInvoiceId == null){
                    rowInvoiceId='';
                }
                if(rowVinNumber == null){
                    rowVinNumber='';
                }
                if(rowPoNumber == null){
                    rowPoNumber='';
                }
            
                //when user search only invoice Id
                //filter logic: Invoice ID should exactly match with search keyword
                if (invoiceId != '' 
                    && vinNumberSearch == '' 
                    && poNumberSearch == '' 
                    && rowInvoiceId == invoiceId
                    )
                {
                    System.debug( lprefix + 'Invoice found ' + summRow);
                    returnVal.add( summRow);
                    break;
                }
                //when user search only VinNumber
                //filter logic: check if any invoice's Vin number contains the search keyword
                else If (invoiceId == '' 
                    && vinNumberSearch != '' 
                    && poNumberSearch == '' 
                    && rowVinNumber.containsIgnoreCase(vinNumberSearch))
                {
                    System.debug( lprefix + 'Invoice found ' + summRow);
                    returnVal.add( summRow);
                   
                }
                 //when user search only poNumber
                //filter logic -  check if any invoice's poNumber contains the search keyword
                    else If (invoiceId == '' 
                    && vinNumberSearch == '' 
                    && poNumberSearch != '' 
                    && rowPoNumber.containsIgnorecase(poNumberSearch)
                    )
                {
                    System.debug( lprefix + 'Invoice found ' + summRow);
                    returnVal.add( summRow);
                    
                }
                //when user search for invoice Id and VinNumber
                //filter logic - 'AND' operator for invoice Id and VIn search
                else If (invoiceId != '' 
                    && vinNumberSearch != '' 
                    && poNumberSearch == '' 
                    && rowInvoiceId == invoiceId
                    && rowVinNumber.containsIgnoreCase(vinNumberSearch)
                    )
                {
                    System.debug( lprefix + 'Invoice found ' + summRow);
                    returnVal.add( summRow);
                    
                }
                //when user search for invoice Id and poNumber
                //filter logic - 'AND' operator for invoice Id and poNumber search
                else If (invoiceId != null 
                    && vinNumberSearch == '' 
                    && poNumberSearch != '' 
                    && rowInvoiceId == invoiceId
                    && rowPoNumber.containsIgnoreCase(poNumberSearch)
                    )
                {
                    System.debug( lprefix + 'Invoice found ' + summRow);
                    returnVal.add( summRow);
                    
                }
                //when user search for poNumber and vinNumber
                //filter logic - and operator for invoice and poNumber search
                else If (invoiceId == '' 
                    && vinNumberSearch != '' 
                    && poNumberSearch != '' 
                    && rowVinNumber.containsIgnoreCase(vinNumberSearch)
                    && rowPoNumber.containsIgnoreCase(poNumberSearch)
                    )
                {
                    System.debug( lprefix + 'Invoice found ' + summRow);
                    returnVal.add( summRow);
                    
                }
                //when user search for invoice Id, poNumber and vinNumber
                //filter logic - and operator for invoice and poNumber search
                else If (invoiceId != '' 
                    && vinNumberSearch != '' 
                    && poNumberSearch != '' 
                    && rowInvoiceId == invoiceId
                    && rowVinNumber.containsIgnoreCase(vinNumberSearch)
                    && rowPoNumber.containsIgnoreCase(poNumberSearch)
                    )
                {
                    System.debug( lprefix + 'Invoice found ' + summRow);
                    returnVal.add( summRow);
                    
                }
            
                
            }
        }

        return returnVal;
    }

    //---
    //---
    //---Get the Invoice History, Need to provide the SAP Account Id, and the start and end date range
    
    public static List<Fleet_Model_OrderHistorySummary> getInvoiceSummary(String sapAccountId, Date startDate, Date endDate) 
    {
        DateTime startTimeAll = Datetime.now(); 
        System.debug( lprefix + 'Request for Invoice Summary for sapAccountId:' + sapAccountId + ' startDate: ' + startDate + ' endDate: ' + endDate);

        DateTime dtStart = DateTime.newInstance(startDate.year(), startDate.month(),startDate.day());
        DateTime dtEnd = DateTime.newInstance(endDate.year(), endDate.month(),endDate.day());
        String dateStrStart = dtStart.format('yyyy-MM-dd');
        String dateStrEnd = dtEnd.format('yyyy-MM-dd');

        String endUrl = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.SETTING_INVOICE_SUMMARY_URL);
        endUrl += sapAccountId +  '?summaryStartDate=' + dateStrStart + '&summaryEndDate=' + dateStrEnd;

        Int_Message__c intMsg = new Int_Message__c(Type__c=Int_Values.TYPE_CAR_LIST, Status__c=Int_Values.STATUS_PENDING, Url__c=endUrl);

        String body = '';
        
        if (isTest)
        {
            body = testPayload;
        }
        else 
        {
            HttpRequest req = buildCARHttpReq( endUrl);
            req.setTimeout(1000*60*2);  //---2 minutes is the max
            system.debug('** req **' +req);
            body = Fleet_IntegrationUtil.getRequestBody(req, intMsg);
            system.debug('** body ** '+body);
            intMessages.add(intMsg);

        /*    if (intMsg.Id == null)
            {
                insert intMsg;
            }
            else 
            {
                update intMsg;    
            }*/
            
            
            if (body == null || body == '')
            {
                System.debug( lprefix + 'Request for Invoice Summary FAILED');
                return null;
            } 
        }

        System.debug( lprefix + 'Timing-API: ' + Fleet_IntegrationUtil.getDuration(startTimeAll, Datetime.now()) + ' ms');
        List<Fleet_Model_OrderHistorySummary> retList;

        try 
        {
            Datetime startTimeParse = Datetime.now();
            System.debug('body :::::' + body);
            Fleet_CarSummaryModel summModel = Fleet_CarSummaryModel.parse(body);
            retList = Fleet_Model_OrderHistorySummary.build(summModel.responseSummary.orderHistorySummary);

            System.debug( lprefix + 'Timing-Parse: ' + Fleet_IntegrationUtil.getDuration(startTimeParse, Datetime.now()) + ' ms');     
        } 
        catch (Exception ex) 
        {
            Logger logInstance = Logger.getInstance();
            logInstance.log('Invoice Service', 'Fleet_InvoiceService', ex);
            System.debug( lprefix + 'Parsing Exception: ' +  ex.getMessage() + ex.getStackTraceString());     
        }

        if (retList != null && retList.size() > 0)
        {
            System.debug( lprefix + 'Converted ' + retList.size() + ' records');     
        }
        else 
        {
            System.debug( lprefix + 'No records found');     
        }

        System.debug( lprefix + 'Request for Invoice Summary SUCCESS - ' + Fleet_IntegrationUtil.getDuration(startTimeAll, Datetime.now()) + ' ms');
        return retList;  
    }
}