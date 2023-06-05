@isTest
public class Appt_ResourceAbsenceTriggerTest {   
    public static testMethod void resorceAbsenceTest() {
        Date startDat=Date.newInstance(2021,8,8);
        Date endDat=Date.newInstance(2021,8,9);
        User u;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Fleet Sales User']; 
        u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                      LocaleSidKey='en_US', ProfileId = p.Id, isActive=true,
                      TimeZoneSidKey='America/Los_Angeles', UserName='standarduserFleet@testorg.com');
        System.debug('Inside the test setup');
        insert u;
         
        ServiceResource sr = new ServiceResource(RelatedRecordId=u.id,name='Satya', Type__c='Front Room',isActive=true);
        insert sr;
        
        try
        {
            ResourceAbsence ra = new ResourceAbsence(resourceId=sr.id,start=startDat,end=endDat);
            insert ra;
        }
        catch(Exception ex){
        
        }
    }
}