@isTest
public class FleetServiceParkingControllerTest {
    @testSetup static void setupTestData(){      
        Account acc = new Account(
            Name='Test Account'      
        );
        insert acc;
        
        Contact c = new Contact(
            FirstName='Test FN',
            LastName='Test LN',
            Email='test@discountire.example',
            Phone = '1231231231',
            AccountId = acc.Id
        );
        insert c;
        
        User u1 = getNewUser('Test FN1', 'Test LN1', 'Fleet Customer Community User');
        u1.ContactId = c.id;
        insert u1;
        
        User u2 = getNewUser('Test FN2', 'Test LN2', 'Standard User');
        insert u2;
        
        
    }
    
    static testmethod void testGettingContactData(){
        
        List<User> uList = [select id, name from User where LastName='Test LN1' OR LastName='Test LN2'];
        
        System.runAs(uList[0]) {
            Contact actualcont = FleetServiceParkingController.getContactInfo(uList[0].id);    
            system.assertEquals('test@discountire.example', actualcont.Email); 
        }           
    }
    
    /*static testmethod void testGettingContactDataException(){
FleetServiceParkingController.throwException = true;
try{
List<User> uList = [select id, name from User where LastName='Test LN1' OR LastName='Test LN2'];
System.runAs(uList[0]) {
FleetServiceParkingController.getContactInfo(uList[0].id);
}          
system.assert(false, 'Should have thrown an exception');
}catch(Exception e){
system.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
}         	 
}
*/   
    
    private static Map<String, String> parentConData(string isContactDataUsed)
    {
        Map<String, String> tempParentConData = new Map<String, String>();
        
        tempParentConData.put('ContactName', 'ParentConName');
        tempParentConData.put('AccountName', 'ParentAccName');
        tempParentConData.put('Email', 'sudipk417@gmail.com');
        tempParentConData.put('AccountPhone', '1234554321');
        tempParentConData.put('fleetAccountNumber', '12345');
        tempParentConData.put('fleetSize', '5');
        tempParentConData.put('isContactData', isContactDataUsed);
        
        return tempParentConData;
    }
 
    
    private static Map<String, String> newConData(string isNewDataUsed)
    {
        Map<String, String> tempNewConData = new Map<String, String>();
        
        tempNewConData.put('newContactName', 'NewConName');
        tempNewConData.put('newContactTitle', 'NewConTitle');
        tempNewConData.put('newContactEmail', 'sudipk417@gmail.com');
        tempNewConData.put('newContactPhoneNumber', '1234554321');
        tempNewConData.put('newContactMobile', '1234554321');
        tempNewConData.put('isNewData', isNewDataUsed);
        
        return tempNewConData;
    }
    
    static testmethod void testUpdateSobject(){
        Account acc = [select id from Account where name='Test Account'];
        Contact con = [select id from Contact where LastName='Test LN'];
        Map<String, String> newSobjRecord = new Map<String, String>();
        Map<String, String> newSobjRecord1 = new Map<String, String>();
        newSobjRecord.put('objectName','Account');
        newSobjRecord.put('id', string.valueof(acc.id));
        newSobjRecord.put('Phone','1231231231');
        newSobjRecord.put('Fleet_Number_of_Vehicles__c', '12345');
        
        newSobjRecord1.put('objectName','Contact');
        newSobjRecord1.put('id', string.valueof(con.id));
        newSobjRecord1.put('Email','test@gmail.com');
        
        FleetServiceParkingController.updateSobject(newSobjRecord);
        FleetServiceParkingController.updateSobject(newSobjRecord1);
    }
     
    
    static testmethod void testSendEmail(){
        getEmailTemplateData();   
        
        Map<String, String> parentContactData = parentConData('true');
        Map<String, String> newContactData = newConData('true');
        Map<String, String> newContactData1 = newConData('false');
        
        FleetServiceParkingController.sendMail(parentContactData, newContactData);
        FleetServiceParkingController.sendMail(parentContactData, newContactData1);
    }
    
    
    
    static testmethod void testSendEmailException(){
        FleetServiceParkingController.throwException = true;
        try{
            Map<String, String> parentContactData = parentConData('true');
            Map<String, String> newContactData = newConData('true');
            
            FleetServiceParkingController.sendMail(parentContactData, newContactData);
            
            system.assert(false, 'Should have thrown an exception');
        }catch(Exception e){
            system.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }         	 
    }
    
    
    public static User getNewUser(String firstName, String lastName, String profileName)
    {
        User newUser = new User();
        newUser.ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        newUser.FirstName = firstName;
        newUser.LastName = lastName;
        newUser.Email = 'test@discounttire.com';
        newUser.Username = 'test@discounttire.com' + System.currentTimeMillis();
        newUser.CompanyName = 'TEST';     
        newUser.Title = 'title';
        newUser.Alias = 'alias';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        return newUser;
    }
    
    @future
    private static void getEmailTemplateData()    
    {
        User u = [select id, name from User where LastName='Test LN1'];
        
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'Fleet Service Parking Email';
        validEmailTemplate.DeveloperName = 'unique_name_addSomethingSpecialHere';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.Body='Test Email';
        validEmailTemplate.FolderId = u.Id;  
        validEmailTemplate.HTMLValue = 'link';
        insert validEmailTemplate; 
        
    }
    
    
}