@isTest
public class manageAccountDataTableControllerTest {
	@testSetup static void setupTestdata() {
        Account newAcc = new Account(Name = 'TestAccount');
        insert newAcc;
        
        Contact newCon = new Contact(FirstName = 'TestContact', LastName = 'TestLN', AccountId = newAcc.id);
        insert newCon;
        
        Profile p = [SELECT Id FROM Profile where name='Customer Community Login User'];
        User u = new User(profileId = p.Id, contactId = newCon.id, username = 'atest@test.demo', email = 'atest@test.demo', 
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US', 
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles', 
                           alias='cspu', lastname='lastname');
        insert u;
        Group newGrp = new Group(Name='AR Group Queue', type='queue');
        insert newGrp;
        
        Id recordType = Schema.sObjectType.Case.getRecordTypeInfosByName().get('Fleet Community Case').getRecordTypeId();
        Case caseRecord = new Case(RecordTypeId = recordType);
        insert caseRecord;
    }
    
    @IsTest static void testgetRecordTypeId(){
        Case caseRecord = [SELECT Id, RecordTypeId FROM Case where RecordType.name='Fleet Community Case'];
        Id recordId = manageAccountDataTableController.getRecordTypeId();
        System.assertEquals(recordId, caseRecord.RecordTypeId); 
    }
    
     @IsTest static void testgetRecordTypeIdException(){
      manageAccountDataTableController.throwException = true;
        try{
            manageAccountDataTableController.getRecordTypeId();
            system.assert(false, 'Should have thrown an exception');
        }catch(Exception e){
            system.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }         	 
    }
    
    @IsTest static void testgetAccounts(){     
        Account acc = [select id, name from Account where Name='TestAccount'LIMIT 1];
        Id accId = manageAccountDataTableController.getAccounts();
        System.assertEquals(accId, acc.id);                                 	 
    }
    
    @IsTest static void testgetAccountsException(){
      manageAccountDataTableController.throwException = true;
        try{
            manageAccountDataTableController.getAccounts();
            system.assert(false, 'Should have thrown an exception');
        }catch(Exception e){
            system.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }         	 
    }
    
    @IsTest static void testgetContact(){                
        User user = [select id, name, contactId  from user where lastname = 'lastname' limit 1];
        user u = manageAccountDataTableController.getContact(user.id);
        System.assertEquals(u.contactId, user.contactId);               	 
    }
    
     @IsTest static void testgetContactException(){
      manageAccountDataTableController.throwException = true;
        try{
            User user = [select id, name, contactId  from user where lastname = 'lastname'LIMIT 1];
            manageAccountDataTableController.getContact(user.id);
            system.assert(false, 'Should have thrown an exception');
        }catch(Exception e){           
            system.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }         	 
    }
    
    @IsTest static void testgetGroupId(){
        try{
            Group grp = [select id, name, type from group where type='queue' and name='AR Group Queue' LIMIT 1];
            Id grpId = manageAccountDataTableController.getGroupId();
        	System.assertEquals(grpId, grp.id);
        }catch (DmlException e) {
            System.assertEquals(e.getMessage(), 'List has no rows for assignment to SObject');         
        }            	 
    }
    
    
    @IsTest static void testgetGroupIdException(){
      manageAccountDataTableController.throwException = true;
        try{
            manageAccountDataTableController.getGroupId();
            system.assert(false, 'Should have thrown an exception');
        }catch(Exception e){           
            system.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }         	 
    }
}