/***********************************************************************************************************************************
Name      : PIIDataCleanseTest
Usage     : Apex Controller to test PIIDataCleanse class
Associated Controller:PIIDataCleanse
Date      : December 2020  
************************************************************************************************************************************/
@isTest
public class PIIDataCleanseTest {
    @testSetup
    static void setup()
    {
        List<lead> leadList = new List<lead>();
        List<Contact> contactList = new List<Contact>();
        List<account> accountList = new List<account>();
        for(integer i=0;i<2;i++)
        {
            Lead newLead = new Lead() ;
            newLead.LastName = 'Swain'+' '+i;
            newLead.Company = 'BlueWave'+' '+i;
            newLead.Status = 'contacted';
            newLead.Phone='222222123';
            newLead.Email='sandbox@sandbox.com';
            newLead.MobilePhone='22222222';
            leadList.add(newLead);
        }
        
        insert leadList;
        for(integer i=0;i<2;i++)
        {
            Account newaccount = new Account();
            newaccount.Name = 'test Account'+' '+i;
            newaccount.Email__c ='sandbox@sandbox.com';
            newaccount.Fax='23457656';
            newaccount.Phone='44444444';
            accountList.add(newaccount);
        }
        insert accountList;
        for(integer i=0;i<2;i++)
        {
            Contact newcontact = new Contact();
            newcontact.FirstName = 'test';
            newcontact.LastName ='user'+' '+i;
            newcontact.Email ='sandbox@sandbox.com';
            newcontact.AccountId = accountList[i].id;
            contactList.add(newcontact);
        }
        
        insert contactList;
        
    }
    static testMethod void testMySandboxPrep() {
        Test.startTest();
        
        Test.testSandboxPostCopyScript(new PIIDataCleanse(),UserInfo.getOrganizationId(),
                                       UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
        
        Test.stopTest();
        List<lead> leadList =[SELECT Id, Phone, Email, MobilePhone FROM Lead];
        system.debug('leadList++'+leadList[0]);
        List<contact> contactList =[SELECT Id, Fax, Phone,email, HomePhone, MobilePhone FROM Contact];
        system.debug('contactList++'+contactList[0]);
        List<Account> accountList =[SELECT Id, Phone, Fax, Email__c FROM Account];
        system.debug('accountList++'+accountList[0]);
        system.assertEquals(leadList[0].Phone,'1234567891');
        system.assert(leadList[0].email==null,'Email not empty');
        system.assert(contactList[0].email==null,'Email not empty');
        system.assert(accountList[0].Email__c==null,'Email not empty');
    }
}