@isTest
public class CommunityPostForCCCTest {
    @testSetup static void testdata()
    {
        Id RecordTypeIdPersonAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account a1 = new Account();
        a1.PersonEmail='test@yahoo.com';
        a1.PersonHomePhone='1234567';
        a1.PersonMobilePhone='12345678';
        a1.firstName ='test ';
        a1.lastName ='Person account';
        a1.RecordTypeId = RecordTypeIdPersonAccount;
        insert a1;
        Id RecordTypeIdCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CCC Support').getRecordTypeId();
        case case1 = new case();
        case1.RecordTypeId=RecordTypeIdCase;
        case1.AccountId=a1.Id;
        insert case1; 
    }
    static testMethod void testFeedPersonAcc()
    {
        Account acc = [select id from account limit 1 ];
        FeedItem f = new FeedItem();
        f.Body = 'test Account feed';
        f.parentID = acc.Id;
        insert f;
        system.assert( f.body!=null);
    }
    
    static testMethod void testFeedCase()
    {
        Account acc = [select id from account limit 1 ]; 
        case case1 = [select caseNumber,id from case where accountid=:acc.id ];
        FeedItem f = new FeedItem();
        f.Body = 'test case feed';
        f.parentID = case1.Id;
        insert f;
        system.assert( f.body!=null);
    }
    
}