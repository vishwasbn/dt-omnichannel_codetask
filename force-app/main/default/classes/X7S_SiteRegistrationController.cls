public with sharing class X7S_SiteRegistrationController {

    private static Integer MINIMUM_PASSWORD_LENGTH = 8;

    @AuraEnabled(Cacheable=true)
    public static Map<String, String> getStates() {
        return new Map<String, String> {
                'Alabama' => 'Alabama',
                'Alaska' => 'Alaska',
                'Arizona' => 'Arizona',
                'Arkansas' => 'Arkansas',
                'California' => 'California',
                'Colorado' => 'Colorado',
                'Connecticut' => 'Connecticut',
                'Delaware' => 'Delaware',
                'District of Columbia' => 'District of Columbia',
                'Florida' => 'Florida',
                'Georgia' => 'Georgia',
                'Hawaii' => 'Hawaii',
                'Idaho' => 'Idaho',
                'Illinois' => 'Illinois',
                'Indiana' => 'Indiana',
                'Iowa' => 'Iowa',
                'Kansas' => 'Kansas',
                'Kentucky' => 'Kentucky',
                'Louisiana' => 'Louisiana',
                'Maine' => 'Maine',
                'Maryland' => 'Maryland',
                'Massachusetts' => 'Massachusetts',
                'Michigan' => 'Michigan',
                'Minnesota' => 'Minnesota',
                'Mississippi' => 'Mississippi',
                'Missouri' => 'Missouri',
                'Montana' => 'Montana',
                'Nebraska' => 'Nebraska',
                'Nevada' => 'Nevada',
                'New Hampshire' => 'New Hampshire',
                'New Jersey' => 'New Jersey',
                'New Mexico' => 'New Mexico',
                'New York' => 'New York',
                'North Carolina' => 'North Carolina',
                'North Dakota' => 'North Dakota',
                'Ohio' => 'Ohio',
                'Oklahoma' => 'Oklahoma',
                'Oregon' => 'Oregon',
                'Pennsylvania' => 'Pennsylvania',
                'Rhode Island' => 'Rhode Island',
                'South Carolina' => 'South Carolina',
                'South Dakota' => 'South Dakota',
                'Tennessee' => 'Tennessee',
                'Texas' => 'Texas',
                'Utah' => 'Utah',
                'Vermont' => 'Vermont',
                'Virginia' => 'Virginia',
                'Washington' => 'Washington',
                'West Virginia' => 'West Virginia',
                'Wisconsin' => 'Wisconsin',
                'Wyoming' => 'Wyoming'
        };
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, String> getProvinces() {
        return new Map<String, String> {
                'Alberta' => 'Alberta',
                'British Columbia' => 'British Columbia',
                'Manitoba' => 'Manitoba',
                'New Brunswick' => 'New Brunswick',
                'Newfoundland and ' => 'Newfoundland and ',
                'Nova Scotia' => 'Nova Scotia',
                'Northwest Territories' => 'Northwest Territories',
                'Nunavut' => 'Nunavut',
                'Ontario' => 'Ontario',
                'Prince Edward Island' => 'Prince Edward Island',
                'Quebec' => 'Quebec',
                'Saskatchewan' => 'Saskatchewan',
                'Yukon' => 'Yukon'
        };
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, String> getCountries() {
        return new Map<String, String> {
                'United States' => 'United States',
                'Canada' => 'Canada'
        };
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, String> getPhoneTypes() {
        return new Map<String, String> {
                'Mobile' => 'Mobile',
                'Home' => 'Home',
                'Work' => 'Work'
        };
    }

    @AuraEnabled(Cacheable=true)
    public static Boolean validateUsername(String username) {
        List<User> existingUsers = [SELECT Id FROM User WHERE Username = :username];

        return existingUsers.isEmpty();
    }

    @AuraEnabled(Cacheable=true)
    public static Boolean validatePassword(String password) {
        Boolean lengthRequirementMet = password.length() >= MINIMUM_PASSWORD_LENGTH;
        Boolean letterRequirementMet = password.containsAny('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ');
        Boolean numberRequirementMet = password.containsAny('0123456789');

        return lengthRequirementMet && letterRequirementMet && numberRequirementMet;
    }

    @AuraEnabled(Cacheable=true)
    public static Boolean registerNewUser(
            String firstName, String lastName, String email, String password, Boolean acceptCommunityTerms, String phoneType,
            String phoneNumber, String streetAddress, String country, String postalCode, String city, String state, String domain
    ) {

        if (!acceptCommunityTerms) {
            throw new RegistrationException('You must accept the Community Terms and Conditions to register for the community');
        }

        X7S_SiteRegistration newRegistrationController = new X7S_SiteRegistration();
        newRegistrationController.firstName = firstName;
        newRegistrationController.lastName = lastName;
        newRegistrationController.email = email;
        newRegistrationController.password = password;
        newRegistrationController.acceptCommunityTerms = acceptCommunityTerms;
        newRegistrationController.phoneType = phoneType;
        newRegistrationController.phoneNumber = phoneNumber;
        newRegistrationController.streetAddress = streetAddress;
        newRegistrationController.country = country;
        newRegistrationController.postalCode = postalCode;
        newRegistrationController.city = city;
        newRegistrationController.state = state;
        newRegistrationController.domain = domain;

        return newRegistrationController.registerUser();
    }

    public class RegistrationException extends Exception {}
}