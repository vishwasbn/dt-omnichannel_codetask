@isTest
public class Fleet_AccountsTransferUtilTest {
    
    public static User u2;
     public static User u;
    @testSetup static void createTestClassData() {

    }
    static testMethod void testTransfer() {
        
          Fleet_AccountsTransferUtil.search('null',null,'Te','test'); 
        System.debug('Uvalue is '+u);
        Fleet_AccountsTransferUtil.transferAccountsOwnership('owner1','owner2');
                Account acc = new Account(
            Name='Test Account',
            Fleet_Account_Status__c='Prospect'
        );
        insert acc;
        
        Contact c = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example',
            AccountId = acc.Id
        );
        insert c;
        
        acc.Fleet_Primary_Contact__c = c.Id;
        update acc;
        // Setup test data
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Fleet Sales User']; 
         u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, isActive=true,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduserFleet@testorg.com');
        System.debug('Inside the test setup');
        
        insert u;
         u2 = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                           EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, 
                           TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2Fleet2@testorg.com');
        insert u2;
        acc.ownerId=u.id;
        upsert acc;
        
        List<sObject> acctSObjectList = new List<sObject>();
        acctSObjectList.add(acc);
        
        
        Fleet_AccountsMassTransferBatch fleetMassTransferBatch = new Fleet_AccountsMassTransferBatch(acctSObjectList);
        String jobId = Database.executeBatch(fleetMassTransferBatch, 50);
        Fleet_AccountsTransferUtil.getJobStatus(jobId);
            
        Fleet_AccountsTransferUtil.search('null',null,'Te','test'); 
        System.debug('Uvalue is '+u);
        Fleet_AccountsTransferUtil.transferAccountsOwnership(u.username,u2.username);
        
    }
}