global class Fleet_BatchSchedule implements Schedulable
{
    public static final String lprefix = 'SP:';

    public static final String AR_NOTIFICATION_COMMENT = 'The online application was submitted by the customer';

    public static Boolean isTest = false;
  //Vaneet : Changes 'Closed Won' to 'Closed Won - 100%' (INC1312053)
  //public static final String OPPORTUNITY_STAGE_CLOSEDWON = 'Closed Won';
    public static final String OPPORTUNITY_STAGE_CLOSEDWON = 'Closed Won - 100%';
    public static final String ACCOUNT_STATUS_PROSPECT = 'Prospect';

    public static final Decimal LIMIT_PERCENT = 0.9;
    public static final Integer CONTACT_CONVERSION_LIMIT = 20;

    //---Setup the schedule for the process
    public static void setupSchedule()
    {

        System.debug( lprefix + 'Setting up Scheduled Jobs - START');

        String cronExpList = Fleet_IntegrationUtil.getSettingValue( Fleet_Values.BATCH_SCHEDULE_CRONEXP_LIST);
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
                        System.debug( lprefix + 'Setting schedule to:'  + cronExp);
                        System.schedule('Fleet_BatchSchedule at: ' + cronExp, cronExp, new Fleet_BatchSchedule());
                    }
                }
            }
        }

        System.debug( lprefix + 'Setting up Scheduled Jobs - END');

