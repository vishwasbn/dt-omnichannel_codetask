@isTest
public class LeadAssignmentRRTest {
     static testMethod void testGetSummary() {
         List<Lead> newLead = new List<Lead>();
         List<Lead> oldLead = new List<Lead>();
         List<Lead> newLeadExactMatch = new List<Lead>();
         List<Lead> newLeadWithState = new List<Lead>();
         List<Lead> newLeadAllState = new List<Lead>();
         List<Id> uIdList = new List<Id>();
    
        String orgId = UserInfo.getOrganizationId();  
        String dateString =   
        String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));  
        String uniqueName = orgId + dateString + randomInt; 
         
        Id profileId = [Select Id From Profile Where Name ='Fleet Customer Community User'].Id;
        Account acc = Fleet_TestUtility.createAccount('Test Account');
        insert acc;
        Contact con = Fleet_TestUtility.createContact('test','Contact','test@gmail.com',acc.Id);
        insert con;
        Contact con2 = Fleet_TestUtility.createContact('test2','Contact2','test2@gmail.com',acc.Id);
        insert con2;
        Contact con3 = Fleet_TestUtility.createContact('test3','Contact3','test3@gmail.com',acc.Id);
        insert con3;
        Contact con4 = Fleet_TestUtility.createContact('test4','Contact4','test4@gmail.com',acc.Id);
        insert con4;
        Contact con5 = Fleet_TestUtility.createContact('test5','Contact5','test5@gmail.com',acc.Id);
        insert con5;
         
         User u = 
             //Fleet_TestUtility.createCommunityUser(con.Id,profileId,'Satya','Siva');
         new User(  
            FirstName = 'firstName1',  
            LastName = 'lastName1',  
            email = uniqueName + '1@sfdc' + orgId + '.org',  
            Username = uniqueName + '1@sfdc' + orgId + '.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profileId,
            Fleet_Assignment_State__c = 'alabama', 
            Fleet_Purchase_Category_Group__c = 'Resale',
            Fleet_Is_Specialist__c = true,
            ContactId = con.Id,
            Fleet_Assignment_City_New__c = 'Birmingham'
        );   
         insert u;
         
         User u2 = new User(  
            FirstName = 'firstName2',  
            LastName = 'lastName2',  
            email = uniqueName + '2@sfdc' + orgId + '.org',  
            Username = uniqueName + '2@sfdc' + orgId + '.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profileId,
            Fleet_Assignment_State__c = 'alabama', 
            Fleet_Purchase_Category_Group__c = 'ALL',
            Fleet_Is_Specialist__c = true,
            ContactId = con2.Id,
            Fleet_Assignment_City_New__c = 'Auburn'
        );   
         insert u2;
         
         
         User u3 = new User(  
            FirstName = 'firstName3',  
            LastName = 'lastName3',  
            email = uniqueName + '3@sfdc' + orgId + '.org',  
            Username = uniqueName + '3@sfdc' + orgId + '.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profileId,
            Fleet_Assignment_State__c = 'Texas',
            Fleet_Assignment_City_New__c = 'Abilene',
            Fleet_Purchase_Category_Group__c = 'ALL',
            Fleet_Is_Specialist__c = true,
            ContactId = con3.Id );   
         insert u3;

         User u4 = new User(  
            FirstName = 'firstName4',  
            LastName = 'lastName4',  
            email = uniqueName + '4@sfdc' + orgId + '.org',  
            Username = uniqueName + '4@sfdc' + orgId + '.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profileId,
            Fleet_Assignment_State__c = 'ALL',
            Fleet_Purchase_Category_Group__c = 'ALL',
            Fleet_Is_Specialist__c = true,
            ContactId = con4.Id );   
         insert u4;
         
         User u5 = new User(  
            FirstName = 'firstName5',  
            LastName = 'lastName5',  
            email = uniqueName + '5@sfdc' + orgId + '.org',  
            Username = uniqueName + '5@sfdc' + orgId + '.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profileId,
            Fleet_Assignment_State__c = 'ALL',
            Fleet_Purchase_Category_Group__c = 'Resale',
            Fleet_Is_Specialist__c = true,
            ContactId = con5.Id );   
         insert u5;
         
         uIdList.add(u.id);
         uIdList.add(u2.id);
         uIdList.add(u3.id);
         uIdList.add(u4.id);
         uIdList.add(u5.id);
         
         
         Lead l = new Lead(LastName='Satya',Fleet_Specialist_Id__c=u.id,country__c='United States', state__c='alabama', Selectedcity__c='Birmingham', Fleet_Purchase_Product__c = 'Both');
         insert l;
         Lead l2 = new Lead(LastName='Satya',Fleet_Specialist_Id__c=u2.id,country__c='United States', state__c='Texas', Selectedcity__c='Abilene', Fleet_Purchase_Product__c = 'Resale');
         insert l2;
         Lead l3= new Lead(LastName='Satya',country__c='United States', state__c='Tennessee', Selectedcity__c='Memphis',Fleet_Purchase_Product__c = 'Company Vehicles');
         insert l3;
         Lead l4 = new Lead(LastName='Satya',country__c='United States', state__c='alabama', Selectedcity__c='Birmingham', Fleet_Purchase_Product__c = 'Both');
         insert l4;
         Lead l5 = new Lead(LastName='Satya',country__c='United States', state__c='alabama', Selectedcity__c='Auburn', Fleet_Purchase_Product__c = 'Resale');
         insert l5;
  
         Lead l6 = new Lead(LastName='Satya',country__c='United States', state__c='Texas', Selectedcity__c='Angleton');
         insert l6;
         
         Lead l7 = new Lead(LastName='Satya',country__c='United States', state__c='Texas', Selectedcity__c='Abilene');
         insert l7;
         
         Lead l8= new Lead(LastName='Satya',country__c='United States', state__c='Florida');
         insert l8;
         Lead l9 = new Lead(LastName='Satya',country__c='United States', state__c='Tennessee',Selectedcity__c='Memphis',Fleet_Purchase_Product__c = 'Resale');
         insert l9;

         

         newLead.add(l);
         newLead.add(l2);
         newLead.add(l3);
         newLead.add(l4);
         newLead.add(l5);
         newLead.add(l6);
         newLead.add(l7);
         newLead.add(l8);
         newLead.add(l9);


         
         
         
         Lead l1 = new Lead(LastName='Satya',Fleet_Specialist_Id__c=u.id,country__c='United States', State__c='Alabama');
         insert l1;
         oldLead.add(l1);
         

     
         

       	test.startTest();
         LeadAssignmentRRHandler.assigntoFleetSpecialist(newLead);
         LeadAssignmentRRHandler.processLeadWithExactMatchOnInsert(newLead);
         LeadAssignmentRRHandler.processLeadWithStateAndCity(newLead);         
         LeadAssignmentRRHandler.processLeadWithPartialMatchOnInsert(newLead);
         LeadAssignmentRRHandler.processLeadWithState(newLead);
         LeadAssignmentRRHandler.processLeadWithStateAllonInsert(newLead);
         LeadAssignmentRRHandler.processLeadWithStateAll(newLead);
        test.stopTest();
         
     }
}