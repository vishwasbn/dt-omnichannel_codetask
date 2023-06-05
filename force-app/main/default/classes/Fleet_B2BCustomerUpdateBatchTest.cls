@isTest
public class Fleet_B2BCustomerUpdateBatchTest {
    @TestSetup
    static void makeData(){

        List<Int_Message__c> messages = new List<Int_Message__c>();

        Account newAccount = new Account(Name='Test Account');

        insert newAccount;

        
        Int_Message__c message1 = new Int_Message__c();
        message1.Object_Type__c = 'Contact';
        message1.Status__c = 'Queued';
        message1.URL__c = '/b2bcustomer';
        message1.Type__c = 'ECC_OUTBOUND_CONTACT';
        message1.Group_Key__c = '7643315f359f0905';
        message1.Payload__c = '{"title":null,"publicNotes":[],"privateNotes":[],"primaryContactIndicator":"02","phoneNumber":null,"lastName":"Testerson","invoiceCopy":null,"firstName":"Testor","emailAddress":null,"eccId":"0000044300","customerReferenceNumber":null,"contactPersonId":null,"certificate":null,"accountManager":null}';
        message1.RecordId__c = newAccount.id;

        Int_Message__c message2 = new Int_Message__c();
        message2.Object_Type__c = 'Contact';
        message2.Status__c = 'Queued';
        message2.URL__c = '/b2bcustomer';
        message2.Type__c = 'ECC_OUTBOUND_CONTACT';
        message2.Group_Key__c = '7643315f359f0905';
        message2.Payload__c = '{"title":null,"publicNotes":[],"privateNotes":[],"primaryContactIndicator":"01","phoneNumber":null,"lastName":"Testerson","invoiceCopy":null,"firstName":"Testor","emailAddress":null,"eccId":"0000044300","customerReferenceNumber":null,"contactPersonId":null,"certificate":null,"accountManager":null}';
        message2.RecordId__c = newAccount.id;
        
        Int_Message__c message3 = new Int_Message__c();
        message3.Object_Type__c = 'Contact';
        message3.Status__c = 'Error';
        message3.URL__c = '/b2bcustomer';
        message3.Type__c = 'ECC_OUTBOUND_CONTACT';
        message3.Group_Key__c = '7643315f359f0905';
        message3.Payload__c = '{"title":null,"publicNotes":[],"privateNotes":[],"primaryContactIndicator":"02","phoneNumber":null,"lastName":"Testerson","invoiceCopy":null,"firstName":"Testor","emailAddress":null,"eccId":"0000044300","customerReferenceNumber":null,"contactPersonId":null,"certificate":null,"accountManager":null}';
        message3.RecordId__c = newAccount.id;
        message3.Retry_Count__c = 50;

        messages.add(message1);
        messages.add(message2);
        messages.add(message3);

        insert messages;
        
    }
    @isTest
    public static void proccessTest(){
        
        Test.setMock(HttpCalloutMock.class, new Fleet_ECC_Mock_Response());

        Test.startTest();

        Fleet_B2BCustomerUpdateBatch.process();

        Test.stopTest();               

        List<Int_Message__c> testMessages = [SELECT id FROM Int_Message__c WHERE Status__c = 'Queued'];


        System.debug('--- Start Assert---');

        System.assertEquals(1, testMessages.size(), 'One message should still be queued');

       

    }
}