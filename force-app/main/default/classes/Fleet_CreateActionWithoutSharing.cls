public without sharing class Fleet_CreateActionWithoutSharing {

    public static String lprefix = 'Fleet_CreateAction:';

    // Create a case  (currentUser, description, subject, CASE_STATUS_NEW, CASE_ORIGIN_WEB, fleetSpecialistId)
    public Case submitCase(User communityUser, String caseDescription, String caseSubject, String CASE_STATUS_NEW, String CASE_ORIGIN_WEB, id caseAssignedUser) {


        System.debug(lprefix+'submitCase() - Start Create Case------- caseSubject=' + caseSubject);

        Id communityCaseRecordType = Schema.Sobjecttype.Case.getRecordTypeInfosByDeveloperName().get('Fleet_Community_Case').getRecordTypeId();
        System.debug(communityCaseRecordType);

        if (caseDescription == null || caseDescription == '') return null;

        Account acc = [select OwnerId from Account where Id = :communityUser.AccountId];
        String accountOwnderId = acc.OwnerId;
        System.debug(lprefix+'   account: ' + acc);

        String siteUrl = '';

        // Block out this for test because you can't access ConnectApi as a runAs user
        if(!Test.isRunningTest()){
            String ntwrkId = Network.getNetworkId();
            ConnectApi.Community comm = ConnectApi.Communities.getCommunity(ntwrkId);
            System.debug(lprefix+'   community url: '+comm.siteUrl);
            siteUrl = comm.siteUrl;
        }    
        Logger logInstance = Logger.getInstance();
        logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', 'Before Case creation');
        Case c = new Case();
        c.community_url__c = siteUrl;
        c.RecordTypeId = communityCaseRecordType;
        c.ContactId = communityUser.ContactId;
        c.AccountId = communityUser.AccountId;
        c.Status = CASE_STATUS_NEW;
        c.Subject = caseSubject;
        c.Description = caseDescription;
        c.Origin = CASE_ORIGIN_WEB;
        c.OwnerId = caseAssignedUser;

        try{
            insert c;
            logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', 'After Case creation', JSON.serialize(c));
            return c;
        } catch (DmlException e){
            logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', e);
            throw new AuraHandledException('An error occurred while trying to create the preference change request.');
        }       
    }

    // Create a task and then publish to Chatter
    public Task createTask(id fleetSpecialistId, String taskDescription, String taskSubject, String sapId, id salesforceAcctId, id fleetuser, Boolean chatterFlag)     
    {
        return createTaskDetail(fleetSpecialistId, taskDescription, taskSubject, sapId, salesforceAcctId, fleetuser, chatterFlag, false);
    }
    
    // Create a task and then publish to Chatter
    public Task createTaskDetail(id fleetSpecialistId, String taskDescription, String taskSubject, String sapId, id salesforceAcctId, id fleetuser, Boolean chatterFlag, Boolean linkTaskDetail)
    {    
        Logger logInstance = Logger.getInstance();
        System.debug(lprefix+'createTaskDetail() ENTRY - fleetSpecialistId='+ fleetSpecialistId+ ', taskSubject='+taskSubject+', taskDescription:'+taskDescription);
        // set task properties
        logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', 'Before Task creation');
        Task newTask = new Task();
        newTask.OwnerId = fleetSpecialistId;
        newTask.Subject = taskSubject;
        newTask.Description = taskDescription;  
        newTask.WhatId = salesforceAcctId;     
        newTask.WhoId = fleetuser;    

        // create task in salesforce
        try {
            // Create Task
            System.debug(lprefix+'   ------- before create task, newTask.OwnerId='+newTask.OwnerId);
            insert newTask;
            logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', 'After Task creation', JSON.serialize(newTask));
            System.debug(lprefix+'   -------- after create task');

            if(chatterFlag){
                String sfdcBaseURL = URL.getOrgDomainUrl().getHost();
                System.debug(lprefix+'  Base URL: ' + sfdcBaseURL );
                String hyperLink = '';
                if (linkTaskDetail){
                    hyperLink = sfdcBaseURL + '/lightning/r/Task/' + newTask.Id + '/view';
                } else {
                    hyperLink = sfdcBaseURL + '/lightning/o/Task/home';
                }

                logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', 'Before FeedItem creation');
                FeedItem post = new FeedItem();
                post.ParentId = fleetSpecialistId; 
                post.Title = newTask.Subject;
                post.Body = 'A new task has been created and assigned to you. Click the link to view in your tasks.';
                post.LinkUrl = hyperLink;
                insert post;
                logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', 'After FeedItem creation', JSON.serialize(post));
                System.debug(lprefix+'  Chatter Post: '+post);
            }
            

        } catch (DmlException e) {
            logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', e);
            System.debug(e.getStackTraceString());
        }

        System.debug(lprefix+'createTaskDetail() EXIT - newTask='+newTask);
        return newTask;
    }    
        
    // Just publish to Chatter
    public String postToChatter(id chatterOwnerId, String chatterSubject, id caseId, String salutation, String accountName){
        Logger logInstance = Logger.getInstance();
        try {

            if(chatterOwnerId == null){
                List<CollaborationGroup> chatterGroups = [SELECT Id, Name FROM CollaborationGroup WHERE name = 'AR Notification'];
                System.debug(lprefix+'chatter group:'+chatterGroups);
                if(chatterGroups.size() > 0) {
                    System.debug(chatterGroups[0]);
                    chatterOwnerId = chatterGroups[0].id;
                }
                System.debug(lprefix+'AR Group ID---------------' + chatterOwnerId );
            }
            
            // Post to chatter Feed
            String sfdcBaseURL = URL.getOrgDomainUrl().getHost();
            System.debug(lprefix+'Base URL: ' + sfdcBaseURL );
            String hyperLink = sfdcBaseURL + '/lightning/r/Case/' + caseId +'/view';

            logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', 'Before FeedItem creation');
            FeedItem post = new FeedItem();
            post.ParentId = chatterOwnerId; 
            post.Title = chatterSubject;
            post.Body = salutation + ' - A new Case for Account ' + accountName + ' has been created. Please click the link below to view your case.';
            post.LinkUrl = hyperLink;
            insert post;
            logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing', 'After FeedItem creation', JSON.serialize(post));
            System.debug(lprefix+'Chatter Post: '+post);

        } catch (DmlException e) {
            logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing',e);
            System.debug(e.getStackTraceString());
            return 'Error Posting to chatter';
        }

        return 'success';
    } 
    

    // Send and email confirming that the request was successful
    public String sendEmailNotificaiton(string messageSubject, String messageType, String toAddress, String templateName, id caseId, String fromAddress, id contactId){               
        Logger logInstance = Logger.getInstance();
        System.debug(lprefix+'-----sendEmailNotificaiton() ---------------------');
        System.debug(messageSubject);
        System.debug(messageType);
        System.debug(toAddress);
        System.debug(templateName);
        System.debug(caseId);
        System.debug(fromAddress);
        System.debug(contactId);
        System.debug(lprefix+'----------------------');        
        
        //get email template id
        String templateId = getTemplateId(templateName);

        // Don't send email if template is not found
        if (templateId == null) {
            return 'Email not sent';
        }        
       
       
        //Check for OWA
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :fromAddress];
        OrgWideEmailAddress owa = null;
        if (owaList.size() > 0) {
            owa = owaList[0];
            System.debug(lprefix+'  Setting OrgWideEmailAddress: ' + owa.Address + ' with display name: ' + owa.DisplayName);
        }                
        
        //build email
        Messaging.SingleEmailMessage mail = buildEmail(new String[]{toAddress}, fromAddress, owa, caseId, contactId, templateId);
       
        // send email        
        try {
            Messaging.SendEmailResult[] result =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug(lprefix+'  Email Result: ' + result.toString());

            if (result.get(0).isSuccess()) {
                return 'Email message send successfully';
            }
            else {
                System.debug(JSON.serialize(result.get(0).getErrors()));
                return 'WARNING! message not sent successfully';
            }

        } catch (exception e) {
            logInstance.log('Create Action Without Sharing', 'Fleet_CreateActionWithoutSharing',e);
            System.debug(e.getMessage());
            return 'message not sent successfully';                       
        }

    }


    public Messaging.SingleEmailMessage buildEmail(List<String> toAddresses, String fromAddress, OrgWideEmailAddress owa, Id whatId, Id targetObjectId, Id templateId) {

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        String senderDisplayName = emailSettings.Fleet_SenderDisplayName__c;
        System.debug(lprefix+'--- BUILD EMAIL -----');

        // Build
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        if (owa != null) {
            mail.setOrgWideEmailAddressId(owa.Id);
        } else {
            mail.setReplyTo(fromAddress);
            mail.setSenderDisplayName(fromAddress);
        }

        mail.setToAddresses(toAddresses);
        mail.setUseSignature(false);
        mail.setSaveAsActivity(true);
        mail.setWhatId(whatId);
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(targetObjectId); 

        System.debug(lprefix+'email Message');
        System.debug(mail);
        return mail;
    }

    public String getTemplateId(String emailTemplateName) {
        
        List<EmailTemplate> templateList = [SELECT Id from EmailTemplate WHERE DeveloperName = :emailTemplateName limit 1];
               
        //---Handle email template not found
        if (templateList.size() < 1) {
            System.debug(lprefix+'WARNING! = No email Template found with name: ' + emailTemplateName);
            return null;
        }
        return templateList[0].Id;
    }
}