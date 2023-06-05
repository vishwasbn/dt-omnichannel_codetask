@IsTest
private class Peak_FilesHelperTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = Peak_TestUtils.createTestAccount();

        String base64Data = EncodingUtil.urlDecode(Peak_TestConstants.BASE64FILE, 'UTF-8');
        
        Attachment testAttachment = new Attachment();
        testAttachment.parentId = testAccount.Id;
        testAttachment.Body = EncodingUtil.base64Decode(base64Data);
        testAttachment.Name = Peak_TestConstants.FILENAME;
        testAttachment.ContentType = Peak_TestConstants.FILETYPE;

        insert testAttachment;
    }
    
	@isTest
    public static void testGetFilesForCurrentUserForRecord() {
        Account testAccount = [select Id from Account LIMIT 1];
        Peak_Response peakResponse = Peak_FilesHelper.getFilesForCurrentUserForRecord(UserInfo.getUserId(), testAccount.Id);
        system.assertEquals(1, peakResponse.results.size());
        system.assertEquals(true, peakResponse.success);
        system.assertEquals('Attachments found', peakResponse.messages[0]);
    }
    
    @isTest
    public static void testGetFilesForCurrentUserForRecordException() {
        /*Integer s_num = 1;
        String result = String.valueOf(s_num++);
      	String fakeAccountId = Account.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
        
        Account testAccount = new Account(Id=fakeAccountId);*/
        Peak_Response peakResponse = Peak_FilesHelper.getFilesForCurrentUserForRecord(null, null);
        system.assertEquals(false, peakResponse.success);
    }
}