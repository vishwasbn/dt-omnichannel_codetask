public without sharing class Appt_AppointmentListPageController {
    public static String lprefix = 'LOG Appt_ListPageController';
    public static final String SECOND_HEADER_LABEL = 'childrowheader';
    
    
    @AuraEnabled
    public static String getAppointmentListBySiteId(String siteId, String dateString){
        System.debug(lprefix+'getAppointListBySiteId() ENTRY - site/date:'+siteId + ' ' + dateString);

        List<Appt_UpdateAppointmentServiceModel> returnModelList = new List<Appt_UpdateAppointmentServiceModel>();

        List<ServiceAppointment> appts = [SELECT id, Status, Activity_Type__c, SchedStartTime, SchedEndTime, Start_Time_String__c, End_Time_String__c, Date_String__c, 
            Work_Order__r.Status, Duration, Work_Order__c, WorkType.DurationInMinutes, Work_Order__r.AccountId, Work_Order__r.ContactId, Work_Order__r.Source__c,  
            Work_Order__r.Appointment_Comments__c, Work_Order__r.Order_Type__c, Work_Order__r.Form_Type__c, Work_Order__r.Form_Number__c, Work_Order__r.Form_Date__c, 
            Work_Order__r.Hybris_Order_Id__c, Work_Order__r.POS_Web_Order_Id__c, Work_Order__r.Layaway_Number__c, Work_Order__r.Quote_Number__c, Work_Order__r.Invoice_Number__c, 
            Work_Order__r.Order_Date__c, Work_Order__r.SMS_Phone__c, Work_Order__r.Vehicle__c, Work_Order__r.Vehicle__r.POS_Customer_Vehicle_Id__c, Work_Order__r.Vehicle__r.Hybris_Customer_Vehicle_Id__c, 
            Work_Order__r.Vehicle__r.Vehicle_Manufacture_Year__c,  Work_Order__r.Vehicle__r.Vehicle_Make__c, Work_Order__r.Vehicle__r.Vehicle_Model__c, 
            Work_Order__r.Vehicle__r.Assembly_Id__c, Work_Order__r.Vehicle__r.Vehicle_Id__c, Work_Order__r.Vehicle__r.Trim_Id__c, Work_Order__r.Account.POS_Customer_Id__c, 
            Work_Order__r.Account.Hybris_Customer_Id__c, Work_Order__r.Account.GUID__c, Work_Order__r.Account.FirstName, Work_Order__r.Account.LastName, Work_Order__r.Account.Appt_SMS_Opt_In__pc,
            Work_Order__r.Account.PersonEmail, Work_Order__r.Account.Email__c, Work_Order__r.Account.Phone, Work_Order__r.Account.PersonHomePhone, Work_Order__r.Cancel_Reason__c,
            Work_Order__r.Account.PersonMobilePhone, Work_Order__r.Account.ShippingStreet, Work_Order__r.Account.ShippingCity, Work_Order__r.Account.ShippingState, 
            Work_Order__r.Account.ShippingPostalCode, Work_Order__r.Account.ShippingCountry, Work_Order__r.Account.Appt_Customer_Type__c, 
            Work_Order__r.CreatedDate, Account.PersonContactId, Site_Id__c  
            FROM ServiceAppointment 
            WHERE Date_String__c = :dateString and (Status = :Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CONFIRMED OR Status = :Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED) and Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c = :siteId
            ORDER BY Date_String__c ASC, Start_Time_String__c ASC];
        System.debug(lprefix+'       Retrieved Service Appointment/Work Order records:'+appts);


        //Convert Appointment data to a wrapper so we can later make an API call to populate the Articles
        for(ServiceAppointment sa: appts) {
            Appt_UpdateAppointmentServiceModel returnModel = new Appt_UpdateAppointmentServiceModel();
            
            returnModel.appointmentStatus = sa.Status;
            returnModel.accountId = sa.Work_Order__r.AccountId;
            returnModel.contactId = sa.Work_Order__r.ContactId;
            returnModel.source = sa.Work_Order__r.Source__c;
            returnModel.comments = sa.Work_Order__r.Appointment_Comments__c;
            returnModel.orderType = sa.Work_Order__r.Order_Type__c;
            returnModel.formType = sa.Work_Order__r.Form_Type__c;
            returnModel.formNumber = getMappedFormNumber(sa.Work_Order__r.Order_Type__c, sa.Work_Order__r.POS_Web_Order_Id__c, sa.Work_Order__r.Layaway_Number__c, sa.Work_Order__r.Invoice_Number__c, sa.Work_Order__r.Quote_Number__c);
            returnModel.formDate = String.valueOf(sa.Work_Order__r.Form_Date__c);
            returnModel.hybrisOrderId = sa.Work_Order__r.Hybris_Order_Id__c;
            returnModel.posWebOrderId = sa.Work_Order__r.POS_Web_Order_Id__c;
            returnModel.posCustomerId = sa.Work_Order__r.Account.POS_Customer_Id__c;
            returnModel.layawayNumber = sa.Work_Order__r.Layaway_Number__c;
            returnModel.quoteNumber = sa.Work_Order__r.Quote_Number__c;
            returnModel.invoiceNumber = sa.Work_Order__r.Invoice_Number__c;
            returnModel.orderDate = getOrderDate(sa);//String.valueOf(sa.Work_Order__r.Order_Date__c);
            returnModel.firstName = sa.Work_Order__r.Account.FirstName;
            returnModel.lastName = sa.Work_Order__r.Account.LastName;
            returnModel.workOrderId = sa.Work_Order__c;
            returnModel.mobilePhoneNumber = sa.Work_Order__r.Account.PersonMobilePhone;
            returnModel.homePhoneNumber = sa.Work_Order__r.Account.PersonHomePhone;
            returnModel.smsPhoneNumber = sa.Work_Order__r.SMS_Phone__c;
            returnModel.workPhoneNumber = sa.Work_Order__r.Account.Phone;
            returnModel.appointmentDate = Date.valueOf(sa.Date_String__c);
            returnModel.appointmentId = sa.id;
            returnModel.siteId = siteId;

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


        System.debug(lprefix+'getAppointListBySiteId() EXIT - returnModelList:'+returnModelList);
        if (returnModelList.size() > 0 ) {
            return JSON.serialize(new Appt_AppointmentsPageContainerController.ReturnModel('Success', 'Successfully Created Test SA', JSON.serialize(returnModelList)));
        } else {
            return JSON.serialize(new Appt_AppointmentsPageContainerController.ReturnModel('Error', 'No Records Found', JSON.serialize(returnModelList)));
        }
    }

    // returns the correct id number for the POS
    public static String getMappedFormNumber(String orderType, String posWebOrderId, String layawayNumber, String invoiceNumber, String quoteNumber){
        String formNum = '';

        switch on orderType {
            when 'ROPIS' {		
                formNum = posWebOrderId;
            }	
            when 'BOPIS' {		
                formNum = posWebOrderId;
            }	
            when 'ServiceAppointment' {		
                formNum = posWebOrderId;
            }	
            when 'Layaway' {		
                formNum = layawayNumber;
            }
            when 'Invoice' {		
                formNum = invoiceNumber;
            }
            when 'Quote' {		
                formNum = quoteNumber;
            }
            when else {		  // default block, optional
                formNum = '';
            }
        }

        if (formNum == '0'){
            formNum = '';
        }

        return formNum;
    }


    @AuraEnabled
    public static String getOrderData(String apptModel) {
        // Model comes in as a json serialized string, we need to deserialize into Appt_UpdateAppointmentServiceModel object
        Appt_UpdateAppointmentServiceModel model = (Appt_UpdateAppointmentServiceModel) JSON.deserialize(apptModel, Appt_UpdateAppointmentServiceModel.class);


        Appt_InvoiceDetailModel invDetailModel = new Appt_InvoiceDetailModel();
        // 1 - Get invoice details (getInvoiceDetails())
        if(model.hybrisOrderId != null && Appt_ConstantValues.WORKORDER_ORDER_TYPES_FOR_HYBRISNUMBER.contains( model.orderType)) { 
            invDetailModel = Appt_InvoiceController.getInvoiceDetail(model.siteId, model.hybrisOrderId, Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER, model.orderDate) ;
        }
        else if(model.invoiceNumber != null && model.orderType.equals(Appt_ConstantValues.WORKORDER_ORDERTYPE_INV )){ 
           invDetailModel =  Appt_InvoiceController.getInvoiceDetail(model.siteId, model.invoiceNumber, Appt_ConstantValues.INVOICE_ID_TYPE_INVOICE_NUMBER, model.orderDate); 
        }
        else if(model.quoteNumber != null && model.orderType.equals(Appt_ConstantValues.WORKORDER_ORDERTYPE_QUO)){
            invDetailModel =  Appt_InvoiceController.getInvoiceDetail(model.siteId, model.quoteNumber, Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER, model.orderDate); 
        }
        else if(model.layawayNumber != null && model.orderType.equals(Appt_ConstantValues.WORKORDER_ORDERTYPE_LAY )){
            invDetailModel =  Appt_InvoiceController.getInvoiceDetail(model.siteId, model.layawayNumber, Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER, model.orderDate); 
        }

        //if (invDetailModel != null && invDetailModel.status == Appt_ConstantValues.RESPONSE_STATUS_ERROR) {
        //    return JSON.serialize(new List<Appt_InvoiceDetailModel.LineItems>());
        //}

        // Iterate through line items and set the model's articles
        List<Appt_InvoiceDetailModel.LineItems> l = null;
        if (invDetailModel.responseDetail != null && invDetailModel.responseDetail.orderHistoryDetails.size() > 0) {
            // Set our list of line items to the line items located in invDetailModel's orderHistoryDetails
            l = invDetailModel.responseDetail.orderHistoryDetails[0].lineItems;
        }

        // If our list of line items was created, return a JSON serialized list back to the lwc
        if(l != null){
            l = mapArticleTypeToServiceForLineItems(l);
            return JSON.serialize(l);
        }

        // There was no list returned from the api, return a JSON serialized empty list
        else return JSON.serialize(new List<Appt_InvoiceDetailModel.LineItems>());
    }


    @AuraEnabled
    public static String getOnHandForLineItems(String siteId, String lineItemJson){
        String returnError = 'Failed to retrieve';
        try{

            Appt_InvoiceDetailModel.LineItems lineItem = (Appt_InvoiceDetailModel.LineItems) JSON.deserialize(lineItemJson, Appt_InvoiceDetailModel.LineItems.class);

            Appt_InventoryModel inventoryModel = Appt_InventoryController.getInventory(siteId, lineItem.articleNumber);

            System.debug(inventoryModel);

            if(!inventoryModel.status.equals('Error')){
                return String.valueOf(Integer.valueOf(inventoryModel.site[0].article[0].onHandStockQuantity));
            }
            else {
                return returnError;
            }

        }catch(Exception e){
            System.debug('Get On Hand Items Exception: ' + e.getMessage());
            return returnError;
        }

        

    }


    ////////////////////
    // Utility Methods
    ////////////////////
    public static string getOrderDate(ServiceAppointment sa) {
        try {
            if (sa != null && sa.Work_Order__r != null && sa.Work_Order__r.Order_Date__c != null) {
                return String.valueOf(sa.Work_Order__r.Order_Date__c);
            } else if (sa != null && sa.Work_Order__r != null) {
                return String.valueOf(Date.valueOf(sa.Work_Order__r.CreatedDate));
            }
        } catch (exception e) {
            System.debug(lprefix+'unable to find order date: ' + e.getMessage());
        }
        return '';
        
    }

    public static List<Appt_InvoiceDetailModel.LineItems> mapArticleTypeToServiceForLineItems(List<Appt_InvoiceDetailModel.LineItems> lineItems){
        List<Appt_InvoiceDetailModel.LineItems> newLineItems = new List<Appt_InvoiceDetailModel.LineItems>();
        String typeDescription;

        // Map Order Line Items
        for(Appt_InvoiceDetailModel.LineItems l : lineItems){

            // First Check for an article number match
            Decimal articleNum = Decimal.valueOf(l.articleNumber);
            typeDescription = Appt_OrderLineItemsUtil.getLineItemDescriptionByArticleNumnber(articleNum);            

            if(typeDescription != null){
                l.articleType = typeDescription;
                newLineItems.add(l);
            }else{

                // Then check for a article type match
                String articleType = l.articleType.toUpperCase();           
                typeDescription = Appt_OrderLineItemsUtil.getLineItemDescriptionByType(articleType);
                
                if(typeDescription != null){
                    l.articleType = typeDescription;
                    newLineItems.add(l);
                }else{
                    // If no match is found set as blank
                    l.articleType = '';                    
                }
            }

            /*
            if((articleType.toUpperCase()).equals('ZTIR')){
                l.articleType = 'Tires';
                newLineItems.add(l);
            }
            else if((articleType.toUpperCase()).equals('ZWHL')) {
                l.articleType = 'Wheel';
                newLineItems.add(l);
            }
            else {                
                Decimal articleNum = Decimal.valueOf(l.articleNumber);
                if(articleNum == 80400){
                    l.articleType = 'Roto/Balance';
                    newLineItems.add(l);
                }
                else if(articleNum == 80222 || articleNum == 80225){
                    l.articleType = 'Free Labor';
                    newLineItems.add(l);
                }
                else if(articleNum == 84802 || articleNum == 90079){
                    l.articleType = 'Labor';
                    newLineItems.add(l);
                }
                else{
                    l.articleType = '';
                }
            }*/

            System.debug('article number: ' +l.articleNumber);
            System.debug('assigned service to line item: ' +l.articleType);
        }        
        newLineItems = Appt_OrderLineItemsUtil.sortList(newLineItems);            

        System.debug('new line items: ' +lineItems);
        
        return newLineItems; 
    }
}