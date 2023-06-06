public class Fleet_UserUtil
{
    public static String lprefix = 'LOG_UTH:';

    //---Method to resetting an existing User's password
    public static String resetPasswordWithEmail(Id userId)
    {
        
        System.debug( lprefix + 'Request to reset password for: ' + userId);
        
        try{
            System.resetPassword(userId, true); //---Send the reset email
            return 'success';
        } catch (Exception e){
            Logger logInstance = Logger.getInstance();
   			logInstance.log('Appointments', 'Fleet_UserUtil', e);
            System.debug(e.getMessage());
            return 'error';
        }
        
        
    }
    
    //---Method to unlocking a user
    public static String unlockUser(Id userId)
    {
        System.debug( lprefix + 'Request to unlock the user: ' + userId);

        List<UserLogin> userLoginList = [SELECT UserId, IsPasswordLocked FROM UserLogin WHERE UserId = :userId];
        
        if (userLoginList == null || userLoginList.size() == 0)
        {
            System.debug( lprefix + 'No users found: ' + userId);
            return 'No Users Found';
        }
        else
        {
            UserLogin selLogin = userLoginList[0];
            System.debug( lprefix + 'Found the user: ' + userId);

            try
            {
                selLogin.IsPasswordLocked = false;
                update selLogin;

                System.debug( lprefix + 'User unlocked: ' + selLogin);
                return 'success';
            }
            catch (Exception ex) 
            {
                Logger logInstance = Logger.getInstance();
   				logInstance.log('Appointments', 'Fleet_UserUtil', ex);
                String errorMessage = ex.getMessage();
                System.debug( lprefix + 'Error tring to unlock the User:' + userId);
                return 'error';
            }
        }
    }

    public static Boolean isUserLocked(Id userId){

        List<UserLogin> userLoginList = [SELECT UserId, IsPasswordLocked FROM UserLogin WHERE UserId = :userId AND IsPasswordLocked = true];
             
        System.debug('userLocked List: ' +userLoginList);
        if (userLoginList == null || userLoginList.size() == 0)
        {
            System.debug( lprefix + 'No users found: ' + userId);
            return false;
        } else{
            return true;
        }

        
    }

    public static string deactivateUser(Id userId)
    {
        System.debug( lprefix + 'Request deactivate user: ' + userId);
        try{
            User userToDeactivate = [SELECT id, IsActive FROM User WHERE id = :userId];
            userToDeactivate.IsActive = false;
            update userToDeactivate;
            return 'success';
        }catch(Exception e){
            Logger logInstance = Logger.getInstance();
   			logInstance.log('Appointments', 'Fleet_UserUtil', e);
            System.debug(userId + ': id was not able to be deactivated');
            System.debug(e.getMessage());
            return 'error';
        }

        
    }

    // Check for deactivated user
    public static Boolean isUserActive(Id userId)
    {
        System.debug( lprefix + 'Request deactivate user: ' + userId);
        try{
            User userToDeactivate = [SELECT id, IsActive FROM User WHERE id = :userId];    
            
            return userToDeactivate.IsActive;

        }catch(Exception e){
            Logger logInstance = Logger.getInstance();
   			logInstance.log('Appointments', 'Fleet_UserUtil', e);
            System.debug(userId + ': id was not able to be deactivated');
            System.debug(e.getMessage());
            return false;
        }

        
    }
}