@isTest
public with sharing class Appt_AppointmentsPageControllerTest {
    static String posString = '{"action": "CRT",'
        +'"appointmentStatus": "Pending",'
        +'"posCustomerId": "9130000081",'
        +'"hybrisCustomerId": "", '
        +'"formType": "BOP",'
        +'"orderType": "BOPIS",'
        +'"formNumber": "1009465",'
        +'"orderDate": "20201210",'
        +'"formDate": "20201210",'
        +'"hybrisOrderId": "",'
        +'"posWebOrderId": "",'
        +'"layawayNumber": "000002",'
        +'"quoteNumber": "001",'
        +'"guid": "",'
        +'"customerType": "Retail",'
        +'"firstName": "John",'
        +'"lastName": "Johnson",'
        +'"emailAddress": "JOHN@DT.TEST.com",'
        +'"mobileAreaCode": "555",'
        +'"mobilePhoneNumber": "1234567",'
        +'"homeAreaCode": "555",'
        +'"homePhoneNumber": "1234567",'
        +'"workAreaCode": "555",'
        +'"workPhoneNumber": "1234567",'
        +'"siteId": "6667",'
        +'"textOptIn": false,'
        +'"emailAddressOptIn": false,'
        +'"address1": "123 E Camelback Rd",'
        +'"address2": "",'
        +'"zipCode": "85395",'
        +'"city": "PHOENIX",'
        +'"state": "Arizona",'
        +'"country": "United States",'
        +'"posCustomerVehicleId": "1002007",'
        +'"hybrisCustomerVehicleID": "",'
        +'"vehicleType": "Fitment",'
        +'"year": "2012",'
        +'"make": "HONDA",'
        +'"model": "CIVIC COUPE",'
        +'"vehicleId": "32570",'
        +'"trimId": "8427",'
        +'"assemblyId": "5469|8427|D",'
        +'"articles": [{ '
            +'"quantity": 1,'
            +'"size": "195 65   R15    91H SL BSW ",'
            +'"articleType": "Tire",'
            +'"articleId": "32491",'
            +'"description": "MCH DEFENDER T H"'
        +'}]'
        +'}';


    @isTest
    static void appointmentsPageControllerTest(){
        PageReference pageRef1 = Page.Appt_AppointmentsPage; // Add your VF page Name here
        PageReference pageRef2 = Page.Appt_AppointmentsPage;
       
        pageRef1.getParameters().put('jsonArgs', posString);
        Map<String, Object> posStringMap = (Map<String,Object>) JSON.deserializeUntyped(posString);
        for(String key: posStringMap.keyset()){
            pageRef2.getParameters().put(key, String.valueOf(posStringMap.get(key)));
        }

        Test.startTest();

        Test.setCurrentPage(pageRef1);
        Appt_AppointmentsPageController apptPageController1 = new Appt_AppointmentsPageController();
        apptPageController1.logInput();

        System.assertEquals(true, apptPageController1.intMessage.Status__c.equals('Successful'), 'Test 1 should be successful');
        
        Test.setCurrentPage(pageRef2);
        Appt_AppointmentsPageController apptPageController2 = new Appt_AppointmentsPageController();
        apptPageController2.logInput();

        System.assertEquals(true, apptPageController2.intMessage.Status__c.equals('Error'), 'Test 2 should be an error');

        Test.stopTest();


        


    }
}