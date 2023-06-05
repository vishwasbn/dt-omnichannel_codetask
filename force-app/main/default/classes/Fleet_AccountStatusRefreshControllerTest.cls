@isTest
public class Fleet_AccountStatusRefreshControllerTest {
    @TestSetup
    static void setupData(){
        List<Account> testAcctList = new List<Account> ();

        Account testAcct1 = new Account (
            Name = 'ENTERPRISE FLEET SVCS',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            ShippingStreet = '9315 OLIVE BLVD',
            ShippingCity = 'SAINT LOUIS',
            ShippingState = 'Missouri',
            ShippingPostalCode = '63132-3211',
            ShippingCountry = 'United States',
            ShippingStateCode = null,
            ShippingCountryCode = 'US',
            Phone = '800-325-8838',
            Fleet_Account_Status__c = 'Customer',
            SAP_Created_Date__c = Date.today(),
            Fleet_Use_Certificates__c = true,
            Fleet_POS_Notes__c = '**PLEASE FOLLOW ALL OPERATIONAL BEST PRACTICES AND PROCESSES WHEN USING AUTO INTEGRATE**',
            ECC_Account_Number__c = '29894',
            Credit_Limit__c = 999999,
            Accounting_Clerk__c = '04',
            Payment_Type__c = 'AR CHARGE',
            Tax_Classification__c = 'Taxable',
            Payment_Key_Terms__c = 'Due 15th of Following Month',
            PO_Required__c = true,
            Account_Type__c = 'FMC',
            ECC_AutoIntegrate__c = 'Yes',
            ECC_Corporate_Group__c = 'DT FLEET CHARGE ACCOUNTS',
            ECC_Industry_Key__c = 'Fleet Companies',
            ECC_Account_Manager__c = '03',
            ECC_Country__c = 'USA',
            ECC_State__c = 'MO',
            ECC_Account_Company__c = 'FLEET'                        
        );
        testAcctList.add(testAcct1);

        Account testAcct2 = new Account (
            Name = 'Sams Solutions'
        );
        testAcctList.add(testAcct2);
        insert testAcctList;
    }

    static testmethod void test1()
    {
        List<Account> acctList = [SELECT Id, Name, ECC_Account_Number__c FROM Account];

        String status0 = Fleet_AccountStatusRefreshController.updatePageData('');
        System.debug('Status0: ' + status0);
        System.assertEquals('Invalid Account Id received', status0, 'Incorrect Invalid Acccount received message');

        String statusB = Fleet_AccountStatusRefreshController.updatePageData('123456tyuiasdfg');
        System.debug('StatusB: ' + statusB);
        System.assert(statusB.contains('No Accounts found for Account Id:'), 'Incorrect unfound Acccount message');

        String status1 = Fleet_AccountStatusRefreshController.updatePageData(acctList[0].Id);
        System.debug('Status1: ' + status1);
        System.assertEquals('', status1, 'Incorrect Valid Acccount received message');
        
        String status2 = Fleet_AccountStatusRefreshController.updatePageData(acctList[1].Id);
        System.debug('Status2: ' + status2);
        System.assert(status2.contains('Selected Account does not have an SAP number: '), 'Incorrect SAP number missing message');

    }
}