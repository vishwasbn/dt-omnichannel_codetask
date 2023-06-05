/**
 Created By : Prasad Vudi / Capgemini
 Creatted Dated : 10/12/2022
 Description : This is the test coverage for the  Fleet_DoNotSellMyPersonalInformation apex class.
 User Story Number : Salesforce-667
 */
@isTest
public class Fleet_DoNotSellMyPersonalInformationTest {
    @isTest
    public static void getUserIdTest(){
   		 Test.startTest();
         Fleet_DoNotSellMyPersonalInformation.getUserId();
         Test.stopTest();  
    }
}