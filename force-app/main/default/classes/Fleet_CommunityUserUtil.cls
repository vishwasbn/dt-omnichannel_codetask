public without sharing class Fleet_CommunityUserUtil {
    
    // Checks for a contact that has a user already created
    public static Boolean checkForActiveContactUser(id contactId, List<User> usersToCheck){
        for(User checkUser: usersToCheck){
            if(checkUser.ContactId == contactId){
                return true;
            }
        }
    return false;
    }

    // Gets a user for the contact Id passed
    public static User getContactUser(id contactId, List<User> usersToCheck){
        for(User checkUser: usersToCheck){
            if(checkUser.ContactId == contactId){
                return checkUser;
            }
        }
        return null;
    }

    // checks for the permisison set to be assinged to the user     
    public static Boolean checkForPermissionSetAssigment(id userId, List<PermissionSetAssignment> psaList){
        for(PermissionSetAssignment assigment: psaList){
            if(assigment.AssigneeId == userId){
                return true;
            }
        }
        return false;
    }

    // Add Permision Set to User
    @Future
    public static void addPermissionSets(List<id> users, Id permSet ){
        Logger logInstance = Logger.getInstance();
        System.debug('Fleet_CommunityUserUtil.addPermissionSets() ENTRY - permSet=' + permSet + ', users:' + users);
        
        logInstance.log('Community User Util', 'Fleet_CommunityUserUtil', 'Before PermissionSetAssignment upsert');
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        
        for (Id userId : users) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId=permSet,AssigneeId=userId);
            psaList.add(psa);
        }
           
        // This method gets called by triggers and batch processes, and therefore sometimes more than once for the same user and permset.
        // Catch exceeption and If DmlException exception with 'DUPLICATE_VALUE' error, then swallow the exception and continue
        try {
            upsert psaList;
            logInstance.log('Community User Util', 'Fleet_CommunityUserUtil', 'After PermissionSetAssignment upsert', JSON.serialize(psaList));
        } catch (DmlException e) {
            logInstance.log('Community User Util', 'Fleet_CommunityUserUtil', e);
            System.debug('CAUGHT DmlException in addPermissionSets() - message=' + e.getMessage());
            if (e.getMessage().contains('DUPLICATE_VALUE')) {
                System.debug('DUPLICATE_VALUE found in message, so swallowing exception and continuing');
            } else {
                throw e;
            }
        }
    }

    // Remove permission set from the User
    @Future
    public static void removePermissionSets(List<id> users, Id permSet ){
        Logger logInstance = Logger.getInstance();
        logInstance.log('Community User Util', 'Fleet_CommunityUserUtil', 'Before PermissionSetAssignment Delete');
        List<PermissionSetAssignment> psaList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN :users AND PermissionSetId=:permSet];
        delete psaList;
        logInstance.log('Community User Util', 'Fleet_CommunityUserUtil', 'After PermissionSetAssignment Delete', JSON.serialize(psaList));
    }

    // Sets the profile to fleet community user for all Ids passed 
    @Future
    public static void setProfile(List<id> users, id communityProfileId){
        Logger logInstance = Logger.getInstance();
        logInstance.log('Community User Util', 'Fleet_CommunityUserUtil', 'Before User update');
        List<User> updateUsers = [SELECT id, profileId FROM user WHERE id IN :users];        
        

        if(updateUsers.size() > 0){
        
            for(User usr: updateUsers){
                usr.ProfileId = communityProfileId;
            }

            update updateUsers;
            logInstance.log('Community User Util', 'Fleet_CommunityUserUtil', 'After User update', JSON.serialize(updateUsers));
        }

    }
}