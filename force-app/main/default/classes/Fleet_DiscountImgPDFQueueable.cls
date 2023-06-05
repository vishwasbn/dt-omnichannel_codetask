public class Fleet_DiscountImgPDFQueueable implements Queueable, Database.AllowsCallouts {
    public final static String STATUS_SUCCESS = 'Success';
    public final static String STATUS_ERROR = 'Error';
    public final static String STATUS_EXCEPTION = 'Exception';
    private Id parent;
    private String templateName; 
    private String accountId; 
    private List<String> bccAddressList; 
    private String fromAddress; 
    private Account acc; 
    private List<OrgWideEmailAddress> owaList; 
    private String templateId;
    public Fleet_DiscountImgPDFQueueable(ID id,String templateName, List<String> bccAddressList, String fromAddress, Account acc, List<OrgWideEmailAddress> owaList, String templateId) {
        this.parent = id;
        this.templateName = templateName;
        this.bccAddressList = bccAddressList;
        this.fromAddress = fromAddress;
        this.acc = acc;
        this.owaList =owaList;
        this.templateId = templateId;
    }
    public void execute(QueueableContext context) {
        if(templateName =='Fleet_Welcome_Credit_Application_Accepted'){
            if(acc.AT_Customer__c){
                templateName = 'Fleet_Welcome_Credit_Application_Accepted_For_Non_California_AT';
            }else{
                templateName = 'Fleet_Welcome_Credit_Application_Accepted_For_Non_California';
            }
        }else if(templateName =='Fleet_Welcome_Cash_Application_Accepted'){
            if(acc.AT_Customer__c){
                templateName = 'Fleet_Welcome_Cash_Application_Accepted_For_Non_California_AT';
            }else{
                templateName = 'Fleet_Welcome_Cash_Application_Accepted_For_Non_California';
            }
        }
        templateId = Fleet_AccountEmailUtil.getTemplateId(templateName);
        Account acc = [SELECT Id,Name,ECC_Account_Number__c,Fleet_Primary_Contact__r.Email,Selected_State__c, Fleet_Business_Located__c,AT_Customer__c,DT_Customer__c,ShippingPostalCode,Welcome_Email_Triggered__c,WelcomeEmailSent__c FROM Account WHERE Id=:parent];
        pageReference pdf;
        if(acc.AT_Customer__c){
            System.debug('&&&&&');
        	pdf = Page.FleetAmericanImgPdf;
            System.debug('&&&&&');
    	}
        else{
            pdf = Page.FleetDiscountImgPdf;
        }
        pdf.getParameters().put('accno', acc.ECC_Account_Number__c);
        pdf.getParameters().put('name', acc.Name);
        if(acc.AT_Customer__c)
            pdf.getParameters().put('isdtimage', 'false');
       // else if(ATZipCodes__c.getAll().get(acc.MailingPostalCode) != null)
       //     pdf.getParameters().put('isdtimage', 'false');
        else
            pdf.getParameters().put('isdtimage', 'true');
        Blob body;
        //system.debug('===accId==>'+pdf.getContentasPDF());
        if(!test.isRunningTest()){
            body = pdf.getContentasPDF();
            System.debug('body '+body);
        }else{
            body=blob.valueOf('TestString');
        }
        system.debug('===accId==>'+parent);
        Logger logInstance = Logger.getInstance();
        logInstance.log('Discount Img PDF', 'Fleet_DiscountImgPDFQueueable', 'After ContentVersion creation');
        ContentVersion contentVersion_1 = new ContentVersion(
            Title='Welcome Fleet PDF', 
            PathOnClient ='Welcome_Fleet.pdf',
            VersionData = body, 
            origin = 'H',
            FirstPublishLocationId = parent
        );
        //if(acc.Selected_State__c != null && Label.FleetDiscountImgExcludeState.contains(acc.Selected_State__c) ==false)        
         //if(acc.Selected_State__c == null || ((acc.Selected_State__c!= null && Label.FleetDiscountImgExcludeState.contains(acc.Selected_State__c) ==false)))
            insert contentVersion_1;
         
         logInstance.log('Discount Img PDF', 'Fleet_DiscountImgPDFQueueable', 'After ContentVersion creation', JSON.serialize(contentVersion_1));
       /* String toAddress = acc.Fleet_Primary_Contact__r.Email; 
        OrgWideEmailAddress owa = null;
        if (owaList.size() > 0) {
            owa = owaList[0];
            System.debug('Setting OrgWideEmailAddress: ' + owa.Address + ' with display name: ' + owa.DisplayName);
        }
        Fleet_AccountApprovalController.ResultWrapper emailResult = new Fleet_AccountApprovalController.ResultWrapper();
        //build email
        Messaging.SingleEmailMessage mail = Fleet_AccountEmailUtil.buildEmail(new String[]{toAddress}, bccAddressList, fromAddress, owa, parent, acc.Fleet_Primary_Contact__c, templateId);
        if(Label.FleetDiscountImgExcludeState.contains(acc.Selected_State__c) ==false){
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setContentType('application/pdf');
            attach.setFileName('DTFleet_AccountCard.pdf');
            attach.setInline(false);
            attach.setBody(body);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});     
        }
        
        // send email
        
        try {
            Messaging.SendEmailResult[] result =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Email Result: ' + result.toString());
            
            if (result.get(0).isSuccess()) {
                emailResult.status = STATUS_SUCCESS;
                emailResult.message = 'Email Successfully Sent!';
            }
            else {
                emailResult.status = STATUS_ERROR;
                emailResult.message = JSON.serialize(result.get(0).getErrors());
            }
            
        } catch (exception e) {
            emailResult.status = STATUS_EXCEPTION;
            emailResult.message = e.getMessage();
            
        }
        System.debug('Result Wrapper: ' + emailResult); */
       // if(acc.Selected_State__c != null && Label.FleetDiscountImgExcludeState.contains(acc.Selected_State__c) ==false){
           DateTime myDateTime = Datetime.now().addSeconds(Integer.valueOf(Label.Fleet_WelcomeEmailQueueTime));
          system.debug('===myDateTime=>'+myDateTime+'===Datetime.now()=>'+Datetime.now());
            String hour = String.valueOf(myDateTime.hour());
            String min = String.valueOf(myDateTime.minute()); 
            String ss = String.valueOf(myDateTime.second());
            /*if(Integer.valueOf(ss) > 59){
                min = String.valueOf(Integer.valueOf(min) +1);
                ss = '59';
            }
        if(Integer.valueOf(min) > 59){
            hour = String.valueOf(Integer.valueOf(hour) +1);
            ss='59';
        }*/
            //parse to cron expression
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
            System.schedule('ScheduledJob ' + String.valueOf(Math.random()), nextFireTime, new Fleet_DiscountPNGSchedulable(contentVersion_1.Id,parent,templateName,bccAddressList,fromAddress,acc,owaList,templateId));
          
       // }
            //System.enqueueJob(new Fleet_DiscountPNGQueueable(contentVersion_1.Id));
        //Fleet_DiscountPNG.createPNGDiscount(contentVersion_1.Id,parent);
    }
}