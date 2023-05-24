@isTest
private class emailPublisherController_Test{

     @testSetup static void createTestData() {
         Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
         Account account1 = new Account(FirstName = 'Test Account First', LastName='Test Contact Last', RecordTypeId=personAccountRecordTypeId);
         insert account1;
         
         Account account2 = new Account(Name = 'Test Account');
         insert account2;
        
         Contact contact2 = new Contact(LastName='Test Contact', AccountId=account2.id, Email='contact@test.com');
         insert contact2;
        
         Region__c region1 = new Region__c(Name = 'TXH');
         insert region1;
         
         Store__c store1 = new Store__c(Region__c = region1.id,Store_email__c = 'test@dt.com');
         insert store1;

         Case case1 = new Case(Subject = 'Test Case 1', AccountId = account1.id,Store_new__c = store1.id);
         Case case2 = new Case(Subject = 'Test Case 2', Description='Test Description', AccountId = account1.id,Store_new__c = store1.id);
         Case case3 = new Case(Subject = 'Test Case 3', Description='Test Description', AccountId = account2.id,Store_new__c = store1.id ,ContactId=contact2.Id);
        
         List<Case> casesToInsert = new List<Case>();
         casesToInsert.add(case1);
         casesToInsert.add(case2);
         casesToInsert.add(case3);
         insert casesToInsert;


        EmailMessage emailmessage = new EmailMessage(parentid=case1.id , FromAddress = 'v@test.com', ToAddress ='t@test.com', CcAddress='cc@test.com', textbody ='This is a test class.', Incoming=true);
        insert emailmessage;

        Regional_Email__c regionemail = new Regional_Email__c(Region__c = region1.id, name ='txhregion@dt.com');
        insert regionemail;
    }
    
    static testmethod void testGetToAddress() {
        Case testCase = [select Id, Subject, AccountId, Store_New__c, (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) from Case where Subject='Test Case 1' LIMIT 1];
        Assert.areEqual(1, testCase.EmailMessages.size());
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Assert.areEqual('v@test.com', controller.getToAddress());
    }
    
    static testmethod void testGetCcAddressesWithEmailMessage() {
        Case testCase = [select Id, Subject, AccountId, Store_New__c, (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) from Case where Subject='Test Case 1' LIMIT 1];
        Assert.areEqual(1, testCase.EmailMessages.size());
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Assert.areEqual('cc@test.com', controller.getCcAddresses());
    }
    
    static testmethod void testGetCcAddressesWithoutEmailMessage() {
        Case testCase = [select Id, Subject, AccountId, Store_New__c, (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) from Case where Subject='Test Case 2' LIMIT 1];
        Assert.areEqual(0, testCase.EmailMessages.size());
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Assert.areEqual('', controller.getCcAddresses());
    }
    
    static testmethod void testIsToAddressOfCustomerTrueCase() {
        Case testCase = [select Id, Subject, AccountId, ContactId, Store_New__c, (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) from Case where Subject='Test Case 3' LIMIT 1];
        Assert.areEqual(0, testCase.EmailMessages.size());
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Assert.areEqual(true, controller.isToAddressOfCustomer());
    }
    
    static testmethod void testIsToAddressOfCustomerFalseCase() {
        Case testCase = [select Id, Subject, AccountId, Store_New__c, (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) from Case where Subject='Test Case 1' LIMIT 1];
        Assert.areEqual(1, testCase.EmailMessages.size());
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Assert.areEqual(false, controller.isToAddressOfCustomer());
    }
    
    static testmethod void testGetBccAddresses() {
        Case testCase = [select Id, Subject, AccountId, Store_New__c, (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) from Case where Subject='Test Case 3' LIMIT 1];
        Assert.areEqual(0, testCase.EmailMessages.size());
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Assert.areEqual('txhregion@dt.com,test@dt.com', controller.getBccAddresses());
    }
    
    static testmethod void testGetRegionEmails() {
        Region__c region = [select Id, Name from Region__c where Name = 'TXH' LIMIT 1];
        Case testCase = [select Id, Subject, AccountId, Store_New__c, (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) from Case where Subject='Test Case 2' LIMIT 1];
        Assert.areEqual(0, testCase.EmailMessages.size());
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Assert.areEqual('txhregion@dt.com', controller.getRegionEmails(region.Id)[0]);
    }
    
    static testmethod void testGetOriginalMessageWithEmailMessageRecord() {
        Case testCase = [select Id, Subject, AccountId, Store_New__c, (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) from Case where Subject='Test Case 1' LIMIT 1];
        Assert.areEqual(1, testCase.EmailMessages.size());
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Assert.isTrue(controller.getOriginalMessage().contains('v@test.com'));
    }
    
    static testmethod void testGetOriginalMessageWithoutEmailMessageRecord() {
        Case testCase = [select Id, Subject, AccountId, Store_New__c, (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) from Case where Subject='Test Case 2' LIMIT 1];
        Assert.areEqual(0, testCase.EmailMessages.size());
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Assert.isTrue(controller.getOriginalMessage().contains('Test Description'));
    }

    static testmethod void testOriginalMessage() {
        //createTestData();
        Case testCase = [select Id, Subject, AccountId, Store_New__c from Case where Subject='Test Case 1' LIMIT 1];
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);

        Test.startTest();  
        //test to see if original email is attached
        System.assertEquals(true, controller.getOriginalMessage().contains('This is a test class.'));
        test.StopTest();
       
    }  
    
    static testmethod void testSendBCCEmailInHTML() {
        //createTestData();
        Case testCase = [select Id, Subject, AccountId, Store_New__c from Case where Subject='Test Case 1' LIMIT 1];
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Test.startTest();
        controller.emailAddresses = 'test@test.com';
        controller.emailSubject = 'hello test';
        controller.emailBody = 'test body';
        controller.includeHTML = true;
        controller.sendBCCEmail();
        Test.stopTest();
    }
    
    static testmethod void testSendBCCEmailInText() {
        Case testCase = [select Id, Subject, AccountId, Store_New__c from Case where Subject='Test Case 1' LIMIT 1];
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCase);
        emailPublisherController controller = new emailPublisherController(stdController);
        
        Test.startTest();
        controller.emailAddresses = 'test@test.com';
        controller.emailSubject = 'hello test';
        controller.emailBody = 'test body';
        controller.includeHTML = false;
        controller.sendBCCEmail();
        Test.stopTest();
    }
}