@isTest
public class Fleet_B2BCustomerUpdateModelTest {
    @isTest static void buildFromAccount(){
        
        Account acc = new Account(Name='Test Account');
        acc.Fleet_Use_Certificates__c = True;
        acc.Invoice_Copy_Sent__c = True; 
        //acc.Fleet_Specialist__c = '0050r000001axyNAAQ';
        acc.Fleet_Public_Notes__c = 'richTextOld';
        acc.Fleet_Private_Notes__c = 'longTextOld';
        insert acc;
        
        Account acc1 = new Account(Name='Test Account');
        acc1.Fleet_Use_Certificates__c = False;
        acc1.Invoice_Copy_Sent__c = False;
        //acc1.Fleet_Specialist__c = '0056g000001woelAAA';
        acc1.Fleet_Public_Notes__c = 'richTextNew';
        acc1.Fleet_Private_Notes__c = 'LongTextNew';
        insert acc1;
        
        Account acc2 = new Account(Name='Test Account');
        acc2.Fleet_Public_Notes__c = NULL;
        acc2.Fleet_Private_Notes__c = NULL;
        insert acc2;
        
        Contact con = new Contact(LastName='Test Contact con');
        con.FirstName = 'con First Name';
        con.Phone = '1231231231';
        con.Title = 'Con title';
        con.Email = 'con@g.com';
        con.ECC_Is_Primary_Contact__c = True;
        con.ECC_Customer_Reference_Number__c = 'test con no';
        insert con;
        
        Contact con1 = new Contact(LastName='Test Contact con1');
        con1.FirstName = 'con1 First Name';
        con1.Phone = '1231231232';
        con1.Title = 'Con1 title';
        con1.Email = 'con1@g.com';
        con1.ECC_Is_Primary_Contact__c = False;
        con1.ECC_Customer_Reference_Number__c = 'test no';
        insert con1;
        
        Contact con2 = new Contact(LastName='Test Contact con2');
        con2.FirstName = NULL;
        con2.Phone = NULL;
        con2.Title = NULL;
        con2.Email = NULL;
        con2.ECC_Customer_Reference_Number__c = NULL;
        insert con2;
        
        Contact con3 = new Contact(LastName='Test Contact con3');
        con3.ECC_Pending_Fields__c = NULL;
        con3.ECC_Contact_Person_Id__c = 'testing';
        insert con3; 
        
        Contact con4 = new Contact(LastName='Test Contact con');
        con4.ECC_Pending_Fields__c = 'FirstName';
        con4.ECC_Contact_Person_Id__c = NULL;
        insert con4;
        
        Contact con5 = new Contact(LastName='Test Contact con');
        con5.ECC_Pending_Fields__c = 'LastName';
        insert con5;
        
        Contact con6 = new Contact(LastName='Test Contact con');
        con6.ECC_Pending_Fields__c = 'Phone';
        insert con6;
        
        Contact con7 = new Contact(LastName='Test Contact con');
        con7.ECC_Pending_Fields__c = 'Title';
        insert con7;
        
        Contact con8 = new Contact(LastName='Test Contact con');
        con8.ECC_Pending_Fields__c = 'Email';
        insert con8;
        
        Contact con9 = new Contact(LastName='Test Contact con');
        con9.ECC_Pending_Fields__c = 'ECC_Is_Primary_Contact__c';
        insert con9;
        
        Contact con10 = new Contact(LastName='Test Contact con');
        con4.ECC_Pending_Fields__c = 'ECC_Customer_Reference_Number__c';
        insert con10;
        
        
        Fleet_B2BCustomerUpdateModel fb2b = new Fleet_B2BCustomerUpdateModel();
        test.startTest();
        
        fb2b.getJson();
        fb2b.buildFromAccount(acc, acc1);
        fb2b.buildFromAccount(acc, acc2);
        fb2b.buildFromContact(con, con1);
        fb2b.buildFromContact(con, con2);
        fb2b.buildFromPendingContact(con3);
        fb2b.buildFromPendingContact(con4);
        fb2b.buildFromPendingContact(con5);
        fb2b.buildFromPendingContact(con6);
        fb2b.buildFromPendingContact(con7);
        fb2b.buildFromPendingContact(con8);
        fb2b.buildFromPendingContact(con9);
        fb2b.buildFromPendingContact(con10);
        fb2b.buildDeleteContact(con3);
        fb2b.buildDeleteContact(con4);
        fb2b.getSeparateLines('Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text'+
                             'Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text' +
                             'Testing for multiple line text Testing for multiple line text Testing for multiple line text Testing for multiple line text');
        fb2b.getSeparateLinesSplitBySpace('Testing for multiple line text');
       	fb2b.getSeparateLinesSplitBySize('Testing for multiple line text');
        test.stopTest();
    }
}