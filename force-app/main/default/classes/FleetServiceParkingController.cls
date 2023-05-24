global without sharing class FleetServiceParkingController {
    
    @testVisible
    private static Boolean throwException = false;

    private virtual class BaseException extends Exception {}
    private class OtherException extends BaseException {}
    
    @AuraEnabled(cacheable=true)
    public static Contact getContactInfo(Id userId){
       System.debug('user id--'+userId);
        User userData = [select id, contactId from user where id= :userId];
        Contact cont = [select id, Name, AccountId, Account.Name, Account.Phone, Account.ECC_Account_Number__c, Email, Account.Fleet_Number_of_Vehicles__c from Contact where id = :userData.contactId];            
       
        //system.debug('@@@ cont: '+ cont);
        return cont;     
    }
    
    @AuraEnabled
    public static void updateSobject(Map<String, String> record){
        try {
            //system.debug('@@@ '+ record);
            if(record.get('objectName') == 'Account'){
                Account acc = new Account(id=record.get('id'));
                if(record.get('Phone')!=null) acc.Phone = record.get('Phone');
                if(record.get('Fleet_Number_of_Vehicles__c')!=null) acc.Fleet_Number_of_Vehicles__c = Decimal.valueOf(record.get('Fleet_Number_of_Vehicles__c'));
                update acc;
            }else if(record.get('objectName') == 'Contact'){
                Contact con = new Contact(id=record.get('id'));
                con.Email = record.get('Email');
                update con;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void sendMail(Map<String, String> parentContactData, Map<String, String> newContactData){
        system.debug('@@@ contactData: '+ parentContactData);
        system.debug('@@@ contactData: '+ newContactData);
        String ParentContactBody;
        try {
            if(FleetServiceParkingController.throwException){
                throw new OtherException('Script-thrown exception');
        	}
            String heading = '<h2>Please see below table for the following Discount Tire Fleet customer.</h2><br></br>';
            if(parentContactData.get('isContactData') == 'true'){ 
               ParentContactBody = '<table style="width=100%; border-collapse: collapse;">'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Contact Name </th><td style="text-align: left; border: 1px solid #dddddd; padding: 15px;">'+parentContactData.get('ContactName')+'</td></tr>'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Account name </th><td style="text-align: left; border: 1px solid #dddddd; padding: 15px;">'+parentContactData.get('AccountName')+'</td></tr>'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Email </th><td style="text-align: left; border: 1px solid #dddddd; padding: 15px;">'+parentContactData.get('Email')+'</td></tr>'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Account phone number  </th><td style="text-align: left; border: 1px solid #dddddd; padding: 15px;">'+parentContactData.get('AccountPhone')+'</td></tr>'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">SAP Account number </th><td style="text-align: left; border: 1px solid #dddddd; padding: 15px;">'+parentContactData.get('fleetAccountNumber')+'</td></tr>'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Fleet vehicle quantity  </th><td style="text-align: left; border: 1px solid #dddddd; padding: 15px;">'+parentContactData.get('fleetSize')+'</td></tr>'+
                '</table><br></br>';
            }else {
               ParentContactBody = '<table style="width=100%; border-collapse: collapse;">'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Contact Name </th><td style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Parent Contact Does Not Exist</td></tr>'+
                     '</table><br></br>';    
            }

            String fleetParkingToEmailAddress = Label.Fleet_Parking_Email_Address;
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>();
           
            // toAddresses.add('krishna.sripada@discounttire.com');
            //toAddresses.add('sudipk417@gmail.com');
            // toAddresses.add(fleetParkingToEmailAddress);

            email.setToAddresses(fleetParkingToEmailAddress.split(',')); 
            email.setSubject('Discount Tire Fleet Customer Inquiry'); 

            String HTMLBody = heading;
            if(newContactData.get('isNewData') == 'true'){
                //system.debug('@@@ NEW CONTACT FILLED');
                HTMLBody = HTMLBody + 
                '<h2>Parent Contact</h2>'+
                ParentContactBody +
                '<h2>New Contact</h2>'+
                '<table style="width=100%; border-collapse: collapse;">'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Name </th><td style="text-align: left; padding: 15px; border: 1px solid #dddddd;">'+newContactData.get('newContactName')+'</td></tr>'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Title </th><td style="text-align: left; padding: 15px; border: 1px solid #dddddd;">'+newContactData.get('newContactTitle')+'</td></tr>'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Email </th><td style="text-align: left; padding: 15px; border: 1px solid #dddddd;">'+newContactData.get('newContactEmail')+'</td></tr>'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Phone number  </th><td style="text-align: left; padding: 15px; border: 1px solid #dddddd;">'+newContactData.get('newContactPhoneNumber')+'</td></tr>'+
                '   <tr><th style="text-align: left; border: 1px solid #dddddd; padding: 15px;">Mobile </th><td style="text-align: left; padding: 15px; border: 1px solid #dddddd;">'+newContactData.get('newContactMobile')+'</td></tr>'+
                '</table>';                
            }else{
                //system.debug('@@@ OLD Contact');
                HTMLBody = HTMLBody +
                '<h2>Contact Detail</h2>' +
                 ParentContactBody;
            }

            email.setHtmlBody(HTMLBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            //system.debug('SENT');
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    } 
}