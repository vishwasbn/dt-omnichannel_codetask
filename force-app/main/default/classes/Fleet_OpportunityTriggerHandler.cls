public class Fleet_OpportunityTriggerHandler {
    //public static final String lprefix = 'FLEET_OTH:';
    //public static final String OPPORTUNITY_STAGE_CLOSEDWON = 'Closed Won';
    //public static final String ACCOUNT_STATUS_PROSPECT = 'Prospect';

    //-- DISABLING TRIGGER UNTIL WE HAVE A SAFER SOLUTION ------------------------------------------------
    //public static Boolean suspendTrigger = true;

    //---Primary Opportunity Trigger Handler for Fleet
    public static void handle(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, System.TriggerOperation triggerEvent )
    {
        //-- NO LONGER USED -------------------------
        
        
        
        
        
        
        
        // System.debug( lprefix + 'Fleet OpportunityTrigger Handler - START');

        // if (suspendTrigger) {
        //     System.debug( lprefix + ' ------ Trigger Handler Suspended-------- ');
        // } else {

             switch on triggerEvent {
               //  when AFTER_INSERT {
             //        updateATCustomerOnAccount();
            //     }
                 when AFTER_UPDATE {
                     updateATCustomerOnAccount(oldMap, newMap);
                 }
        //         when else {
        //             //do nothing 
        //         }
             }
        // }
        // System.debug( lprefix + 'Fleet OpportunityTrigger Handler - END');
    }

    //--DTFS-391 - Process before change for Opportunity update, update updated fields on Account:
    //     Customer Type, Primary Contact, Application Type
    /**
    public static void processBeforeOpportunityUpdate(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        Id b2bRT = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        System.debug( lprefix + '     ORG Opportnity B2B record type=' + b2bRT);

        List<Opportunity> b2bOpportunityList = new List<Opportunity>();

        System.debug( lprefix + 'processBeforeOpportunityUpdate() ENTRY - Processing the following Opportunities: ' + newMap);
        
        //---Loop through the changed records
        for( Opportunity newObj : newMap.values()) {

            System.debug( lprefix + '     updated Opportunity record type=' + newObj.RecordTypeId + ', new Opp:' +newObj);

            //---Only process the trigger update if opp record type = B2B AND opp is not closed won- DTFS-391
            if (newObj != null && newObj.RecordTypeId == b2bRT && newObj.StageName <> OPPORTUNITY_STAGE_CLOSEDWON) {
                //---Get the Old Record
                Opportunity oldObj = oldMap.get( newObj.Id);
                System.debug( lprefix + '     old Opportunity:' + oldObj);

                Boolean addToList = false;

                if (oldObj != null) {
                    //---act if the Customer_Type__c has changed
                    if (newObj.Customer_Type__c != oldObj.Customer_Type__c) {
                        System.debug( lprefix + '    Found Opportunity with changed Customer_Type__c, Old: ' + oldObj + '  New: ' + newObj);
                        addToList = true;
                    }

                    //---act if the Fleet_Primary_Contact__c has changed
                    if (newObj.Fleet_Primary_Contact__c != oldObj.Fleet_Primary_Contact__c) {
                        System.debug( lprefix + '    Found Opportunity with changed Fleet_Primary_Contact__c, Old: ' + oldObj + '  New: ' + newObj);
                        addToList = true;
                    }

                    //---act if the Application_Type__c has changed
                    if (newObj.Application_Type__c != oldObj.Application_Type__c) {
                        System.debug( lprefix + '    Found Opportunity with changed Application_Type__c, Old: ' + oldObj + '  New: ' + newObj);
                        addToList = true;
                    }

                    if (addToList) {
                        //something has been updated, so add to the list for later bulk processing
                        b2bOpportunityList.add(newObj);
                    }
                }
            }
            System.debug( lprefix + 'processBeforeOpportunityUpdate() Exit ');
        }

        //---Process the Opportunity List
        if (b2bOpportunityList.size() > 0)
        {
            //get map of accounts related to the opportunities
            Map<Id, Account> accountMap = buildAccountMap(b2bOpportunityList);
            List<Account> accountsToUpdate = new List<Account>();

            //loop through list of updated Opportunities and update fields on related Acount 
            for( Opportunity opp : b2bOpportunityList)
            {
                Account updateAccount = accountMap.get(opp.AccountId);

                //DTFS-391 - Only push these values from Opp to Acct on update while  Account is status = Prospect.
                if (updateAccount.Fleet_Account_Status__c == ACCOUNT_STATUS_PROSPECT ) {
                    updateAccount.Fleet_Customer_Type__c = opp.Customer_Type__c;
                    updateAccount.Fleet_Primary_Contact__c = opp.Fleet_Primary_Contact__c;
                    updateAccount.Fleet_Application_Type__c = opp.Application_Type__c;

                    System.debug( lprefix + '    adding updated account to list for bulk update, account: ' + updateAccount);
                    //add updated account to accountsToUpdate List for bulk update
                    accountsToUpdate.add(updateAccount);
                } else {
                    System.debug( lprefix + '    NOT updating account because status must be prospect, status=' + updateAccount.Fleet_Account_Status__c + ', account: ' + updateAccount);
                }
            }

            //update account records
            System.debug( lprefix + '    Accounts about to be updated from updated Opportunities: ' + accountsToUpdate);
            if (accountsToUpdate.size() > 0) update accountsToUpdate;
        }
    }

    public static Map<Id, Account> buildAccountMap (List<Opportunity> opportunities) {
            //loop through the opportunities and build a list of Account IDs
            List<Id> accountIds = new List<Id>();
            for( Opportunity oRow : opportunities) {
                accountIds.add(oRow.AccountId);
            }
            System.debug( lprefix + 'buildAccountMap() - Acquired account Ids for Opportunities:' + accountIds);
            
            // Retreive the accounts
            List<Account> accountsToUpdate = [SELECT Id, Fleet_Primary_Contact__c, Fleet_Customer_Type__c, Fleet_Application_Type__c, Fleet_Account_Status__c 
                                              FROM Account WHERE Id in :accountIds];
            System.debug( lprefix + '  Acquired accounts: ' + accountsToUpdate);

            //build map from list of accounts for fast access
            Map<Id, Account> accountMap = new Map<Id, Account>();
            for( Account aRow : accountsToUpdate) {
                accountMap.put(aRow.Id, aRow);
            }
            System.debug( lprefix + 'buildAccountMap() - return accountMap: ' + accountMap);
            return accountMap;
    }*/
    public static void updateATCustomerOnAccount(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap){
        Map<String,Opportunity> mapOpportunities = New Map<String,Opportunity>();
        List<Account> lstAccounts = New List<Account>();
        for(Opportunity newObj : newMap.values()){ 
            if(newObj.AT_Customer__c != oldMap.get(newObj.id).AT_Customer__c || newObj.DT_Customer__c != oldMap.get(newObj.id).DT_Customer__c){
				mapOpportunities.put(newObj.AccountId,newObj);                 
             }
        }
        if(mapOpportunities.size()>0){
            for(Account objAcc :[SELECT Id,AT_Customer__c,DT_Customer__c FROM Account WHERE Id IN : mapOpportunities.keySet()]){
                objAcc.AT_Customer__c = mapOpportunities.get(objAcc.Id).AT_Customer__c;
                objAcc.DT_Customer__c = mapOpportunities.get(objAcc.Id).DT_Customer__c;
                lstAccounts.add(objAcc);
            }    
        }
        if(!lstAccounts.isEmpty()){
            Update lstAccounts;
        }
    }
}