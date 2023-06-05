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
        System.debug('Fleet_CommunityUserUtil.addPermissionSets() ENTRY - permSet=' + permSet + ', users:' + users);
        List<User> activeUsers = [SELECT id,isActive FROM user WHERE id IN :users and isActive=true];  
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        
        for (User activeUser : activeUsers) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId=permSet,AssigneeId=activeUser.id);
            psaList.add(psa);
        }
           
        // This method gets called by triggers and batch processes, and therefore sometimes more than once for the same user and permset.
        // Catch exceeption and If DmlException exception with 'DUPLICATE_VALUE' error, then swallow the exception and continue
        try {
            upsert psaList;
        } catch (DmlException e) {
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

        List<PermissionSetAssignment> psaList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN :users AND PermissionSetId=:permSet];
        delete psaList;

    }

    // Sets the profile to fleet community user for all Ids passed 
    @Future
    public static void setProfile(List<id> users, id communityProfileId){

        List<User> updateUsers = [SELECT id, profileId FROM user WHERE id IN :users];        
        

        if(updateUsers.size() > 0){

            for(User usr: updateUsers){
                usr.ProfileId = communityProfileId;
            }

            update updateUsers;

        }

    }
}