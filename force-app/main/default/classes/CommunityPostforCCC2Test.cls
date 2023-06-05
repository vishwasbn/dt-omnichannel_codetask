@isTest(seeAllData=true)
public class CommunityPostforCCC2Test {
    @isTest   
    static  void testFeedCommunityUser()
    {
        List<FeedItem> feedItemList=[SELECT Id, ParentId, Type, Body,createdbyId,CreatedDate FROM FeedItem where type='QuestionPost' and parent.type='User' limit 1];
        communityPostForCCChandler comm= new communityPostForCCChandler();
        comm.sendMailForCCCommunity(feedItemList);
    }  
}