public class Fleet_DiscountPNGQueueable implements Queueable, Database.AllowsCallouts{
    private Id parent;
    private String accId;
    public final static String STATUS_SUCCESS = 'Success';
    public final static String STATUS_ERROR = 'Error';
    public final static String STATUS_EXCEPTION = 'Exception';
    private String templateName; 
    private String accountId; 
    private List<String> bccAddressList; 
    private String fromAddress; 
    private Account acc; 
    private List<OrgWideEmailAddress> owaList; 
    private String templateId;
    public Fleet_DiscountPNGQueueable(ID id,String accId,String templateName, List<String> bccAddressList, String fromAddress, Account acc, List<OrgWideEmailAddress> owaList, String templateId) {
        this.parent = id;
        this.accId = accId;
        this.templateName = templateName;
        this.bccAddressList = bccAddressList;
        this.fromAddress = fromAddress;
        this.acc = acc;
        this.owaList =owaList;
        this.templateId = templateId;
    }
    public void execute(QueueableContext context) {
        Account acc = [SELECT Id,Name,ECC_Account_Number__c,Fleet_Primary_Contact__r.Email,WelcomeEmailSent__c,Fleet_Business_Located__c FROM Account WHERE Id=:accId];
        String baseURL = DomainCreator.getContentHostname();
        if(!baseURL.startsWithIgnoreCase('https://')) baseURL = 'https://' + baseURL;
        String customPdfURL = baseURL + '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId='+parent;
        system.debug('====>'+customPdfURL);
        
        Blob imgBody;
        if(!test.isRunningTest()){
            imgBody = (new PageReference(customPdfURL).getContent());
        }else{
            imgBody=blob.valueOf('TestString');
            acc.Fleet_Business_Located__c = 'Arkansas';
        }
        ContentVersion contentVersion_2 = new ContentVersion(
            Title=' Welcome Fleet PNG', 
            PathOnClient ='Welcome_Fleet.png',
            VersionData = imgBody, 
            origin = 'H',
            FirstPublishLocationId = accId
        );
        insert contentVersion_2;
        String toAddress = acc.Fleet_Primary_Contact__r.Email; 
        OrgWideEmailAddress owa = null;
        if (owaList.size() > 0) {
            owa = owaList[0];
            System.debug('Setting OrgWideEmailAddress: ' + owa.Address + ' with display name: ' + owa.DisplayName);
        }
        Fleet_AccountApprovalController.ResultWrapper emailResult = new Fleet_AccountApprovalController.ResultWrapper();
        //build email
        Messaging.SingleEmailMessage mail = Fleet_AccountEmailUtil.buildEmail(new String[]{toAddress}, bccAddressList, fromAddress, owa, accId, acc.Fleet_Primary_Contact__c, templateId);
       // if(acc.Fleet_Business_Located__c != null && Label.FleetDiscountImgExcludeState.contains(acc.Fleet_Business_Located__c) ==false){
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setContentType('image/png');
            attach.setFileName('DTFleet_AccountCard.png');
            attach.setInline(false);
            attach.setBody(imgBody);
            //mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach}); 
            mail.setEntityAttachments(New List<Id>{contentVersion_2.Id});
      //  }
         try {
            Messaging.SendEmailResult[] result =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Email Result: ' + result.toString());
            
            if (result.get(0).isSuccess()) {
                acc.WelcomeEmailSent__c=true;
                acc.Welcome_Email_Triggered__c = false;
                emailResult.status = STATUS_SUCCESS;
                emailResult.message = 'Email Successfully Sent!';
            }
            else {
                acc.Welcome_Email_Triggered__c = false;
                emailResult.status = STATUS_ERROR;
                emailResult.message = JSON.serialize(result.get(0).getErrors());
            }
            update acc;
        } catch (exception e) {
            emailResult.status = STATUS_EXCEPTION;
            emailResult.message = e.getMessage();
            
        }
    }
}