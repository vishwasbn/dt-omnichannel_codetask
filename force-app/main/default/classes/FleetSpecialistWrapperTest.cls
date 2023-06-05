@isTest
public class FleetSpecialistWrapperTest {
@isTest
   public static void validateFleetSpecialistWrapperTest(){
       Profile p = [SELECT Id FROM Profile WHERE Name='Fleet Sales User']; 
        User specialistLess50 = new User(Alias = 'standl', Email='specialistLess50@testorg.com', 
                                         EmailEncodingKey='UTF-8', LastName='specialistLess50', LanguageLocaleKey='en_US', 
                                         LocaleSidKey='en_US', ProfileId = p.Id, 
                                         TimeZoneSidKey='America/Los_Angeles', UserName='specialistLess50@testorg.com');
        specialistLess50.Fleet_Specialist_Assignment_Group__c = '1-50';
        specialistLess50.Fleet_Is_Specialist__c = true;
        FleetSpecialistWrapper[] userList = new List<FleetSpecialistWrapper>();
       userList.add( new FleetSpecialistWrapper(specialistLess50));
       userList.sort();
       FleetSpecialistWrapper obj=new FleetSpecialistWrapper(specialistLess50);
       obj.compareTo(obj);
}
}