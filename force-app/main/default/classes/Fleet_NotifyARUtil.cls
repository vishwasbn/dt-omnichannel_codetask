public class Fleet_NotifyARUtil {
    
    public static final String PREFIX = 'FLEETARUtil:';

    public static final String ACCOUNT_STATUS_SUBMITTED = 'Submitted for AR Review';
    public static final String APPLICATION_STATUS_SUBMITTED = 'Submitted';
    public static final String AR_APP_STATUS_PENDING = 'Pending';

    public static final String CHATTER_GROUP = 'AR Notification';
    public static final String CHATTER_MESSAGE_1 = ' - An Application for Account ';
    public static final String CHATTER_MESSAGE_2 = ' has been received and submitted to AR. Please review the application for account approval. ';
    public static final String CHATTER_MESSAGE_3 = '\n\nAdditional comments for AR: ';

    //-- Broke logic out of Controller for batch process to reference. Chatter post is now handled within this method, so 
    //-- Fleet Notify AR Application Received (process builder) is no longer needed and will be inactivated - DTFS-730
    public static Boolean notifyARApplicationReceived(Id accntId, String appType, Id primaryContactId, String additionalARComments) {
        system.debug(PREFIX+' notifyARApplicationReceived() -  accntId = '+accntId);

        // passed validation, now retrieve and update account record
        Account accnt = [SELECT Id, Fleet_Account_Status__c, Fleet_AR_App_Sent_Date__c, Fleet_AR_App_Status__c, 
                            Fleet_AR_Notification_Comments__c, Fleet_Application_Type__c, Fleet_Primary_Contact__c
                            FROM Account WHERE Id = :accntId];
        system.debug(PREFIX+'     accnt retrieved:'+accnt);

        if (accnt != null) {
            // get the Fleet Application for the Account
            List<Fleet_Application__c> faList = [SELECT Id, Application_Status__c, Fleet_Application_Format__c from Fleet_Application__c 
                                                    WHERE Parent_Account__c =: accnt.Id AND Is_Primary_Application__c = true];
            Fleet_Application__c fltApp = null;
            if ((faList != null) && (faList.size() > 0)){
                fltApp = faList[0];
                System.debug('     primary Fleet Application retreived:' + fltApp);
            }

            accnt.Fleet_Account_Status__c = ACCOUNT_STATUS_SUBMITTED;
            accnt.Fleet_AR_App_Sent_Date__c = Date.today();
            accnt.Fleet_AR_Notification_Comments__c = additionalARComments;
            accnt.Fleet_Application_Type__c = appType;
            accnt.Fleet_Primary_Contact__c = primaryContactId;
            accnt.Fleet_AR_App_Status__c = AR_APP_STATUS_PENDING;

            system.debug(PREFIX+'      accnt before update:'+accnt);
            update accnt;
            system.debug(PREFIX+'      accnt UPDATED:'+accnt);

            // if there is a Fleet Application, then update Status to Submitted
            if ((fltApp != null)){
                fltApp.Application_Status__c = APPLICATION_STATUS_SUBMITTED;
                update fltApp;
                System.debug('     primary Fleet Application UPDATED:' + fltApp);
            }

            //call method to post to chatter
            List<Id> idList = new List<Id>();
            idList.add(accntId);
            postNotificationToChatter(idList);

            system.debug(PREFIX+' notifyARApplicationReceived() -  return true');
            return true;
        } else {
            system.debug(PREFIX+' notifyARApplicationReceived() -  return FALSE');
            return false;
        }
    }


     /** Post AR Notification to Chatter with a hyperlink to the account detail page, which requires Apex code
     * DTFS-147  ****/
    @InvocableMethod
    public static void postNotificationToChatter(List<Id> accountIdList){
        system.debug(PREFIX+'postNotificationToChatter():ENTRY accountIdList=' + accountIdList);
        List<Account> accounts = [SELECT Id, Name, Fleet_AR_Notification_Comments__c FROM Account WHERE Id = :accountIdList];
        if (accounts != null && accounts.size() > 0) {
            for (Account acnt: accounts) {
                postChatterToAccount(acnt);
            }
        } else {
            system.debug(PREFIX+'   postNotificationToChatter(): Warning! Accounts unable to be retrieved with accountIdList=' + accountIdList);
        }

        system.debug(PREFIX+'postNotificationToChatter():EXIT');
    }

    //Post to Account chatter via Apex coide. Also @mention AR Notification chatter group
    private static void postChatterToAccount(Account account){
        system.debug(PREFIX+'postChatterToAccount():ENTRY account=' + account);
        if (account != null) {

            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();   
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();

            //@mention to post to the AR Notification Group 
            mentionSegmentInput.Id = getChatterGroupId(CHATTER_GROUP);
            messageBodyInput.messageSegments.add(mentionSegmentInput);
        
            ConnectApi.TextSegmentInput textSegmentInput1 = new ConnectApi.TextSegmentInput();
            textSegmentInput1.text = CHATTER_MESSAGE_1;   
            messageBodyInput.messageSegments.add(textSegmentInput1);
            ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputAccount = new ConnectApi.EntityLinkSegmentInput();
            entityLinkSegmentInputAccount.entityId = account.Id;   
            messageBodyInput.messageSegments.add(entityLinkSegmentInputAccount);
            ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
            textSegmentInput2.text = CHATTER_MESSAGE_2;     
            messageBodyInput.messageSegments.add(textSegmentInput2);

            //if Fleet_AR_Notification_Comments__c is populated, add to chatter post
            if (!String.isBlank(account.Fleet_AR_Notification_Comments__c)) {

                ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
                textSegmentInput3.text = CHATTER_MESSAGE_3 + account.Fleet_AR_Notification_Comments__c;     
                messageBodyInput.messageSegments.add(textSegmentInput3);
            }
        
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = account.Id;

            ConnectApi.FeedElement feedElement =
            ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);

        }

        system.debug(PREFIX+'postChatterToAccount():EXIT');
    }

    //retrieve Id of the AR Notification chatter group 
    private static String getChatterGroupId(String groupName) {
        system.debug(PREFIX+'getChatterGroupId():ENTRY  groupName=' + groupName);
        String returnId;
        List<CollaborationGroup> groups = [SELECT Id, Name FROM CollaborationGroup WHERE Name = :groupName];
        system.debug(PREFIX+'   groups retrieved are:' + groups);
        If (groups != null && groups.size() > 0) {
            returnId = groups[0].Id;
        }

        system.debug(PREFIX+'getChatterGroupId():EXIT  Id=' + returnId);
        return returnId;
    }
}