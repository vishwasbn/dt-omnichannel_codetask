public class Fleet_ContactTriggerHandler
{
    public static String lprefix = 'LOG_CTH:';
    public static boolean stopECCCall = false;
    
    //---Primary Contact Trigger Handler for Fleet
    public static void handle(Map<Id, Contact> oldMap, Map<Id, Contact> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug( lprefix + 'Fleet Contact Trigger Handler - START');

        switch on triggerEvent {

            when AFTER_INSERT 
            {                
                if (!Fleet_ECCService.disableECCCallout() && !Fleet_ContactTriggerHandler.stopECCCall) processNewContactForECC(newMap, false);
            }
            when AFTER_UPDATE 
            {
                if (!Fleet_ECCService.disableECCCallout() && !Fleet_ContactTriggerHandler.stopECCCall) processChangesforECC(oldMap, newMap);  
                // Checks for changes on the contact Is Fleet Community Manager and updates the user record permission set
                communityUserManagerCheck(oldMap, newMap);
                
                sendSurvey(oldMap, newMap);     
            }
            when BEFORE_DELETE
            {
                if (!Fleet_ECCService.disableECCCallout()) processDeleteContactForECC(oldMap);
                
            }
            when else {
                
            }
        }

        System.debug( lprefix + 'Fleet Contact Trigger Handler - END');
    }

    //---Check for changes that are to be sent to ECC, build a Model Object for each one
    public static void processChangesforECC(Map<Id, Contact> oldMap, Map<Id, Contact> newMap)
    {
        Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();
        Map<Id, Fleet_B2BCustomerUpdateModel> eccUpdateMap = new Map<Id, Fleet_B2BCustomerUpdateModel>();

        List<Contact> contactsToUpdateList = new List<Contact>();

        for( Contact newObj : newMap.values())
        {
            Contact oldObj = oldMap.get( newObj.Id);
            
            Fleet_B2BCustomerUpdateModel eccUpdate = new Fleet_B2BCustomerUpdateModel();
            Fleet_B2BCustomerUpdateModel.ModelBuildStatus modelStatus = eccUpdate.buildFromContact(oldObj, newObj);

            Boolean hasECCChanges = modelStatus.hasChanges;
            
            //---Check if it is a B2B Record Type, and if there are ECC Changes
            if (newObj.RecordTypeId == b2bRT)
            {
                if (hasECCChanges)
                {
                    eccUpdateMap.put(newObj.Id, eccUpdate); 
                }

                //---Under special situations, need to update field after the Trigger
                if (modelStatus.eccPendingFields != null && modelStatus.eccPendingFields != oldObj.ECC_Pending_Fields__c)
                {
                    Contact updateContact = new Contact( Id=newObj.Id);
                    updateContact.ECC_Pending_Fields__c = modelStatus.eccPendingFields;

                    System.debug( lprefix + 'Writing back to the Contact Object: ' + updateContact);

                    contactsToUpdateList.add( updateContact);
                }
            } 
        }

        if (eccUpdateMap.values().size() > 0) processECCUpdates(eccUpdateMap, false);

        if (contactsToUpdateList.size() > 0)
        {
            System.debug( lprefix + 'Fields need to be updated, make sure that this does not create a feedback loop, Writing back to the Contact Object: ' + contactsToUpdateList);
            update contactsToUpdateList;
        }
    }

    //--- Create new contact and send it out to ECC
    public static void processNewContactForECC(Map<Id, Contact> newMap, Boolean useQueue)
    {     
        Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();
        Map<Id, Fleet_B2BCustomerUpdateModel> eccUpdateMap = new Map<Id, Fleet_B2BCustomerUpdateModel>();
        
        List<Contact> contactsToUpdateList = new List<Contact>();

        for( Contact newObj : newMap.values())
        {
            System.debug(newMap);
            Fleet_B2BCustomerUpdateModel eccUpdate = new Fleet_B2BCustomerUpdateModel();
            Fleet_B2BCustomerUpdateModel.ModelBuildStatus modelStatus = eccUpdate.buildFromNewContact(newObj);

            //---Check if it is a B2B Record Type, and if there are ECC Changes
            if (newObj.RecordTypeId == b2bRT)
            {
                String eccCreateValues = Fleet_B2BCustomerUpdateModel.getNewContactCreateValues( newObj);

                eccUpdateMap.put(newObj.Id, eccUpdate); 

                //---Under special situations, need to update field after the Trigger
                if (eccCreateValues != null)
                {
                    Contact updateContact = new Contact( Id=newObj.Id);
                    updateContact.ECC_Create_Values__c = eccCreateValues;
                    updateContact.ECC_Pending_Fields__c = modelStatus.eccPendingFields;

                    System.debug( lprefix + 'Writing back to the Contact Object: ' + updateContact);

                    contactsToUpdateList.add( updateContact);
                }
            } 
        }
        if (eccUpdateMap.values().size() > 0) processECCUpdates(eccUpdateMap, useQueue);

        if (contactsToUpdateList.size() > 0)
        {
            System.debug( lprefix + 'Fields need to be updated, make sure that this does not create a feedback loop, Writing back to the Contact Object: ' + contactsToUpdateList);
            update contactsToUpdateList;
        }
    }

    //---Process a contact delete from Salesforce to ECC
    public static void processDeleteContactForECC(Map<Id, Contact> deleteContactMap)
    {
        Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();
        Map<Id, Fleet_B2BCustomerUpdateModel> eccDeleteMap = new Map<Id, Fleet_B2BCustomerUpdateModel>();      

        System.debug(deleteContactMap);
        for( Contact deleteContact : deleteContactMap.values())
        {
            if (deleteContact.RecordTypeId == b2bRT)
            {

                System.debug('Delete Contact: ' + deleteContact);
                Fleet_B2BCustomerUpdateModel eccDelete = new Fleet_B2BCustomerUpdateModel();
                Boolean hasECCContactId = eccDelete.buildDeleteContact(deleteContact);

                //---Check if it is a B2B Record Type, and if the contact can be deleted in SAP
                if (hasECCContactId)
                {
                    eccDeleteMap.put(deleteContact.Id, eccDelete); 
                }  

            }

                                  
        }
        System.debug('Delete Contacts map: ' + eccDeleteMap);
        if (eccDeleteMap.values().size() > 0) processECCUpdates(eccDeleteMap, false);
        
    }

    //---Process the list of Accounts to send to ECC
    public static void processECCUpdates(Map<Id, Fleet_B2BCustomerUpdateModel> eccUpdateMap, Boolean useQueue)
    {
        List<UpdateModelHolder> verifiedEccUpdateList = new List<UpdateModelHolder>();
        System.debug('proccess updates');
        System.debug(eccUpdateMap);
        //---For all the ECC Update records, get the SAP number and confirm Account Status (NOTE not all will be found)
        for (Contact contactRow : [SELECT Id, Account.ECC_Account_Number__c FROM Contact WHERE Id in :eccUpdateMap.keySet() and Account.ECC_Account_Number__c != null and Account.Fleet_Account_Status__c = :Fleet_Values.ACCOUNT_STATUS_CUSTOMER])
        {
            System.debug('contact:' + contactRow);
            //---Find the corresponding acct
            Fleet_B2BCustomerUpdateModel eccUpdate = eccUpdateMap.get(contactRow.Id);

            if (eccUpdate != null)  //---This should always return a valid EccUpdate record
            {
                //---Add the SAP number and put on list to process
                eccUpdate.eccId = Fleet_B2BCustomerService.getECCIdPadded( contactRow.Account.ECC_Account_Number__c);

                UpdateModelHolder updateHolder = new UpdateModelHolder();
                updateHolder.model = eccUpdate;
                updateHolder.contactSfId = contactRow.Id;

                verifiedEccUpdateList.add( updateHolder);
            }
        }

        //---Records in this list have changes in the specified fields, and have been enriched with SAP number
        if (verifiedEccUpdateList.size() > 0)
        {
            List<Int_Message__c> messageList = new List<Int_Message__c>();

            String groupKey = Int_Values.createGUID();

            //---Build an Int Message for all messages
            for( UpdateModelHolder eccUpdateH : verifiedEccUpdateList)
            {
                Int_Message__c newMsg = new Int_Message__c();
                newMsg.Type__c = Int_Values.TYPE_CONTACT_ECC;
                newMsg.Object_Type__c = 'Contact';
                newMsg.RecordId__c = eccUpdateH.contactSfId;
                newMsg.Status__c = useQueue ? Int_Values.STATUS_QUEUED : Int_Values.STATUS_PENDING;
                newMsg.Payload__c = eccUpdateH.model.getJson();
                newMsg.Group_Key__c = groupKey;

                messageList.add( newMsg);
            }

            insert messageList;

            System.debug( lprefix + 'Created the following Int_Messages to send: ' + messageList);

            //---Get the list of created in messages
            List<Id> messageIdList = new List<Id>();
            for( Int_Message__c mRow : messageList) messageIdList.add( mRow.Id);

            //---If not putting in the Queue
            if (!useQueue)
            {
                //---Call the Asynch Update
                Fleet_ECCService.sendMessges(messageIdList);
            }
        }
    }

    //---Send an outbound message for a Contact that has just been synched with ECC
    public static void sendOutboundForContactECCSynch(Contact updatedContact)
    {
        Map<Id, Fleet_B2BCustomerUpdateModel> eccUpdateMap = new Map<Id, Fleet_B2BCustomerUpdateModel>();
        Fleet_B2BCustomerUpdateModel eccUpdate = new Fleet_B2BCustomerUpdateModel();
        eccUpdate.buildFromPendingContact(updatedContact);

        System.debug( lprefix + 'Built the following model for sending outbound update ' + updatedContact);
        eccUpdateMap.put(updatedContact.Id, eccUpdate); 

        processECCUpdates(eccUpdateMap, false);
    }

    //---Send an outbound message for all contacts when an Account has been synched with ECC
    public static void sendOutboundForAccountECCSynch(Id accountId)
    {
        System.debug( lprefix + 'This is the first synch for Account:' + accountId + ' sending any preexsiting Contacts');

        Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();

        //---Get the current list of Contacts
        List<Contact> contactList = [SELECT Id, FirstName, LastName, Phone,Phone_Extension__c,Is_Alternate_Contact__c,Send_Invoice_Receipt__c, Title, Email, ECC_Contact_Person_Id__c, ECC_Customer_Reference_Number__c, ECC_Is_Primary_Contact__c,  ECC_Create_Values__c, ECC_Pending_Fields__c, RecordTypeId FROM Contact WHERE AccountId = :accountId AND RecordTypeId = :b2bRT];

        if (contactList != null && contactList.size() > 0)
        {
            System.debug( lprefix + 'On ECC Account synch for ' + accountId + ', found the following preexisting Contacts : ' + contactList);

            Map<Id, Contact> newMap = new Map<Id, Contact>();
            for(Contact cRow : contactList) newMap.put(cRow.Id, cRow);

            processNewContactForECC( newMap, true);  //---Tell downstream methods to use Queued
        }
        else 
        {
            System.debug( lprefix + 'No preexisting Contacts found for the Account when the ECC Account synch is initiated for Account: ' + accountId);
        }
    }

    public class UpdateModelHolder {
        public Fleet_B2BCustomerUpdateModel model;
        public String contactSfId;
    }
    
    public static void sendSurvey(Map<Id, Contact> oldMap, Map<Id, Contact> newMap)
    {
        for(Contact rec : newMap.values())
        {
            if(rec.Exit__c && oldMap.get(rec.Id).Exit__c == false)
                InmomentAPIUtility.sendSurvey(rec.Id, '3', 'Exit');
            if(rec.Onboarding__c && oldMap.get(rec.Id).Onboarding__c == false)
                InmomentAPIUtility.sendSurvey(rec.Id, '1', 'Onboarding');
            if(rec.Post_Visit__c && oldMap.get(rec.Id).Post_Visit__c == false)
                InmomentAPIUtility.sendSurvey(rec.Id, '4', 'Post Visit');
            if(rec.Relationship__c && oldMap.get(rec.Id).Relationship__c == false)
                InmomentAPIUtility.sendSurvey(rec.Id, '2', 'Relationship');
        }
    }

    // Check for community contact manager assignment check and updates user record
    public static void communityUserManagerCheck(Map<Id, Contact> oldMap, Map<Id, Contact> newMap){

        Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();

        System.debug('---Start Community Manager Check---');
        System.debug('old: '+ oldMap);
        System.debug('new: '+ newMap);

        Set<Contact> contactsToCheck = new Set<Contact>();
        Set<id> contactsToCheckId = new Set<id>();   

        for( Contact newObj : newMap.values())
        {
            if(newObj.RecordTypeId == b2bRT){
                contactsToCheck.add(newObj);
                contactsToCheckId.add(newObj.id);
            }
        }

        // Only do work if we have at least 1 b2b contact being updated - Keep it fast for everyone else
        if(contactsToCheckId.size() > 0){

        // Get Contact Users
        List<User> usersToCheck = [SELECT id, ContactId FROM User WHERE ContactId IN :contactsToCheckId];        

        Set<User> addPermSet = new Set<User>();
        Set<User> removePermSet = new Set<user>();

        // Get two sets of users 1 to add the perm set and 1 to remove
        for(Contact updatedContact: contactsToCheck){
            // build add perm set 
            if(updatedContact.Is_Fleet_Community_Manager__c == true && Fleet_CommunityUserUtil.checkForActiveContactUser(updatedContact.id,usersToCheck )){
                User addUser = Fleet_CommunityUserUtil.getContactUser(updatedContact.id,usersToCheck);

                if(addUser != null){
                    addPermSet.add(addUser);
                }
                
            // build remove perm set
            }else if(updatedContact.Is_Fleet_Community_Manager__c == false && Fleet_CommunityUserUtil.checkForActiveContactUser(updatedContact.id,usersToCheck )){
                User addUser = Fleet_CommunityUserUtil.getContactUser(updatedContact.id,usersToCheck);

                if(addUser != null){
                    removePermSet.add(addUser);
                }
            }
        }

        if(removePermSet.size() > 0 || addPermSet.size() > 0){

                // Get Permission Set and Assignment for evaluation
                String communityPermissionSetName = Fleet_SettingUtil.getSettingValue(Fleet_Values.SETTING_FLEET_COMMUNITY_USER_PERMISSION_SET);
                PermissionSet permSet = [SELECT id,label FROM permissionset WHERE label = :communityPermissionSetName limit 1]; 
                List<PermissionSetAssignment> psaList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN :usersToCheck AND PermissionSetId=:permSet.Id];

                System.debug('Users to check:' + usersToCheck);
                System.debug('pasList: ' + psaList);

                System.debug('---------');
                System.debug('Add Perm Set: '+ addPermSet);
                System.debug('Remove Perm Set: '+ removePermSet);

                List<id> removeAssignmentList = new List<id>();
                List<id> addAssignmentList = new List<id>();

                // gather all users that need permission sets removed
                if(removePermSet.size() > 0) {
                    for(User removeUser: removePermSet){
                        if(Fleet_CommunityUserUtil.checkForPermissionSetAssigment(removeUser.id, psaList)){
                            removeAssignmentList.add(removeUser.id);
                        }
                    }
                }                

                // gather all users that need permission set added
                if(addPermSet.size() > 0) {
                    for(User addUser: addPermSet){
                        if(!Fleet_CommunityUserUtil.checkForPermissionSetAssigment(addUser.id, psaList)){
                            addAssignmentList.add(addUser.id);
                        }
                    }
                }

                System.debug('-------------');
                System.debug('Add Perm Set assignment: '+ addAssignmentList);
                System.debug('Remove Perm Set assignment: '+ removeAssignmentList);

                // add permissions to selected users
                if(addAssignmentList.size() > 0){
                    Fleet_CommunityUserUtil.addPermissionSets(addAssignmentList,permSet.id);
                }

                // remove permissions from selected users
                if(removeAssignmentList.size() > 0){
                    Fleet_CommunityUserUtil.removePermissionSets(removeAssignmentList,permSet.id);
                }


            }                    

        }        

    }
    
}