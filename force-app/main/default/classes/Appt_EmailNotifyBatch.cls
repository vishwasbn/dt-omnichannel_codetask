/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   The Batch class creates a query to get all Notifications for eMail, with an Invoice status of pending and an Initial eMail send status of Pending.  When the Batch is executed, a callout for each notification is performed to obtain the Hybris, Invoice, Layaway, or Quote Invoice detail information.  The Invoice detail information is packaged into a Invoice Detail Model payload and attached to the Notification record.  The Notification Invoice status is changed to Successful (or Error if the Batch failed to retrieve and Invoice).  Finally the Batch updates the Notification records that had Invoice payloads attached.  There was a switch added based on the custom metadata 'Use_SFMC_Email' value that prevents the Batch from processing records.  There is also log metering added for load testing;
 */

public class Appt_EmailNotifyBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Database.RaisesPlatformEvents
{
    final static string LPREFIX = 'Appt_EmailNotifyBatch: ';
    public final String QUERY;

    public Appt_EmailNotifyBatch() 
    {
        QUERY = 'SELECT Id, API_Callout_Order_Type__c, Work_Order__r.Order_Date__c, Order_Number__c, SAP_Store_Id__c, Invoice_Status__c, Invoice_Payload__c, Invoice_Date__c, Invoice_Error__c, Initial_Email_Send_Status__c, Initial_PE_SMS_Send_Status__c, Last_Error_Message__c FROM Notification__c WHERE Channels__c LIKE \'%EMAIL%\' AND (Invoice_Status__c = null OR Invoice_Status__c = \'' + Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_PENDING + '\') AND Initial_Email_Send_Status__c = \'' + Appt_ConstantValues.NOTIFICATION_STATUS_PENDING + '\' ORDER BY CreatedDate';
        System.debug('QUERY: ' + QUERY);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug( LPREFIX + 'start');
        System.debug( LPREFIX + 'QUERY: ' + QUERY);
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<Notification__c> scope)
    {
        System.debug('Start ' + LPREFIX + ' execute: ' + scope.size());

        //---06.09.22.SS - Switch to new SFMC Email System
        Boolean useSFMCEmail = Test.isRunningTest() ? false : Appt_SettingUtil.getSettingBooleanValue( 'Use_SFMC_Email');

        if (useSFMCEmail)
        {
            System.debug(LPREFIX + 'Using new SFMC Email, no need for this processing');
            return;
        }

        executeEmailNotify( scope );

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug('End ' + LPREFIX + ' execute');
    } // End of Execute()


    public static void executeEmailNotify( List<Notification__c> scope )
    {
        List<Notification__c> updateList = new List<Notification__c>();
        List<Int_Message__c> intMsgList = new List<Int_Message__c>();

        for (Notification__c notif: scope)
        {
            try {

                String storeNum = notif.SAP_Store_Id__c;
                String orderNum = notif.Order_Number__c;
                String orderDateStr = '';

                if (Test.isRunningTest())
                {
                    //---Use Test data (ONLY FOR TESTING)
                    orderNum = '00000000000001187373';
                    storeNum = '0000001958';
                    orderDateStr = '2020-07-30';
                }
                else
                {
                    //---Need to read order date into format 'yyyy-mm-dd'  from notif.Work_Order__r.Order_Date__c; 
                    Date orderDate = notif.Work_Order__r.Order_Date__c;
                    String orderYear = '' + orderDate.year();
                    String orderMonth = '' + orderDate.month();
                    String orderDay = '' + orderDate.day();
                    orderDateStr = orderYear.leftPad(4, '0') + '-' + orderMonth.leftPad(2, '0') + '-' + orderDay.leftPad(2, '0');
                } 
                
                Appt_InvoiceDetailModel invModel = new Appt_InvoiceDetailModel();

                // Get hybris order 
                if(notif.API_Callout_Order_Type__c == Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER_PARAM_NAME){
                    //---QUERY the data
                    invModel = Appt_InvoiceService.getInvoiceDetailBulk(storeNum, orderNum, Appt_ConstantValues.INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER, intMsgList);
                }  
        
                // Get invoice order
                if(notif.API_Callout_Order_Type__c == Appt_ConstantValues.INVOICE_ID_TYPE_INVOICE_NUMBER_PARAM_NAME){
                    //---QUERY the data
                    invModel = Appt_InvoiceService.getInvoiceDetailBulk(storeNum, orderNum, orderDateStr, intMsgList);
                }
        
                // Get layaway
                if(notif.API_Callout_Order_Type__c == Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER_PARAM_NAME){
                    //---QUERY the data
                    invModel = Appt_InvoiceService.getInvoiceDetailBulk(storeNum, orderNum, Appt_ConstantValues.INVOICE_ID_TYPE_LAYAWAY_NUMBER, intMsgList);
                }  
        
                // Get Quote order
                if(notif.API_Callout_Order_Type__c == Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER_PARAM_NAME){
                    //---QUERY the data
                    invModel = Appt_InvoiceService.getInvoiceDetailBulk(storeNum, orderNum, Appt_ConstantValues.INVOICE_ID_TYPE_QUOTE_NUMBER, intMsgList);
                }  
        
                Notification__c updateNote = new Notification__c(Id = notif.Id, Initial_Email_Send_Status__c = notif.Initial_Email_Send_Status__c, Invoice_Status__c = notif.Invoice_Status__c);
                if(invModel.payload != null) {
                    //---Update the status on the notification
                    updateNote.Invoice_Payload__c = invModel.payload;
                    updateNote.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_SUCCESSFUL;
                    
                    updateList.add( updateNote );
                    System.debug(LPREFIX + 'Complete, Updating Notification: ' + updateNote);
                } else {
                    updateNote.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_ERROR;
                    updateList.add( updateNote );
                }                        
            } 
            catch (Exception ex) 
            {
                System.debug('Exception: ' + ex.getMessage());
                System.debug('Stack: ' + ex.getStackTraceString());
                System.debug('Line: ' + ex.getLineNumber());

                Notification__c errorNotify = new Notification__c(Id = notif.Id);
                errorNotify.Invoice_Status__c = Appt_ConstantValues.NOTIFICATION_INVOICE_STATUS_ERROR;
                errorNotify.Last_Error_Message__c = String.isNotBlank( notif.Last_Error_Message__c ) ? notif.Last_Error_Message__c + ex.getMessage() : ex.getMessage();
                updateList.add( errorNotify );
            }
        } // End of scope loop

        upsert intMsgList;
        update updateList;

    } // End of executeEmailNotify()

    public void finish(Database.BatchableContext context)
    {
        Id batchId = context.getJobId();
        System.debug( LPREFIX + '::finish: batchId: ' + batchId);

        //---Checking final status of the Job
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClassID, JobItemsProcessed, TotalJobItems, JobType, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchId];
        System.debug( LPREFIX + 'apexJob: ' + apexJob);
    }    
}