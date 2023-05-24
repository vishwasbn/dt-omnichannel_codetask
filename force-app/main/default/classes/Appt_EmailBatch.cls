public class Appt_EmailBatch implements Schedulable {
    public static final String LPREFIX = 'Appt_EmailBatch: ';
    public static final Decimal LIMIT_PERCENT = 0.8;
    
    //---Process to execute the Scheduled job
    public void execute(SchedulableContext ctx)
    {
        process();

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }
    }

    public static void setupSchedule()
    {
        System.debug( LPREFIX + 'Setting up Scheduled Jobs - START');

        String scheduleName = 'Appt_EmailBatch:';

        // give unique name so it won't fail if the real one is running
        if(Test.isRunningTest()){scheduleName = 'Appt_EmailBatchTest:';}

        System.schedule(scheduleName+' at 00 min','0, 0 * * * ?', new Appt_EmailBatch());
        System.schedule(scheduleName+' at 15 min','0, 15 * * * ?', new Appt_EmailBatch());
        System.schedule(scheduleName+' at 30 min','0, 30 * * * ?', new Appt_EmailBatch());
        System.schedule(scheduleName+' at 45 min','0, 45 * * * ?', new Appt_EmailBatch());

        System.debug( LPREFIX + 'Setting up Scheduled Jobs - START');
    }
    
    //---Primary processing  
    public static void process() 
    {
        System.debug(LPREFIX + 'Appt_EmailBatch.process() ENTRY');

        procesSet();
             
        System.debug(LPREFIX + 'Appt_EmailBatch.process() EXIT - successfully');
    }

    public static void procesSet()
    {
        Appt_Appointment_Setting__mdt apptSetting = Appt_Appointment_Setting__mdt.getInstance('Use_SFMC_Email');
        if(apptSetting != null && apptSetting.Value__c.toLowerCase() == 'yes'){
            System.debug('Appt_EmailBatch is disabled by setting DT_Flow_Setting__mdt!');
            return;
        }
        Integer setMaxSize = 5000;  //---Limit of number of FUTURE calls

        //---Get all notifications that:
        //-----Are Email
        //-----Invoice status is null or Pending
        //-----Email send status is Pending
        //---Sorting by create date (oldest)  
        
        //TODO - if there are errors, this may always proceess the oldest records over and over.  
        //---May want to have a process date and put at the back of the line if errors
        List<Notification__c> pendingNotList = [SELECT Id, Invoice_Status__c FROM Notification__c WHERE Channels__c LIKE '%EMAIL%' AND (Invoice_Status__c = null OR Invoice_Status__c = :Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING) AND Initial_Email_Send_Status__c = :Appt_ConstantValues.NOTIFICATION_STATUS_PENDING ORDER BY CreatedDate LIMIT :setMaxSize];

        // Sends a list of notificaitons to have their order information added
        Appt_EmailOrderEnrichment.buildQueueableJobs(pendingNotList);

 

        /*
        if (pendingNotList != null && pendingNotList.size() > 0)
        {
            for(Notification__c notRow : pendingNotList)
            {
                System.debug(LPREFIX + 'Processing Notification: procesSet() ' + notRow);
                processNotificationFuture(notRow.Id);
            }
        }*/
    }

    //---Process a single notification, and update the invoice payload
    public static void processNotification(Id notificationId, List<id> idsToProcess)
    {
        Notification__c notif = [SELECT Id, API_Callout_Order_Type__c, Work_Order__r.Order_Date__c, Order_Number__c, SAP_Store_Id__c, Invoice_Status__c, Invoice_Payload__c, Invoice_Date__c, Invoice_Error__c, Initial_Email_Send_Status__c FROM Notification__c WHERE Id = :notificationId];

        System.debug(LPREFIX + 'Processing Notification: processNotification()' + notif);

        //---Email is not Pending, this may have changed since the initial query.
        if (notif.Initial_Email_Send_Status__c != Appt_ConstantValues.NOTIFICATION_STATUS_PENDING)
        {
            System.debug(LPREFIX + 'Cancellig processing, Email send status is: ' + notif.Initial_Email_Send_Status__c);
            return;
        } 
        
        //---Email is not Pending, this may have changed since the initial query.
        if (notif.Invoice_Status__c == Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_SUCCESSFUL)
        {
            System.debug(LPREFIX + 'Cancellig processing, Invoice Send status is: ' + notif.Invoice_Status__c);
            return;
        }
        
        //---Read the Parameters
        String storeNum = notif.SAP_Store_Id__c;
        String orderNum = notif.Order_Number__c;
        String orderDateStr = '';
        //---Need to read order date into format 'yyyy-mm-dd'  from notif.Work_Order__r.Order_Date__c; 
        try{
            Date orderDate = notif.Work_Order__r.Order_Date__c;
            String orderYear = '' + orderDate.year();
            String orderMonth = '' + orderDate.month();
            String orderDay = '' + orderDate.day();
            orderDateStr = orderYear.leftPad(4, '0') + '-' + orderMonth.leftPad(2, '0') + '-' + orderDay.leftPad(2, '0');
        } catch (Exception e){
            System.debug('try to convert order date failed: ' + e.getMessage());
        }
        

        
        if (Test.isRunningTest())
        {
            //---Use Test data (ONLY FOR TESTING)
            orderNum = '00000000000001187373';
            storeNum = '0000001958';
            orderDateStr = '2020-07-30';
        }

        Appt_InvoiceDetailModel invModel = new Appt_InvoiceDetailModel();

        // Get hybris order 
        if(notif.API_Callout_Order_Type__c == Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER_PARAM_NAME){
            //---QUERY the data
            invModel = Appt_InvoiceService.getInvoiceDetail(storeNum, orderNum, Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER);
        }  

        // Get POS order
        if(notif.API_Callout_Order_Type__c == Appt_ConstantValues.INVOICE_ID_TYPE_LEGACY_ORDER_NUMBER_PARAM_NAME){
            //---QUERY the data
            invModel = Appt_InvoiceService.getInvoiceDetail(storeNum, orderNum, Appt_ConstantValues.INVOICE_ID_TYPE_LEGACY_ORDER_NUMBER);
        }          

        // Get invoice order
        if(notif.API_Callout_Order_Type__c == Appt_ConstantValues.INVOICE_ID_TYPE_INVOICE_NUMBER_PARAM_NAME){
            //---QUERY the data
            invModel = Appt_InvoiceService.getInvoiceDetail(storeNum, orderNum, orderDateStr);
        }

        // Get layaway
        if(notif.API_Callout_Order_Type__c == Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER_PARAM_NAME){
            //---QUERY the data
            invModel = Appt_InvoiceService.getInvoiceDetail(storeNum, orderNum, Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER);
        }  

        // Get Quote order
        if(notif.API_Callout_Order_Type__c == Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER_PARAM_NAME){
            //---QUERY the data
            invModel = Appt_InvoiceService.getInvoiceDetail(storeNum, orderNum, Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER);
        }  

        if(idsToProcess.size() > 0){
            
            // Excludes chaining methods for tests
            if(!Test.isRunningTest()){
                System.enqueueJob(new Appt_EmailOrderEnrichment(idsToProcess));
            }
            
        } else {
            System.debug(LPREFIX + 'All Ids have been processed');
        }
        
        System.debug('***********TEST*****');
        System.debug(invModel.payload);

          
        if(invModel.payload != null) {
            //---Update the status on the notification
            Notification__c updateNote = new Notification__c(Id=notificationId);
            updateNote.Invoice_Payload__c = invModel.payload;
            updateNote.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_SUCCESSFUL;
            
            update updateNote;
            System.debug(LPREFIX + 'Complete, Updating Notification: ' + updateNote);
        } else {
            Notification__c updateNote = new Notification__c(Id=notificationId);
            updateNote.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_ERROR;
            update updateNote;
        }                

        System.debug(LPREFIX + 'End process');
    }

    
}