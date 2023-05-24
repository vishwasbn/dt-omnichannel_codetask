//SF is forcing me to use seeAllData = true because of error - ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).
// However this test class still only tests test data created within the test class
@isTest (seeAllData = true)
private class Fleet_NotifyARControllerTest {
    static void createTestClassData() {
        System.debug('Fleet_NotifyARControllerTest...createTestClassData() ENTRY--------------');

        Account acc = new Account(
            Name = 'Test AR Notification Account Good',
            Fleet_Account_Status__c = 'Prospect',
            Fleet_AR_Notification_Comments__c = 'blah blah blah'
        );
        insert acc;

        Account accInvalid = new Account(
            Name = 'Test AR Notification Account Bad',
            Fleet_Account_Status__c = Fleet_NotifyARUtil.ACCOUNT_STATUS_SUBMITTED
        );
        insert accInvalid;

        Account accInvalid2 = new Account(
            Name = 'Test AR Notification Account Bad Two',
            Fleet_Account_Status__c = Fleet_NotifyARController.ACCOUNT_STATUS_CUSTOMER
        );
        insert accInvalid2;

        Account accInvalidNoFile = new Account(
            Name = 'Test AR Notification Account No File Attached to Contract',
            Fleet_Account_Status__c = 'Prospect'
        );
        insert accInvalidNoFile;

        Fleet_Application__c app = new Fleet_Application__c(Attachment_Status__c = 'Draft', Application_Type__c = 'Credit',
        Parent_Account__c = accInvalidNoFile.Id);
        insert app;

        Fleet_App_Attachment__c attachment = new Fleet_App_Attachment__c(
        Attachment_Type__c = 'Credit Application', 
        Fleet_Application__c = app.Id,
        Parent_Account__c = accInvalidNoFile.Id);
        insert attachment;

        System.debug('Fleet_NotifyARControllerTest...createTestClassData() EXIT');
    }

    static testMethod void testhandleNotifyARApplicationReceived() {
        System.debug('Fleet_NotifyARControllerTest...testhandleNotifyARApplicationReceived() ENTRY--');
        createTestClassData();

        Account accnt = [SELECT Id FROM Account WHERE Name='Test AR Notification Account Good'];
        system.debug(Fleet_NotifyARController.PREFIX+' TEST TEST handleNotifyARApplicationReceived(): GOOD test accnt retrieved:'+accnt);

        Account accntBad = [SELECT Id FROM Account WHERE Name='Test AR Notification Account Bad'];
        system.debug(Fleet_NotifyARController.PREFIX+' TEST TEST handleNotifyARApplicationReceived(): Bad test accnt retrieved:'+accntBad);

        test.startTest();
        String resultStr = Fleet_NotifyARController.handleNotifyARApplicationReceived(accnt.Id, '{"Fleet_Application_Type__c":"Non-Credit"}', 'This is the AR comment');
        String resultStrInvalid = Fleet_NotifyARController.handleNotifyARApplicationReceived(accntBad.Id, '{}', '');
        test.stopTest();

        Fleet_NotifyARController.ResultWrapper result = (Fleet_NotifyARController.ResultWrapper) JSON.deserialize(resultStr, Fleet_NotifyARController.ResultWrapper.class);
        Fleet_NotifyARController.ResultWrapper resultInvalid = (Fleet_NotifyARController.ResultWrapper) JSON.deserialize(resultStrInvalid, Fleet_NotifyARController.ResultWrapper.class);

        //test happy path
        Account updatedAccnt = [SELECT Id, Is_Notify_AR_Application_Received__c, Fleet_Account_Status__c, Fleet_AR_App_Sent_Date__c
                FROM Account WHERE Id = :accnt.Id];
        system.debug(Fleet_NotifyARController.PREFIX+' TEST TEST handleNotifyARApplicationReceived(): accnt after test:'+updatedAccnt);

        System.assertEquals(Fleet_NotifyARController.STATUS_SUCCESS, result.status, 'SUCCESS response expected from Fleet_NotifyARController.handleNotifyARApplicationReceived(accnt.Id)');
        System.assertEquals(Date.today(), updatedAccnt.Fleet_AR_App_Sent_Date__c, 'TODAY date expected for updatedAccnt.Fleet_AR_App_Sent_Date__c after calling Fleet_NotifyARController.handleNotifyARApplicationReceived(accnt.Id)');
        System.assertEquals(Fleet_NotifyARUtil.ACCOUNT_STATUS_SUBMITTED, updatedAccnt.Fleet_Account_Status__c, 'Submitted for AR Review expected for updatedAccnt.Fleet_Account_Status__c after calling Fleet_NotifyARController.handleNotifyARApplicationReceived(accnt.Id)');

        //test unhappy path, where account fails validation
        System.assertEquals(Fleet_NotifyARController.STATUS_ERROR, resultInvalid.status, 'Error response expected from Fleet_NotifyARController.handleNotifyARApplicationReceived(accntBad.Id)');
        System.assertEquals(Fleet_NotifyARController.TOAST_MESSAGE_ACCOUNT_APP_TYPE_BLANK, resultInvalid.message, 'App Type Blank message expected from Fleet_NotifyARController.handleNotifyARApplicationReceived(accntBad.Id)');

        System.debug('Fleet_NotifyARControllerTest...testhandleNotifyARApplicationReceived() EXIT');
    }

