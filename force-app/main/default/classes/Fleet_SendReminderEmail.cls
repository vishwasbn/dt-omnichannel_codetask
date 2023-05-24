global class Fleet_SendReminderEmail implements Database.Batchable<sObject>,Schedulable{
    public transient List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
      List<User> userList;
    global void execute(SchedulableContext sc) {
        Fleet_SendReminderEmail sendreminder = new Fleet_SendReminderEmail(); 
        Database.executebatch(sendreminder);
    }
    public Iterable<sObject> start(Database.BatchableContext bc) {
        List<Profile> communityProfiles = [select Id from Profile where name='Fleet Customer Community User'  limit 1];
        userList =   [select Id, hasLoggedIn__c,name,userName,firstname, createdDate,Contact.Account.AccountSource, LastLoginDate,Email from user where Contact.Account.AccountSource !='Online Inquiry Form' and LastLoginDate=null and  ProfileId = :communityProfiles[0].id];
        List<sObject> sObjList= (List<sObject>) userList;
        return sObjList;
    }
    public void execute(Database.BatchableContext bc, List<sObject> records){
        emailMessages = new List<Messaging.SingleEmailMessage>();
        Fleet_ConfigReminders__c mc = Fleet_ConfigReminders__c.getOrgDefaults();
        Date today = Date.today();
        EmailTemplate et=[Select id,name,HTMLValue,subject,Body from EmailTemplate where name='Fleet Community Account Invitation_DT'];
      //  List<User> userList2 = new List<User>();
        for(sObject userRec: records)
        {
            User userRecord = (User)userRec;            
            DateTime dT = (DateTime)userRecord.createdDate;
            Date creationDate = date.newinstance(dT.year(), dT.month(), dT.day());
            Date reminderDate = creationDate.addDays(Integer.valueOf(mc.reminderInterval__c));   
            System.debug('Days since created Date '+today.daysBetween(creationDate));
            System.debug('User Name '+userRecord.name);             
            if(Integer.valueOf(mc.reminderInterval__c)+today.daysBetween(creationDate)== 0 || Math.mod(today.daysBetween(reminderDate),Integer.valueOf(mc.reminderInterval__c))==0|| ((Integer.valueOf(mc.reminderInterval__c)+today.daysBetween(creationDate) < 0) && userRecord.hasLoggedIn__c == false)){
                userRecord.hasLoggedIn__c = true;
               // userList.add(UserRecord);                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] sendingTo = new String[]{userRecord.Email}; 
                    mail.setToAddresses(sendingTo);                 
                mail.setTemplateId(et.Id);
                mail.Subject ='Reminder - Invitation to join Community';
                mail.setBccSender(false);        
                String domain =  URL.getSalesforceBaseUrl().getHost();        
                String HTMLVal = et.HTMLValue.replace('link','<a href="https://'+domain+'/secur/forgotpassword.jsp?locale=us">Reset Password</a>');
                HTMLVal = HTMLVal.replace('{!Receiving_User.Username}',userRecord.userName);
                if(userRecord.firstName !=null)
                    HTMLVal = HTMLVal.replace('{!Receiving_User.FirstName}',userRecord.firstName);
                mail.setHtmlBody(HTMLVal);                     
                emailMessages.add( mail );                 
            }
        }
        Messaging.sendEmail( (List<Messaging.Email>) emailMessages, false );        
       
    } 
    public void finish(Database.BatchableContext bc){
         if(userList!=null && userList.size()>0)
            Database.upsert(userList);
    }
}