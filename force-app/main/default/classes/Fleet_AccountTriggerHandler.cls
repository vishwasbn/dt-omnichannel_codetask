/**
 Created By : John Bruning
 Creatted Dated : 10/30/2020
 Description : This Trigger Handler Class is called when record in Inserted,Updated or deleted on the Account Object 
 #1
 Modified By : Krishna Murty Sastry
 Modified Date :  8/26/2022,03/09/2023
 User Story Number : Salesforce-422.
 #2
 Modified By : Ritika Sharma	
 Modified Date :  2/16/2023
 User Story Number : Salesforce-842.
 #3
 Modified By : Rohith V	
 Modified Date :  3/08/2023
 User Story Number : Salesforce-844..
 #4
 Modified By : Ritika Sharma	
 Modified Date :  1/05/2023
 User Story Number : Salesforce-842(batch correction).
 #5
 Modified By : Ritika Sharma	
 Modified Date :  23/05/2023
 User Story Number : Salesforce-1275.
*/


public class Fleet_AccountTriggerHandler
{
    public static String lprefix = 'LOG_ATH:';
    public static Boolean isUpdated = true;
    public static String APPLICATION_TYPE_CREDIT = 'Credit';
    public static String APPLICATION_TYPE_NONCREDIT = 'Non-Credit';
    Public Static Integer count=0;
    
    
   public static void countNoOfDays(List<Account> newList){
    // developed to get No of days since account has been submitted for AR review.
    // SF-842
     list<date> datelist = new list<date>();
     map<ID, StoreHolidays__c> holidayKeyHolidayRecMap = new map<ID, StoreHolidays__c>([SELECT id, Active__c, End__c,Name, Start__c  FROM StoreHolidays__c WHERE Active__c = true 
                                                                                        AND Start__c >= TODAY]); 
     for(StoreHolidays__c sh:holidayKeyHolidayRecMap.values())
      {//To get list of dates have holidays 
         DateTime dT = sh.start__c;
         Date myDate = date.newinstance(dT.year(), dT.month(), dT.day());
         datelist.add(mydate);
     }
       
    DateTime dT = system.now();
    Date todayDate = date.newinstance(dT.year(), dT.month(), dT.day());
    Date weekStart1  = todayDate.toStartofWeek();
    Integer todayday = weekStart1.daysBetween(todayDate);  
    List<Account> fleetlst = new List<Account>();
              
       for(Account acc : newList)
       {
           //count=count+1;
           system.debug(count);
           Integer noOfDays=0;
           //added addition criteria to check Fleet_AR_App_Status__c value too
           if(acc.Fleet_Account_Status__c =='Pending Additional Information' &&  acc.Fleet_AR_App_Status__c =='Pending Additional Information')
             {
               Integer count= acc.Fleet_Pending_Additional_Info_Date__c.daysbetween(todayDate)+1;
               system.debug(count);
               if(acc.Fleet_Days_Until_Decline__c<7&& acc.Fleet_Days_Until_Decline__c>=0)
                {
                   for(Integer i=0; i<count; i++)
                   { 
                     system.debug('Inside Loop with i='+i);
                     Date checktoday = acc.Fleet_Pending_Additional_Info_Date__c.adddays(i);  
                     Date weekStart  = checktoday.toStartofWeek();
                     Integer todaydayy = weekStart.daysBetween(checktoday); 
                     noOfDays= noOfDays+1;
                     system.debug(noOfDays);
                       
                      if(todaydayy==0 || todaydayy==6)
                      { 
                          system.debug('today is weekend');
                          noOfDays=noOfDays-1;
                       }
                       else if(datelist.contains(checktoday))
                        {
                            system.debug('today is holiday');
                            noOfDays=noOfDays-1;
                        }
                       system.debug('Final Value is'+noOfDays);
                    }
                  acc.Fleet_Days_Until_Decline__c=noOfDays;
                 }
                 //to check if count is 7 or more,can push account to declined 
                 else if(acc.Fleet_Days_Until_Decline__c>=7)
                  {
                     acc.Fleet_Account_Status__c='Declined';
                     acc.Fleet_AR_App_Status__c='Declined';
                     acc.Fleet_Days_Until_Decline__c = 0;
                      
                      if(acc.Fleet_Application_Type__c=='Credit')
                      {
                          acc.Fleet_Credit_App_Status__c='Declined';
                      }
                      else if(acc.Fleet_Application_Type__c=='Non-Credit')
                      {
                          acc.Fleet_NonCredit_App_Status__c='Declined';
                      }
                 }
                 
                 fleetlst.add(acc);
             }
          }
       //checking list size to avoid null pointer error 
       if(fleetlst.size()>0 && fleetlst!= null)
       {
            update fleetlst;
       }
       
       
      
     }

