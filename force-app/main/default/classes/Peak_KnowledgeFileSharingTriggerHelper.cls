/* Copyright © 2016-2017 7Summits, Inc. All rights reserved. */

public with sharing class Peak_KnowledgeFileSharingTriggerHelper {
    public static void handleBeforeInsert(List<ContentDocumentLink> newList){
        for(ContentDocumentLink contentLink : newList) {
            Schema.SObjectType sobjectType = contentLink.LinkedEntityId.getSObjectType();
            Map<String, Schema.SObjectType> describedItems = Schema.getGlobalDescribe();
            for (String key : describedItems.keySet()) {
                if (key.contains('kav')) {
                    if(Schema.getGlobalDescribe().get(key) == sobjectType){
                        contentLink.Visibility='AllUsers';
                    }
                }
            }
        }
    }
}