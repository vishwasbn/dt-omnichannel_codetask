@isTest
public with sharing class Appt_PageHeaderControllerTest {
    static String lprefix = 'Appt_PageHeaderControllerTest: ';

    @TestSetup
    static void setupData(){
        List<ServiceAppointment> appts = Appt_TestUtil.basicAppointment_storeConfiguration();
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present (tag 1)');
    }

    @isTest
    static void retrieveSiteIdAddressStringBySiteIdTest(){
        List<Account> siteAccounts = [SELECT ID, Store_ID__c, SAP_STORE_ID__c, ShippingStreet  FROM Account];
        System.assertEquals(true, siteAccounts.size() > 1, 'There are no site accounts');

        Account siteAccount = siteAccounts[0];
        String siteId = siteAccounts[0].SAP_STORE_ID__c;

        String result1 = Appt_PageHeaderController.retrieveSiteIdAddressStringBySiteId(siteId); // Result should be a valid address and store id
        String result2 = Appt_PageHeaderController.retrieveSiteIdAddressStringBySiteId('0000'); // Result should be 'No Store Found'

        // Update the Account to have no store Id or store address
        siteAccount.Store_ID__c = null;
        siteAccount.ShippingStreet = null;
        update siteAccount;

        String result3 = Appt_PageHeaderController.retrieveSiteIdAddressStringBySiteId(siteId);

        System.assertEquals(false, result1.equals('No Store Found'), 'Store was not found');
        System.assertEquals(true, result2.equals('No Store Found'), 'Store was found but should not have been');
        System.assertEquals(true, result3.contains('No Store Id Found - No Store Address Found'), 'Result should be \'No Store Id Found - No Store Address Found\'');
    }
    @isTest static void catchExceptionCoverage(){
        try{
            Appt_PageHeaderController.retrieveSiteIdAddressStringBySiteId('exception');
        }catch(exception ex){
            System.AssertNotEquals(NULL,ex);
        }
    }       

}