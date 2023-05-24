@IsTest
public class LeadAssignmentRRTriggerTest {
@IsTest
    static void testLead()
    {
         //UserRole r = new UserRole(DeveloperName = 'B2B', Name = 'System Administartor');
         //insert r;
        User testUser1 = new User();
        testUser1.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Fleet Sales User'].Id;
        testUser1.FirstName = 'firstName';
        testUser1.LastName = 'lastName';
        testUser1.Email = 'test1@test.com';
        testUser1.Username = 'test1@test.com' + System.currentTimeMillis();
        testUser1.CompanyName = 'TEST';
        testUser1.Title = 'title';
        testUser1.Alias = 'ali11';
        testUser1.TimeZoneSidKey = 'America/Los_Angeles';
        testUser1.EmailEncodingKey = 'UTF-8';
        testUser1.LanguageLocaleKey = 'en_US';
        testUser1.LocaleSidKey = 'en_US';
        testUser1.Fleet_Is_Specialist__c=true;

        insert testUser1;
        System.runAs(testUser1) {}
        test.startTest();
        List<Lead> lstLead =   new List<Lead>{
                          new Lead(Company = 'JohnMiller', LastName = 'Mike', Status = 'Open',Fleet_How_Hear__c='Store',Fleet_Years_Business__c=5,Fleet_Purchase_Product__c='Both',State__c='MH'),
                          new Lead(Company = 'Nike', LastName = 'John', Status = 'Open',Fleet_How_Hear__c='Website',Fleet_Years_Business__c=6,Fleet_Purchase_Product__c='Resale',State__c='MH'),
                          new Lead(Company = 'Miles', LastName = 'Davis', Status = 'Open',Fleet_How_Hear__c='Store',Fleet_Years_Business__c=7,Fleet_Purchase_Product__c='Company Vehicles',State__c='MH'),
                          new Lead(Company = 'Reebok', LastName = 'Hillen', Status = 'Open',Fleet_How_Hear__c='Website',Fleet_Years_Business__c=8,Fleet_Purchase_Product__c='Both',State__c='MH'),
                          new Lead(Company = 'Addidas', LastName = 'Shrin', Status = 'Open',Fleet_How_Hear__c='other',Fleet_Years_Business__c=9,Fleet_Purchase_Product__c='Resale',State__c='MH')
                         }; 
        
        insert lstLead;
        lstLead[0].LastName = 'MikeMuller';
        update lstLead;
        test.stopTest();  
    }
}