@IsTest
public class Appt_PrivacyRequestTriggerTest {
 @IsTest
    public static void privacyTest() {
     Account a = new Account();
     a.name = 'Satya';
     insert a;
     Privacy_Request__c nc = new Privacy_Request__c();
        //Account a = new Account(name='Satya');
        nc.Account__c=a.id;
        nc.confirmed__c=true;
        insert nc;
        nc.Account__c=a.id;
        nc.confirmed__c=false;
        update nc;
    }
    
}