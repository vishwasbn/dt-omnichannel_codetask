public class Appt_OrderLineItemsUtil {

    public static String lprefix = 'Appt_OrderLineItemsUtil: ';   
    public static Map<Decimal, String> articleNumberLookUp = new Map<Decimal, String>();
    public static Map<String, String> articleTypeLookUp = new Map<String, String>();
    public static final String ARTICLE_NUMBER = 'Article Number';
    public static final String ARTICLE_TYPE = 'Article Type';
    public static Map<String, Integer> sortPriority = new Map<String, Integer>();

    // get the display value based on an article's type
    public static String getLineItemDescriptionByType(String articleType){        
        // makes sure the configs are setup
        getOrderLineItemsConfig();        
        System.debug(lprefix + 'articleTypeLookUp:' + articleTypeLookUp);     
        return articleTypeLookUp.get(articleType);
    }

    // get the display value based on an article's number 
    public static String getLineItemDescriptionByArticleNumnber(Decimal articleNumber){        
        // makes sure the configs are setup
        getOrderLineItemsConfig();
        System.debug(lprefix + 'articleNumberLookUp:' + articleNumberLookUp);
        return articleNumberLookUp.get(articleNumber);            
    }

    // update the internal maps for line items details 
    public static void getOrderLineItemsConfig(){
        // only update if they haven't already been updated
        if(articleNumberLookUp.size() == 0 && articleTypeLookUp.size() == 0){
            try{
                list<Appt_Order_Line_Items__mdt> lineItemConfigs = [SELECT Display_Order__c, Article_Number__c, Article_Type__c, Config_Type__c, Display_Value__c FROM Appt_Order_Line_Items__mdt];                
                
                System.debug(lprefix + 'lineItemConfigs:' + lineItemConfigs);
                for(Appt_Order_Line_Items__mdt item: lineItemConfigs){
                    
                    sortPriority.put(item.Display_Value__c, Integer.valueOf(item.Display_Order__c));

                    if(item.Config_Type__c == ARTICLE_TYPE){
                        articleTypeLookUp.put(item.Article_Type__c, item.Display_Value__c);
                    }
                    if(item.Config_Type__c == ARTICLE_NUMBER){
                        articleNumberLookUp.put(item.Article_Number__c, item.Display_Value__c);
                    }
                }

                System.debug('Sort Priority: ' + sortPriority);
            }catch(Exception e){
                System.debug(lprefix + ' getOrderLineItemsConfig:' + e.getMessage());
                // SO-41 START:  Added logInstance 
                Logger logInstance = Logger.getInstance();
                String errDetails = 'Cause: '+ e.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ e.getMessage();
                logInstance.Log(LPREFIX, Appt_OrderLineItemsUtil.class.getName(), errDetails); // SO-41 END
            }            
        }
    }

    public static List<Appt_InvoiceDetailModel.LineItems> sortList(List<Appt_InvoiceDetailModel.LineItems> lineItems){
        List<Appt_InvoiceDetailModel.LineItems> sortedList = new List<Appt_InvoiceDetailModel.LineItems>();
        List<LineItemsSortWrapper> sortList = new List<LineItemsSortWrapper>(); 

        System.debug('START Sort');
        System.debug(lineItems);

        for(Appt_InvoiceDetailModel.LineItems item : lineItems){
            System.debug('Process Sort 1');
            LineItemsSortWrapper newWrapper = new LineItemsSortWrapper(item, sortPriority.get(item.articleType));
            System.debug('Process Sort 4');
            sortList.add(newWrapper);
        }

        sortList.sort();

        for(LineItemsSortWrapper ln: sortList){
            Appt_InvoiceDetailModel.LineItems item = new Appt_InvoiceDetailModel.LineItems();
            item.articleType = ln.item.articleType;
            item.articleNumber = ln.item.articleNumber;
            item.retailQuantity = ln.item.retailQuantity;
            item.onHandStockQuantity = ln.item.onHandStockQuantity;
            item.storeSize = ln.item.storeSize;
            item.storeDescription = ln.item.storeDescription;
            item.actualUnit_price = ln.item.actualUnit_price;
            item.fet = ln.item.fet;
            item.totalSalesAmount = ln.item.totalSalesAmount;
            item.vehicleMake = ln.item.vehicleMake;
            item.vehicleModel = ln.item.vehicleModel;
            item.vehicleYear = ln.item.vehicleYear;
            item.mileage = ln.item.mileage;
            item.poNumber = ln.item.poNumber;
            item.discounts = ln.item.discounts;   

            sortedList.add(item);
        }

        return sortedList;
    }

    public class LineItemsSortWrapper implements Comparable {
 
        public LineItemsSort item = new LineItemsSort();
        
        // Constructor
        public LineItemsSortWrapper(Appt_InvoiceDetailModel.LineItems ln, Integer sortPriority) {            
            System.debug(sortPriority);
            
            if(sortPriority != null){
                item.sortOrder = sortPriority;
            } else {
                item.sortOrder = 999;
            }
            item.articleType = ln.articleType;
            item.articleNumber = ln.articleNumber;
            item.retailQuantity = ln.retailQuantity;
            item.onHandStockQuantity = ln.onHandStockQuantity;
            item.storeSize = ln.storeSize;
            item.storeDescription = ln.storeDescription;
            item.actualUnit_price = ln.actualUnit_price;
            item.fet = ln.fet;
            item.totalSalesAmount = ln.totalSalesAmount;
            item.vehicleMake = ln.vehicleMake;
            item.vehicleModel = ln.vehicleModel;
            item.vehicleYear = ln.vehicleYear;
            item.mileage = ln.mileage;
            item.poNumber = ln.poNumber;
            item.discounts = ln.discounts;   
        }
        
        // Compare opportunities based on the opportunity amount.
        public Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            LineItemsSortWrapper compareToItem = (LineItemsSortWrapper)compareTo;
            
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (item.sortOrder > compareToItem.item.sortOrder) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (item.sortOrder < compareToItem.item.sortOrder) {
                // Set return value to a negative value.
                returnValue = -1;
            } else if ((item.sortOrder == null) && (compareToItem.item.sortOrder != null)){
                // nulls-first implementation
                returnValue = -1;
            } else if ((item.sortOrder != null) && (compareToItem.item.sortOrder == null)){
                // nulls-first implementation
                returnValue = 1;
            }        
            return returnValue;       
        }
    }

    public class LineItemsSort{
        public Integer sortOrder;
        public string articleType;
        public String articleNumber;
        public Double retailQuantity;
        public Integer onHandStockQuantity;
        public String storeSize;
        public String storeDescription;
        public Double actualUnit_price;
        public Double fet;
        public Double totalSalesAmount;
        public String vehicleMake;
        public String vehicleModel;
        public String vehicleYear;
        public String mileage;
        public String poNumber;
        public List<Appt_InvoiceDetailModel.Discounts> discounts;    
    }
}