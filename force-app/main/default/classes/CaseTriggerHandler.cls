public with sharing class CaseTriggerHandler {

    public static void OnAfterInsert(Case[] newObjects)
    {
        
        List<Case_Status_Change__c> statusChanges = new List<Case_Status_Change__c>();
        statusChanges.addAll(createCaseStatus(newObjects, null));

        //check if user has permission to create Case_Status_Change__c records
        if (!Schema.sObjectType.Case_Status_Change__c.fields.Status_From__c.isCreateable()
             || !Schema.sObjectType.Case_Status_Change__c.fields.Name.isCreateable()
               || !Schema.sObjectType.Case_Status_Change__c.fields.Case__c.isCreateable()
                 || !Schema.sObjectType.Case_Status_Change__c.fields.Status_Name__c.isCreateable()
                   || !Schema.sObjectType.Case_Status_Change__c.fields.Current_Case_Owner__c.isCreateable()
                     || !Schema.sObjectType.Case_Status_Change__c.fields.Set_Time__c.isCreateable()){
             throw new DmlException('Insufficient permissions to create Case Status Change');
        }
        
        insert statusChanges;
    }
    
    public static void OnBeforeInsert(Case[] newObjects)
    {
        //PersonAccountAutomation
        PersonAccountAutomation(newObjects);
    }
    
    public static void PersonAccountAutomation(Case[] newObjects)
    {
        Boolean canBypassLogic = FeatureManagement.checkPermission('Bypass_Logic');
        
        if(!canBypassLogic)
        {
            RecordType personType = [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' AND sObjectType = 'Account' LIMIT 1];
            for (Case c : newObjects) {
                if (c.SuppliedEmail != null) {
                    Account person;
                    //Checks for existing accounts matching based on email
                    list<Account> accts = [SELECT Id,Phone FROM Account WHERE PersonEmail = :c.SuppliedEmail];
                    if (!accts.isEmpty()) 
                    {
                        if (accts.size() == 1)
                            person = accts[0];
                        else {
                            //If multiple matches, match based on phone
                            for (Account a : accts) {
                                if(a.phone!=null)
                                {
                                    if (a.Phone.equals(c.SuppliedPhone)) {
                                        person = a;
                                        break;
                                    }
                                }
                            }
                            if (person == null)
                                person = accts[0];
                        }
                    } 
                    else 
                    {
                        String first = '';
                        String last = '';
                        //Break the name into first and last if possible
                        if (c.SuppliedName != null && c.SuppliedName.contains(' ')) {
                            first = c.SuppliedName.substring(0,c.SuppliedName.indexOf(' '));
                            last = c.SuppliedName.substring(c.SuppliedName.indexOf(' ')+1);
                        } else {
                            last = c.SuppliedName;
                        }
                        //If no supplied name use unknown and email
                        if (c.SuppliedName == null) {
                            last = 'Unknown';
                            first = c.SuppliedEmail;
                        }
                        person = new Account(RecordTypeId = personType.Id,FirstName = first,LastName = last,PersonEmail = c.SuppliedEmail,Phone = c.SuppliedPhone);
                        //try{
                        //    insert person;
                        //}catch (Exception e){
                        //    System.debug('Exception e'+e.getStackTraceString());
                       // }
                        insert person;
                    }
                    //Set the account and contact on the new case
                    c.AccountId = person.Id;
                    c.ContactId = [SELECT PersonContactId FROM Account WHERE Id = :person.Id].PersonContactId;
                }
            }
        }
    }
    
    public static void OnAfterUpdate(Case[] updatedObjects, Map<Id, Case> oldObjectMap)
    {
         
        List<Case_Status_Change__c> statusChanges = new List<Case_Status_Change__c>();
        List<Case_Status_Change__c> statusChangesToUpdate = new List<Case_Status_Change__c>();
        List<String> oldStatuses = new List<String>();
        List<Id> caseIds = new List<Id>();

        statusChanges.addAll(createCaseStatus(updatedObjects, oldObjectMap));
        
        //construct old status List and Ids to retrieve old case status changes to update the business hours
        for (Case_Status_Change__c statusChange: statusChanges) {
            
            oldStatuses.add(statusChange.Status_From__c);
            caseIds.add(statusChange.Case__c);            
        }
        
        //CRUD/FLS checks
        if (!Schema.sObjectType.Case_Status_Change__c.isAccessible() 
             ||!Schema.sObjectType.Case_Status_Change__c.fields.Name.isAccessible() 
               || !Schema.sObjectType.Case_Status_Change__c.fields.Set_Time__c.isAccessible()
                 || !Schema.sObjectType.BusinessHours.isAccessible()){
             throw new QueryException('Insufficient access to Case Status Change or business hours objects');
        }
        
        if (caseIds.size()>0 && oldStatuses.size()>0) {
           
           List<Case_Status_Change__c> oldStatusChanges = [select Id, Name, Set_Time__c from Case_Status_Change__c where Status_Name__c IN :oldStatuses and Case__c IN :caseIds and Change_Time__c=null];
           BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
          
           for (Case_Status_Change__c oldStatusChange: oldStatusChanges) {
                
                // calculate business hours               
                oldStatusChange.Change_Time__c = Datetime.now();
                Double milliseconds = BusinessHours.diff(bh.Id, oldStatusChange.Set_Time__c, oldStatusChange.Change_Time__c);                 
                oldStatusChange.Status_Time__c = (Decimal.valueOf(milliseconds)).Divide((60*60*1000), 2);
                oldStatusChange.Age__c = getAge(milliseconds);
                statusChangesToUpdate.add(oldStatusChange);
            }
        }
                
        //check if user has permission to create Case_Status_Change__c records
        if (!Schema.sObjectType.Case_Status_Change__c.fields.Status_From__c.isCreateable()
             || !Schema.sObjectType.Case_Status_Change__c.fields.Name.isCreateable()
               || !Schema.sObjectType.Case_Status_Change__c.fields.Case__c.isCreateable()
                 || !Schema.sObjectType.Case_Status_Change__c.fields.Status_Name__c.isCreateable()
                   || !Schema.sObjectType.Case_Status_Change__c.fields.Current_Case_Owner__c.isCreateable()
                     || !Schema.sObjectType.Case_Status_Change__c.fields.Set_Time__c.isCreateable()){
             throw new DmlException('Insufficient permissions to create Case Status Change');
        }
        
        insert statusChanges;
        
        //check if user has permission to update
        if (!Schema.sObjectType.Case_Status_Change__c.fields.Change_Time__c.isUpdateable()
             || !Schema.sObjectType.Case_Status_Change__c.fields.Status_Time__c.isUpdateable()
               || !Schema.sObjectType.Case_Status_Change__c.fields.Age__c.isUpdateable()
                 || !Schema.sObjectType.Case_Status_Change__c.fields.Status_From__c.isUpdateable()
                   || !Schema.sObjectType.Case_Status_Change__c.fields.Name.isUpdateable()
                     || !Schema.sObjectType.Case_Status_Change__c.fields.Case__c.isUpdateable()
                       || !Schema.sObjectType.Case_Status_Change__c.fields.Status_Name__c.isUpdateable()
                         || !Schema.sObjectType.Case_Status_Change__c.fields.Current_Case_Owner__c.isUpdateable()
                           || !Schema.sObjectType.Case_Status_Change__c.fields.Set_Time__c.isUpdateable()
                   ){
             throw new DmlException('Insufficient permissions to update Case Status Change');
        }
        
        update statusChangesToUpdate;
    
        // update Account Detail on Status Approved
        List<Account> accList = new List<Account>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(Case newCase : updatedObjects){
            if(newCase.Status != oldObjectMap.get(newCase.id).Status && newCase.Status == 'Approved' && newCase.AccountId != null){
                system.debug('@@@ Approved SECTION.');  
                Account acc = new Account(id=newCase.AccountId);
                acc.Lead_Email__c = acc.Lead_Email__c==null ? newCase.Email__c : acc.Lead_Email__c; 
                acc.Email__c = newCase.Email__c;
                acc.Phone = newCase.Phone__c;
                acc.BillingCountry = newCase.Billing_Country__c;
                acc.BillingStreet = newCase.Billing_Street__c;
                acc.BillingCity = newCase.Billing_City__c;
                acc.BillingStateCode = newCase.Billing_State_Province_Code__c;
                acc.BillingPostalCode = newCase.Billing_Zip_Postal_Code__c;
                acc.ShippingCountry = newCase.Shipping_Country__c;
                acc.ShippingStreet = newCase.Shipping_Street__c;
                acc.ShippingCity = newCase.Shipping_City__c;
                acc.ShippingStateCode = newCase.Shipping_State_Province_Code__c;
                acc.ShippingPostalCode = newCase.Shipping_Zip_Postal_Code__c;
                accList.add(acc);
            }
            else if(newCase.Status != oldObjectMap.get(newCase.id).Status && newCase.Status == 'Reject'){  
                    system.debug('@@@ REJECTED SECTION.');            
                    if (newCase.Contact_Email__c != null) {  
                        Account acc = new Account(id=newCase.AccountId);                    
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        List<String> sendTo = new List<String>();
                        sendTo.add(newCase.Contact_Email__c);                      
                        mail.setToAddresses(sendTo);
                        mail.setReplyTo(acc.Email__c);                      
                        mail.setSenderDisplayName('Salesforce Team');
                        mail.setSubject('Address Change Request was Rejected');
                        String body = 'Your Account Address Change Request was Rejected. Please Contact Discount Tire Support Team for further assistance.';
                        mail.setHtmlBody(body);
                        mails.add(mail);
                    }
            }
        }
        
        if(mails!=null && mails.size()>0){
            Messaging.sendEmail(mails);
        }

        if(accList!=null && accList.size()>0 && !Test.isRunningTest()){
            update accList;
        }
    }
    
    
    private static List<Case_Status_Change__c> createCaseStatus(Case[] caseObjects, Map<Id, Case> oldObjectMap)
    {
        
        List<Case_Status_Change__c> statusChanges = new List<Case_Status_Change__c>();
  
         //CRUD/FLS checks
        if (!Schema.sObjectType.Case.isAccessible() 
             ||!Schema.sObjectType.Case.fields.CaseNumber.isAccessible() 
                 || !Schema.sObjectType.User.isAccessible()
                   || !Schema.sObjectType.User.fields.Name.isAccessible()){
             throw new QueryException('Insufficient access to Case or User objects');
        }
   
        Map<Id, Case> cases = new Map<Id, Case>([SELECT CaseNumber, Owner.Name from Case where id in:caseObjects]);

        for (Case caseObject: caseObjects) {
            Case_Status_Change__c  statusChange = null;
            
            if (cases.size()>0) {
                //this is the update case, check if the status has changed or not, if changed
                //a new case status change record is created 
                if (oldObjectMap!=null){
                    Case oldObject = oldObjectMap.get(caseObject.Id);
                    if (caseObject.Status != oldObject.Status) { 
                      
                       statusChange = new Case_Status_Change__c();
                       statusChange.Status_From__c  = oldObject.Status;
                       statusChange.Name = cases.get(caseObject.id).CaseNumber+' from '+oldObject.Status +' to '+caseObject.Status;
                    }
               }
               // this is the new case, the first case status change record is created
               else{
                    statusChange = new Case_Status_Change__c();
                    statusChange.Name = cases.get(caseObject.id).CaseNumber+' status: '+caseObject.Status;                 
               }
               
               //populate the rest of fields, add it to the result list to return 
               if (statusChange!=null) {
                   
                    statusChange.Case__c = caseObject.Id;
                    statusChange.Status_Name__c = caseObject.Status;
                    statusChange.Current_Case_Owner__c = cases.get(caseObject.id).Owner.Name;
                    statusChange.Set_Time__c = Datetime.now();
                    statusChanges.add(statusChange);
               }   
            }
        }
        return statusChanges;
    }
    
    private static String getAge(Double milliseconds) 
    {
        
        Double duration = milliseconds;
        Double d = Math.floor(duration/86400000); //Get whole days
        duration -= d*86400000;
        Double h = Math.floor(duration/3600000); //Get whole hours
        duration -= h*3600000;
        Double m = Math.floor(duration/60000);
        duration -= m*60000;
        Double s = Math.floor(duration/1000);
        return d.format()+' days '+h.format()+' hours '+ m.format() + ' minutes ' + s.format() +' seconds';
    }
   
}