    static testMethod void testprevalidateAccount() {
        System.debug('Fleet_NotifyARControllerTest...testprevalidateAccount() ENTRY--');
        createTestClassData();

        Account accnt = [SELECT Id FROM Account WHERE Name='Test AR Notification Account Good'];
        system.debug(Fleet_NotifyARController.PREFIX+' TEST TEST handleNotifyARApplicationReceived(): GOOD test accnt retrieved:'+accnt);

        Account accntBad = [SELECT Id FROM Account WHERE Name='Test AR Notification Account Bad'];
        system.debug(Fleet_NotifyARController.PREFIX+' TEST TEST handleNotifyARApplicationReceived(): Bad test accnt retrieved:'+accntBad);

        Account accntBad2 = [SELECT Id FROM Account WHERE Name='Test AR Notification Account Bad Two'];
        system.debug(Fleet_NotifyARController.PREFIX+' TEST TEST handleNotifyARApplicationReceived(): Bad test accnt retrieved:'+accntBad2);

        Account accntBadNoFile = [SELECT Id FROM Account WHERE Name='Test AR Notification Account No File Attached to Contract'];
        system.debug(Fleet_NotifyARController.PREFIX+' TEST TEST handleNotifyARApplicationReceived(): Bad test accnt retrieved:'+accntBadNoFile);

        test.startTest();
        String resultStr = Fleet_NotifyARController.prevalidateAccount(accnt.Id);
        String resultStrInvalid = Fleet_NotifyARController.prevalidateAccount(accntBad.Id);
        String resultStrInvalid2 = Fleet_NotifyARController.prevalidateAccount(accntBad2.Id);
        String resultStrNoFile = Fleet_NotifyARController.prevalidateAccount(accntBadNoFile.Id);
        test.stopTest();

        Fleet_NotifyARController.ResultWrapper resultNoContracts = (Fleet_NotifyARController.ResultWrapper) JSON.deserialize(resultStr, Fleet_NotifyARController.ResultWrapper.class);
        Fleet_NotifyARController.ResultWrapper resultInvalidStatus = (Fleet_NotifyARController.ResultWrapper) JSON.deserialize(resultStrInvalid, Fleet_NotifyARController.ResultWrapper.class);
        Fleet_NotifyARController.ResultWrapper resultInvalidStatus2 = (Fleet_NotifyARController.ResultWrapper) JSON.deserialize(resultStrInvalid2, Fleet_NotifyARController.ResultWrapper.class);
        Fleet_NotifyARController.ResultWrapper resultInvalidNoFile = (Fleet_NotifyARController.ResultWrapper) JSON.deserialize(resultStrNoFile, Fleet_NotifyARController.ResultWrapper.class);

        //test pre-validation errors - NO CONTRACTS
        System.assertEquals(Fleet_NotifyARController.STATUS_ERROR, resultNoContracts.status, 'Error response expected from Fleet_NotifyARController.prevalidateAccount(accnt.Id)');
        System.assertEquals(Fleet_NotifyARController.TOAST_MESSAGE_NO_APPLICATION, resultNoContracts.message, 'No Contracts message expected from Fleet_NotifyARController.prevalidateAccount(accnt.Id)');

        //test unhappy path, where account fails validation on account status
        System.assertEquals(Fleet_NotifyARController.STATUS_ERROR, resultInvalidStatus.status, 'Error response expected from Fleet_NotifyARController.prevalidateAccount(accntBad.Id)');
        System.assertEquals(Fleet_NotifyARController.TOAST_MESSAGE_AR_ALREADY_NOTIFIED, resultInvalidStatus.message, 'ALready SUbmitted to AR  message expected from Fleet_NotifyARController.prevalidateAccount(accntBad.Id)');
        System.assertEquals(Fleet_NotifyARController.STATUS_ERROR, resultInvalidStatus2.status, 'Error response expected from Fleet_NotifyARController.prevalidateAccount(accntBad2.Id)');
        System.assertEquals(Fleet_NotifyARController.TOAST_MESSAGE_ACCOUNT_ALREADY_CUSTOMER, resultInvalidStatus2.message, 'ALready Customer  message expected from Fleet_NotifyARController.prevalidateAccount(accntBad2.Id)');

        //test where related Contract with no file
        System.assertEquals(Fleet_NotifyARController.STATUS_ERROR, resultInvalidNoFile.status, 'Error response expected from Fleet_NotifyARController.prevalidateAccount(accntBadNoFile.Id)');
        System.assertEquals(Fleet_NotifyARController.TOAST_MESSAGE_ONLINE_APP_ALREADY_SUBMITTED, resultInvalidNoFile.message, 'No FIle Attached to Contract  message expected from Fleet_NotifyARController.prevalidateAccount(accntBadNoFile.Id)');

        System.debug('Fleet_NotifyARControllerTest...testprevalidateAccount() EXIT');
    }

