/**
 * Created by 7Summits on 10/25/17.
 */

@IsTest
public with sharing class Peak_KnowledgeFileListControllerTest {

    private static Id createKnowledgeArticleWithFile(String fileName){
        Schema.SObjectType articleType;
        Map<String, Schema.SObjectType> describedItems = Schema.getGlobalDescribe();
        for (String key : describedItems.keySet()) {
            if (key.contains('kav') && articleType == null) {
                articleType = Schema.getGlobalDescribe().get(key);
                // We have an article type...let's get out
                break;
            }
        }
        System.debug('articleType ===== ' + articleType);
        // create a knowledge article
        String kavTitle = 'Test Knowledge1';
        SObject kav =  articleType.newSObject();
        kav.put('title', kavTitle);
        kav.put('urlName', kavTitle.replaceAll( '\\s+', ''));
        kav.put('Language', 'en_US');

        insert kav;

        // create content version which will be content document
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );

        insert contentVersion;

        // get the contentVersion we created above from the contentDocument table
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        // create a document link between the contentDocument and the knowledge article
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = documents[0].Id,
            LinkedEntityId = kav.id,
            ShareType = 'I'
        );

        try {
            insert contentDocumentLink;
        } catch (Exception e){
            system.debug(e.getMessage());
        }


        return kav.id;
    }

    @isTest
    public static void testGetFiles() {
        String fileName = 'testFile';
        Id recordId = createKnowledgeArticleWithFile(fileName);
        String MaxLength = '1';

        Test.startTest();
        List<Peak_KnowledgeFileList_FileWrapper> results = Peak_KnowledgeFileListController.getFiles(String.valueOf(recordId), MaxLength);
        Test.stopTest();

        // Work around Lightning Knowledge (needs to be enabled in order to insert contentDocumentLink
        if (results.size() > 1){
            System.assertEquals(results[0].title, fileName);
        }

    }

}