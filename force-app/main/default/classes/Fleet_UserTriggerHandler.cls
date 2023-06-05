public class Fleet_UserTriggerHandler
{
    public static String lprefix = 'LOG_UTH:';

    //---Primary Account Trigger Handler for Fleet
    public static void handle(Map<Id, User> oldMap, Map<Id, User> newMap, System.TriggerOperation triggerEvent,List<User> lstNewUsers )
    {
        System.debug( lprefix + 'Fleet UserTrigger Handler - START');

        switch on triggerEvent 
        {
            when AFTER_INSERT 
            {
                validateCommunityUserSetupCorrectly(newMap);
            }
            when BEFORE_INSERT 
            {
                assignCommunityAccountNameId(lstNewUsers);
            }
            when BEFORE_UPDATE 
            {
                assignCommunityAccountNameId(lstNewUsers);
            }
            when AFTER_UPDATE 
            {   
                processChangesforCommunity(oldMap, newMap);      
            }
            
            when else {
                //do nothing 
            }
        }

        System.debug( lprefix + 'Fleet UserTrigger Handler - END');
    }

    //---Process the changes for the User to Contact field copy
    public static void processChangesforCommunity(Map<Id, User> oldMap, Map<Id, User> newMap)
    {   
        if (disableUserTrigger()) return;

        String fieldList = Fleet_SettingUtil.getSettingValue( Fleet_Values.SETTING_USER_TRIGGER_FIELD_LIST);

        if (fieldList == null || fieldList == '')
        {
            System.debug( lprefix + 'No fields found for Setting: ' + Fleet_Values.SETTING_USER_TRIGGER_FIELD_LIST + ' cannot run Trigger');
            return;
        }

        List<String> fieldNameList = fieldList.split(',');

        List<Contact> updateContactList = new List<Contact>();

        for( User newObj : newMap.values())
        {
            //---Reference to the Old Object
            User oldObj = oldMap.get( newObj.Id);

            //---Check that the user is linked to a Contact (Community)
            if (newObj.ContactId != null)
            {
                Logger logInstance = Logger.getInstance();
                logInstance.log('updateContact', 'Fleet_UserTriggerHandler', 'Before updateContact');
                Contact updateContact = new Contact();
                updateContact.Id =  newObj.ContactId;
                logInstance.log('updateContact', 'Fleet_UserTriggerHandler', 'After updateContact',JSON.serialize(updateContact.Id));
                Boolean hasChanges = false;

                for (String fieldName : fieldNameList)
                {
                    if (setTargetObjIfFieldChanged(oldObj, newObj, fieldName, updateContact)) hasChanges = true;
                }

                if (hasChanges) updateContactList.add( updateContact);
            }
        }

        if (updateContactList != null && updateContactList.size() > 0 && !System.isBatch() && !System.isFuture())
        {
            System.debug( lprefix + 'Updating the following Contacts: ' + updateContactList);
            //updateContactFromUserUpdate(JSON.serialize(updateContactList));
            System.enqueueJob(new Fleet_UpdateContactFormUser(updateContactList));
        }
    }
    
    
    @future
    public static void updateContactFromUserUpdate(String updateContactStr)
    {
        Logger logInstance = Logger.getInstance();
        logInstance.log('updateContactList', 'Fleet_UserTriggerHandler', 'Before updateContact');
        List<Contact> updateContactList = (List<Contact>) JSON.deserialize(updateContactStr, List<Contact>.Class);
        System.debug('updateContactList :::::' + updateContactList);
        update updateContactList;
        System.debug('updateContactList :::::' + [SELECT Id, FirstName FROM Contact where id in : updateContactList]);
        logInstance.log('updateContactList', 'Fleet_UserTriggerHandler', 'After updateContact',JSON.serialize(updateContactList));
    }
    

    //---Determine if the automatic ECC callouts should be disabled
    public static Boolean disableUserTrigger()
    {
        Boolean returnValue = false;

        if (Fleet_SettingUtil.getSettingBooleanValue( Fleet_Values.SETTING_USER_TRIGGER_DISABLE))
        {
            System.debug( lprefix + 'Disable user trigger flag is set, preventing logic');
            return true;
        }

        return returnValue;
    }

    //---Set the field on the Update Object, if the value has changed
    public static Boolean setTargetObjIfFieldChanged(SObject oldObj, SObject newObj, String fieldName, SObject targetObj)
    {
        System.debug( lprefix + 'Set Contact field if changed Value:  FieldName:' + fieldName + ' oldObj:' + oldObj + ' newObj:' +  newObj);

        Object oldRef = oldObj.get(fieldName);
        Object newRef = newObj.get(fieldName);

        if (oldRef == null && newRef == null) return false;

        String oldValue = (String)oldRef;
        String newValue = (String)newRef;

        if (newValue == oldValue) return false;

        try 
        {
            targetObj.put(fieldName, newValue);
        } 
        catch (Exception ex) 
        {
            Logger logInstance = Logger.getInstance();
            logInstance.log('Appointments', 'Fleet_UserTriggerHandler', ex);
            String errorMessage = ex.getMessage();
            System.debug( lprefix + 'Error tring to set value on Contact:  FieldName:' + fieldName + ' Value:' + newValue);
        }
        
        return true;
    }

    // Used to make sure Fleet Community Users are setup Correctly
    public static void validateCommunityUserSetupCorrectly(Map<Id, User> newMap){

        System.debug('---Community User After Insert---');
        System.debug(newMap);

        List<User> portalUser = new List<User>();
        List<User> portalUserB2B = new List<User>();
        List<Id> portalUserB2BIds = new List<Id>();
        List<User> addPermSetList = new List<User>();
        List<Id> portalChangeProfile = new List<Id>();
        List<Id> portalUserContactIds = new List<Id>();
        List<Id> portalUserIds = new List<id>();
        Map<String,Contact> mapContacts = New Map<String,Contact>();

        for( User newUser : newMap.values())
        {
            System.debug('Contact Id: '+ newUser.ContactId);
            if(newUser.ContactId != null){
                portalUserIds.add(newUser.id);
                portalUserContactIds.add(newUser.ContactId);
                portalUser.add(newUser);
            }
        }
        System.debug('Portal User Ids: '+portalUserIds);
        
        if(portalUserIds.size() > 0){
            Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();
                        
            List<Contact> portalContacts = [SELECT Id, Is_Fleet_Community_Manager__c,AccountId,Account.Name FROM Contact WHERE id IN:portalUserContactIds AND RecordTypeId = :b2bRT];
            System.debug('Portal Contacts: ' +portalContacts);
            
            if(portalContacts.size() > 0){
                for(Contact portalContact: portalContacts){
                    mapContacts.put(portalContact.Id,portalContact);
                    User addUser = Fleet_CommunityUserUtil.getContactUser(portalContact.id, portalUser);
                    if(addUser != null){
                        portalUserB2B.add(addUser);
                        portalUserB2BIds.add(addUser.Id);
                        if(portalContact.Is_Fleet_Community_Manager__c){
                            addPermSetList.add(addUser);
                        }
                    }
                }
               
                List<Profile> commmunityProfile = [SELECT id, Name FROM Profile WHERE Name = 'Fleet Customer Community User' Limit 1];                

                Id communityProfileId = commmunityProfile[0].Id;

                if(portalUserB2B.size() > 0){
                    for(User usr: portalUserB2B){
                        if(usr.ProfileId != communityProfileId){
                            portalChangeProfile.add(usr.id);
                        }
                    }
                }

                if(portalChangeProfile.size() > 0){
                    Fleet_CommunityUserUtil.setProfile(portalChangeProfile, communityProfileId);
                }



                // Add permission set if the manager permisison set was selected
                if(addPermSetList.size() > 0){
                    
                    // Get Permission Set and Assignment for evaluation
                    String communityPermissionSetName = Fleet_SettingUtil.getSettingValue(Fleet_Values.SETTING_FLEET_COMMUNITY_USER_PERMISSION_SET);
                    PermissionSet permSet = [SELECT id,label FROM permissionset WHERE label = :communityPermissionSetName limit 1]; 
                    List<PermissionSetAssignment> psaList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN :portalUserB2BIds AND PermissionSetId=:permSet.Id];
    
                    System.debug('Users to check:' + portalUserB2BIds);
                    System.debug('pasList: ' + psaList);
    
                    System.debug('---------');
                    System.debug('Add Perm Set: '+ addPermSetList);

                    List<id> addAssignmentList = new List<id>();
    
                    // gather all users that need permission set added
                    if(addPermSetList.size() > 0) {
                        for(User addUser: addPermSetList){
                            if(!Fleet_CommunityUserUtil.checkForPermissionSetAssigment(addUser.id, psaList)){
                                addAssignmentList.add(addUser.id);
                            }
                        }
                    }
    
                    System.debug('-------------');
                    System.debug('Add Perm Set assignment: '+ addAssignmentList);
    
                    // add permissions to selected users
                    if(addAssignmentList.size() > 0){
                        Fleet_CommunityUserUtil.addPermissionSets(addAssignmentList,permSet.id);
                        
                    }    
    
                }


            } 
            
        }
        for( User newUser : newMap.values())
        {
            System.debug('Contact Id: '+ newUser.ContactId);
            if(newUser.ContactId != null && mapContacts.containsKey(newUser.ContactId)){
                portalUserIds.add(newUser.id);
                portalUserContactIds.add(newUser.ContactId);
                portalUser.add(newUser);
            }
        }
    }
    
    // This is the method to stamp Account Name and Account Id to user for Motorq implementation
    public static void assignCommunityAccountNameId(List<User> lstUsers){
         System.debug('---Community User before Insert---');
       // System.debug(newMap);

        List<Id> portalUserContactIds = new List<Id>();
        Map<String,Contact> mapContacts = New Map<String,Contact>();

        for( User newUser : lstUsers)
        {
            System.debug('Contact Id: '+ newUser.ContactId);
            if(newUser.ContactId != null){
                portalUserContactIds.add(newUser.ContactId);
            }
        }
        
        if(portalUserContactIds.size() > 0){
            Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();
                        
            List<Contact> portalContacts = [SELECT Id, Is_Fleet_Community_Manager__c,AccountId,Account.Name FROM Contact WHERE id IN:portalUserContactIds AND RecordTypeId = :b2bRT];
            System.debug('Portal Contacts: ' +portalContacts);
            
            if(portalContacts.size() > 0){
                for(Contact portalContact: portalContacts){
                    mapContacts.put(portalContact.Id,portalContact);
                }
            }
        }
        for( User newUser : lstUsers)
        {
            System.debug('Contact Id: '+ newUser.ContactId);
            if(newUser.ContactId != null && mapContacts.containsKey(newUser.ContactId)){
                newUser.ContactAccountId__c = mapContacts.get(newUser.ContactId).AccountId;
                newUser.ContactAccountName__c = mapContacts.get(newUser.ContactId).Account.Name;
            }
        }
    }
}