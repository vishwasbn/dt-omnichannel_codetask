/**
 * Created by 7Summits on 10/24/17.
 */

public with sharing class Peak_KnowledgeFileList_FileWrapper {

    @auraEnabled
    @TestVisible Public Id id {get;set;}

    @auraEnabled
    @TestVisible Public String title {get;set;}

    @auraEnabled
    @TestVisible Public Datetime lastModifiedDate {get;set;}

    @auraEnabled
    @TestVisible Public Integer contentSize {get;set;}

    @auraEnabled
    @TestVisible Public String fileExtension {get;set;}

    public Peak_KnowledgeFileList_FileWrapper(Id id, String title, Datetime lastModifiedDate, Integer contentSize, String fileExtension){
        this.id = id;
        this.title = title;
        this.lastModifiedDate = lastModifiedDate;
        this.contentSize = contentSize;
        this.fileExtension = fileExtension;
    }

}