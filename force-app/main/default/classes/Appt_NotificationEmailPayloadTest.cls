@isTest
public class Appt_NotificationEmailPayloadTest {
    @isTest static void AppNotificaitonEmailPayload(){                       
        
        // Get the Order type from the Work Order and format it to all caps
        String workOrderType = 'BOPIS';

        Appt_NotificationEmailPayload emailPayloadObj = new Appt_NotificationEmailPayload();
        emailPayloadObj.subscriberKey = '012345677';
        emailPayloadObj.emailAddress = 'test@test.com';
        emailPayloadObj.communicationType = 'A'; // This is 'A' for appointment, add logic for 'O' if there is implementation for Orders in the future
        emailPayloadObj.transactionType = workOrderType;
        emailPayloadObj.orderNumber = '1024543';
        emailPayloadObj.customerName = 'Testing test';
        emailPayloadObj.vehicleId = '1235346';
        emailPayloadObj.vehicleInformation = 'test';
        emailPayloadObj.streetAddress = 'testing 123';
        emailPayloadObj.city = 'test city';
        emailPayloadObj.state = 'AZ';
        emailPayloadObj.zipCode = '85111';
        emailPayloadObj.country = 'USA';
        emailPayloadObj.customerPhone = '1112223333';
        emailPayloadObj.storeId = '1247';
        emailPayloadObj.storeName = 'Test Store';
        emailPayloadObj.storeStreetAddress = 'Testing 456';
        emailPayloadObj.storeCity = 'Test City';
        emailPayloadObj.storeState = 'AZ';
        emailPayloadObj.storeZipCode = '85111';
        emailPayloadObj.storePhoneNumber = '2223334444';
        emailPayloadObj.appointmentTime = '0800';
        emailPayloadObj.recipientFirstName = 'Test';
        emailPayloadObj.recipientLastName = 'Customer';
        emailPayloadObj.recipientPhone = '2223334467';
        emailPayloadObj.recipientEmail = 'altTest@test.com';
        emailPayloadObj.appointmentDate = '08/01/2022';
        emailPayloadObj.appointmentStatus = 'Scheduled';
        Datetime todaysDate = System.today();
        emailPayloadObj.dateAdded = todaysDate.format('MMM') + ' ' + todaysDate.day() + ',' + todaysDate.year();
        emailPayloadObj.fleetCompanyName = 'Test';
        emailPayloadObj.fleetAccountNumber = '0425463';
        emailPayloadObj.orderCode = '963865';
        emailPayloadObj.storeCode = '1247';
        emailPayloadObj.orderDate = '08/01/2022';
        emailPayloadObj.appointmentId = '034523462353425';
        emailPayloadObj.vehicleAssemblyId = 'B';
        emailPayloadObj.clientId = 'DT';
        emailPayloadObj.customerKey = 'OrderConfirmationTSDv2';


        System.debug('***********START TEST***************');
        Test.startTest();
            
        String testPayload = Appt_NotificationEmailPayload.compose(emailPayloadObj);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        
        System.assert(testPayload.contains('test@test.com'), 'payload created with valid email number');
            
    }
}