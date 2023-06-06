public without sharing class Fleet_CommunityUserBuilder {
    public static String lprefix = 'LOG_CUB';

    // Defaults user creation to Community Manager
    public static void convertContactToCommunityUser(Set<Id> contactIdSet) {
        convertContactToCommunityUser(contactIdSet, true);
    }

    public static void convertContactToCommunityUser(Set<Id> contactIdSet, Boolean isCommunityManager) 
    {
        System.debug('convertContactToCommunityUser() Starting - isCommunityManager='+isCommunityManager + ', contactIdSet:'+contactIdSet);

        if (contactIdSet.size() == 0) return;

        String communityProfileName = Fleet_SettingUtil.getSettingValue(Fleet_Values.SETTING_FLEET_COMMUNITY_USER_PROFILE);
        String communityPermissionSetName = Fleet_SettingUtil.getSettingValue(Fleet_Values.SETTING_FLEET_COMMUNITY_USER_PERMISSION_SET);

        List<Contact> contactList = [SELECT Id, Email, FirstName, LastName, Phone, MobilePhone FROM Contact WHERE Id IN :contactIdSet];
        // System.debug( lprefix + 'Contacts to convert: ' + contactList);
        
        Profile p = [SELECT Id from Profile where Name = :communityProfileName];
        PermissionSet cuPermSet = [select id,label from permissionset where label = :communityPermissionSetName limit 1]; // get Id of Fleet Community Permission Set
        // System.debug( lprefix + 'Profile: ' + p + ' PS: ' + cuPermSet);

        //---Get the Users for the Contacts
        List<User> existingUserList = [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIdSet];
        Map<Id, User> userMap = new Map<Id, User>();
        for(User uRow : existingUserList) 
        {
            User checkUser = userMap.get(uRow.Id);
            if (checkUser == null) userMap.put(uRow.ContactId, uRow);
        }

        List<User> newUserList = new List<User>();
        List<User> foundUserList = new List<User>();
        Logger logInstance = Logger.getInstance();
        logInstance.log('Community User Builder', 'Fleet_CommunityUserBuilder', 'Before Contact update');
        List<Contact> contactToUpdateList = new List<Contact>();
        Set<String> userNameSet = new Set<String>();

        //---Loop over the Contacts
        for(Contact cRow : contactList)
        {
            User checkUser = userMap.get(cRow.Id);

            if (checkUser == null)
            {
                User newUser = buildNewCommunityUser( cRow);
                newUser.profileID = p.Id;
            
                newUserList.add( newUser);
                userNameSet.add(newUser.Username + '%'); // setting up WHERE filter for LIKE new username
                
                if (isCommunityManager == true) {
                    // set is community manager to true, AND just in case set Convert_To_Fleet_Community_Manager__c to false
                    contactToUpdateList.add (new Contact(Id=cRow.Id, Is_Fleet_Community_Manager__c=true, Convert_To_Fleet_Community_Manager__c = false));
                }
            }
            else
            {
                foundUserList.add(checkUser);
            }
        }

        if (contactToUpdateList.size() > 0) {
            update contactToUpdateList;
            logInstance.log('Community User Builder', 'Fleet_CommunityUserBuilder', 'After Contact update', JSON.serialize(contactToUpdateList));
            // System.debug(lprefix+ 'Updating Contacts: ' + contactToUpdateList);
        }
        
        //---Create the New Users
        if (newUserList.size() > 0) {

            // Map User ... UserName, User
            Map<String, User> existingUserMap = new Map<String, User>();
            // get Users with usernames close to the ones created (search is case insensitive)
            List<User> userLst = [SELECT Id, ContactId, Username, FirstName, LastName, Email, Phone FROM User WHERE Username LIKE: userNameSet ORDER BY Username];
            if ((userLst != null) && (userLst.size() > 0)) {
                for (User usr: userLst){
                    existingUserMap.put(usr.Email.toLowerCase(), usr); // the Map ends up with the largest value LIKE name
                    System.debug('similar username: ' + usr.Username);
                }
            }

            while ((newUserList != null) && (newUserList.size() > 0)) 
            {
                // save the list of User, convert the returned users to a list
                newUserList = new List<User>( saveUsers(newUserList, existingUserMap) );
            }
            
        }
        System.debug('convertContactToCommunityUser Ending');
       
    }

    //---Build the new User
    public static User buildNewCommunityUser(Contact contact)
    {
        User usr = new User();
        
        String tempString = '' + contact.Id;
        String alias = tempString.substring(7,8);
        
        usr.ContactId = contact.Id;
        //NOTE: email can be null
        usr.Username = contact.Email;
        usr.Email = contact.Email;
        usr.FirstName = contact.FirstName;
        usr.LastName = contact.LastName;
        usr.TimeZoneSidKey = 'GMT';
        usr.LanguageLocaleKey = 'en_US';
        usr.EmailEncodingKey = 'UTF-8';
        usr.LocaleSidKey = 'en_US';
        usr.Phone = contact.Phone;
        usr.MobilePhone = contact.MobilePhone;
        usr.Alias = alias;
        //user.CommunityNickname = 'testUser123';

        return usr;
    }
    
    @TestVisible
    private static Set<User> saveUsers(List<User> newUserList, Map<String, User> existingUserMap)
    {
        System.debug('saveUsers Starting');

        Database.SaveResult[] srList;
        Set<User> retryUsers = new Set<User>(); // As a set there can be only one
        // Try to insert users as they are
        try
        {
            // Insert new users
            // first pass does not have the advantage of checking the existing users
            srList = Database.insert(newUserList, false); // insert valid users, triage errors
            Logger logInstance = Logger.getInstance();
            logInstance.log('Community User Builder', 'Fleet_CommunityUserBuilder', 'User', srList);
            // System.debug('Creating New Users: ' + newUserList);

            // loop through results
            Database.SaveResult sr;
            for (Integer srIndex = 0; srIndex < srList.size(); ++srIndex) 
            {
                sr = srList[srIndex];
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('saveUsers::Successfully inserted user. User ID: ' + sr.getId() + ' Name: ' + newUserList[srIndex].username);
                }
                else {
                    // Operation failed, so get all errors
                    // the errors are coming from the Indexed SaveResults row, which is only for the single insert record             
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('saveUsers::The following error has occurred.');                    
                        System.debug('saveUsers::Status code: ' + err.getStatusCode());
                        System.debug('saveUsers::Message: ' + err.getMessage());
                        System.debug('saveUsers::Id: ' + sr.getId());                    
                        System.debug('saveUsers::Account fields that affected this error: ' + err.getFields());
                        System.debug('saveUsers::StatusCode DUPLICATE_USERNAME: ' + StatusCode.DUPLICATE_USERNAME);
                        
                        // the user records Id = null, the SaveResults Id = null and the StatusCode is Duplicate Username
                        if ((newUserList[srIndex].Id == null) && (sr.getId() == null) && (err.getStatusCode() == StatusCode.DUPLICATE_USERNAME))
                        {
                            String lastSuffix = '';
                            // do the existing Users contain this new user name pattern
                            if ( existingUserMap.containsKey( newUserList[srIndex].username.toLowerCase() ) )
                            {
                                System.debug('saveUsers::Existing suffix: ' + existingUserMap.get( newUserList[srIndex].username ));

                                // grab the existing user with the highest sequence number
                                String lastInSeqUsername = existingUserMap.get( newUserList[srIndex].username ).username;
                                System.debug('saveUsers::Existing suffix:username: ' + lastInSeqUsername);
                                if( containsDtExt( lastInSeqUsername ) )
                                {  
                                    lastSuffix = getDtExtValue(lastInSeqUsername);
                                    System.debug('saveUsers::Existing suffix value: ' + lastSuffix);
                                }
                            }

                            // this check assumes that are coming back around after failing the second time (not sure how realistic it is)
                            String currentSuffix = '';
                            if( containsDtExt( newUserList[srIndex].username ) )
                            {
                                currentSuffix = getDtExtValue(newUserList[srIndex].username);
                            }

                            System.debug('saveUsers::Starting username: ' + newUserList[srIndex].username);
                            // which sequnce number to base the new username
                            // if the new username has a sequence number then increment it (like you tried one and it didn't work)
                            if ( String.isNotBlank( currentSuffix ) )
                            {
                                newUserList[srIndex].username = newUserList[srIndex].Email + '.dt' + incrementDtExtValue( currentSuffix );
                            }
                            else if ( String.isNotBlank( lastSuffix ) ) // if there is an existing username with a sequence then increment from there
                            {
                                newUserList[srIndex].username = newUserList[srIndex].Email + '.dt' + incrementDtExtValue( lastSuffix );
                            }
                            else  // if there is no sequence number then start at 2
                            {
                                newUserList[srIndex].username = newUserList[srIndex].Email + '.dt' + '2';
                            }
                            System.debug('saveUsers::Ending username: ' + newUserList[srIndex].username);

                            retryUsers.add(newUserList[srIndex]);
                        }
                        else 
                        {
                            System.debug('saveUsers::Insert Error: ' + err.getStatusCode() + ' Message: ' + err.getMessage());
                            break; // another error is present, so don't proceed with this records errors
                        }
                    }
                }
            }
        } catch (Exception ex) {
            System.debug('saveUsers::Insert Error: ' + ex.getStackTraceString());
        }
        System.debug('saveUsers Ending');

        return retryUsers;
    } // End of saveUsers()

    @TestVisible
    private static boolean containsDtExt(String username)
    {
        Boolean result = false;
        if ( (String.isNotBlank(username)) && (username.containsIgnoreCase('.dt')) ){
            String seqNum = username.toLowerCase().substringAfterLast('.dt');
            result = seqNum.isNumeric();
        }
        return result;
    }
    
    @TestVisible
    private static String getDtExtValue(String username)
    {
        String result = '';
        if ( String.isNotBlank(username) )
        {
            String seqNum = username.toLowerCase().substringAfterLast('.dt');
            result = (String.isBlank(seqNum) || !seqNum.isNumeric()) ? '' : String.valueOf( Integer.valueOf(seqNum) );
        }
        return result;
    }
    
    @TestVisible
    private static String incrementDtExtValue(String suffix)
    {
        String result = '';
        if ( String.isNotBlank(suffix) )
        {
            result = String.valueOf( Integer.valueOf(suffix) + 1 );
        }
        return result;
    }

} // End of Fleet_CommunityUserBuilder class