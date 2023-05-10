public class emailPublisherController {
    
    public Case caseRecord {get;set;}
    public String emailAddresses {get;set;}
    public String emailBody {get;set;}
    public String emailSubject {get;set;}
    public Boolean includeHTML {get;set;}
    public Case caseWithAllDetails {get;set;}
    
    public emailPublisherController(ApexPages.standardController std){
        caseRecord = (Case)std.getRecord(); 
        
        caseWithAllDetails = [SELECT E2CP__Case_Thread_Id__c,Account.FirstName, Account.LastName, Account.PersonEmail,
                              Account.Phone, SuppliedEmail, SuppliedPhone, store_new__r.Name,  Store_New__c,                         
                              id, Contact.Email, Description, Region_New__c, 
                              (SELECT FromAddress, CcAddress, Subject 
                               FROM Case.EmailMessages 
                               where Incoming = true ORDER BY CreatedDate DESC LIMIT 1) 
                              FROM Case 
                              WHERE Id = :caseRecord.Id];    
    }
    
    public boolean isToAddressOfCustomer(){
        if(getToAddress() != null)
            if(getToAddress().equals(caseWithAllDetails.contact.email))
            return true;
        
        return false;
    }
    
    public String getBccAddresses(){
        String address = '';
        if(isToAddressOfCustomer()){
            List<String> emails ;
            
            List<Store__c> storeList = [select Store_Email__c,Store_Manager_Email__c,Region__c from Store__c where id =: caseWithAllDetails.Store_new__c];
            if(storeList.size() > 0 ){
                
                emails = getRegionEmails(storeList[0].Region__c);
                if(storeList[0].Store_Email__c != null) emails.add(storeList[0].Store_Email__c);if(storeList[0].Store_Manager_Email__c != null) emails.add(storeList[0].Store_Manager_Email__c);address = String.join(emails,',');
            }
        }
        return address;
    }
    
    public List<String> getRegionEmails(String regionID){
        List<String> emails = new List<String>();
        for(Regional_Email__c regionalEmail: [select name from Regional_Email__c where Region__c =:  regionID]){
            emails.add(regionalEmail.name);
        }
        return emails;
    }
    
    public String getOriginalMessage(){
        
        system.debug('****** emailbody' + caserecord.id);
        Case c = [SELECT id,E2CP__Case_Thread_Id__c, Description, (SELECT textBody,FromAddress, ToAddress, Subject FROM Case.EmailMessages ORDER BY CreatedDate DESC LIMIT 1) FROM Case 
                  WHERE Id = :caseRecord.Id];
        
        
        
        if(c.EmailMessages.size() > 0){ 
            String fromAddress = c.EmailMessages[0].FromAddress;
            String toAddress = c.EmailMessages[0].ToAddress;
            String subject = c.EmailMessages[0].subject;
            String originalMsgBody = '*********original message*****\r\nFrom:\t\t' + fromAddress + '\nSent:\t\t' + toAddress + 
                '\nSubject:\t\t' + subject;
           
            return  originalMsgBody+ '\n' + c.EmailMessages[0].textBody ;
        }
        
        String originalMsgBody = '*********original message*****\r\n' + c.Description ;
        return originalMsgBody;
    }
    
    public String getToAddress(){
        
        if(caseWithAllDetails.EmailMessages.size() > 0){ 
            return  caseWithAllDetails.EmailMessages[0].FromAddress ;
        }
        
        return caseWithAllDetails.contact.email;
    }
    
    public String getCcAddresses(){
        
        if(caseWithAllDetails.EmailMessages.size() > 0){ 
            return  caseWithAllDetails.EmailMessages[0].CcAddress ;
        }
        
        return '';
    }
    
    public void sendBCCEmail() {         
        
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            // Set addresses, body, and subject
            if(emailAddresses == null || emailSubject == null || emailBody == null || includeHtml == null)
                return;
            
            //emailBody = emailBody.removeStart('https://c.cs59.visual.force.com/');
            //emailBody = emailBody.removeStart('https://c.na39.visual.force.com/');
            
            system.debug(emailBody);

            String caseThreadID = '';
            if(caseWithAllDetails != null){
             caseThreadID = '\n\n***********PLEASE DO NOT REMOVE THIS***********\n\n' +
               caseWithAllDetails.E2CP__Case_Thread_Id__c;
            }

            
            String emailBodyWithCustomerDetails = getCustomerDetailsInPlainTextFormat() + '\n\n\n' + emailbody;
            
            String[] toAddresses = emailAddresses.split(',');
            mail.setToAddresses(toAddresses);        
            mail.setSubject(emailSubject);        
            mail.setPlainTextBody(emailBodyWithCustomerDetails + caseThreadID);
            
            // Set from address
            ID orgId = [select id from OrgWideEmailAddress where DisplayName = 'Customer Relations'].id;
            mail.setOrgWideEmailAddressId(orgId);
            
            // Set HTML body if needed
            if(includeHTML) {
                mail.setHTMLBody(getCustomerDetailsInHtmlformat() + '\n\n\n' + emailbody + caseThreadID);
            }
            
            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        } catch (Exception e) {
            system.debug(e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error Sending BCC'));
        }
    }
    
    public string getCustomerDetailsInHtmlformat(){
        String caseDetails = '';
        if(caseWithAllDetails != null){
            caseDetails = '<p>CUSTOMER DETAILS</p>';
            if(!getCustomerName().equals(''))
                caseDetails = caseDetails + '<table><tr><td>Customer Name:</td>    ' + '<td>'+caseWithAllDetails.Account.FirstName + '  '+ 
                caseWithAllDetails.Account.LastName + '</td></tr>';
            if(!getCustomerEmail().equals(''))
                caseDetails = caseDetails + '<tr><td>Email:</td>   ' + getCustomerEmail() + '</td></tr>';
            if(!getCustomerPhone().equals(''))
                caseDetails = caseDetails +  '<tr><td>Phone Number:</td>   ' + getCustomerPhone() + '</td></tr>';
            if(!getstoreName().equals(''))
                caseDetails = caseDetails +  '<tr><td>Store:</td>   ' + caseWithAllDetails.Store_new__r.Name + '</td></tr>';
            if(!getRegionName().equals(''))
                caseDetails = caseDetails +  '<tr><td>Region:</td>  ' + caseWithAllDetails.region_new__c + '</td></tr>';
            caseDetails = caseDetails + '</table>';
        }
        return caseDetails;
    }
    
    public string getCustomerDetailsInPlainTextFormat(){
        String caseDetails = '';
        if(caseWithAllDetails != null){
            
            caseDetails = 'CUSTOMER DETAILS\n';
            
            if(!getCustomerName().equals('')) {
                caseDetails = caseDetails + 'Customer Name:    ' + caseWithAllDetails.Account.FirstName + ' '+ 
                    caseWithAllDetails.account.LastName + '\n';
            }
            
            if(!getCustomerEmail().equals('')) {
                caseDetails = caseDetails + 'Email:   ' + getCustomerEmail() + '\n';
            }
            if(!getCustomerPhone().equals('')) {
                caseDetails = caseDetails +  'Phone Number:   ' + getCustomerPhone() + '\n';
            }
            if(!getStoreName().equals('')) {
                caseDetails = caseDetails +  'Store:   ' + caseWithAllDetails.Store_new__r.Name + '\n';
            }
            if(!getRegionName().equals('')){
                caseDetails = caseDetails +  'Region:   ' + caseWithAllDetails.region_new__c + '\n';
            }
        }
        return caseDetails;
    }
    
    public String getCustomerName(){
        system.debug('Name: ' + caseWithAllDetails);
        if(caseWithAllDetails.Account.Firstname != null && caseWithAllDetails.Account.Lastname != null)
            return caseWithAllDetails.Account.Firstname + '\t' + caseWithAllDetails.Account.Lastname;
        return '';
        
    }
    
    public String getCustomerEmail(){
        String email = '';
        
        if(caseWithAllDetails.Account.PersonEmail != null )
            email = caseWithAllDetails.Account.PersonEmail;
        
        if(caseWithAllDetails.SuppliedEmail != null )
            email = caseWithAllDetails.SuppliedEmail;
        
        return email;
    }
    
    public String getCustomerPhone(){
        String phone = '';
        
        if(caseWithAllDetails.Account.Phone != null)
            phone = caseWithAllDetails.Account.Phone;
        
        if(caseWithAllDetails.SuppliedPhone != null)
            phone = caseWithAllDetails.SuppliedPhone;
        
        return phone;
    }
    
    public String getStoreName(){
        if(caseWithAllDetails.Store_new__r.Name != null)
            return caseWithAllDetails.Store_new__r.Name;
        
        return '';
    }
    
    public String getRegionName(){
        if(caseWithAllDetails.region_new__c != null)
            return caseWithAllDetails.region_new__c;
        
        return '';
    }    
}