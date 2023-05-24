public with sharing class X7S_ArticleRatingController {
    public static final String OK = 'OK';

    @AuraEnabled
    public static void submitFeedback(String articleFeedback, String articleId) {
        List <Article_Rating__c> articleRating = [
                SELECT Id
                FROM Article_Rating__c
                WHERE Knowledge__c = :articleId
        ];

        Article_Rating_Feedback__c feedback = new Article_Rating_Feedback__c(Feedback__c = articleFeedback,
                Article_Rating__c = articleRating[0].Id);

        insert feedback;
    }

    @AuraEnabled
    public static Article_Rating__c loadArticleRating(String articleVersionId) {
        Article_Rating__c articleRating = null;

        for (Article_Rating__c ar : [
                SELECT Helpful_Count__c, Not_Helpful_Count__c
                FROM Article_Rating__c
                WHERE Knowledge__c = :articleVersionId
                LIMIT 1
        ]) {
            articleRating = ar;
        }

        if (articleRating == null) {
            articleRating = new Article_Rating__c(Helpful_Count__c = 0 , Not_Helpful_Count__c = 0);
        }

        return articleRating;
    }

    @AuraEnabled
    public static String rateArticle(String articleVersionId, Boolean helpful, Boolean rollbackVote) {
        Article_Rating__c articleRating = null;

        for (Article_Rating__c ar : [
                SELECT Helpful_Count__c, Not_Helpful_Count__c
                FROM Article_Rating__c
                WHERE Knowledge__c = :articleVersionId
                LIMIT 1
        ]) {
            articleRating = ar;
        }

        if (articleRating == null) {
            articleRating = new Article_Rating__c(
                    Knowledge__c = articleVersionId,
                    Helpful_Count__c = 0,
                    Not_Helpful_Count__c = 0
            );
        }

        if (helpful) {
            if (rollbackVote) {
                articleRating.Not_Helpful_Count__c--;
            }
            articleRating.Helpful_Count__c++;
        } else {
            if (rollbackVote) {
                articleRating.Helpful_Count__c--;
            }
            articleRating.Not_Helpful_Count__c++;
        }

        upsert articleRating;

        return OK;
    }
}