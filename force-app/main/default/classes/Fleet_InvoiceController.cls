/**
 Created By : John Bruning
 Creatted Dated : 10/30/2020
 Description : This Class will get parent and child account using SAP Account Id.
 Modified By : Prasad
 Modified Date :  9/19/2022
 User Story Number : Salesforce-544.

 */
public without sharing class Fleet_InvoiceController {

    public static String lprefix = 'FLEET_INV_CONT: ';
    public static String STORE_ACCOUNT_RECORD_TYPE = 'Site';

    private static Map<String, Account> storeMap = new Map<String, Account>();

    static {
        populateStoreMap();
    }

    @AuraEnabled
    public static Integer getDaysPerBlock(){
        List<Fleet_Integration_Settings__mdt> fISettings = [SELECT Value__c FROM Fleet_Integration_Settings__mdt WHERE DeveloperName='Invoice_Days_Per_Block'];
        System.debug('fiSettings: ' +fISettings);
        if(fISettings.size() < 1){
            throw new AuraHandledException('Error grabbing the Fleet Integration Settings metadata');
        }

        try {
            System.debug('fiSettings: ' +fISettings[0]);
            return Integer.valueOf(fISettings[0].Value__c);
        } catch (Exception e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('Invoice', 'Fleet_InvoiceController', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Integer getMaxInvoiceSearchDays(){
        List<Fleet_Integration_Settings__mdt> fISettings = [SELECT Value__c FROM Fleet_Integration_Settings__mdt WHERE DeveloperName='Max_Invoice_Search_Days'];
        System.debug('fiSettings: ' +fISettings);
        if(fISettings.size() < 1){
            throw new AuraHandledException('Error grabbing the Fleet Integration Settings metadata');
        }

        try {
            System.debug('fiSettings: ' +fISettings[0]);
            return Integer.valueOf(fISettings[0].Value__c);
        } catch (Exception e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('Invoice', 'Fleet_InvoiceController', e);
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String getInvoiceSummaryDataForDisplay(String recordId , Date startDate, Date endDate, String invoiceIdSearch, string vinNumberSearch, string poNumberSearch) {
        System.debug(lprefix+'getInvoiceSummaryDataForDisplay():ENTRY recordId='+recordId+': startDate='+startDate+': endDate'+endDate);
        List<Fleet_Model_InvoiceSummaryDisplayable> invoiceList;
        String returnJSON;

        List<Fleet_Model_OrderHistorySummary> invoiceDataList = getInvoiceSummary(recordId, startDate, endDate, invoiceIdSearch, vinNumberSearch, poNumberSearch);
        System.debug(lprefix+'   retrieved invoiceDataList:' + invoiceDataList);

        if (invoiceDataList != null && invoiceDataList.size() > 0) {
            Fleet_Model_InvoiceSummaryDisplayable inv;
            invoiceList = new List<Fleet_Model_InvoiceSummaryDisplayable>();
            List<String> lstInvoicesTypes = Label.Fleet_InvoiceTransactionTypes.split(',');
            Set<String> setInvTypes = New Set<String>();
            setInvTypes.addAll(lstInvoicesTypes);
            system.debug('setInvTypes:::'+setInvTypes);
            system.debug('setInvTypes:::'+invoiceDataList);
            for (Fleet_Model_OrderHistorySummary summary: invoiceDataList) {
                inv = new Fleet_Model_InvoiceSummaryDisplayable();
                system.debug('summary.getTransactionType()):::'+summary.getTransactionType());
                if(setInvTypes.contains(summary.getTransactionType())){
                    inv.setInvoiceId(summary.getInvoiceId()); 
                    Date dte = Date.valueOf(summary.getBusinessdayDate()); // convert from yyyy-MM-dd, instead of mm/dd/yyyy
                    DateTime dt = Datetime.newInstance(dte, Time.newInstance(23,59,59,0)); // create a roll back Datetime
                    String utcDt = dt.format('yyyy-MM-dd', 'UTC'); // convert back to yyyy-MM-dd
                    System.debug('getInvoiceSummaryDataForDisplay::transactionDate ' + utcDt);
                    system.debug('vinNumber**'+ summary.getVinNumber() + '** poNumber **' + summary.getPoNumber());
                    inv.setTransactionDate(utcDt);
                    inv.setStoreId(summary.getSiteId());
                    inv.setStore(getStoreDisplay(summary.getSiteId()));
                    inv.setTotalAmount(summary.getTotalAmount());
                    inv.setVehicle(summary.getVehicle());
                    inv.setCertificate(summary.getIsCertificateAllowed());
                    inv.setPoNumber(summary.getPoNumber());
                    inv.setVinNumber(summary.getVinNumber());
                }
                invoiceList.add(inv);
            }
        }

        returnJSON = JSON.serialize(invoiceList);
        System.debug(lprefix+'getInvoiceSummaryDataForDisplay():EXIT returnJSON:'+returnJSON);
        return returnJSON;
    }

    public static List<Fleet_Model_OrderHistorySummary> getInvoiceSummary(String recordId , Date startDate, Date endDate, String invoiceIdSearch, string vinNumberSearch, string poNumberSearch) {
        System.debug(lprefix+'getInvoiceSummary():ENTRY recordId='+recordId+': startDate='+startDate+': endDate'+endDate);

        //make sure params are populated, as params are required for invoice summary API
        if (!String.isBlank(recordId) && startDate != null && endDate != null) {

            List<Fleet_Model_OrderHistorySummary> summeries = new List<Fleet_Model_OrderHistorySummary>();

            //query Account by recordId to get ECC_Account_number for invoice API call param
            Account acnt = [SELECT Id, ECC_Account_Number__c, 
                           (SELECT Id, ECC_Account_Number__c FROM ChildAccounts) 
                            FROM Account 
                            WHERE Id = :recordId];
            System.debug(lprefix+'   retrieved Account:' + acnt);

            if (acnt != null) {
                
                List<Fleet_Model_OrderHistorySummary> tempList;
                String sapAccountId;
                    
                if(acnt.ChildAccounts.size() > 0)
                {
                    for(Account a : acnt.ChildAccounts)
                    {
                        sapAccountId = a.ECC_Account_Number__c;
                        
                        if (!String.isBlank(sapAccountId)) {
        
                            
                            //call service class to make API call
                            if ((String.isNotBlank(invoiceIdSearch)) || (String.isNotBlank(vinNumberSearch)) || (String.isNotBlank(poNumberSearch)))
                            {
                                tempList =  Fleet_InvoiceService.searchInvoiceSummary(sapAccountId, startDate, endDate, invoiceIdSearch, vinNumberSearch, poNumberSearch );                                    
                            } else {
                                tempList =  Fleet_InvoiceService.getInvoiceSummary(sapAccountId, startDate, endDate);   
                            }
                                    
                            if(tempList != null && tempList.size() > 0) summeries.addAll(tempList);

                        }
                    }
                    
                }

                	sapAccountId = acnt.ECC_Account_Number__c;
                    if (!String.isBlank(sapAccountId)) {
    
                        //call service class to make API call
                        if ((String.isNotBlank(invoiceIdSearch)) || (String.isNotBlank(vinNumberSearch)) || (String.isNotBlank(poNumberSearch)) )
                        {
                            system.debug('searchInvoiceSummary start');
                            tempList =  Fleet_InvoiceService.searchInvoiceSummary(sapAccountId, startDate, endDate, invoiceIdSearch, vinNumberSearch, poNumberSearch);
                        } else {
                            system.debug('getInvoiceSummary start');
                            tempList =  Fleet_InvoiceService.getInvoiceSummary(sapAccountId, startDate, endDate);
                        }
                        
                        if(tempList != null && tempList.size() > 0) summeries.addAll(tempList);
    
                        System.debug(lprefix+'getInvoiceSummary():EXIT return inv summeries:' + summeries);
                        //return summeries;
                        
                    } else {
                        System.debug(lprefix+'getInvoiceSummary():EXIT Account does not have ECC_Account_Number__c populated, returning null');
                        //return null;
                    }
                
            
            	    if(Fleet_InvoiceService.intMessages.size()>0)
                    	upsert(Fleet_InvoiceService.intMessages);
                    
                    if(summeries.size() > 0)
                        return summeries;
                    else
                        return null;
				  
            
            } else {
                System.debug(lprefix+'getInvoiceSummary():EXIT could NOT retrieve account with Id=' + recordId + ', returning null');
                return null;
            }
        } else {
            System.debug(lprefix+'getInvoiceSummary():EXIT recordId blank or startDate null or endDate null, returning null');
            return null;
        }
    }

    private static String getStoreDisplay(String sapStoreId) {
        System.debug(lprefix+'getStoreDisplay():ENTRY sapStoreId=' + sapStoreId);
        Account site = storeMap.get(sapStoreId);
        String siteIDNoPad='';
        
        if(String.isNotBlank(sapStoreId))
        {
            if(sapStoreId == 'DTD')
                siteIDNoPad = sapStoreId;
            else
                siteIDNoPad = String.valueOf(Integer.valueOf(sapStoreId));
        }
        
        if(site == null){
            site = storeMap.get(siteIDNoPad);
        }

        if (site != null) {

            //DT asked that Store_ID__c be displayed to user instead of Name, in Store column
            String store = site.Store_ID__c;
            System.debug(lprefix+'getStoreDisplay():EXIT store=' + store);
            return store;
        } else {
            System.debug(lprefix+'populateStoreMap():WARNING - unable to retrieve store with SAP_Store_ID__c=' + sapStoreId);
        }

        //No site data was found for the SAP Store ID provided in the CAR API JSON response, return null
        return null;
    }

    private static void populateStoreMap() {
        System.debug(lprefix+'populateStoreMap():ENTRY');

        List<Account> sites = [SELECT Id, SAP_Store_ID__c, Store_ID__c, Name, ShippingAddress FROM Account WHERE RecordType.Name=:STORE_ACCOUNT_RECORD_TYPE];
        if(sites != null && sites.size() > 0) {
            System.debug(lprefix+'   number of Site accounts retreived:' + sites.size());
            for (Account site: sites) {
                storeMap.put(site.SAP_Store_ID__c, site);
            }
            System.debug(lprefix+'populateStoreMap():EXIT - storeMap populated');
        } else {
            System.debug(lprefix+'populateStoreMap():WARNING - unable to retrieve store Site Accounts');
        }
    }

    public class ResultWrapper {
        public string recordId;
        public string message;
        public string status; // 'success' or 'error'
    }

    @AuraEnabled
    public static String getInvoiceDetail(String siteId, String invoiceId, String invoiceBusinessDate)
    {
        System.debug(lprefix+'getInvoiceDetail():ENTRY siteId=' + siteId + ' invoiceId='+invoiceId+' : invoiceBusinessDate='+invoiceBusinessDate);
        //String siteId = '0000001958';
        String returnJSON;
        Date invoiceDate;
        String invSiteId = siteId;//.leftPad(10,'0'); // needs 10 digits
        String invId = invoiceId;//.leftPad(20, '0'); // needs 20 digits
        
        if(invId.contains(',')) invId = invId.split(',')[0];

        // convert the date string to a Date
        if (invoiceBusinessDate.contains('/')){
            invoiceDate = Date.parse(invoiceBusinessDate);
        } else {
            // contains '-'
            invoiceDate = Date.valueOf(invoiceBusinessDate);
        }

        DateTime dt = Datetime.newInstanceGmt(invoiceDate, Time.newInstance(0,0,0,0)); // create the 'GMT' time

        System.debug(lprefix+'getInvoiceDetail():Converted siteId=' + invSiteId + ' invoiceId='+invId+' : invoiceBusinessDate='+dt.date());

        Fleet_Model_OrderHistoryDetails invoiceDetail = Fleet_InvoiceService.getInvoiceDetail(invId, invSiteId, dt.date()); // use the date() to roll it back to local time
        System.debug(lprefix+'   retrieved invoiceDetail:' + invoiceDetail);

        Local_InvoiceDetails_Wrapper idWrapper = new Local_InvoiceDetails_Wrapper(invoiceDetail);

        returnJSON = JSON.serialize(idWrapper);
        System.debug(lprefix+'getInvoiceDetail():EXIT returnJSON:'+returnJSON);
        return returnJSON;

    } // End of getInvoiceDetail()

    @AuraEnabled
    public static String getMockInvoiceDetail()
    {
        String returnJSON;
        Local_InvoiceDetails_Wrapper resultData = new Local_InvoiceDetails_Wrapper();

        returnJSON = JSON.serialize(resultData);
        System.debug(lprefix+'getInvoiceDetail():EXIT returnJSON:'+returnJSON);
        return returnJSON;
    }

    @AuraEnabled
    public static String getSiteData(String siteId)
    {
        System.debug('Start getSiteData');
        siteId = siteId.leftPad(10,'0'); // needs 10 digits
        System.debug('SiteId: ' + siteId);

        String siteIDNoPad = String.valueOf(Integer.valueOf(siteId));
        List<Account> siteList = [SELECT Id, SAP_Store_ID__c, Store_ID__c, ShippingStreet, ShippingCity, ShippingState,AT_Customer__c,DT_Customer__c, ShippingPostalCode, ShippingStateCode, Phone, Store_DBA_Name__c FROM Account WHERE SAP_Store_ID__c =: siteId OR  SAP_STORE_ID__c = :siteIDNoPad LIMIT 1];

        //List<Account> siteList = [SELECT Id, SAP_Store_ID__c, Store_ID__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingStateCode, Phone, Store_DBA_Name__c FROM Account WHERE SAP_Store_ID__c =: siteId];
        Account returnSite = null;

        if (siteList.size() > 0){
            System.debug('getSiteData:: data available');
            returnSite = siteList[0];
        }
        return JSON.serialize(returnSite);
    }

    public class Local_InvoiceDetails_Wrapper 
    {
        public String siteId  {get; set;}
        public Decimal totalAmount  {get; set;}
        public String businessdayDate  {get; set;}
        public String invoiceNumber  {get; set;}
        public String addressLine1  {get; set;}
        public String addressLine2  {get; set;}
        public String city  {get; set;}
        public String state  {get; set;}
        public String zipCode  {get; set;}
        public String county  {get; set;}
        public String workPhone  {get; set;}
        public String arCustomerAccountNumber  {get; set;}
        public String arCustomerAccountName  {get; set;}
        public String taxId  {get; set;}
        public Decimal taxAmount  {get; set;}
        public Decimal discountAmount  {get; set;}
        public String employeeName  {get; set;}
        public String timeStamp  {get; set;}

        public String arDriverName;
        public String arCompanyName;
        public String arStreetAdd;
        public String arVehicleYear;
        public String arVehicleMake;
        public String arVehicleModel;
        public String arLicensePlateNumber;
        public String arLicensePlateState;
        public String arVin;
        public String arMileage;
        public String arFleetCardNumber;
        public String arStockNumber;
        public String arUnitNumber;
        public String arFleetNumber;
        public String arFleetCardExpDt;
        public String arId_JobNumber;
        public String arDriverLicense;
        public String arCity;
        public String arState;
        public String arZip;        

        public List<Fleet_Model_TenderDetails> tenderDetails  {get; set;}
        public List<Fleet_Model_TransactionDetails> transactionDetails  {get; set;}
        public List<Fleet_Model_LineItems> lineItems  {get; set;}
        // public Fleet_Model_ARFields arFields  {get; set;}
    
        public Local_InvoiceDetails_Wrapper(Fleet_Model_OrderHistoryDetails iDetails)
        {
            if (iDetails == null) return;
            
            siteId = iDetails.GetSiteId();
            System.debug('SiteId: ' + siteId);
            totalAmount = iDetails.GetTotalAmount();
            businessdayDate = iDetails.GetBusinessdayDate();
            invoiceNumber = iDetails.GetInvoiceNumber();
            addressLine1 = iDetails.GetAddressLine1();
            addressLine2 = iDetails.GetAddressLine2();
            city = iDetails.GetCity();
            state = iDetails.GetState();
            zipCode = iDetails.GetZipCode();
            county = iDetails.GetCounty();
            workPhone = iDetails.GetWorkPhone();
            arCustomerAccountNumber = iDetails.GetArCustomerAccountNumber();
            arCustomerAccountName = iDetails.GetArCustomerAccountName();
            taxId = iDetails.GetTaxId();
            taxAmount = iDetails.GetTaxAmount();
            discountAmount = iDetails.GetDiscountAmount();
            employeeName = iDetails.GetEmployeeName();
            timeStamp = iDetails.GetTimeStamp();

            arDriverName = iDetails.getArFields().getDriverName();
            arCompanyName = iDetails.getArFields().getCompanyName();
            arStreetAdd = iDetails.getArFields().getStreetAdd();
            arVehicleYear = iDetails.getArFields().getArVehicleYear();
            arVehicleMake = iDetails.getArFields().getArVehicleMake();
            arVehicleModel = iDetails.getArFields().getArVehicleModel();
            arLicensePlateNumber = iDetails.getArFields().getArLicensePlateNumber();
            arLicensePlateState = iDetails.getArFields().getArLicensePlateState();
            arVin = iDetails.getArFields().getVin();
            arMileage = iDetails.getArFields().getArMileage();
            arFleetCardNumber = iDetails.getArFields().getFleetCardNumber();
            arStockNumber = iDetails.getArFields().getStockNumber();
            arUnitNumber = iDetails.getArFields().getUnitNumber();
            arFleetNumber = iDetails.getArFields().getFleetNumber();
            arFleetCardExpDt = iDetails.getArFields().getFleetCardExpDt();
            arId_JobNumber = iDetails.getArFields().getId_JobNumber();
            arDriverLicense = iDetails.getArFields().getArDriverLicense();
            arCity = iDetails.getArFields().getArCity();
            arState = iDetails.getArFields().getArState();
            arZip = iDetails.getArFields().getArZip();                                
            
            tenderDetails = iDetails.getTenderDetails();
            transactionDetails = iDetails.getTransactionDetails();
            lineItems = iDetails.getLineItems();
            // arFields = iDetails.getArFields();
        }

        // mock data
        public Local_InvoiceDetails_Wrapper()
        {
            siteId = '0000001942';
            totalAmount = 299.28;
            businessdayDate = '2020-08-26';
            invoiceNumber = '00000000000001233801';
            addressLine1 = '9315 OLIVE BLVD';
            addressLine2 = '';
            city = 'SAINT LOUIS';
            state = 'MO';
            zipCode = '63132';
            county = '';
            workPhone = '8003258838';
            arCustomerAccountNumber = '29894';
            arCustomerAccountName = 'ENTERPRISE FLEET MANAGEMENT';
            taxId = 'TAX_ID_NUMBER';
            taxAmount = 21.21;
            discountAmount = 0.00;
            employeeName = 'RICARDO H MARTINEZ';
            timeStamp = '2020-08-26 17:37';

            // tenderDetails
            tenderDetails = new List<Fleet_Model_TenderDetails>();
            Fleet_Model_TenderDetails tdObj = new Fleet_Model_TenderDetails();
            tdObj.setTenderTypeCode('ZARC');
            tdObj.setTenderAmount(299.28);
            tenderDetails.add(tdObj);

            // transactionDetails
            transactionDetails = new List<Fleet_Model_TransactionDetails>();
            Fleet_Model_TransactionDetails trnsObj = new Fleet_Model_TransactionDetails();
            trnsObj.setName('TRANSNUMBER');
            trnsObj.setValue('00000000000001233801');
            transactionDetails.add(trnsObj);

            // lineItems
            lineItems = new List<Fleet_Model_LineItems>();
            Fleet_Model_LineItems liObj = new Fleet_Model_LineItems();
            liObj.setArticleNumber('000000000000037548');
            liObj.setRetailQuantity(1.000);
            liObj.setStoreSize('LT275  /70   R18   125R E1 RWL');
            liObj.setStoreDescription('BFG  ALL TERRAIN T/A KO2 DT');
            liObj.setActualUnitPrice(253.00);
            liObj.setFet(1.32);
            liObj.setTotalSalesAmount(254.32);
            liObj.setVehicleMake('FORD');
            liObj.setVehicleModel('F-250');
            liObj.setVehicleYear('2018');
            liObj.setMileage('052452');
            liObj.setPoNumber('*23139605A8042');
            liObj.setDiscounts(new List<Fleet_Model_Discounts>());
            lineItems.add(liObj);

            Fleet_Model_LineItems liObj2 = new Fleet_Model_LineItems();
            liObj2.setArticleNumber('000000000000080017');
            liObj2.setRetailQuantity(0.000);
            liObj2.setStoreSize('CERTIFICATES FOR');
            liObj2.setStoreDescription('REFUND,  REPLACEMENT');
            liObj2.setActualUnitPrice(43.25);
            liObj2.setFet(0.00);
            liObj2.setTotalSalesAmount(0.00);
            liObj2.setVehicleMake('FORD');
            liObj2.setVehicleModel('F-250');
            liObj2.setVehicleYear('2018');
            liObj2.setMileage('052452');
            liObj2.setPoNumber('');
            liObj2.setDiscounts(new List<Fleet_Model_Discounts>());
            lineItems.add(liObj2);
            
            Fleet_Model_LineItems liObj3 = new Fleet_Model_LineItems();
            liObj3.setArticleNumber('000000000000080224');
            liObj3.setRetailQuantity(1.000);
            liObj3.setStoreSize('WASTE TIRE');
            liObj3.setStoreDescription('DISPOSAL FEE');
            liObj3.setActualUnitPrice(2.75);
            liObj3.setFet(0.00);
            liObj3.setTotalSalesAmount(2.75);
            liObj3.setVehicleMake('FORD');
            liObj3.setVehicleModel('F-250');
            liObj3.setVehicleYear('2018');
            liObj3.setMileage('052452');
            liObj3.setPoNumber('');
            liObj3.setDiscounts(new List<Fleet_Model_Discounts>());
            lineItems.add(liObj3);
            
            Fleet_Model_LineItems liObj4 = new Fleet_Model_LineItems();
            liObj4.setArticleNumber('000000000000080219');
            liObj4.setRetailQuantity(1.000);
            liObj4.setStoreSize('INSTALLATION &');
            liObj4.setStoreDescription('LIFE OF TIRE MAINTENANCE');
            liObj4.setActualUnitPrice(21.00);
            liObj4.setFet(0.00);
            liObj4.setTotalSalesAmount(21.00);
            liObj4.setVehicleMake('FORD');
            liObj4.setVehicleModel('F-250');
            liObj4.setVehicleYear('2018');
            liObj4.setMileage('052452');
            liObj4.setPoNumber('');
            liObj4.setDiscounts(new List<Fleet_Model_Discounts>());
            lineItems.add(liObj4);

            // arFields
            arDriverName = 'CASTILLO';
            arCompanyName = 'SM ENERGY';
            arStreetAdd = 'LAREDO';
            arVehicleYear = '2019';
            arVehicleMake = 'FORD';
            arVehicleModel = 'F-350';
            arLicensePlateNumber = '123-ABC';
            arLicensePlateState = 'TX';
            arVin = '1FD8W3B60KED85002';
            arMileage = '52452';
            arFleetCardNumber = '1';
            arStockNumber = '';
            arUnitNumber = '1';
            arFleetNumber = '';
            arFleetCardExpDt = '0000-00-00';
            arId_JobNumber = '';
            arDriverLicense = '';
            arCity = 'LAREDO';
            arState = 'TEXAS';
            arZip = '78041';
        }
    } // End of Local_InvoiceDetails_Wrapper class

}