    public static void handle(List<Account> lstAccounts, Map<Id, Account> oldMap, Map<Id, Account> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug( lprefix + 'Fleet AccountTrigger Handler - START');
        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();

        //---Check if there are any B2B Accounts
         Boolean hasB2B = false;
        if(newMap != null){
            for (Account aRow : newMap.values()) if (aRow.RecordTypeId == b2bRT) hasB2B = true;
            if (!hasB2B) return;
        }
         

        switch on triggerEvent 
        {
            when AFTER_INSERT 
            {
                
            }
            when BEFORE_INSERT 
            {
                
                updatePublicNotes(lstAccounts);
                addFleetSpecialistAccountTeam(null,lstAccounts);
                checkDeliveryOther(lstAccounts);
            }
            when BEFORE_UPDATE 
            {
                if(system.isFuture()) return;
                updatePublicNotes(newMap.values());
                updatePOSFields(oldMap, newMap); 
                addFleetSpecialistAccountTeam(oldMap,lstAccounts);
                checkDeliveryOther(lstAccounts);
               	handleDeclinedAccounts(lstAccounts);

                
            }
            when AFTER_UPDATE 
            {
                if(system.isFuture() || System.isBatch()) {
                    Fleet_AccountTriggerHandler.isUpdated = false;
                    system.debug('I am Update Trigger'+Fleet_AccountTriggerHandler.isUpdated);
                    processChangesforECC(oldMap, newMap);   
                    //processContactCommunityUsers(oldMap, newMap);    
                    processEmailsForApplicationApproval( oldMap, newMap); 
                    checkForNonCreditCommunityUsers(oldMap, newMap);
                    updateWelcomeCheckATCustomerCheck(oldMap, newMap);
					
                }
                if(Fleet_AccountTriggerHandler.isUpdated){
                    Fleet_AccountTriggerHandler.isUpdated = false;
                    system.debug('I am Update Trigger'+Fleet_AccountTriggerHandler.isUpdated);
                    processChangesforECC(oldMap, newMap);   
                    //processContactCommunityUsers(oldMap, newMap);    
                    processEmailsForApplicationApproval( oldMap, newMap); 
                    checkForNonCreditCommunityUsers(oldMap, newMap);
                    updateWelcomeCheckATCustomerCheck(oldMap, newMap);

                }
                               
            }
            when else {
                //do nothing 
            }
        }

        System.debug( lprefix + 'Fleet AccountTrigger Handler - END');
    }

    
    public static void updatePublicNotes(List<Account> newMap)
    {
        for(Account rec : newMap)
        {
            if(rec.Fleet_Public_Notes__c != NULL)
            {
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('<b>', '**strong**').replace('</b>', '**/strong**');
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('<strong>', '**strong**').replace('</strong>', '**/strong**');
                
                String notes = '';
                for(String s : rec.Fleet_Public_Notes__c.split('<br>'))
                {
                    if(s.contains('</p>'))
                        notes += s;
                    else
                        notes += s+'<br>';
                }
                
                rec.Fleet_Public_Notes__c = notes;
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('</p>', '<br>');
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.stripHtmlTags();
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('\r\n', '<br>').replace('\r', '<br>').replace('\n', '<br>');
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace('**strong**', '<strong>').replace('**/strong**', '</strong>');
                rec.Fleet_Public_Notes__c = rec.Fleet_Public_Notes__c.replace(' <br>', '<br>').replace('<br> ', '<br>');
            }
        }
    }
    public static void checkDeliveryOther(List<Account> newMap){
        for(Account rec : newMap){
            if(rec.Delivery_Service_Provider__c != 'Other' && String.isNotBlank(rec.Other__c)){
                rec.Other__c='';
            }
            if(rec.Delivery_Service_Provider__c == 'Other' && String.isBlank(rec.Other__c)){
                rec.Other__c.addError('Please enter Courier Company name.');
            }
        }
    }
    
    
    
