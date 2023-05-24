@isTest
private class FleetEmailToActivityServiceTest {
    @isTest 
    static void testValidEmailToActivity() {
        // Create test data
        
        Contact primaryContact = new Contact();
        primaryContact.FirstName = 'John';
        primaryContact.LastName = 'Doe';
        primaryContact.Email = 'test@test.com';
        insert primaryContact;
        
        Account account = new Account();
        account.Name = 'Test Account';
        account.Email__c='test@test.com';
        insert account;   
        
        primaryContact.AccountId = account.Id;
        update primaryContact;
        
        account.Fleet_Primary_Contact__c = primaryContact.Id;
        update account;



        
        // Create test email message
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Test Email';
        email.fromAddress = 'test@test.com';
        email.toAddresses = new List<String>{'test@test.com'};
        email.plainTextBody = 'This is a test email.';

        // Call handleInboundEmail method
        Fleet_EmailToActivityService emailHandler = new Fleet_EmailToActivityService();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(email, null);

        // Assert email message is created and linked to the account
        List<EmailMessage> messages = [SELECT Id, RelatedToId FROM EmailMessage WHERE FromAddress = 'test@test.com'];
        System.assertEquals(1, messages.size());
        System.assertEquals(account.Id, messages[0].RelatedToId);

        // Assert handleInboundEmail method returns success
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.message);
    }

    @isTest 
    static void testInvalidEmailToActivity() {
        // Create test email message with invalid from address
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Test Email';
        email.fromAddress = 'invalid@test.com';
        email.toAddresses = new List<String>{'test@test.com'};
        email.plainTextBody = 'This is a test email.';

        // Call handleInboundEmail method with invalid email message
        Fleet_EmailToActivityService emailHandler = new Fleet_EmailToActivityService();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(email, null);

        // Assert email message is not created
        List<EmailMessage> messages = [SELECT Id FROM EmailMessage WHERE FromAddress = 'invalid@test.com'];
        System.assertEquals(0, messages.size());

        // Assert handleInboundEmail method returns error message
        System.assertEquals(false, result.success);
    }

    @isTest 
    static void testNoAccountFound() {
        // Create test email message with valid from address but no matching account
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Test Email';
        email.fromAddress = 'test@test.com';
        email.toAddresses = new List<String>{'test@test.com'};
        email.plainTextBody = 'This is a test email.';

        // Call handleInboundEmail method with email message and no matching account
        Fleet_EmailToActivityService emailHandler = new Fleet_EmailToActivityService();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(email, null);

        // Assert email message is not created
        List<EmailMessage> messages = [SELECT Id FROM EmailMessage WHERE FromAddress = 'test@test.com'];
        System.assertEquals(0, messages.size());

        // Assert handleInboundEmail method returns error message
        System.assertEquals(false, result.success);
    }
}