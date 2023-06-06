@IsTest
private class Peak_FileUploadControllerTest {
    public static Account testAccount = new Account();
    public static Attachment testAttachment = new Attachment();

    static void testSetup() {
        testAccount = Peak_TestUtils.createTestAccount();


        String base64Data = EncodingUtil.urlDecode(Peak_TestConstants.BASE64FILE, 'UTF-8');
        testAttachment.parentId = testAccount.Id;

        testAttachment.Body = EncodingUtil.base64Decode(base64Data);
        testAttachment.Name = Peak_TestConstants.FILENAME;
        testAttachment.ContentType = Peak_TestConstants.FILETYPE;


        insert testAttachment;
    }
    @isTest
    public static void testGetFileRestrictions() {
        Network testNetwork;
        List<Network> testNetworkList = [SELECT Id, MaxFileSizeKb, AllowedExtensions FROM Network];
        System.debug('testNetworkList ======  ' + testNetworkList);
        if (!Peak_Utils.isNullOrEmpty(testNetworkList)) {
            testNetwork = testNetworkList[0];
            if(testNetwork.MaxFileSizeKb == null || testNetwork.MaxFileSizeKb == 0 || testNetwork.MaxFileSizeKb > 4248){
                testNetwork.MaxFileSizeKb = 4248;
                //If the heap issue ever gets fixed then set the max size to the Salesforce max file size of 2GB.
                //curNetwork.MaxFileSizeKb = 2097152;
            }
        }
        Network testResults = (Network)Peak_FileUploadController.getFileRestrictions().results[0];
        String testString = testResults.AllowedExtensions + testResults.MaxFileSizeKb;
        String assertString = testNetwork.AllowedExtensions + testNetwork.MaxFileSizeKb;

        System.assertEquals(assertString, testString);
    }
    @isTest
    public static void saveChunkSaveTest() {
        testSetup();
        Peak_Response testResults = Peak_FileUploadController.saveChunk(testAccount.Id, Peak_TestConstants.FILENAME, Peak_TestConstants.BASE64FILE, Peak_TestConstants.FILETYPE, null);
        Peak_ContentObject testPeakResults = (Peak_ContentObject)testResults.peakResults[0];
        System.assertEquals(testResults.success, true);
        System.assertNotEquals(testPeakResults.contentID, null);
    }
    @isTest
    public static void saveChunkAppendTest() {
        testSetup();
        Peak_Response testResults = Peak_FileUploadController.saveChunk(testAccount.Id, Peak_TestConstants.FILENAME, Peak_TestConstants.BASE64FILE, Peak_TestConstants.FILETYPE, testAttachment.Id);
        Peak_ContentObject testPeakResults = (Peak_ContentObject)testResults.peakResults[0];

        System.assertEquals(testResults.success, true);
        System.assertNotEquals(testPeakResults.contentID, null);
    }
    @isTest
    public static void saveTheFileTest() {
        testSetup();

        Attachment testAttachment = Peak_FileUploadController.saveTheFile(testAccount.Id, Peak_TestConstants.FILENAME, Peak_TestConstants.BASE64FILE, Peak_TestConstants.FILETYPE);
        String testString = testAttachment.Name + testAttachment.ContentType;
        String assertString = Peak_TestConstants.FILENAME + Peak_TestConstants.FILETYPE;

        System.assertEquals(assertString, testString);
        System.assertNotEquals(null, testAttachment.Id);
    }
    @isTest
    public static void appendToFileTest() {
        testSetup();

        Attachment testResults = Peak_FileUploadController.appendToFile(testAttachment.Id, Peak_TestConstants.BASE64FILE);
        String testString = testResults.Id + testResults.Name + testResults.ContentType;
        String assertString = testAttachment.Id + Peak_TestConstants.FILENAME + Peak_TestConstants.FILETYPE;

        System.assertEquals(assertString, testString);
    }
    @isTest
    public static void deleteAttachmentTest() {
        testSetup();

        Peak_Response testResults = Peak_FileUploadController.deleteAttachment(testAttachment.Name, testAttachment.parentId);
        Attachment deletedAttachment = [SELECT Id, IsDeleted FROM Attachment WHERE Id = :testAttachment.Id ALL ROWS];

        System.assertEquals(true, testResults.success);
        System.assertEquals(true, deletedAttachment.IsDeleted);
    }
}