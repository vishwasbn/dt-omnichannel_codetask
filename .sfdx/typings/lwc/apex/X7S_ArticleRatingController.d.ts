declare module "@salesforce/apex/X7S_ArticleRatingController.submitFeedback" {
  export default function submitFeedback(param: {articleFeedback: any, articleId: any}): Promise<any>;
}
declare module "@salesforce/apex/X7S_ArticleRatingController.loadArticleRating" {
  export default function loadArticleRating(param: {articleVersionId: any}): Promise<any>;
}
declare module "@salesforce/apex/X7S_ArticleRatingController.rateArticle" {
  export default function rateArticle(param: {articleVersionId: any, helpful: any, rollbackVote: any}): Promise<any>;
}
