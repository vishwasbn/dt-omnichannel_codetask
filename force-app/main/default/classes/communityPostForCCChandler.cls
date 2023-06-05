public class communityPostForCCChandler {
    public void sendMailForCCCommunity(List<FeedItem> feed)
    {
        system.debug('feed++++++'+feed);
        for (FeedItem feedItem: feed) { 
            String AccKeyPrefix = Account.sObjectType.getDescribe().getKeyPrefix();
            String CaseKeyPrefix = Case.sObjectType.getDescribe().getKeyPrefix();
            String UserKeyPrefix = User.sObjectType.getDescribe().getKeyPrefix();
            OrgWideEmailAddress owa = [select id, DisplayName, Address from OrgWideEmailAddress where DisplayName='Customer Relations'];
            String parentId = feedItem.parentId;
            User userRecord= [select name from user where id=:feedItem.CreatedById ];
            Date feeddate = feedItem.CreatedDate.date();
            String formattedFeedDate = feeddate.format();
            String body = 'Date:&nbsp' +formattedFeedDate+'<br/>';
            body +='ID:&nbsp'+feedItem.Id+'<br/>';
            body += 'Created By:&nbsp'+String.valueOf(userrecord.name)+'<br/>';
            body += 'Feed Item Type:&nbsp'+feedItem.type+'<br/>';
            String userList = '';
            if(!test.isRunningTest())
            {
                userList =System.Label.CCC_NotificationUsers;  
            }
            else
            {
                userList='pinky.reghu@discounttire.com' ; 
            }
            List<String> settoAddresses = userList.split(',');
            if (parentId.startsWith(AccKeyPrefix))
            {
                system.debug('Parent of the feed item is Account'+parentId);
                Account accRecord = [SELECT Id,Name,IsPersonAccount ,recordtype.name FROM account where id=:parentId];
                if(accRecord!=null && accRecord.IsPersonAccount ==True)
                {
                    String accountType= accRecord.recordtype.name;
                    if(accountType.contains('Person'))
                    {
                        system.debug('Parent recordtype of the feed item is'+accountType);
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setOrgWideEmailAddressId(owa.Id);
                        mail.setSaveAsActivity(false);
                        mail.setHtmlBody(body);
                        mail.setSubject('NEW Community Activity');
                        mail.setToAddresses(settoAddresses);
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                    }
                }
            }
            else if(parentid.startsWith(CaseKeyPrefix))
            {
                Case caseRecord =[select id, caseNumber ,recordtype.name from case where id=: parentid];
                String caseRecordtypeName = caseRecord.recordtype.name;
                if(caseRecordtypeName.contains('CCC'))
                {
                    system.debug('Parent recordtype of the feed item is'+caseRecordtypeName);
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setOrgWideEmailAddressId(owa.Id);
                    mail.setSaveAsActivity(false);
                    mail.setHtmlBody(body);
                    mail.setSubject('NEW Community Activity');
                    mail.setToAddresses(settoAddresses);
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
                }
            }
            else if(parentid.startsWith(UserKeyPrefix))
            {
                User userRec=[SELECT Account.name,account.recordtypeId, ContactId,contact.name, Id, Name FROM User where id =:parentId];
                if(userRec.account != null && userRec.account.recordtypeId != null){
                    Recordtype getRecordType =[select id, name from recordtype where id=:userRec.account.recordtypeId];
                    system.debug('getRecordType++'+getRecordType);
                    String accRecordtypeName = getRecordType.name;
                    if(accRecordtypeName.contains('Person'))
                    {
                        system.debug('Parent recordtype of the feed item is'+accRecordtypeName);
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setOrgWideEmailAddressId(owa.Id);
                        mail.setSaveAsActivity(false);
                        mail.setHtmlBody(body);
                        mail.setSubject('NEW Community Activity');
                        mail.setToAddresses(settoAddresses);
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });               
                    }    
                }
            }
        }
    }
}