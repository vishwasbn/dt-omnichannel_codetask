@isTest
public with sharing class Fleet_UserTriggerHandlerTest {
    
    @TestSetup
    static void makeData(){
        Contact c = new Contact(
            FirstName='test',
            LastName='lastname',
            Email='test@discountire.example'
        );
        insert c;
        
        Account newAccount = new Account(Name = 'Test Account12345678910');
        newAccount.Fleet_Invoice_AR_Fields__c = '{"termsOfPaymentKeyDescription":null,"termsOfPaymentKey":null,"taxClassificationDescription":null,"taxClassification":null,"street4":null,"street":null,"state":null,"salesforceId":null,"publicNotes":null,"privateNotes":null,"postingBlockForCompanyCode":null,"postalCode":null,"poRequiredDescription":null,"poRequired":null,"phoneNumber":null,"invoiceCopyDescription":null,"invoiceCopy":null,"invoiceARRequiredFields":[{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"DRIVER NAME","characteristicValueAUSP":"01"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"VEHICLE YEAR","characteristicValueAUSP":"07"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"VEHICLE MAKE","characteristicValueAUSP":"08"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"VEHICLE MODEL","characteristicValueAUSP":"09"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"LICENSE PLATE #","characteristicValueAUSP":"10"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"LIC PLATE STATE","characteristicValueAUSP":"11"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"MILEAGE","characteristicValueAUSP":"13"}],"industryKeyDescription":null,"industryKey":null,"groupKey":null,"eccPOSNotes":null,"eccId":null,"creditLimit":null,"createdDate":null,"countryDescription":null,"country":null,"corporateGroupDescription":null,"contacts":null,"companyName2":null,"companyName":null,"city":null,"certificateDescription":null,"certificate":null,"billingBlockforSalesAreaDescription":null,"billingBlockforSalesArea":null,"autoIntegrateDescription":null,"autoIntegrate":null,"accountTypeDescription":null,"accountType":null,"accountPaymentTypeDescription":null,"accountPaymentType":null,"accountManagerDescription":null,"accountManager":null,"accountingClerkAbbreviation":null,"accountCompanyDescription":null,"accountCompany":null}';  
    
        insert newAccount;  
        
        c.AccountId = newAccount.Id;
        update c;
    
        TestCommunityUserFactory.createCommunityUserAsAdmin(newAccount.id, 'Fleet Customer Community User','fleetDev2.com');
    }

    @isTest
    public static void validateCommunityUserSetupCorrectlyTest(){   
        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, contactId, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];

        List<Contact> updateContacts = [SELECT id, Is_Fleet_Community_Manager__c FROM Contact WHERE id = :testUser.contactId];

        Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();
        
        Contact updateContact = updateContacts[0];
        updateContact.Is_Fleet_Community_Manager__c = true;
        updateContact.RecordTypeId = b2bRT;
    
        Test.startTest();

        update updateContact;               
        
        Test.stopTest();
    }
    
    @isTest
    public static void validateCommunityUserSetupCorrectlyTest1(){   
        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        
        List<User> communityUser = [SELECT id, FirstName, contactId, Contact.FirstName, accountId, Profile.Name, isActive 
                                    FROM USER 
                                    WHERE Profile.Name = 'Fleet Customer Community User' 
                                    AND accountId = :myAccount.id];      
                                    
        User testUser = communityUser[0];
        
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        
        System.runAs ( usr ) {
            Test.startTest();
                Fleet_UpdateFutureUser.updateUser(testUser.Id);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void validateContactUpdate(){   
        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        
        List<User> communityUser = [SELECT id, FirstName, contactId, Contact.FirstName, accountId, Profile.Name, isActive 
                                    FROM USER 
                                    WHERE Profile.Name = 'Fleet Customer Community User' 
                                    AND accountId = :myAccount.id];      
                                    
        User testUser = communityUser[0];
        
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        
        System.runAs ( usr ) {
            Test.startTest();
                testUser.FirstName = 'AAAAAAA';
                update testUser;
            Test.stopTest();
        
            List<Contact> conList = [SELECT Id, FirstName FROM Contact WHERE Id =: testUser.ContactId];
            System.assertEquals(conList[0].FirstName, testUser.FirstName);
            System.assertEquals(conList[0].FirstName, 'AAAAAAA');
        }
    }
}