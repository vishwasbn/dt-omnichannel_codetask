public without sharing class X7S_SiteRegistration {
    public String firstName;
    public String lastName;
    public String email;
    public String password;
    public String phoneType;
    public String phoneNumber;
    public String streetAddress;
    public String country;
    public String postalCode;
    public String city;
    public String state;
    public String domain;
    public Boolean acceptCommunityTerms;

    @TestVisible
    private static String customerCommunityProfileId = Label.Customer_Community_User_Default_Profile_Id;
    private static String newRecordOwnerId = Label.Customer_Community_New_Record_Owner_Id;

    public Boolean registerUser() {
        User newUser = generateNewUser();
         System.debug('newRecordOwnerId'+newRecordOwnerId);
          System.debug('password'+password);
        System.debug('newUser'+newUser );
        Id newUserId = Site.createPersonAccountPortalUser(newUser, newRecordOwnerId, password);
          System.debug('newUserId'+newUserId);
        updateAccountFields(newUserId);
    
        return newUserId != null;
    }

    @TestVisible
    private User generateNewUser() {
        User newUser = new User();
        newUser.FirstName = firstName;
        newUser.LastName = lastName;
        newUser.Username = email;
        newUser.Email = email;
        newUser.CommunityNickname = getDefaultNickname(firstName, lastName);
        newUser.Alias = getAlias(firstName, lastName);
        newUser.Street = streetAddress;
        newUser.City = city;
        newUser.State = state;
        newUser.PostalCode = postalCode;
        newUser.Country = country;
        newUser.Preferred_Brand__c = getPreferredBrand(domain);
        newUser.TimeZoneSidKey = 'America/Phoenix';
        newUser.LocaleSidKey = 'en_US';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.Community_Terms_Acceptance_Date__c = Datetime.now();
        newUser.Phone_Type__c =  phoneType;

        setUserPhoneNumber(newUser, phoneType, phoneNumber);
        return newUser;
    }

    @Future
    public static void updateAccountFields(Id userId) {
        User newUser = [SELECT Id, Phone_Type__c, Phone, MobilePhone, Street, City, State, PostalCode, AccountId FROM User WHERE Id = :userId];

        Account personAccount = new Account(Id = newUser.AccountId);
        personAccount.PersonMailingStreet = newUser.Street;
        personAccount.PersonMailingCity = newUser.City;
        personAccount.PersonMailingState = newUser.State;
        personAccount.PersonMailingPostalCode = newUser.PostalCode;
        personAccount.Type = 'Community User';

        switch on (newUser.Phone_Type__c) {
            when 'Mobile' {
                personAccount.PersonMobilePhone = newUser.MobilePhone;
                personAccount.Phone = newUser.MobilePhone;
            } when 'Home' {
                personAccount.PersonHomePhone = newUser.Phone;
                personAccount.Phone = newUser.Phone;
            } when 'Work' {
                personAccount.PersonOtherPhone = newUser.Work_Phone__c;
                personAccount.Phone = newUser.Work_Phone__c;
            }
        }

        update personAccount;
    }

    private static String getDefaultNickname(String firstName, String lastName) {
        String nickname = firstName + ' ' + lastName.substring(0, 1);

        List<User> usersWithSimilarNicknames = [SELECT Id FROM User WHERE CommunityNickname LIKE :nickname + '%'];

        if (!usersWithSimilarNicknames.isEmpty()) {
            nickname = nickname + ' ' + (usersWithSimilarNicknames.size() + 1);
        }

        return nickname;
    }

    private static String getAlias(String firstName, String lastName) {
        String alias;

        if (firstName.length() > 7) {
            alias = firstName.substring(0, 7);
        } else {
            alias = firstName;
        }

        alias += lastName.substring(1, 1);

        return alias;
    }

    private static String getPreferredBrand(String registrationDomain) {
        if (registrationDomain != null && registrationDomain.containsIgnoreCase('americastire.com')) {
            return 'Americas Tire';
        } else {
            return 'Discount Tire';
        }
    }

    private static void setUserPhoneNumber(User u, String phoneType, String phoneNumber) {
        switch on phoneType {
            when 'Home' {
                u.Phone = phoneNumber;
            } when 'Work' {
                u.Work_Phone__c = phoneNumber;
            } when 'Mobile' {
                u.MobilePhone = phoneNumber;
            } when else {
                u.Phone = phoneNumber;
            }
        }
    }
}