/*

        List<String> batchTimes = new List<String>();
        batchTimes.add('0, 0 * * * ?');
        batchTimes.add('0, 15 * * * ?');
        batchTimes.add('0, 30 * * * ?');
        batchTimes.add('0, 45 * * * ?');
        
        if (isTest)
        {
            batchTimes = new List<String>();
            batchTimes.add('0, 1 * * * ?');    //---Needs a unique time in case the Batch is already scheduled in the running Org
        }

        for( String bRow : batchTimes)
        {
            System.debug( lprefix + 'Setting schedule to:'  + bRow);
            System.schedule('Fleet_BatchSchedule at: ' + bRow, bRow, new Fleet_BatchSchedule());
        }

        */
    }

    //---Process to execute the Scheduled job
    global void execute(SchedulableContext ctx)
    {
        process();
    }

    //---Primary processing  (NOTE:  These are all sharing the same limit Context, make sure that the system can catch up over the 24 hour period.)
    public static void process()
    {
        processOpportunity();
        if (!areLimitsOk()) return;

        processApplications();
        if (!areLimitsOk()) return;

        processContactstoConvert();
        if (!areLimitsOk()) return;

        processIntMessagePurge();
        if (!areLimitsOk()) return;
    }

    //---Primary processing - NOTE this process is very Expensive in Processing, it consumes a lot of SOQL Queryies, for each Application processed
    public static void processApplications()
    {
        System.debug( lprefix + 'Application Batch - START' );

        Decimal pctToLimit = Limits.getQueries() / Limits.getLimitQueries();
        
        Decimal appLimitDec = 6 * (1- pctToLimit);  //---NOTE - currently, each app takes a large number of SOQL Queries, we have determine that we can process 6 at a time.
        Integer appLimit = appLimitDec.intValue();

        //-- DTFS-802 - limiting how many Apps can be processed in one batch, due to limits we were hitting
        List<Fleet_Application__c> appList = [SELECT Id, Name, isApplicationSubmitted__c FROM Fleet_Application__c WHERE isApplicationSubmitted__c = TRUE LIMIT :appLimit];

        if (appList != null && appList.size() > 0)
        {
            notifyAccountApplicationReceived(appList);
        }

        System.debug( lprefix + 'Application Batch - END' );
    }

    //---Notify that the Applicaiton has been recieved
    public static void notifyAccountApplicationReceived(List<Fleet_Application__c> fltApplicationList) 
    {
        System.debug( lprefix + 'notifyAccountApplicationReceived() - Start notifyAccountApplicationReceived');

        Set<Id> fltAppSet = new Set<Id>();

        for (Fleet_Application__c app : fltApplicationList)
        {
            app.isApplicationSubmitted__c = false; // clear batch process trigger
            fltAppSet.add(app.Id);
        }

        //---Reset the flag
        update fltApplicationList;

        //-- DTFS-802 - limiting how many Apps can be processed in one batch, due to limits we were hitting
        Map<Id, Account> parentAccountMap = new Map<Id, Account>( [SELECT Id, Fleet_Application_Type__c, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Fleet_Specialist__r.Email,AT_Customer__c,DT_Customer__c,ShippingPostalcode, Owner.Email
                                                                    FROM Account WHERE ID IN ( SELECT Parent_Account__c FROM Fleet_Application__c WHERE Id IN :fltAppSet ) LIMIT 6] );

        System.debug( lprefix + '      parentAccountMap: ' + parentAccountMap );
//---Get email settings
        Map<String,List<EmailTemplate>> mapTemplates = New Map<String,List<EmailTemplate>>();
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        System.debug( lprefix + '      notifyAccountApplicationReceived Current User: ' + UserInfo.getUserId() );
        Map<String,OrgWideEmailAddress> owaAddressMapToId = new Map<String,OrgWideEmailAddress>();
        for(OrgWideEmailAddress owa : [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress]){
            owaAddressMapToId.put(owa.Address, owa);
        }
       //ist<EmailTemplate> templateList = new List<EmailTemplate>();
        String templateNameAT;
        String templateNameDT;
        if (emailSettings != null){
             templateNameDT = emailSettings.Fleet_AccountApplicationReceivedTemplate__c;
             templateNameAT = emailSettings.Fleet_Account_Application_Received_AT__c;
            for(EmailTemplate email : [SELECT Id,DeveloperName from EmailTemplate WHERE DeveloperName = :templateNameDT OR DeveloperName = :templateNameAT]){
                mapTemplates.put(email.DeveloperName,New List<EmailTemplate>{email});
            }
     // templateList = [SELECT Id from EmailTemplate WHERE DeveloperName = :templateName limit 1];
        }
        
        //chatterId = getChatterGroupId(CHATTER_GROUP);

        for (Account acctRec: parentAccountMap.values())
        {
            Fleet_CreateActionWithoutSharing newAction = new Fleet_CreateActionWithoutSharing();

            // Send email to Customer that Applicatin was received, but do not send emails if settings are not configured
            if (emailSettings != null)
            {
                String templateName = emailSettings.Fleet_AccountApplicationReceivedTemplate__c;

                //-- DTFS-802 - handle when Fleet_Specialist__r is not populated
                String fromAddress;
                if (!String.isBlank(acctRec.Fleet_Specialist__r.Email)) fromAddress = acctRec.Fleet_Specialist__r.Email;
                else fromAddress = acctRec.Owner.Email;

                String toAddress = acctRec.Fleet_Primary_Contact__r.Email;
                Id contactId = acctRec.Fleet_Primary_Contact__c;
                Id whatId = null; 

                //newAction.sendEmailNotificaiton('', '', toAddress, templateName, whatId, fromAddress, contactId);
                if(acctRec.AT_Customer__c)
                	newAction.sendEmailNotificaiton('', '', toAddress, templateNameAT, whatId, fromAddress, contactId);  
                else
                    newAction.sendEmailNotificaiton('', '', toAddress, templateNameDT, whatId, fromAddress, contactId);         
            }

            //-- Call Util method to update Account, Fleet Application and notify AR that the application was received
            if(!Test.isRunningTest()){
                System.debug('HERE');
                Fleet_NotifyARUtil.notifyARApplicationReceived(acctRec.Id, acctRec.Fleet_Application_Type__c, acctRec.Fleet_Primary_Contact__c, AR_NOTIFICATION_COMMENT);    
            }
            
        }

        System.debug( lprefix + 'notifyAccountApplicationReceived() - End notifyAccountApplicationReceived');
        
    } // End of notifyAccountApplicationReceived()
    
    //---Primary processing
    public static void processOpportunity()
    {
        System.debug( lprefix + 'Opportunity Batch - START' );

        Id b2bRT = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();

        List<Opportunity> oppList = [SELECT Id, Name, Customer_Type__c, Fleet_Primary_Contact__c, Application_Type__c, AccountId FROM Opportunity WHERE Fleet_OpAct_Match__c = false AND RecordTypeId = :b2bRT AND StageName <> :OPPORTUNITY_STAGE_CLOSEDWON AND Account.Fleet_Account_Status__c = :ACCOUNT_STATUS_PROSPECT];
        
        if (oppList != null && oppList.size() > 0)
        {
            List<Account> updateList = new List<Account>();
			Set<String> setAccIds = new Set<String>();
            for (Opportunity opp : oppList)
            {
                Account updateAcct = new Account(Id=opp.AccountId);
                updateAcct.Fleet_Customer_Type__c = opp.Customer_Type__c;
                updateAcct.Fleet_Primary_Contact__c = opp.Fleet_Primary_Contact__c;
                updateAcct.Fleet_Application_Type__c = opp.Application_Type__c;
                if(!setAccIds.contains(updateAcct.Id)){
                    setAccIds.add(updateAcct.Id);
                	updateList.add(updateAcct);    
                }
                
            }

            System.debug( lprefix + 'Updating the following Accounts' + updateList );
            update updateList;
        }

        System.debug( lprefix + 'Opportunity Batch - END' );
    }

    //---Process the Int Message Purge
    public static void processIntMessagePurge(){
        //---Get the max records to be processed in a batch
        Integer maxRecords = Fleet_IntegrationUtil.getSettingIntValue(Fleet_Values.PURGE_REC_LIMIT_QUERY);
        System.debug('maxRecords=' +maxRecords);

        purgeSuccessfulRecords(maxRecords);
        purgeAllRecords(maxRecords);

    }

    //---Purge successful records from the Int Message Object
    public static void purgeSuccessfulRecords(Integer maxRecords){
        Integer purgeDaysBack = Fleet_IntegrationUtil.getSettingIntValue(Fleet_Values.PURGE_DAYS_COMPLETE);        
        DateTime checkDate = Date.today().addDays(-purgeDaysBack);

        System.debug( lprefix + 'Purge all messages older than '+ checkDate);

        try{

            List<Int_Message__c> purgeMessages = [SELECT Id, Status__c, CreatedDate 
                                                  FROM Int_Message__c 
                                                  WHERE CreatedDate < :checkDate AND (Status__c = 'Successful' OR Status__c = 'Submitted')
                                                  ORDER BY CreatedDate ASC
                                                  LIMIT :maxRecords];

            
            System.debug( lprefix + 'Purge successful message count: '+ purgeMessages.size());

            if(purgeMessages.size() > 0){
                delete purgeMessages;
            }

        }catch(DmlException e){
            System.debug( lprefix + 'Purge successful messages Delete Error : '+ e.getMessage());
        }        
        
    }

    //---Purge all records after a certain time frame
    public static void purgeAllRecords(Integer maxRecords){
        Integer purgeDaysBack = Fleet_IntegrationUtil.getSettingIntValue(Fleet_Values.PURGE_DAYS_ALL);
        
        Date checkDate = Date.today().addDays(-purgeDaysBack);
        System.debug( lprefix + 'Check Date All ' + checkDate);
		if(maxRecords > Limits.getLimitDMLRows() - Limits.getDMLRows()-2){
            maxRecords = Limits.getLimitDMLRows() - Limits.getDMLRows()-2;
        }
        System.debug('Check DML Statements ' + Limits.getDMLRows()+'=='+Limits.getLimitDMLRows()+'==='+maxRecords);
        try{

            List<Int_Message__c> purgeMessages = [SELECT Id, Status__c, CreatedDate 
                                                  FROM Int_Message__c 
                                                  WHERE CreatedDate < :checkDate AND (Status__c != 'Successful' AND Status__c != 'Submitted')
                                                  ORDER BY CreatedDate ASC
                                                  LIMIT :1000];
            
            System.debug( lprefix + 'Purge all message count: '+ purgeMessages.size());

            if(purgeMessages.size() > 0){
                delete purgeMessages;
            }

        }catch(DmlException e){
            System.debug( lprefix + 'Purge all messages delete Error : '+ e.getMessage());
        }          

    }

    //---Process Contacts that have been identified to be converted to Fleet Community Manager. 
    public static void processContactstoConvert()
    {
        System.debug( lprefix + 'Contacts Conversion to Community MGR  Batch - START' );

        //get records type Id for B2B COntact RT on Contact object
        Id b2BContactRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
        System.debug( lprefix + '     B2B Contact Record Type Id = ' + b2BContactRT);

        // Get Contacts that aren't already Community Mgrs and with Convert_To_Fleet_Community_Manager__c = true and Account has ECC_Account_Number__c populated and account is CUSTOMER
        //NOTE: This batch process does a lot of SOQL/DML and therefore can hit lmits, so we will only process 20 Contacts in a batch transaction
        system.debug('@@@ status picklist: '+ Fleet_Values.ACCOUNT_STATUS_CUSTOMER);
        List<Contact> contacts = [SELECT Id, Convert_To_Fleet_Community_Manager__c FROM Contact WHERE Convert_To_Fleet_Community_Manager__c = true 
                                    AND Is_Fleet_Community_Manager__c = false AND RecordTypeId = :b2BContactRT AND (Account.ECC_Account_Number__c != null 
                                    AND Account.Fleet_Account_Status__c = :Fleet_Values.ACCOUNT_STATUS_CUSTOMER) LIMIT :CONTACT_CONVERSION_LIMIT];
        System.debug( lprefix + '     B2B Contact records queried for conversion to Fleet Community Manager: ' + contacts);

        if (contacts != null && contacts.size() > 0) {

            //build set of Ids, required by Fleet_CommunityUserBuilder.convertContactToCommunityUser()
            Set<Id> contactsIdSet = new Set<Id>();
            for (Contact cntct: contacts) {
                contactsIdSet.add(cntct.Id);
            }

            //call Fleet_CommunityUserBuilder to convert the Contacts to Community Managers
            Fleet_CommunityUserBuilder.convertContactToCommunityUser(contactsIdSet, true);

        }

        
        System.debug( lprefix + 'Contacts Conversion to Community MGR  Batch - END' );
    }



    //---Check the Limits
    public static Boolean areLimitsOk()
    {
        if (!checkLimit('DML', Limits.getLimitDMLStatements(), Limits.getDMLStatements())) return false;
        if (!checkLimit('Queries', Limits.getLimitQueries(), Limits.getQueries())) return false;
        if (!checkLimit('CPU', Limits.getLimitCpuTime(), Limits.getCpuTime())) return false;
        
        return true;
    }
    
    //---Check a single limit value
    public static boolean checkLimit(String limitName, Integer limitLimit, Integer limitValue)
    {
        System.debug( lprefix + ' checkLimit() ENTRY for ' + limitName + ', limitLimit:' + limitLimit + ' current limitValue: ' + limitValue);
        if (limitValue > (LIMIT_PERCENT * limitLimit))
        {
            System.debug( lprefix + 'WARNING!' + limitName + ' limit too close for, limit is:' + limitLimit + ' current value is: ' + limitValue);
            return false;
        }
        return true;
    }
}