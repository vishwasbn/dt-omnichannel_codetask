/**
 Created By : Prasad Vudi / Capgemini
 Creatted Dated : 10/12/2022
 Description : This is the controller for the  Fleet_DoNotSellMyPersonalInformation vf page and used to fetch the ECC-ID of the portal user.
 User Story Number : Salesforce-667

 11/11/22	Prasad Vudi		Change for Salesforce-780 to send Contact SAP# if available.

 */
public class Fleet_DoNotSellMyPersonalInformation {
    public static String getUserId(){
        
        String userId = '';
        User currentUser = [Select Id, Name, Contact.Name, Contact.ECC_Contact_Person_Id__c, Account.Name, Account.ECC_Account_Number__c from User where Id = :UserInfo.getUserId()];
        System.debug(currentUser);
        
        if(String.isNotBlank(currentUser.Contact.ECC_Contact_Person_Id__c)) userId = currentUser.Contact.ECC_Contact_Person_Id__c;
        else if(String.isNotBlank(currentUser.Account.ECC_Account_Number__c)) userId = currentUser.Account.ECC_Account_Number__c+'-'+currentUser.Contact.Name;
        
        return userId;
    }
}