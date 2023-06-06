@isTest
public class Fleet_InvoicePreferencesControllerTest {

    @TestSetup
    static void makeData(){
        Account newAccount = new Account(Name = 'Test Account12345678910');
        newAccount.Fleet_Invoice_AR_Fields__c = '{"termsOfPaymentKeyDescription":null,"termsOfPaymentKey":null,"taxClassificationDescription":null,"taxClassification":null,"street4":null,"street":null,"state":null,"salesforceId":null,"publicNotes":null,"privateNotes":null,"postingBlockForCompanyCode":null,"postalCode":null,"poRequiredDescription":null,"poRequired":null,"phoneNumber":null,"invoiceCopyDescription":null,"invoiceCopy":null,"invoiceARRequiredFields":[{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"DRIVER NAME","characteristicValueAUSP":"01"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"VEHICLE YEAR","characteristicValueAUSP":"07"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"VEHICLE MAKE","characteristicValueAUSP":"08"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"VEHICLE MODEL","characteristicValueAUSP":"09"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"LICENSE PLATE #","characteristicValueAUSP":"10"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"LIC PLATE STATE","characteristicValueAUSP":"11"},{"objectKeyINOB":"0000020072","characteristicValueDescriptioinCAWNT":"MILEAGE","characteristicValueAUSP":"13"}],"industryKeyDescription":null,"industryKey":null,"groupKey":null,"eccPOSNotes":null,"eccId":null,"creditLimit":null,"createdDate":null,"countryDescription":null,"country":null,"corporateGroupDescription":null,"contacts":null,"companyName2":null,"companyName":null,"city":null,"certificateDescription":null,"certificate":null,"billingBlockforSalesAreaDescription":null,"billingBlockforSalesArea":null,"autoIntegrateDescription":null,"autoIntegrate":null,"accountTypeDescription":null,"accountType":null,"accountPaymentTypeDescription":null,"accountPaymentType":null,"accountManagerDescription":null,"accountManager":null,"accountingClerkAbbreviation":null,"accountCompanyDescription":null,"accountCompany":null}';
        insert newAccount;    

        System.debug('Test Account ID---------' + newAccount.id);
        TestCommunityUserFactory.createCommunityUserAsAdmin(newAccount.id, 'Fleet Customer Community User','fleetDev2.com');
        

    }

    @isTest
    public static void getAccountIdTest(){
        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){

            User newUser = [SELECT id, accountId, ContactId FROM USER WHERE id = :UserInfo.getUserId()];                  

            System.debug('----------Start Test----------');
            Test.startTest();

            String accountId = Fleet_InvoicePreferencesController.getAccountId();           

            System.assert(newUser.accountId == accountId, 'Account Id Matched');

            Test.stopTest();
            System.debug('----------End Test----------');
        }
        

        
    }

    @isTest
    public static void handleGetInvoicePreferencesTest(){
        
        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        System.runAs(testUser){

          

            System.debug('----------Start Test----------');
            Test.startTest();

            Map<String, Boolean> invoicePreference = Fleet_InvoicePreferencesController.handleGetInvoicePreferences(testUser.accountId);       
            
            System.debug(invoicePreference.get('licensePlate'));

            System.assert(invoicePreference.get('licensePlate') == true, 'Invoice Preference Check');
            
            Test.stopTest();
            System.debug('----------End Test----------');
        }

    }

    
    @isTest
    public static void handleInvoicePreferencesChangeRequestTest(){   
        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        System.runAs(testUser){

            System.debug('----------Start Test----------');
            Test.startTest();

            String result = Fleet_InvoicePreferencesController.handleInvoicePreferencesChangeRequest('Test Description', 'Test Subject');       
            
            System.debug(result);

            System.assert(result == 'success', 'Handle Invoice Preference Change Request');
            
            Test.stopTest();
            System.debug('----------End Test----------');

        }               

    }

}