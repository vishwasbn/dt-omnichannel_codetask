/**
 * An apex page controller that exposes the site login functionality
 */
@IsTest 
public class CommunitiesLoginControllerTest 
{

    @TestSetup
    static void setupData()
    {
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Fleet Sales User' ];
        System.debug('number of Profiles: ' + profileList.size());

        User testUser = new User (
            Username = 'wstor@ethos.com.dt.fleetdev2',
            LastName = 'Stor',
            FirstName = 'William',
            Email = 'apex+wstorr@ethos.com',
            EmailPreferencesAutoBcc = true,
            EmailPreferencesAutoBccStayInTouch = false,
            EmailPreferencesStayInTouchReminder = true,
            ProfileId = profileList[0].Id,
            Phone = '(602) 123-4567',
            Alias = 'wstr',
            CommunityNickname = 'User15960418108414009002',
            IsActive = true,
            TimeZoneSidKey = 'America/Phoenix',
            LocaleSidKey = 'en_US',
            ReceivesInfoEmails = true,
            ReceivesAdminInfoEmails = true,
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            UserPreferencesActivityRemindersPopup = true,
            UserPreferencesEventRemindersCheckboxDefault = true,
            UserPreferencesTaskRemindersCheckboxDefault = true,
            UserPreferencesDisableLikeEmail = true,
            UserPreferencesSortFeedByComment = true,
            UserPreferencesShowTitleToExternalUsers = true,
            UserPreferencesHideS1BrowserUI = true,
            UserPreferencesPathAssistantCollapsed = true,
            UserPreferencesLightningExperiencePreferred = true,
            UserPreferencesHideSfxWelcomeMat = true,
            DigestFrequency = 'D',
            DefaultGroupNotificationFrequency = 'N',
            Fleet_ECC_Key__c = '09',
            Fleet_Specialist_Assignment_Group__c = '1-50',
            Fleet_Is_Specialist__c = true
        );

        insert testUser;

        system.setPassword(testUser.id, 'userpwd99@');
    }

    static testmethod void testCommunitiesLoginController () 
    {
        System.currentPageReference().getParameters().put('startURL', 'testURL');
        System.currentPageReference().getParameters().put('display', 'testDisplay');

        CommunitiesLoginController controller = new CommunitiesLoginController();
        PageReference pgRef = controller.forwardToAuthPage();
        System.debug('forward Pg Ref: ' + pgRef);
        System.assertEquals(null, pgRef, 'forward page reference is wrong');
        
        try {
            String resultLogin = CommunitiesLoginController.loginUser('wstor@ethos.com.dt.fleetdev2', 'password','app');            
            System.debug('loginUser bad pwd: ' + resultLogin);
            System.assert(false, 'LoginUser failed to flag the username/password as bad');
            
        } catch (Exception ex) {
            System.debug('loginUser bad pwd: ' + ex.getMessage());            
            System.debug('loginUser bad pwd: ' + ex.getStackTraceString());            
            System.assertEquals('Username or password is incorrect', ex.getMessage(), 'loginUser failure message is wrong');         
        }
        try {            
            String resultLogin1 = CommunitiesLoginController.loginUser('wstor@ethos.com.dt.fleetdev2', 'password','app','parking');
            System.debug('loginUser bad pwd: ' + resultLogin1);
            System.assert(false, 'LoginUser failed to flag the username/password as bad');
            
        } catch (Exception ex) {
            System.debug('loginUser bad pwd: ' + ex.getMessage());            
            System.debug('loginUser bad pwd: ' + ex.getStackTraceString());            
            System.assertEquals('Username or password is incorrect', ex.getMessage(), 'loginUser failure message is wrong');         
        }
        try {            
            String resultLogin1 = CommunitiesLoginController.loginUser('wstor@ethos.com.dt.fleetdev2', 'password','app','mobileservices');
            System.debug('loginUser bad pwd: ' + resultLogin1);
            System.assert(false, 'LoginUser failed to flag the username/password as bad');
            
        } catch (Exception ex) {
            System.debug('loginUser bad pwd: ' + ex.getMessage());            
            System.debug('loginUser bad pwd: ' + ex.getStackTraceString());            
            System.assertEquals('Username or password is incorrect', ex.getMessage(), 'loginUser failure message is wrong');         
        }

        // valid login not working in test
        // String resultLogin = CommunitiesLoginController.loginUser('wstor@ethos.com.dt.fleetdev2', 'userpwd99@');
        // System.debug('loginUser: ' + resultLogin);

        try {
            String resultReset0 = CommunitiesLoginController.resetUserPassword('bogus.com.dt.fleetdev2');
            System.debug('loginReset bad usrNme: ' + resultReset0);
            System.assert(false, 'ResetUserPwd failed to flag the username as bad');
                
        } catch (Exception ex) {
            System.debug('loginReset bad usrNme: ' + ex.getMessage());            
            System.debug('loginReset bad usrNme: ' + ex.getStackTraceString());
            System.assertEquals('Cannot find a user with that username.', ex.getMessage(), 'ResetUserPwd failure message is wrong');         
        }


        String resultReset = CommunitiesLoginController.resetUserPassword('wstor@ethos.com.dt.fleetdev2');
        System.debug('loginReset: ' + resultReset);
        System.assertEquals('An email has been sent succesfully to your email address!', resultReset, 'ResetUserPwd success message is wrong');
    }    
}