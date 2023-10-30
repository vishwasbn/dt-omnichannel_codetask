/******************************************************************************************************
* Project : Appointment 3.0
*******************************************************************************************************
* Business Owner : Discount Tire
* Purpose        : To get List of Service Appointments for current day and future days.
* Business Logic : Query on Service appointment for a site and return Vehicle, WorkOrder and Account Details
*
*******************************************************************************************************
* Test Class: Appt3_AppointmentListPageControllerTest
* Dependencies (Other) : 
*
*******************************************************************************************************
* Version   Date          Updated By                       Test          Target        Comments
*                                                          Coverage      Release
*
* 1.0      11/14/2022   sindhur.borusu@discounttire.com   96%           FY23-June    
*****************************************************************************************/
/**
* @description This controller Class shows how get List of Service Appointments for current day and future days.
*/
public without sharing class Appt3_AppointmentListPageController {
    public static String lPrefix = 'LOG Appt3_ListPageController';
    
    /**
    * @description Method returns Service Appointments and corresponding Vehicle ,Work Order,Account details based on Site ID and Date selected.
    * @return a string of appointment list
    * @param siteId
    * @param dateString
    */
    @AuraEnabled
    public static String getAppointmentListBySiteId(String siteId, String dateString){
        System.debug(lPrefix+'getAppointListBySiteId() ENTRY - site/date:'+siteId + ' ' + dateString);
        try {
            List<Appt_UpdateAppointmentServiceModel> returnModelList = new List<Appt_UpdateAppointmentServiceModel>();
            List<ServiceAppointment> appts = [SELECT id, Status, Activity_Type__c,Date_String__c, Start_Time_String__c, End_Time_String__c,Work_Order__r.Status, Work_Order__r.Hybris_Order_Id__c, Work_Order__r.Invoice_Number__c,
                                              Work_Order__c, Work_Order__r.AccountId, Work_Order__r.ContactId,Work_Order__r.Order_Type__c, Work_Order__r.Vehicle__r.Appt3_Generic_Vehicle_Category__c,
                                              Work_Order__r.Appointment_Comments__c,Work_Order__r.Appt3_Sales_Order_Id__c,Work_Order__r.Form_Type__c, Work_Order__r.Form_Number__c, Work_Order__r.Form_Date__c, 
                                              Work_Order__r.Order_Date__c, Work_Order__r.Vehicle__c,Work_Order__r.Source__c, Work_Order__r.Vehicle__r.POS_Customer_Vehicle_Id__c, Work_Order__r.POS_Web_Order_Id__c, 
                                              Work_Order__r.Vehicle__r.Vehicle_Manufacture_Year__c,  Work_Order__r.Vehicle__r.Vehicle_Make__c, Work_Order__r.Vehicle__r.Vehicle_Model__c, Work_Order__r.Account.POS_Customer_Id__c,
                                              Work_Order__r.Vehicle__r.Assembly_Id__c, Work_Order__r.Vehicle__r.Vehicle_Id__c, Work_Order__r.Vehicle__r.Trim_Id__c, Work_Order__r.Layaway_Number__c, Work_Order__r.Quote_Number__c,
                                              Work_Order__r.Account.FirstName, Work_Order__r.Account.LastName, Work_Order__r.Account.PersonMobilePhone,Work_Order__r.Vehicle__r.Appt3_Generic_Vehicle_SubCategory__c,
                                              Work_Order__r.Account.Appt_Customer_Type__c, Work_Order__r.CreatedDate, Account.PersonContactId, Site_Id__c  
                                              FROM ServiceAppointment 
                                              WHERE Date_String__c = :dateString AND 
                                              (Status = :Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED OR Status = :Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED) 
                                              AND Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c = :siteId WITH SECURITY_ENFORCED
                                              ORDER BY Start_Time_String__c ASC];
            System.debug(lPrefix+'Retrieved Service Appointment/Work Order records:'+appts); 
            
            //Convert Appointment data to a wrapper so we can later make an API call to populate the Articles
            for(ServiceAppointment sa: appts) {
                Appt_UpdateAppointmentServiceModel returnModel = new Appt_UpdateAppointmentServiceModel();
                
                returnModel.accountId = sa.Work_Order__r.AccountId;
                returnModel.contactId = sa.Work_Order__r.ContactId;
                returnModel.salesOrderId =sa.Work_Order__r.Appt3_Sales_Order_Id__c; 
                returnModel.source = sa.Work_Order__r.Source__c;
                returnModel.comments = sa.Work_Order__r.Appointment_Comments__c;
                returnModel.orderType = getOrderType(sa.Work_Order__r.Order_Type__c);
                returnModel.formType = sa.Work_Order__r.Form_Type__c;
                returnModel.formDate = String.valueOf(sa.Work_Order__r.Form_Date__c);
                returnModel.orderDate = getOrderDate(sa);
                returnModel.firstName = sa.Work_Order__r.Account.FirstName;
                returnModel.lastName = sa.Work_Order__r.Account.LastName;
                returnModel.workOrderId = sa.Work_Order__c;
                returnModel.mobilePhoneNumber = sa.Work_Order__r.Account.PersonMobilePhone;                          
                returnModel.appointmentDate = Date.valueOf(sa.Date_String__c);
                returnModel.appointmentId = sa.id;
                returnModel.siteId = siteId;
                returnModel.year=sa.Work_Order__r.Vehicle__r.Vehicle_Manufacture_Year__c;
                returnModel.make= sa.Work_Order__r.Vehicle__r.Vehicle_Make__c;
                returnModel.model=sa.Work_Order__r.Vehicle__r.Vehicle_Model__c;
                returnModel.genericVehicleCategory = sa.Work_Order__r.Vehicle__r.Appt3_Generic_Vehicle_Category__c;
                returnModel.genericVehicleSubCategory = sa.Work_Order__r.Vehicle__r.Appt3_Generic_Vehicle_SubCategory__c;
                returnModel.hybrisOrderId = sa.Work_Order__r.Hybris_Order_Id__c;
                returnModel.posWebOrderId = sa.Work_Order__r.POS_Web_Order_Id__c;
                returnModel.posCustomerId = sa.Work_Order__r.Account.POS_Customer_Id__c;
                returnModel.layawayNumber = sa.Work_Order__r.Layaway_Number__c;
                returnModel.quoteNumber = sa.Work_Order__r.Quote_Number__c;
                returnModel.invoiceNumber = sa.Work_Order__r.Invoice_Number__c;                
                
                if (sa.Activity_Type__c == Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_FRONT) {
                    //Front Room appointment fields
                    returnModel.consultAppointmentId = sa.id;
                    returnModel.consultStartTime = sa.Start_Time_String__c;
                } else if (sa.Activity_Type__c == Appt_ConstantValues.SERVICE_APPOINTMENT_ACTIVITY_TYPE_BACK) {
                    //Back Room appointment fields
                    returnModel.backOfficeAppointmentId = sa.id;
                    returnModel.backOfficeStartTime = sa.Start_Time_String__c;
                }
                
                returnModelList.add(returnModel);
            }
            
            System.debug(lPrefix+'getAppointListBySiteId() EXIT - returnModelList:'+returnModelList);
            if (returnModelList.size() > 0 ) {
                return JSON.serialize(new Appt_AppointmentsPageContainerController.ReturnModel('Success', 'Successfully returned SA List', JSON.serialize(returnModelList)));
            } else {
                return JSON.serialize(new Appt_AppointmentsPageContainerController.ReturnModel('Error', 'No Records Found', JSON.serialize(returnModelList)));
            }
        }
        catch (exception e) {
            Appt3_ApptsPageContainerController.logExceptions(e, Appt3_AppointmentListPageController.class.getName(), 'Appointments 3.0');
            Appt_UpdateAppointmentServiceModel serviceModel = new Appt_UpdateAppointmentServiceModel();
            serviceModel.status = Appt_ConstantValues.RESPONSE_STATUS_ERROR;
            serviceModel.message = 'System Error: ' + e.getMessage();
            return JSON.serialize(serviceModel);
        }        
    }
    
   
    /**
    * @description Method returns order history details from CAR.
    * @return a string of order data
    * @param apptModel
    */   
    @AuraEnabled
    public static String getOrderData(String apptModel) {
        try {
            System.debug(lPrefix + 'getOrderData() ENTRY - apptModel: '+apptModel);
            //Model comes in as a json serialized string, we need to deserialize into Appt_UpdateAppointmentServiceModel object
            Appt_UpdateAppointmentServiceModel model = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(apptModel, Appt_UpdateAppointmentServiceModel.class);
            Appt_InvoiceDetailModel invDetailModel = new Appt_InvoiceDetailModel();
            List<Appt_InvoiceDetailModel.LineItems> lineItemResponse = new List<Appt_InvoiceDetailModel.LineItems>();
            if (String.isNotBlank(model.salesOrderId)) {
                if (model.orderType == 'Store Order') {
                    model.orderType = 'StoreOrder';
                } else if (model.orderType == 'Service Appointment') {
                    model.orderType = 'ServiceAppointment';
                }
                //CAR call with universal sales order id
                invDetailModel = Appt_InvoiceController.getOrderHistoryDetails(model.siteId, model.salesOrderId, model.orderType);      
            }
            else if(model.hybrisOrderId != null) { 
                invDetailModel = Appt_InvoiceController.getInvoiceDetail(model.siteId, model.hybrisOrderId, Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER, model.orderDate);
            }
            else if(model.invoiceNumber != null){ 
                invDetailModel =  Appt_InvoiceController.getInvoiceDetail(model.siteId, model.invoiceNumber, Appt_ConstantValues.INVOICE_ID_TYPE_INVOICE_NUMBER, model.orderDate); 
            }
            else if(model.quoteNumber != null){
                invDetailModel =  Appt_InvoiceController.getInvoiceDetail(model.siteId, model.quoteNumber, Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER, model.orderDate); 
            }
            else if(model.layawayNumber != null){
                invDetailModel =  Appt_InvoiceController.getInvoiceDetail(model.siteId, model.layawayNumber, Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER, model.orderDate); 
            }
            
            //Set our list of line items to the line items located in invDetailModel's orderHistoryDetails
            if (invDetailModel.responseDetail != null && invDetailModel.responseDetail.orderHistoryDetails.size() > 0) {
                lineItemResponse = invDetailModel.responseDetail.orderHistoryDetails[0].lineItems;
            }
            
            //If our list of line items was created, return a JSON serialized list back to the lwc
            if(lineItemResponse != null) {
                return JSON.serialize(lineItemResponse);
            }
            // There was no list returned from the api, return a JSON serialized empty list
            else {
                return JSON.serialize(new List<Appt_InvoiceDetailModel.LineItems>());	
            }
        }
        catch(Exception e){
            Appt3_ApptsPageContainerController.logExceptions(e, Appt3_AppointmentListPageController.class.getName(), 'Appointments 3.0');            
            throw new AuraHandledException(e.getMessage());
        }        
    }
    
    
    /**
    * @description Method returns on hand inventory quantity from CAR.
    * @return a string of list of on hand lines
    * @param siteId
    * @param lineItemJson
    */
    @AuraEnabled
    public static String getOnHandForLineItems(String siteId, String lineItemJson, Boolean isUniversalSalesOrder) {
        try {
            String returnError = 'Failed to retrieve';
            Map<String, String> articleQuantityMap = new Map<String, String>();
            Map<String, Appt_InvoiceDetailModel.LineItems> articleInvoiceDetailMap = new Map<String, Appt_InvoiceDetailModel.LineItems>();
            List<Appt_InvoiceDetailModel.LineItems> lineItems = (List<Appt_InvoiceDetailModel.LineItems>) JSON.deserialize(lineItemJson, List<Appt_InvoiceDetailModel.LineItems>.class);
            if (!lineItems.isEmpty()) {
                Appt3_InventoriesModelRequest inventoryLineItems = new Appt3_InventoriesModelRequest();
                List<Appt3_InventoriesModelRequest.ArticleCollection> acList = new List<Appt3_InventoriesModelRequest.ArticleCollection>();
                List<Appt3_InventoriesModelRequest.SiteCollection> scList = new List<Appt3_InventoriesModelRequest.SiteCollection>();
                Appt3_InventoriesModelRequest.SiteCollection sc = new Appt3_InventoriesModelRequest.SiteCollection();
                Appt3_InventoriesModelRequest.SiteItem si = new Appt3_InventoriesModelRequest.SiteItem();
                //Generate site number collection
                si.id = siteId;
                sc.siteItem = si;
                scList.add(sc);
                //Generate article number collection
                for (Appt_InvoiceDetailModel.LineItems lineItem : lineItems) {
                    Appt3_InventoriesModelRequest.ArticleItem ai = new Appt3_InventoriesModelRequest.ArticleItem();	
                    Appt3_InventoriesModelRequest.ArticleCollection ac = new Appt3_InventoriesModelRequest.ArticleCollection();
                    ai.number_x = lineItem.articleNumber;
                    ac.articleItem = ai;
                    acList.add(ac);
                    articleInvoiceDetailMap.put(lineItem.articleNumber, lineItem);
                }
                inventoryLineItems.siteCollection = scList;
                inventoryLineItems.articleCollection = acList;
                Appt3_InventoriesModelResponse inventoryModel = Appt_InventoryController.getInventoryItems(inventoryLineItems); 
                //Appt 3.0 - Use the response here to generate a map of articleNumber & corresponding on hand quantity. Return the map as response.            
                if (inventoryModel.siteCollection[0].siteItem.articleCollection != null && inventoryModel.siteCollection[0].siteItem.articleCollection.size() > 0) {     
                    for (Appt3_InventoriesModelResponse.ArticleCollection article : inventoryModel.siteCollection[0].siteItem.articleCollection) {
                        if (isUniversalSalesOrder) {
                            if(articleInvoiceDetailMap.containsKey(article.articleItem.articleId)) {
                                articleInvoiceDetailMap.get(article.articleItem.articleId).onHandStockQuantity = Integer.valueOf(article.articleItem.onHand);    
                            }    
                        } else {
                            articleQuantityMap.put(article.articleItem.articleId, article.articleItem.onHand); 
                        }
                    }
                }
            }
            
            //Pass the map to prepare finally formatted articles to be sent to the UI for legacy orders
            if (!articleQuantityMap.isEmpty()) {
                lineItems = mapArticleTypeToServiceForLineItems(lineItems, articleQuantityMap);
                return JSON.serialize(lineItems);
            }
            return JSON.serialize(lineItems);
        } catch(Exception e){
            Appt3_ApptsPageContainerController.logExceptions(e, Appt3_AppointmentListPageController.class.getName(), 'Appointments 3.0');            
            throw new AuraHandledException(e.getMessage());
        }     
    }
    
    ////////////////////
    // Utility Methods
    ////////////////////
    
    /**
    * @description To transform Order Type to fromat presentable on UI
    * @return a string of order type
    * @param orderType
    */
    public static String getOrderType(String orderType) {
        switch on orderType {
            when 'ServiceAppointment' {		
                return 'Service Appointment';
            }	
            when 'StoreOrder' {		
                return 'Store Order';
            }
            when else {
                return orderType;
            }
        }       
    }
    
    /**
    * @description To transform Order Date to format presentable on UI
    * @return a string of order date
    * @param sa
    */
    public static string getOrderDate(ServiceAppointment sa) {
        if (sa != null && sa.Work_Order__r != null && sa.Work_Order__r.Order_Date__c != null) {
            return String.valueOf(sa.Work_Order__r.Order_Date__c);
        } else if (sa != null && sa.Work_Order__r != null) {
            return String.valueOf(Date.valueOf(sa.Work_Order__r.CreatedDate));
        }
        return '';
    }

    /**
    * @description Method to Map ArticleType to Service Appointment
    * @return updated lineItems
    * @param lineItems, articleMap
    */
    public static List<Appt_InvoiceDetailModel.LineItems> mapArticleTypeToServiceForLineItems(List<Appt_InvoiceDetailModel.LineItems> lineItems, Map<String, String> articleQuantityMap){
        List<Appt_InvoiceDetailModel.LineItems> newLineItems = new List<Appt_InvoiceDetailModel.LineItems>();
        String typeDescription;
        
        //Map Order Line Items
        for(Appt_InvoiceDetailModel.LineItems l : lineItems){
            
            //Use the Map, get the on hand quantity and update onHandStockQuantity
            if (articleQuantityMap.containsKey(l.articleNumber)) {
                l.onHandStockQuantity = Integer.valueOf(articleQuantityMap.get(l.articleNumber));
            } else {
  				l.onHandStockQuantity = 0;
            }
            //First Check for an article number match
            Decimal articleNum = Decimal.valueOf(l.articleNumber);
            typeDescription = Appt_OrderLineItemsUtil.getLineItemDescriptionByArticleNumnber(articleNum);            
            
            if(typeDescription != null){
                l.articleType = typeDescription;
                newLineItems.add(l);
            } else{
                //Then check for a article type match
                String articleType = l.articleType.toUpperCase();           
                typeDescription = Appt_OrderLineItemsUtil.getLineItemDescriptionByType(articleType);
                
                if(typeDescription != null){
                    l.articleType = typeDescription;
                    newLineItems.add(l);
                }else{
                    //If no match is found set as blank
                    l.articleType = '';                    
                }
            }
            System.debug('article number: ' +l.articleNumber);
            System.debug('assigned service to line item: ' +l.articleType);
        }        
        newLineItems = Appt_OrderLineItemsUtil.sortList(newLineItems);            
        System.debug('new line items: ' +lineItems);        
        return newLineItems; 
    }    
}