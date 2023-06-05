@isTest
public class Fleet_SendReminderEmailTest {
    @isTest
    public static void createCommunityUser(){
  
        Id profileId1 = [Select Id From Profile Where Name ='System Administrator'].Id;
        User adminUser = Fleet_TestUtility.createUser('',profileId1,'Satya','Siva');
        Test.startTest();
        
        /* Query Community User Profile */
        Id profileId = [Select Id From Profile Where Name ='Fleet Customer Community User'].Id;
        Account acc = Fleet_TestUtility.createAccount('Test Account');
        insert acc;
        
        Contact con = Fleet_TestUtility.createContact('test','Contact','test@gmail.com',acc.Id);
        insert con;
        
        Fleet_SendReminderEmailTest.getEmailTemplateData();
        
        //User u = Fleet_TestUtility.createCommunityUser(con.Id,profileId,'Satya','Siva');
        
        Date today = Date.today();
        DateTime dT = today;
        System.debug('cdate is '+dT);
        Date creationDate = date.newinstance(dT.year(), dT.month(), dT.day());
        Fleet_ConfigReminders__c mc = Fleet_ConfigReminders__c.getOrgDefaults(); 
        mc.reminderInterval__c = String.valueOf(today.daysBetween(creationDate));
        insert mc;
        Fleet_SendReminderEmail sret = new Fleet_SendReminderEmail();
        Database.executeBatch(sret, 2000);
    }
    
    @future
    private static void getEmailTemplateData()    
    {
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'TestTemplateForLoginReminderSatya';
        validEmailTemplate.DeveloperName = 'unique_name_addSomethingSpecialHere';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.Body='Test Email';
        validEmailTemplate.FolderId = UserInfo.getUserId();  
        validEmailTemplate.HTMLValue = 'link';
        insert validEmailTemplate; 
    }
}