global class Fleet_B2BCustomerUpdateBatch implements Schedulable
{
    public static Boolean isTest = false;
    public static String lprefix = 'BATCH:';
    public static final Decimal LIMIT_PERCENT = 0.8;

    //---Process to execute the Scheduled job
    global void execute(SchedulableContext ctx)
    {
        process();
    }

    //---Setting up the scheduled jobs based on the Fleet Integration Settings
    public static void setupSchedule()
    {
        System.debug( lprefix + 'Setting up Scheduled Jobs - START');

        String cronExpList = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.ERROR_RETRY_CRONEXP_LIST);
        System.debug( lprefix + 'Reading cronExp: ' + cronExpList);

        if (isTest)
        {
            cronExpList = '0, 1 * * * ?;0, 16 * * * ?';
        }

        if (cronExpList == null || cronExpList == '')
        {
            System.debug( lprefix + 'No valid CronExp values, no schedules started');
        }
        else 
        {
            String[] cronStringList = cronExpList.split(';');

            if (cronStringList == null || cronStringList.size() == 0 )
            {
                System.debug( lprefix + 'No valid CronExp values, no schedules started');
            }
            else 
            {
                for (String cronExp : cronStringList)
                {
                    System.debug( lprefix + 'Found cronExpr: ' + cronExp);


                    if (cronExp != null && cronExp != '') 
                    {
                        System.debug( lprefix + 'Setting up scheduled job: Fleet_B2BCustomerUpdateBatch: at ' + cronExp);
                        System.schedule('Fleet_B2BCustomerUpdateBatch: at ' + cronExp, cronExp, new Fleet_B2BCustomerUpdateBatch());
                    }
                }
            }
        }

        System.debug( lprefix + 'Setting up Scheduled Jobs - END');
    }
    
    //---Primary process method
    public static void process()
    {
        processRetry();
        processQueued();
    }

    //---Process retry messages
    public static void processRetry()
    {
        System.debug( lprefix + 'B2B Customer Retry Logic - START');

        Integer maxAttempts = Fleet_IntegrationUtil.getSettingIntValue( Fleet_Values.ERROR_RETRY_MAX_ATTEMPTS);
        Integer maxAgeInMin = Fleet_IntegrationUtil.getSettingIntValue( Fleet_Values.ERROR_RETRY_MAX_AGE_MIN);
        Integer retryRecordLimit = Fleet_IntegrationUtil.getSettingIntValue( Fleet_Values.ERROR_RETRY_REC_LIMIT);
        String typeList = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.ERROR_RETRY_TYPE_LIST);

        System.debug( lprefix + 'Reading retry settings:   typeList: ' + typeList + ' maxAttempts: ' + maxAttempts + ' maxAgeInMin: ' + maxAgeInMin + ' retryRecordList: ' + retryRecordLimit);

        if (typeList == null || typeList == '')
        {
            System.debug( lprefix + 'Invalid setttings, cannot run retry');
        }
        else 
        {
            String[] typeStringList = typeList.split(',');

            String typeWhere = '';
            for(String typeRow : typeStringList)
            {
                if (typeRow != null && typeRow != '')
                {
                    if (typeWhere != null && typeWhere != '') typeWhere += ',';
                    typeWhere += '\'' + typeRow.trim() +  '\'';
                }
            }

            String inMesgQuery = 'SELECT Id FROM Int_Message__c WHERE Status__c = \'' + Int_Values.STATUS_ERROR + '\' AND Type__c IN (' + typeWhere + ') AND Age_In_Minutes__c < ' + maxAgeInMin + ' AND Retry_Count__c < ' + maxAttempts + ' ORDER BY Retry_Date__c ASC LIMIT ' + retryRecordLimit;
            System.debug( lprefix + 'Running the following Query to pull Int_Messages to retry: ' + inMesgQuery);

            List<Int_Message__c> messageList = null;
            
            try 
            {
                messageList = database.Query( inMesgQuery);
            } 
            catch (Exception ex) 
            {
                Logger logInstance = Logger.getInstance();
                logInstance.log('B2B Customer Update', 'Fleet_B2BCustomerUpdateBatch', ex);
                String errorMessage = ex.getMessage();
                System.debug( lprefix + 'Error reading Int_Messages to process: ' + errorMessage);  
            }

            if (messageList != null && messageList.size() > 0)
            {
                System.debug( lprefix + 'Found the following records to retry: ' + messageList);

                //---Building the list of IDs
                List<Id> messageIdList = new List<Id>();
                for( Int_Message__c mRow : messageList) messageIdList.add( mRow.Id);
                
            
                Fleet_ECCService.sendRetryMessges(messageIdList);
            }
            else 
            {
                System.debug( lprefix + 'No records found that meet the criteria');
            }
        }
        
        System.debug( lprefix + 'B2B Customer Retry Logic - END');
    }

    //---Process retry messages
    public static void processQueued()
    {
        System.debug( lprefix + 'B2B Queued - START');

        Integer queuedLimit = Fleet_IntegrationUtil.getSettingIntValue( Fleet_Values.QUEUED_REC_LIMIT);

        String inMesgQuery = 'SELECT Id, Group_Key__c FROM Int_Message__c WHERE Status__c = \'' + Int_Values.STATUS_QUEUED + '\' ORDER BY CreatedDate ASC LIMIT ' + queuedLimit;
        System.debug( lprefix + 'Running the following Query to pull Int_Messages that are queued: ' + inMesgQuery);

        List<Int_Message__c> messageList = null;
        
        try 
        {
            messageList = database.Query( inMesgQuery);
        } 
        catch (Exception ex) 
        {
            Logger logInstance = Logger.getInstance();
            logInstance.log('B2B Customer Update', 'Fleet_B2BCustomerUpdateBatch', ex);
            String errorMessage = ex.getMessage();
            System.debug( lprefix + 'Error reading Int_Messages to process: ' + errorMessage);  
        }

        if (messageList != null && messageList.size() > 0)
        {
            System.debug( lprefix + 'Found the following records to retry: ' + messageList);

            Set<String> groupKeySet = new Set<String>();

            //---Building the list of IDs
            List<Id> messageIdList = new List<Id>();

            for( Int_Message__c mRow : messageList)
                {
                    //---Check if it has a group key
                    if (mRow.Group_Key__c == null || mRow.Group_Key__c == '')
                    {
                        messageIdList.add( mRow.Id);
                    }
                    else 
                    {
                        if (!groupKeySet.contains(mRow.Group_Key__c))
                        {
                            //---Not in an existing Group
                            messageIdList.add( mRow.Id);
                            groupKeySet.add(mRow.Group_Key__c);  //---Add to the set to prevent any items from a previosly encountered group
                        }
                    }
                } 
        
            Fleet_ECCService.sendMessges(messageIdList);
        }
        else 
        {
            System.debug( lprefix + 'No records found that meet the criteria');
        }
        
        System.debug( lprefix + 'B2B Queued - END');
    }
}