    //---add fleet specialist to account team and assign fleet Sales manager
    public static void addFleetSpecialistAccountTeam(Map<Id, Account> oldMap,List<Account> lstNewAccounts){
        Map<String, Fleet_Sales_Manager__mdt> mapFSM = Fleet_Sales_Manager__mdt.getAll();
        Set<String> setUserNames = New Set<String>();
        Map<String,String> mapUserNames = New Map<String,String>();
        Map<String,String> mapSalesMgr = New Map<String,String>();
        Map<String,String> mapSalesMgrIdName = New Map<String,String>();
        // Added the below query to get the user id using his Profile and Name. This is done as part of the user story 422.
        List<User> usr=[select Id,Name,profileId,Profile.name from user where Name=:Label.Fleet_SalesManager and profile.name ='Fleet Sales user'];        
        for(String fleetManager : mapFSM.keySet()){
            setUserNames.add(mapFSM.get(fleetManager).Label);
            setUserNames.add(mapFSM.get(fleetManager).Fleet_Account_Specialist__c);
        }
        //system.debug('===setUserNames=>'+setUserNames);
        for(User objUser : [SELECT Id,Name FROM User WHERE Name IN : setUserNames AND IsActive = true AND isPortalEnabled = false]){
            mapUserNames.put(objUser.Name,objUser.Id);
            mapSalesMgrIdName.put(objUser.Id,objUser.Name);
        }
       // system.debug('===mapUserNames=>'+mapUserNames);
       // system.debug('===mapSalesMgrIdName=>'+mapSalesMgrIdName);
        for(String fleetManager : mapFSM.keySet()){
            mapSalesMgr.put(mapUserNames.containsKey(mapFSM.get(fleetManager).Label)?mapUserNames.get(mapFSM.get(fleetManager).Label):null,mapUserNames.containsKey(mapFSM.get(fleetManager).Fleet_Account_Specialist__c)?mapUserNames.get(mapFSM.get(fleetManager).Fleet_Account_Specialist__c):null);
        }
       // system.debug('===mapSalesMgr=>'+mapSalesMgr);        
        for(Account objAccount :lstNewAccounts){
            String fleetSpecialist = objAccount.Fleet_Specialist__c;
            if(mapSalesMgr.containsKey(objAccount.OwnerId) && mapSalesMgr.get(objAccount.OwnerId) != null){
                objAccount.Fleet_Specialist__c = mapSalesMgr.get(objAccount.OwnerId);
            }
            if(oldMap != null && oldMap.containsKey(objAccount.Id) && oldMap.get(objAccount.Id).Fleet_Specialist__c != null 
               && fleetSpecialist != null && oldMap.get(objAccount.Id).Fleet_Specialist__c != fleetSpecialist
               && Label.Fleet_Specialist_Change_Permission.contains(UserInfo.getName())){
                   objAccount.Fleet_Specialist__c =fleetSpecialist;
            }
            if(objAccount.OwnerId != objAccount.Fleet_Specialist__c){ 
                System.debug(mapSalesMgrIdName.containsKey(objAccount.OwnerId));
                System.debug(mapSalesMgrIdName.get(objAccount.OwnerId));
                System.debug(mapSalesMgrIdName.containsKey(objAccount.OwnerId)?mapSalesMgrIdName.get(objAccount.OwnerId):null);
                System.debug(mapSalesMgrIdName);
                System.debug(objAccount.Id);
				// Modified the below line of code based on the userstory-785

                objAccount.FLEET_MANAGER_SALES__c = mapSalesMgrIdName.containsKey(objAccount.OwnerId)?objAccount.OwnerId:null;
               
            }
            
            //Updated the Fleet_AccountTriggerHandler code base to assign Chad Emehiser using a custom label-Jira story-460
            else if (objAccount.OwnerId == objAccount.Fleet_Specialist__c){
                objAccount.FLEET_MANAGER_SALES__c = usr.get(0).Id;
                system.debug('157'+objAccount.FLEET_MANAGER_SALES__c);
            }else{
                objAccount.FLEET_MANAGER_SALES__c= usr.get(0).Id;
                system.debug('160'+objAccount.FLEET_MANAGER_SALES__c);
            }
        }
    }
    //---Check for changes that are to be sent to ECC, build a Model Object for each one
    public static void updatePOSFields(Map<Id, Account> oldMap, Map<Id, Account> newMap)
    {   
        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
    
        for( Account newObj : newMap.values())
        {
            if (newObj.RecordTypeId == b2bRT)
            {
                if (newObj.Fleet_Public_Notes__c != null && newObj.Fleet_Public_Notes__c != '')
                {
                    newObj.Fleet_POS_Notes_Display__c = '';
                }
                else 
                {
                    newObj.Fleet_POS_Notes_Display__c = newObj.Fleet_POS_Notes__c;
                }
            }
        }
    }

