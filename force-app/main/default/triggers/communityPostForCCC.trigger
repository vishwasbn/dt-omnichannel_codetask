trigger communityPostForCCC on FeedItem (after insert) {
    system.debug('Trigger fired on feed item insert');
    communityPostForCCChandler commPost = new communityPostForCCChandler();
    commPost.sendMailForCCCommunity(trigger.new);
}