/* Copyright © 2016-2018 7Summits, Inc. All rights reserved. */
@IsTest
private class Peak_KnowledgeSiteMapControllerTest {
    
    
    @isTest static void test_siteUrl() {
        Schema.SObjectType articleType;
        Map<String, Schema.SObjectType> describedItems = Schema.getGlobalDescribe();
        for (String key : describedItems.keySet()) {
            if (key.endsWith('kav')) {
                articleType = Schema.getGlobalDescribe().get(key);
                // We have an article type...let's get out
                break;
            }
        }
        List<String> documentsTitles = new List<String>{'Article One', 'Test Knowledge Two', 'Test Knowledge Three','Test Knowledge Four','Test Knowledge Five','Test Knowledge Six'};
            
            List<SObject> sobjList=new List<SObject>();
            List<SObject> sobjListInsertedKav=new List<SObject>();
        
        for (String title : documentsTitles) {
            SObject kav =  articleType.newSObject();
            kav.put('title', title);
            kav.put('urlName', title.replaceAll( '\\s+', ''));
            kav.put('Language', 'en_US');
            kav.put('IsVisibleInPkb', true);
            
            sobjList.add(kav);
           
        }
        insert sobjList;
        
        //Dynamic SOQL
        String filterQuery = 'SELECT KnowledgeArticleId FROM ' + articleType + ' where ID in (\''+'\'' ;
        for(sObject rcd:sobjList){
            filterQuery=filterQuery+',\''+ rcd.Id + '\'';
        }
        filterQuery=filterQuery+')';
        
        //query to get list of inserted Knowledge__kav
        sobjListInsertedKav=Database.query(filterQuery);
        
        // publishing the list of all inserted Knowledge__kav
        for(SObject insertedRcd: sobjListInsertedKav) {
            KbManagement.PublishingService.publishArticle((String)insertedRcd.get('KnowledgeArticleId'), true);
            
        }
        
        
        Peak_KnowledgeSiteMapController controller = new Peak_KnowledgeSiteMapController();
        
        String url = controller.siteUrl;
        system.assert(url.length() > 0);
    }
    
    @isTest static void test_Search() {
        Schema.SObjectType articleType;
        Map<String, Schema.SObjectType> describedItems = Schema.getGlobalDescribe();
        for (String key : describedItems.keySet()) {
            if (key.endsWith('kav')) {
                articleType = Schema.getGlobalDescribe().get(key);
                // We have an article type...let's get out
                break;
            }
        }
        List<String> documentsTitles = new List<String>{'Article One', 'Test Knowledge Two', 'Test Knowledge Three','Test Knowledge Four','Test Knowledge Five','Test Knowledge Six'};
            
            List<SObject> sobjList=new List<SObject>();
            List<SObject> sobjListInsertedKav=new List<SObject>();
        
        for (String title : documentsTitles) {
            SObject kav =  articleType.newSObject();
            kav.put('title', title);
            kav.put('urlName', title.replaceAll( '\\s+', ''));
            kav.put('Language', 'en_US');
            kav.put('IsVisibleInPkb', true);
            
            sobjList.add(kav);
           
        }
        insert sobjList;
        
        //Dynamic SOQL
        String filterQuery = 'SELECT KnowledgeArticleId FROM ' + articleType + ' where ID in (\''+'\'' ;
        for(sObject rcd:sobjList){
            filterQuery=filterQuery+',\''+ rcd.Id + '\'';
        }
        filterQuery=filterQuery+')';
        
        //query to get list of inserted Knowledge__kav
        sobjListInsertedKav=Database.query(filterQuery);
        
        // publishing the list of all inserted Knowledge__kav
        for(SObject insertedRcd: sobjListInsertedKav) {
            KbManagement.PublishingService.publishArticle((String)insertedRcd.get('KnowledgeArticleId'), true);
            
        }
        
        Peak_KnowledgeSiteMapController controller = new Peak_KnowledgeSiteMapController();
        controller.siteSearchLimit = 100;
        controller.ceiling = 5;
        List<List<KnowledgeArticleVersion>> articles = controller.listOfAllArticles;
        System.assertNotEquals(null, articles);
    }
}