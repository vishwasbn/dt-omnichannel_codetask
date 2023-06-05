/**
 * Created by melindagrad on 3/15/18.
 */

@IsTest
public class Peak_AnnouncementEmailControllerTest {

    @IsTest
    public static void testSendAnnouncementEmail(){
        
        List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];

		User testUser = Peak_TestUtils.createStandardUser();        
        System.assertNotEquals(null, testUser.ContactId);

        //Create Test Community_Announcement List
        List<Id> testAnnouncementIDList = new List<Id>();

        //Test Community_Announcement
        Community_Announcement__c testAnnouncement =
                new Community_Announcement__c(Start_Date_Time__c = Date.newInstance(1990, 1, 1),
                        End_Date_Time__c = Date.newInstance(2090, 1, 1), Name = 'Test Announcement',
                        Announcement_Body__c = 'This is a test.', Announcement_Type__c = 'info',
                        Announcement_Channel__c = 'Default');

        insert testAnnouncement;
        System.assertNotEquals(null, testAnnouncement);

        testAnnouncementIDList.add(testAnnouncement.Id);
        Peak_AnnouncementEmailController.sendAnnouncementEmail(testAnnouncementIDList);
    }
}