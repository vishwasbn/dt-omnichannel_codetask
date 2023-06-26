@IsTest
private class X7S_ArticleRatingControllerTest {
    @IsTest
    static void test_loadArticle_noVotes() {

        Knowledge__kav k = new Knowledge__kav(Title = 'Test', UrlName = 'Tes2342424234t');
        insert k;
        k = [SELECT KnowledgeArticleId,UrlName FROM Knowledge__kav WHERE Id = :k.Id];

        Test.startTest();
        Article_Rating__c ret = X7S_ArticleRatingController.loadArticleRating(k.Id);
        Test.stopTest();

        System.assertEquals(0, ret.Helpful_Count__c);
        System.assertEquals(0, ret.Not_Helpful_Count__c);
    }

    @IsTest
    static void test_loadArticle_hasVotes() {
        Knowledge__kav k = new Knowledge__kav(Title = 'Test', UrlName = 'Tes2342424234t');
        insert k;
        k = [SELECT KnowledgeArticleId,UrlName FROM Knowledge__kav WHERE Id = :k.Id];
        KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
        X7S_ArticleRatingController.rateArticle(k.Id, true, false);

        Test.startTest();
        Article_Rating__c ret = X7S_ArticleRatingController.loadArticleRating(k.Id);
        Test.stopTest();

        System.assertEquals(1, ret.Helpful_Count__c);
        System.assertEquals(0, ret.Not_Helpful_Count__c);
    }

    @IsTest
    static void test_newRating() {
        Knowledge__kav k = new Knowledge__kav(Title = 'Test', UrlName = 'Tes2342424234t');
        insert k;
        k = [SELECT KnowledgeArticleId,UrlName FROM Knowledge__kav WHERE Id = :k.Id];
        KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);

        Test.startTest();
        String ret1 = X7S_ArticleRatingController.rateArticle(k.Id, true, false);
        String ret2 = X7S_ArticleRatingController.rateArticle(k.Id, false, false);
        Test.stopTest();

        System.assertEquals(X7S_ArticleRatingController.OK, ret1);
        System.assertEquals(X7S_ArticleRatingController.OK, ret2);
    }

    @IsTest
    static void test_newRating_rolloback() {
        Knowledge__kav k = new Knowledge__kav(Title = 'Test', UrlName = 'Tes2342424234t');
        insert k;
        k = [SELECT KnowledgeArticleId,UrlName FROM Knowledge__kav WHERE Id = :k.Id];
        KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);

        Test.startTest();
        X7S_ArticleRatingController.rateArticle(k.Id, true, false);
        X7S_ArticleRatingController.rateArticle(k.Id, false, false);
        X7S_ArticleRatingController.rateArticle(k.Id, true, true);
        X7S_ArticleRatingController.rateArticle(k.Id, false, true);
        Test.stopTest();

        Article_Rating__c ret = X7S_ArticleRatingController.loadArticleRating(k.Id);

        System.assertEquals(1, ret.Helpful_Count__c);
        System.assertEquals(1, ret.Not_Helpful_Count__c);
    }

    @IsTest
    static void submitFeedbackTest() {
        Knowledge__kav k = new Knowledge__kav(Title = 'Test', UrlName = 'Tes2342424234t');
        insert k;
        k = [SELECT KnowledgeArticleId,UrlName FROM Knowledge__kav WHERE Id = :k.Id];
        KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);

        Article_Rating__c testRating = new Article_Rating__c(Knowledge__c = k.Id);
        insert testRating;

        Test.startTest();
        X7S_ArticleRatingController.submitFeedback(testRating.Id, k.Id);
        Test.stopTest();
    }
}