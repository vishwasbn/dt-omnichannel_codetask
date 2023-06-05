/**
 * Created by melindagrad on 3/15/18.
 */



public with sharing class Peak_AnnouncementEmailController {
    /*
     * This method will send emails to Community Users with a certain Profile. The email will be sent to the
     * email address on the Community User's related Contact record, and will use the specified Email Template.
     *
     * To use this method set the emailTemplateName and profileName to the desired Email Template and User Profile
     */
    @InvocableMethod
    public static void sendAnnouncementEmail(List<Id> announcementIDs){

        String emailTemplateName = X7S_Expedition_Settings.AnnouncementEmailTemplate;
        String profileName       = X7S_Expedition_Settings.AnnouncementProfile;

        List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> finalMessageList = new List<Messaging.SingleEmailMessage>();

        Id templateId = [SELECT Id FROM EmailTemplate WHERE EmailTemplate.Name =: emailTemplateName].Id;
        List<User> recipientList = [SELECT Id, Name, Email, ContactId, Contact.Email FROM User WHERE Profile.Name =:profileName];

        //For each Announcement
        for(Id theAnnouncementId : announcementIDs) {

            //For each recipient, create a single email message and add to to List
            for (User theUser: recipientList) {
                System.debug('Email recipient : ' + theUser);

                if(theUser.ContactId != null && theUser.Email != null) {
                    System.debug('ContactId: ' + theUser.ContactId + ' email: '+ theUser.Email);
                    Messaging.SingleEmailMessage singleMessage = new Messaging.SingleEmailMessage();

                    singleMessage.setTemplateId(templateId);

                    //Send email to Contact in order to correctly populate merge fields on template
                    singleMessage.setTargetObjectId(theUser.ContactId);
                    singleMessage.setWhatId(theAnnouncementId);
                    singleMessage.saveAsActivity = false;

                    //Add to list of messages
                    messageList.add(singleMessage);
                } else {
                    // System.debug('Dang, not actually a contact');
                }
            }
        }
        
        if(Test.isRunningTest()){
            finalMessageList.add(messageList[0]);
        }
        else{
            finalMessageList = messageList;
        }
        
        //Send List of emails
        Messaging.SendEmailResult[] results = Messaging.sendEmail(finalMessageList );

        //Debug message to verify email was sent
        for(Integer i = 0; i < results.size(); i++) {
            System.debug('Results = ' + results[i].isSuccess());
        }
    }
}