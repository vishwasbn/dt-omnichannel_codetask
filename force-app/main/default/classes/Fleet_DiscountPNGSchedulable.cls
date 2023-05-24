Public class Fleet_DiscountPNGSchedulable implements Schedulable{
    private String parent;
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
    public Fleet_DiscountPNGSchedulable(String parent,String accId,String templateName, List<String> bccAddressList, String fromAddress, Account acc, List<OrgWideEmailAddress> owaList, String templateId){
        this.parent = parent;
        this.accId = accId;
        this.templateName = templateName;
        this.bccAddressList = bccAddressList;
        this.fromAddress = fromAddress;
        this.acc = acc;
        this.owaList =owaList;
        this.templateId = templateId;
    }
    public void execute(SchedulableContext sc) {
       
        Fleet_DiscountPNGQueueable pngDiscountImg = new Fleet_DiscountPNGQueueable(parent,accId,templateName,bccAddressList,fromAddress,acc,owaList,templateId);
        // Enqueue the job for processing
        ID jobID = System.enqueueJob(pngDiscountImg); 
        // Abort the job once the job is queued
        System.abortJob(sc.getTriggerId());
    }
   /* @future(callout=true)
    public static void createPNGDiscount(String parent,String accId){
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        String customPdfURL = baseURL.replace('.my.salesforce.com', '--c.documentforce.com/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId='+parent);
        String customPdfURL1 = customPdfURL.replace('&inline=1', '');
        system.debug('====>'+customPdfURL1);
        Blob imgBody;
        if(!test.isRunningTest()){
            imgBody =  (new PageReference(customPdfURL1).getContent());
        }else{
            imgBody=blob.valueOf('TestString');
        }
        ContentVersion contentVersion_2 = new ContentVersion(
            Title=' Test Title2', 
            PathOnClient ='SampleFile.png',
            VersionData = imgBody, 
            origin = 'H',
            FirstPublishLocationId = '0013C00000TLJq4'
        );
        insert contentVersion_2;
    }*/
}