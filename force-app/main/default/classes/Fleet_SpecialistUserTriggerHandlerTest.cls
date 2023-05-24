@isTest 
public class Fleet_SpecialistUserTriggerHandlerTest { 
@istest 
    static void testLead()
    { 
        Fleet_SpecialistUserTriggerHandler.resetPriority();
        Id B2bRecordType= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2B').getRecordTypeId();
        Profile p = [SELECT Id FROM Profile WHERE Name='Fleet Sales User']; 
        List<Id> testLeadIds = new List<Id>();
        User user90 = new User(Alias = 'stan651', Email='specialistuser90@testorg1.com', 
                               EmailEncodingKey='UTF-8', LastName='specialistuser90', LanguageLocaleKey='en_US', 
                               LocaleSidKey='en_US', ProfileId = p.Id, Fleet_Assignment_State__c='Alabama',
                               TimeZoneSidKey='America/Los_Angeles', UserName='stan651@testorg1.com',LeadAssignmentPriority__c=0);
        user90.Fleet_Specialist_Assignment_Group__c = '100+';
        user90.Fleet_Is_Specialist__c = true;
        user90.isActive = true;
        insert user90;
         User userALL = new User(Alias = 'userAll', Email='userAll0@testorg1.com', 
                               EmailEncodingKey='UTF-8', LastName='userAllNew', LanguageLocaleKey='en_US', 
                               LocaleSidKey='en_US', ProfileId = p.Id, Fleet_Assignment_State__c='ALL',
                               TimeZoneSidKey='America/Los_Angeles', UserName='userAll0@testorg1.com',LeadAssignmentPriority__c=100);
        userALL.Fleet_Specialist_Assignment_Group__c = '100+';
        userALL.Fleet_Is_Specialist__c = true;
        userALL.isActive = true;
        insert userALL;
        Lead lead117Vehs = new Lead(LastName='TestLead33312', Company='TestLead333 yupi3', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+dtfs16712.c@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Alabama',City__c='Montgomery', Fleet_How_Hear__c='Website');
        lead117Vehs.Fleet_Number_of_Vehicles__c = 140;
        lead117Vehs.RecordtypeId = B2bRecordType;
        lead117Vehs.state__c='new';
         Lead lead118Vehs = new Lead(LastName='TestLead118', Company='TestLead333 yupi4', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+TestLead118@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', Fleet_How_Hear__c='Website');
        lead118Vehs.Fleet_Number_of_Vehicles__c = 140;
        lead118Vehs.RecordtypeId = B2bRecordType;
        lead118Vehs.state__c='new';
        
        Lead lead119Vehs = new Lead(LastName='lead119Vehs', Company='TestLead333 yupi44', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'apex+lead119Vehs@ethos.com',
                                    Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', City__c='Tucson',Fleet_How_Hear__c='Website');
        lead119Vehs.Fleet_Number_of_Vehicles__c = 140;
        lead119Vehs.RecordtypeId = B2bRecordType;
        lead119Vehs.state__c='new';
        
        Test.startTest();
        insert lead117Vehs;
        insert lead118Vehs;
        insert lead119Vehs;
        testLeadIds.add(lead117Vehs.id);
        testLeadIds.add(lead118Vehs.id);
          testLeadIds.add(lead119Vehs.id);
        Fleet_WebToLeadAssignmentController.assignLead(testLeadIds);
        Test.stopTest();
        update lead119Vehs;
        List<lead> leadlist = [SELECT Id, Name,Fleet_Purchase_Product__c, Fleet_Specialist__r.Fleet_Specialist_Assignment_Group__c,owner.name,Fleet_Specialist__r.Fleet_Assignment_State__c,Fleet_Business_Located__c FROM Lead];
        system.debug('leadlist++'+leadlist);
        //system.assert(leadlist[0].Fleet_Specialist__c!=null,leadlist[0].name+'has lead owner'+leadlist[0].owner.name+'has fleet specialist'+leadlist[0].Fleet_Specialist__c );
        //system.assert(leadlist[0].Fleet_Specialist__r.Fleet_Specialist_Assignment_Group__c=='100+' );
      //  system.assert(leadlist[1].Fleet_Specialist__c!=null);
     //    system.assert(leadlist[2].Fleet_Specialist__c!=null); 
    } 
}