    //---Check for changes that are to be sent to ECC, build a Model Object for each one
    public static void processChangesforECC(Map<Id, Account> oldMap, Map<Id, Account> newMap)
    {   
        if (Fleet_ECCService.disableECCCallout()) return;

        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        Map<Id, Fleet_B2BCustomerUpdateModel> eccUpdateMap = new Map<Id, Fleet_B2BCustomerUpdateModel>();

        for( Account newObj : newMap.values())
        {
            if (newObj.RecordTypeId == b2bRT)
            {
                //---Reference to the Old Object
                Account oldObj = oldMap.get( newObj.Id);
                
                //---Build a new JSON Model
                Fleet_B2BCustomerUpdateModel eccUpdate = new Fleet_B2BCustomerUpdateModel();
       
                //---Compare the New Obj and Old Obj for changes
                Boolean hasECCChanges = eccUpdate.buildFromAccount(oldObj, newObj);
    
                //---If there are changes, save to the Update Map
                if (hasECCChanges) eccUpdateMap.put(newObj.Id, eccUpdate);
            }
        }

        if (eccUpdateMap.values().size() > 0) processECCUpdates(eccUpdateMap);
    }

    //---Process the list of Accounts to send to ECC
    public static void processECCUpdates(Map<Id, Fleet_B2BCustomerUpdateModel> eccUpdateMap)
    {
        System.debug( lprefix + 'Account-processECCUpdates - On the following updates:' + eccUpdateMap);

        final String ACCOUNT_STATUS_CUSTOMER = 'Customer';
        //final String ACCOUNT_STATUS_CLOSED = 'Closed';
       // final String CLOSED_ACCOUNT_OWNER = 'Gautam Pai'; 
       // final String CLOSED_ACCOUNT_FLEET_SPECIALIST = 'Chelsey Lupeski'; 
        List<UpdateModelHolder> verifiedEccUpdateList = new List<UpdateModelHolder>();
        List<Fleet_Closed_Account__mdt> closeAccMetadata = Fleet_Closed_Account__mdt.getAll().values();
        boolean textField = null;
        List<String> lstCloseAccountOwner = closeAccMetadata[0].Fleet_Closed_Acc_Owner__c.split(',');
        List<String> lstCloseAccountSpecialist = closeAccMetadata[0].Fleet_Closed_Acc_Specialist__c.split(',');
        
        //---For all the ECC Update records, get the SAP number and confirm Account Status (NOTE: not all will be found)
        for (Account accRow : [SELECT Id,owner.name,Fleet_Account_Status__c, ECC_Account_Number__c,WelcomeEmailSent__c, Fleet_Specialist__c, Fleet_Specialist__r.Fleet_ECC_Key__c FROM Account WHERE Id in :eccUpdateMap.keySet() and ECC_Account_Number__c != null and ((owner.name IN : lstCloseAccountOwner  AND Fleet_Specialist__r.name IN : lstCloseAccountSpecialist AND Fleet_Account_Status__c = :closeAccMetadata[0].Fleet_Closed_Acc_Status__c) OR Fleet_Account_Status__c = :Fleet_Values.ACCOUNT_STATUS_CUSTOMER)])
        {
            //---Find the corresponding acct
            Fleet_B2BCustomerUpdateModel eccUpdate = eccUpdateMap.get(accRow.Id);

            if (eccUpdate != null)  //---This should always return a valid EccUpdate record
            {
                //---Add the SAP number and put on list to process
                eccUpdate.eccId = Fleet_B2BCustomerService.getECCIdPadded( accRow.ECC_Account_Number__c);

                //---Get the Fleet Specialist ECC Key from the User table
                if (eccUpdate.accountManager != null)
                {
                    if (accRow.Fleet_Specialist__c != null && accRow.Fleet_Specialist__r.Fleet_ECC_Key__c != null)
                    {
                        eccUpdate.accountManager = accRow.Fleet_Specialist__r.Fleet_ECC_Key__c; //---Reading Key from User field                        
                    }
                    else 
                    {
                        //---Cannot find the User Key, mark the Account Manager as empty
                        eccUpdate.accountManager = null;
                    }
                }

                UpdateModelHolder updateModelH = new UpdateModelHolder();
                updateModelH.accountSfId = accRow.Id;
                updateModelH.model = eccUpdate;

                verifiedEccUpdateList.add( updateModelH);
            }
        }

        //---Records in this list have changes in the specified fields, and have been enriched with SAP number
        if (verifiedEccUpdateList.size() > 0)
        {
            List<Int_Message__c> messageList = new List<Int_Message__c>();

            //---Build an Int Message for all messages
            for( UpdateModelHolder eccUpdateHolder : verifiedEccUpdateList)
            {
                Int_Message__c newMsg = new Int_Message__c();
                newMsg.Type__c = Int_Values.TYPE_ACCOUNT_ECC;
                newMsg.Object_Type__c = 'Account';
                newMsg.RecordId__c = eccUpdateHolder.accountSfId;
                newMsg.Status__c = Int_Values.STATUS_PENDING;
                newMsg.Payload__c = eccUpdateHolder.model.getJson();

                messageList.add( newMsg);
            }

            insert messageList;

            System.debug( lprefix + 'Created the following Int_Messages to send: ' + messageList);

            //---Get the list of created in messages
            List<Id> messageIdList = new List<Id>();
            for( Int_Message__c mRow : messageList) messageIdList.add( mRow.Id);

            //---Call the Asynch Update
            Fleet_ECCService.sendMessges(messageIdList);
        }
    }

