/***********************************************************************************************************************************
     Name      : PIIDataCleanse
     Usage     : Apex Controller to mask the sensitive data 
     Date      : December 2020   
************************************************************************************************************************************/ 
global class PIIDataCleanse implements Sandboxpostcopy{
     /***********************************************************************************************************************************
     Method Name  : runApexclass
     Parameters   : sandboxContext
     Return Type  : void    
     Description  : To call methods on leads,contacts and accounts
   ************************************************************************************************************************************/
    global void runApexclass(sandboxContext sc)
    {
        LeadCleanse();
        contactCleanse();
        accountCleanse();
    }
     /***********************************************************************************************************************************
     Method Name  : LeadCleanse
     Return Type  : void    
     Method call  : LeadCleanse()
     Description  : To mask email, phone and mobilephone of the leads
   ************************************************************************************************************************************/
    global static void LeadCleanse()
    {
        List<lead> leadList =[SELECT Id, Phone, Email, MobilePhone FROM Lead];
        List<lead> updateLeadList= new List<lead>();
        for(lead leadRecord:leadList)
        {
            leadRecord.Phone='1234567891';
            leadRecord.Email='';
            //leadRecord.Email=leadRecord.Email+'.invalid';
            leadRecord.MobilePhone='1234567891';
            updateLeadList.add(leadRecord);
        }
        update updateLeadList;
        system.debug('updateLeadList++++'+updateLeadList);
    }
     /***********************************************************************************************************************************
     Method Name  : contactCleanse
     Return Type  : void    
     Method call  : contactCleanse()
     Description  : To mask email, phone, fax and mobilephone of the contacts
   ************************************************************************************************************************************/
    global static void contactCleanse()
    {
        List<contact> contactList =[SELECT Id, Fax, Phone,Email, HomePhone, MobilePhone FROM Contact];
        List<contact> updateContactList= new List<contact>();
        for(contact contactRecord:contactList)
        {
            contactRecord.Fax='1234567891';
            contactRecord.Email='';
            contactRecord.MobilePhone='1234567891';
            contactRecord.Phone='1234567891';
            contactRecord.HomePhone='1234567891';
            updateContactList.add(contactRecord);
            system.debug('updateContactList++++'+updateContactList);
        }
        update updateContactList;
    }
    /***********************************************************************************************************************************
     Method Name  : accountCleanse
     Return Type  : void    
     Method call  : accountCleanse()
     Description  : To mask email, phone, fax and mobilephone of the accounts
   ************************************************************************************************************************************/
    global static void accountCleanse()
    {
        List<Account> accountList =[SELECT Id, Phone, Fax, Email__c FROM Account];
        List<Account> updateAccountList= new List<Account>();
        for(Account accountRecord:AccountList)
        {
            accountRecord.Fax='1234567891';
            accountRecord.Email__c='';
            accountRecord.Phone='1234567891';
            updateAccountList.add(accountRecord);
            system.debug('updateAccountList++++'+updateAccountList);
        }
        update updateAccountList;
    }
}