    static testMethod void testPostNotificationToChatter() {
        System.debug('Fleet_NotifyARControllerTest...testPostNotificationToChatter() ENTRY--');
        createTestClassData();

        Account accnt = [SELECT Id, Name FROM Account WHERE Name='Test AR Notification Account Good'];
        system.debug(Fleet_NotifyARController.PREFIX+'     testPostNotificationToChatter(): GOOD test accnt retrieved:'+accnt);

        List<Id> accountIdList = new List<Id>();
        accountIdList.add(accnt.Id);

        test.startTest();
        Fleet_NotifyARUtil.postNotificationToChatter(accountIdList);
        test.stopTest();

        // get the Chatter feed items
        List<FeedItem> postList = [ SELECT Id, ParentId, Type, Title, Body, LinkUrl, HasLink, RelatedRecordId, IsClosed, Status FROM FeedItem WHERE ParentId = :accnt.Id ];
        System.debug('   postList.size()=' + postList.size() + ', postlist:' + postList);

        for (Integer idx = 0; idx < postList.size(); ++idx){
            System.assert(postList[idx].Body.contains('has been received and submitted to AR'), 'Chatter post body incorrect');
            System.assert(postList[idx].Body.contains('Additional comments for AR: blah'), 'Chatter post additional comments missing');
            System.assert(postList[idx].Body.contains(accnt.Name), 'Chatter post does not contain account name');
        }

        System.debug('Fleet_NotifyARControllerTest...testPostNotificationToChatter() EXIT');
    }
}