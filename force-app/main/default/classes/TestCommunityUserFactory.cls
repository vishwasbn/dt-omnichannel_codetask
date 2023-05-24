@isTest
public class TestCommunityUserFactory {

    public static void createCommunityUserAsAdmin(Id accountId, String profileName, String domainSuffix) {
         
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'tfnuser', Email='dttestuser@testorg.dt.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = profile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='dttestuser@testorg.dt.com', IsActive=true);        
  
        insert u;

        System.runAs(u){
            createCommunityUser(accountId, profileName, domainSuffix);
        }

    }


    public static void createCommunityUser(Id accountId, String profileName, String domainSuffix) {
        String email = getRandomUsername(domainSuffix);
        List<sObject> sReturn = new List<sObject>();
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = Email,
            AccountId = accountId
        );

        insert c;

        System.debug('Contact Account: ' + c.AccountId);

        sReturn.add(c);
        String uniqueId = 'test' + (math.random() * 1000).intValue().format();
        Id profileId = getProfileId(profileName);
        User u = new User(
            FirstName = c.FirstName,
            LastName = c.LastName,
            Email = c.Email,
            Username = c.Email,
            CommunityNickname = uniqueId + 'test',
            Alias = uniqueId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = profileId,
            LanguageLocaleKey = 'en_US',
            ContactId = c.Id,
            IsActive = true
            // Bypass_Validation_Rules__c = true
        );
        insert u;
        System.debug('insert User: ' + u);
        System.debug('User Account: ' +u.accountId);
        
        //return sReturn;
    }

    public static String getRandomUsername(String domainSuffix) {
        Integer rand1 = Math.round(Math.random() * 10000);
        Integer rand2 = Math.round(Math.random() * 10000);
        return 'testuser' + rand1 + '_' + rand2 + '@' + domainSuffix;
    }

    private static Map<String, Id> profileNameToIdMap;
    private class ProfileNotFoundException extends Exception {
    }
    public static Id getProfileId(String profileName) {
        if (null == profileNameToIdMap) {
            profileNameToIdMap = new Map<String, Id>();
            for (Profile p : [SELECT Id, Name FROM Profile LIMIT 10000]) {
                profileNameToIdMap.put(p.Name, p.Id);
            }
        }
        Id profileId = profileNameToIdMap.get(profileName);
        if (null == profileId) {
            throw new ProfileNotFoundException('Profile \'' + profileName + '\' not found.');
        } else {
            return profileId;
        }
    }
}