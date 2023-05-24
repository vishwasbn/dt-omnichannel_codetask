/**
 * Created by 7Summits on 10/23/17.
 */

public with sharing class Peak_KnowledgeFileListController {

    @AuraEnabled
    public static List<Peak_KnowledgeFileList_FileWrapper> getFiles(String recordId, String maxLength) {

        // check maxLength value and max sure it is valid and greater than 0 and less than 1000
        Integer intMaxLength = (maxLength != null) ? integer.valueof(maxLength) : 20;
        Integer queryLimit = (intMaxLength != null && intMaxLength > 0 && intMaxLength <= 1000) ? intMaxLength : 20;

        // get list of file ids that are related to the record
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:recordId LIMIT :queryLimit];

        // iterate that list of file ids to create a list of ids to bind to query
        List<Id> fileIds = new List<Id>();
        for (ContentDocumentLink file : contentDocumentLinks) {
            fileIds.add(file.ContentDocumentId);
        }

        // get the actual files from the ids we found above
        List<ContentDocument> contentDocuments  = [SELECT Id, Title, LastModifiedDate, ContentSize, FileExtension FROM ContentDocument WHERE Id =:fileIds ORDER BY LastModifiedDate DESC];

        // Create file wrapper objects from the files to be returned to the view
        List<Peak_KnowledgeFileList_FileWrapper> results = new List<Peak_KnowledgeFileList_FileWrapper>();
        for (ContentDocument document : contentDocuments) {
            Peak_KnowledgeFileList_FileWrapper fileWrapper = new Peak_KnowledgeFileList_FileWrapper(document.Id, document.Title, document.LastModifiedDate, document.ContentSize, document.FileExtension);
            results.add(fileWrapper);
        }

        return results;
    }

}