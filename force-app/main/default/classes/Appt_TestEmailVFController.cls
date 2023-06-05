public class Appt_TestEmailVFController
{
    public Notification__c relatedTo {get;set;}

    public Appt_TestEmailVFController(ApexPages.StandardController stdController) {
        Notification__c localRef = (Notification__c)stdController.getRecord();
        
        String notificationId = localRef.Id;
        
        this.relatedTo = [SELECT ID, Order_Items_List__c , Vehicle_Trim__c , Vehicle_Model__c , Vehicle_Make__c ,Customer_Mobile_Phone__c , Vehicle_Year__c,Customer_Email__c , Customer_Zip__c , Customer_State__c , Customer_City__c , Customer_Street__c , Store_Google_Maps_address__c , Store_Phone_Number__c , Store_Zip__c , Store_State__c , Store_City__c, Store_Street__c, Appointment_Day_of_Week__c , Order_Date__c , Email_Template_Date_Label__c, Appointment_Time__c, Order_Number__c, Appointment_Year__c, Appointment_Date__c, Email_Template_Number_Label__c, Store_Logo__c, Customer_Name__c, Notification_Type__c FROM Notification__c WHERE Id=:notificationId];
    }
}