    //---Send outbound message on first synch
    public static void sendOutboundForAccountECCSynch(Account updateAccount)
    {
        System.debug( lprefix + 'This is the first synch for Account:' + updateAccount.Id + ' sending Account Notes update: ' + updateAccount);

        //---Send initial synch updates back to ECC
        Fleet_B2BCustomerUpdateModel eccUpdate = new Fleet_B2BCustomerUpdateModel();
        eccUpdate.buildFromAccount(new Account(), updateAccount);  //---Send a blank Account as the intital record so all fields on updateAccount will be sent
   
        Map<Id, Fleet_B2BCustomerUpdateModel> updateMap = new Map<Id, Fleet_B2BCustomerUpdateModel>();
        updateMap.put(updateAccount.Id, eccUpdate);

        processECCUpdates(updateMap);
    }

    public static void processContactCommunityUsers(Map<Id, Account> oldMap, Map<Id, Account> newMap, Set<Id> sendEmailAccountIdList) {
        String APPLICATION_STATUS = 'Approved';
        // Set up email util
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        if (emailSettings == null) System.debug('FLEET_EMAIL_SETTINGS__C MUST BE CONFIGURED TO SEND EMAILS');

        String fromAddress = emailSettings.Fleet_CashAppWelcomeFromEmail__c;
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :fromAddress];
        String templateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_WelcomeCashAppAcceptedEmail__c);

        Set<Id> accountEmailSet = new Set<Id>();

        List<Account> accountsToCheck = [SELECT Id, AT_Customer__c, Welcome_Email_Triggered__c, ECC_Account_Number__c,WelcomeEmailSent__c, Fleet_Application_Type__c,Selected_State__c, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name,Fleet_Business_Located__c FROM Account WHERE Id IN :sendEmailAccountIdList];
        System.debug('------Proccess Community Users------');
        System.debug(sendEmailAccountIdList);
        
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();

        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();

        //---When an account has received an SAP #, invite Primary Contact to community
        for( Account newObj : newMap.values())
        {

            //---Reference to the Old Object
            Account oldObj = oldMap.get( newObj.Id);

            //---Confirm logic for when Fleet_Primary_Contact Community User should be created 
            if (oldObj.ECC_Account_Number__c == null &&
                newObj.ECC_Account_Number__c != null &&                 
                newObj.Fleet_Application_Type__c == 'Non-Credit' && 
                newObj.RecordTypeId == b2bRT) {

                //---Checks for the update to be in the sendEmailAccountIdList in order to create the contact
                if(sendEmailAccountIdList.contains(newObj.id))
                    {
                        // Get account with additonal fields for the email
                        Account emailAccount;
                        for(Account acct: accountsToCheck){
                            if(newObj.id == acct.id){
                                emailAccount = acct;
                            }
                        }
                        System.debug('====> account detail:' + emailAccount);
                        if(emailAccount != null){
                            // Send non-credit application email
                            if(newObj.SAP_Created_Date__c ==System.today() && newObj.Fleet_AR_App_Status__c == APPLICATION_STATUS){
                                Fleet_AccountEmailUtil.sendNonCreditAppAcceptedWelcomeEmail(emailSettings, newObj.id, emailAccount, owaList, templateId);
                            }
                            accountEmailSet.add(newObj.id);
                        }
                        
                        // Set list of community users to be created
                        if(newObj.Fleet_Primary_Contact__c != null){
                            contactIdSet.add(newObj.Fleet_Primary_Contact__c);
                            accountIdSet.add(newObj.Id);
                        }
                        
                    }
            // Create community user for credit users    
            } else if (newObj.RecordTypeId == b2bRT && 
                        //newObj.Fleet_Account_Approval_Emails_Sent__c == false && 
                        newObj.ECC_Account_Number__c != null && 
                        newObj.ECC_Account_Number__c != '' && 
                        newObj.Credit_Limit__c > 0) {
                if(sendEmailAccountIdList.contains(newObj.id))
                    {
                        contactIdSet.add(newObj.Fleet_Primary_Contact__c);
                        accountIdSet.add(newObj.Id);
                    }

            }
        }
        
        if(accountEmailSet.size() > 0){
            Fleet_AccountEmailUtil.updateApprovalEmailSentFlag(accountEmailSet);
        }

        // Checks setting to determine if it should create users, if not it will return and the users wont be created
        if (!Fleet_SettingUtil.getSettingBooleanValue(Fleet_Values.SETTING_FLEET_AUTO_CREATE_COMMUNITY_USERS))
        {
            System.debug( lprefix + Fleet_Values.SETTING_FLEET_AUTO_CREATE_COMMUNITY_USERS + ' is not set, not automatically creating Community Users');
            return;
        }

        //---Convert Contacts to Community Users
        if (contactIdSet.size() > 0) {
            System.debug( lprefix + 'Contacts to convert:' + contactIdSet);
            Fleet_CommunityUserBuilder.convertContactToCommunityUser(contactIdSet);
        }
    }

    //---Check for changes that are to be sent to ECC, build a Model Object for each one
    public static void processEmailsForApplicationApproval(Map<Id, Account> oldMap, Map<Id, Account> newMap)
    {   
        system.debug('I am running');
        String APPLICATION_STATUS = 'Approved';

        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        System.debug( lprefix + 'processEmailsForApplicationApproval: - START');
       
        // Set up email util
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        if (emailSettings == null) System.debug('FLEET_EMAIL_SETTINGS__C MUST BE CONFIGURED TO SEND EMAILS');

        // get information for sendCreditAppAcceptedEmail
        String fromAddress = emailSettings.Fleet_CreditAppAcceptFromEmail__c;
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :fromAddress];
        String templateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_CreditApplicationAcceptedEmail__c);

        // get information for endCreditAppAcceptedWelcomeEmail
        String welcomeFromAddress = emailSettings.Fleet_CreditAppWelcomeFromEmail__c;
        String welcomeTemplateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_WelcomeCreditAppAcceptedEmail__c);
        List<OrgWideEmailAddress> welcomeOwaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :welcomeFromAddress];

        // List<PermissionSetAssignment> sfAdmins = [SELECT Assignee.Email FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Fleet_Business_Administrator'];
                
        Set<Id> sendEmailAccountIdList = new Set<Id>();
        List<Id> accountsToCheckList = new List<Id>();
        List<Account> accountsToCheck = new List<Account>();
        System.debug('newMap.values():' + newMap.values());
        // Get a list of all accounts that qualify to have the email sent
        for( Account newObj : newMap.values())
        {
             System.debug('RecordTypeId:' + newObj.RecordTypeId);
             System.debug('b2bRT:' + b2bRT);
            System.debug('b2bRT:' + newObj.Id);
            System.debug('Fleet_Account_Approval_Emails_Sent__c:' + newObj.Fleet_Account_Approval_Emails_Sent__c);
            System.debug('ECC_Account_Number__c:' + newObj.ECC_Account_Number__c);
            System.debug('Credit_Limit__c:' + newObj.Credit_Limit__c);
            //---Only act on B2B Record Type
            if (newObj.RecordTypeId == b2bRT && 
                ((newObj.Fleet_Account_Approval_Emails_Sent__c == false && newObj.Fleet_Account_Status__c =='Customer')
                || (newObj.Fleet_Account_Approval_Emails_Sent__c == true && newObj.Fleet_Account_Status__c =='Customer'
                    && newObj.Fleet_Account_Status__c != oldMap.get(newObj.Id).Fleet_Account_Status__c)) &&
                newObj.ECC_Account_Number__c != null && 
                newObj.ECC_Account_Number__c != '' && 
                newObj.Credit_Limit__c > 0)
            {
                System.debug('Account Found:' + newObj);
                accountsToCheckList.add(newObj.id);
            }
        }
        

        accountsToCheck = [SELECT Id,AT_Customer__c,Welcome_Email_Triggered__c,SAP_Created_Date__c,Fleet_AR_App_Status__c,Fleet_Credit_App_Status__c,Fleet_Account_Approval_Emails_Sent__c,ECC_Account_Number__c,WelcomeEmailSent__c,Selected_State__c,FLEET_MANAGER_SALES__c, RecordTypeId,Fleet_Application_Type__c, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name,Fleet_Business_Located__c, ShippingPostalCode FROM Account WHERE Id IN :accountsToCheckList];//Added Shipping Code
        

        // Check the list of account against the oldMap to make sure the ECC_Account_Number__c was blank before ensuring this was an inital record sync
        if(accountsToCheck.size() > 0){
            for(Account acct: accountsToCheck){
                if (acct.RecordTypeId != b2bRT) continue;
            
                Account oldAccount = oldMap.get(acct.id);
                if(oldAccount.Credit_Limit__c == null || oldAccount.Credit_Limit__c > 0){      
                       
                    System.debug(acct.Fleet_Application_Type__c);

                    // Send emails once the account has synced
                   if (acct.Fleet_Application_Type__c == APPLICATION_TYPE_CREDIT && acct.Fleet_Credit_App_Status__c == APPLICATION_STATUS && 
                        ((acct.Fleet_Credit_App_Status__c == oldAccount.Fleet_Credit_App_Status__c || acct.Fleet_Application_Type__c == oldAccount.Fleet_Application_Type__c) || 
                         (oldAccount.Fleet_Application_Type__c != APPLICATION_TYPE_CREDIT || oldAccount.Fleet_Credit_App_Status__c != APPLICATION_STATUS))) {                   
                        System.debug('Send Credit App Emails');              
                        Fleet_AccountEmailUtil.sendCreditAppAcceptedEmail(emailSettings, acct.id, null, acct, owaList, templateId); // removed sfAdmins
                        sendEmailAccountIdList.add(acct.id); 
                    }
                    if(acct.SAP_Created_Date__c >= System.today().addDays(-1*Integer.valueOf(Label.ECC_Mulesoft_QA_Delayy)) && acct.Fleet_AR_App_Status__c == APPLICATION_STATUS){
                        Fleet_AccountEmailUtil.sendCreditAppAcceptedWelcomeEmail(emailSettings, acct.id, acct, welcomeOwaList, welcomeTemplateId);
                    }
                        //sendEmailAccountIdList.add(acct.id); 
                   // }
                    /*else if (acct.Fleet_Application_Type__c == APPLICATION_TYPE_NONCREDIT) {
                        System.debug('Send Non Credit App Email'); 
                        Fleet_AccountEmailUtil.sendNonCreditAppAcceptedWelcomeEmail(emailSettings, acct.id);
                    }*/

                }
            }

            
            

            // set a future method to update the Fleet_Account_Approval_Emails_Sent__c field to true
            if(sendEmailAccountIdList.size() > 0){
                // Create users for Community now that emails have been sent
                processContactCommunityUsers(oldMap, newMap, sendEmailAccountIdList); 
                System.debug('account to update:');
                if(System.IsBatch() == false && System.isFuture() == false){ 
                    Fleet_AccountEmailUtil.updateApprovalEmailSentFlag(sendEmailAccountIdList);
                }
                
            }

        }

        //--Send to Email Util
        //sendEmailAccountIdList

        System.debug( lprefix + 'processEmailsForApplicationApproval: - END');
    }


    public class UpdateModelHolder {
        public Fleet_B2BCustomerUpdateModel model;
        public String accountSfId;
    }
    
    // Support sending out the link for non-credit accounts
    public static void checkForNonCreditCommunityUsers(Map<Id, Account> oldMap, Map<Id, Account> newMap){

        Set<id> accountsToCreateContacts = new Set<id>();
        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();

        for( Account newObj : newMap.values())
        {
             if (newObj.RecordTypeId == b2bRT)
            {
                if(newObj.Fleet_Application_Type__c == APPLICATION_TYPE_NONCREDIT){
                    accountsToCreateContacts.add(newObj.id);
                }
            }
        }

        if(accountsToCreateContacts.size() > 0){
            processContactCommunityUsers(oldMap, newMap, accountsToCreateContacts); 
        }   

    }
      
     // Update welcome email checkbox to false 
    public static void updateWelcomeCheckATCustomerCheck(Map<Id, Account> oldMap, Map<Id, Account> newMap){
        List<Account> lstAccounts = New List<Account>();
        List<Opportunity> lstOpportunities = New List<Opportunity>();
        Set<String> setCreditNames = New Set<String>();
        Map<String,Account> mapAccounts = New Map<String,Account>();
        for(Credit_Hold_for_Re_Trigger_Welcome_Email__mdt credit : [SELECT Id,Label,MasterLabel FROM Credit_Hold_for_Re_Trigger_Welcome_Email__mdt]){
            String creditNm = credit.Label.trim();
            creditNm = creditNm.toLowerCase();
            setCreditNames.add(creditNm);
        }
         for( Account newObj : newMap.values()){ 
             if(newObj.Fleet_Application_Type__c != oldMap.get(newObj.id).Fleet_Application_Type__c && oldMap.get(newObj.id).Fleet_Account_Status__c =='Customer' && newObj.Fleet_Account_Status__c != oldMap.get(newObj.id).Fleet_Account_Status__c){
                 lstAccounts.add(New Account(id=newObj.Id,WelcomeEmailSent__c=false));
             }else if(newObj.ECC_Billing_Block_Sale_Area__c!= null  && oldMap.get(newObj.id).Fleet_Account_Status__c =='Customer' && newObj.Fleet_Account_Status__c != oldMap.get(newObj.id).Fleet_Account_Status__c){
                 String creditHold = newObj.ECC_Billing_Block_Sale_Area__c.trim();
                 creditHold = creditHold.toLowerCase();
                 if(setCreditNames.contains(creditHold)){
                     lstAccounts.add(New Account(id=newObj.Id,WelcomeEmailSent__c=false));
                 }
             }
             if(newObj.AT_Customer__c != oldMap.get(newObj.id).AT_Customer__c || newObj.DT_Customer__c != oldMap.get(newObj.id).DT_Customer__c){
                 mapAccounts.put(newObj.Id,newObj);
             }
         }
        if(mapAccounts.size()>0){
            for(Opportunity objOpp :[SELECT Id,AT_Customer__c,DT_Customer__c,AccountId FROM Opportunity WHERE AccountId IN : mapAccounts.keySet()]){
                objOpp.AT_Customer__c = mapAccounts.get(objOpp.AccountId).AT_Customer__c;
                objOpp.DT_Customer__c = mapAccounts.get(objOpp.AccountId).DT_Customer__c;
                lstOpportunities.add(objOpp);
            }
        }
        if(!lstAccounts.isEmpty()){
            Update lstAccounts;
        }
        if(!lstOpportunities.isEmpty()){
            Update lstOpportunities;
        }
    }
    
    public static void handleDeclinedAccounts(List<Account> Acc) {
        System.debug(lprefix + 'handleDeclinedAccounts() ENTRY');
    
       Fleet_AccountEmailUtil.send7thDayCreditAppDeclinedEmail(Acc);
    
        System.debug(lprefix + 'handleDeclinedAccounts() EXIT');
	}


}