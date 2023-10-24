/*========================================================================================================
* @author: Capgemini
* @date: 16th Dec '22
* @description: Test class for WOM_WorkOrderOmniPosHOSTAPI

Modification Log:
----------------------------------------------------------------------------------------------------------
Developer       Mod Number      Date                    User Story          Description
----------------------------------------------------------------------------------------------------------
Anuradha        M-001           16th Dec '22            WOM-92              Initial development. Test class for WOM_WorkOrderOmniPosHOSTAPIWrapper
Vishal          M-002           24th Mar '23                                Added System.LoggingLevel.DEBUG
Anuradha        M-003           05th Apr '23            WOM-2078            Adding Tax related fields
Anuradha        M-004           29th Jun '23            WOM-2450            Data model update to accomodate Print DWO related fields
========================================================================================================== */
@isTest (seeAllData = false)
public class WOM_WorkOrderOmniPosHOSTAPITest{
    
    public static List <WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleCollection> articleInfoList =  new List <WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleCollection> ();
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleCollection  articleInfo = new WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleCollection();
    
    public static List <WOM_WorkOrderOmniPosHOSTAPIWrapper.Customer> customerList =  new List <WOM_WorkOrderOmniPosHOSTAPIWrapper.Customer> ();
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.Customer  customerInfoUpdate = new WOM_WorkOrderOmniPosHOSTAPIWrapper.Customer();
    
    public static List <WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection> phoneListUpdate =  new List <WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection> ();
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection  phoneInfoUpdate = new WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection();
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection  phoneInfoHome = new WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection();
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection  phoneInfoWork = new WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection();
    
    public static List <WOM_WorkOrderOmniPosHOSTAPIWrapper.EmailCollection> emailListUpdate =  new List <WOM_WorkOrderOmniPosHOSTAPIWrapper.EmailCollection> ();
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.EmailCollection  emailInfoUpdate = new WOM_WorkOrderOmniPosHOSTAPIWrapper.EmailCollection();
    
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.Vehicle vehicleInfo = new WOM_WorkOrderOmniPosHOSTAPIWrapper.Vehicle();
    
    public static WorkOrder wo = new WorkOrder ();
    
    /*Start: WOM-2078: Adding Tax related fields*/
    public static List <WOM_WorkOrderOmniPosHOSTAPIWrapper.TransactionDiscountCollection> transDiscountInfoList =  new List <WOM_WorkOrderOmniPosHOSTAPIWrapper.TransactionDiscountCollection> ();
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.TransactionDiscountCollection transDiscountInfo1 = new WOM_WorkOrderOmniPosHOSTAPIWrapper.TransactionDiscountCollection ();
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.TransactionDiscountCollection transDiscountInfo2 = new WOM_WorkOrderOmniPosHOSTAPIWrapper.TransactionDiscountCollection ();
    
    public static List <WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleDiscountCollection> articleDiscountList =  new List <WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleDiscountCollection> ();
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleDiscountCollection articleDiscountInfo = new WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleDiscountCollection ();
    /*End: WOM-2078: Adding Tax related fields*/
    
    @testSetup
    static void createData(){
        List<User> usr = WOM_TestDataUtility.createUsers(1,'Test','User','Integration User',true);
        usr[0].User_Store_Id__c='123123';
        insert usr; 
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            List<PermissionSet> permissionSets= [SELECT Id FROM PermissionSet WHERE Name like 'WOM%Edit' and PermissionSetGroupid=null];
            List<PermissionSetAssignment> permissionSetAssignmentList = new List<PermissionSetAssignment>();
            for(PermissionSet eachPermissionSet :permissionSets){
                permissionSetAssignmentList.add(new PermissionSetAssignment(AssigneeId = usr[0].Id, PermissionSetId = eachPermissionSet.Id));
            }
            insert permissionSetAssignmentList;
        }
        System.runas(usr[0]){
            //insert operating hours
            List<OperatingHours> opHrs = WOM_TestDataUtility.createOpHours(1,'Test Operating Hours');
            insert opHrs;
            
            //Insert account of record type 'Site'
            List<Account> acct = WOM_TestDataUtility.createAccounts(1,'Test Account','Site');
            acct[0].Store_Id__c = '06061999';
            Insert acct;
            
            //Insert Service Territory
            List<ServiceTerritory> servTerr = WOM_TestDataUtility.createServiceTerritory(1,'Test Service Territory',true);
            servTerr[0].Site_Account__c = acct[0].ID;
            Insert servTerr; 
            
            //Insert Service Resource
            List<ServiceResource> servResource = WOM_TestDataUtility.createServiceResource(1,'Member Name');
            Insert servResource; 
            
            //Insert Service Territory Member
            List<ServiceTerritoryMember> servTerrMember = WOM_TestDataUtility.createServiceTerrMember(1,'Test Service Territory member', servResource[0], servTerr[0]);
            Insert servTerrMember; 
            
            List<Schema.Location> loc = WOM_TestDataUtility.createLocation(1,'Bay 01','Available','Flat','Site',false);
            Insert loc;
            
            list<WorkOrder> listWOs = WOM_TestDataUtility.createWO(1,'Awaiting Service',-30,loc[0].id);
            Insert listWOs;
        }
    }
    
    public static WOM_WorkOrderOmniPosHOSTAPIWrapper dataSetup(){
        WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = new WOM_WorkOrderOmniPosHOSTAPIWrapper();
        WOM_WorkOrderOmniPosHOSTAPIWrapper.Customer customerInfo = new WOM_WorkOrderOmniPosHOSTAPIWrapper.Customer();
        
        WOM_WorkOrderOmniPosHOSTAPIWrapper.Scheduling schedulingInfo = new WOM_WorkOrderOmniPosHOSTAPIWrapper.Scheduling();
        List<WOM_WorkOrderOmniPosHOSTAPIWrapper.AssemblyCollection> assemblyCollection = new List<WOM_WorkOrderOmniPosHOSTAPIWrapper.AssemblyCollection>();
        WOM_WorkOrderOmniPosHOSTAPIWrapper.AssemblyCollection assemblyInfo = new WOM_WorkOrderOmniPosHOSTAPIWrapper.AssemblyCollection();
        List<WOM_WorkOrderOmniPosHOSTAPIWrapper.VehicleTreadDepthCollection> vehicleTreadDepthCollection = new List<WOM_WorkOrderOmniPosHOSTAPIWrapper.VehicleTreadDepthCollection>();
        WOM_WorkOrderOmniPosHOSTAPIWrapper.VehicleTreadDepthCollection vehicleTreadDepthInfo = new WOM_WorkOrderOmniPosHOSTAPIWrapper.VehicleTreadDepthCollection();
        List<WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection> phoneCollection = new List<WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection>();
        WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection phoneInfo = new WOM_WorkOrderOmniPosHOSTAPIWrapper.PhoneCollection();
        List<WOM_WorkOrderOmniPosHOSTAPIWrapper.EmailCollection> emailCollection = new List<WOM_WorkOrderOmniPosHOSTAPIWrapper.EmailCollection>();
        WOM_WorkOrderOmniPosHOSTAPIWrapper.EmailCollection emailInfo = new WOM_WorkOrderOmniPosHOSTAPIWrapper.EmailCollection();
        List<WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleCollection> articleCollection = new List<WOM_WorkOrderOmniPosHOSTAPIWrapper.ArticleCollection>();
        
        
        workOrderTransRecord.storeCode='06061999';
        workOrderTransRecord.siteId='1002';
        workOrderTransRecord.saleOrderNumber ='12006061999';
        workOrderTransRecord.vtvInspectionID ='';
        workOrderTransRecord.workOrderId ='';
        workOrderTransRecord.orderType ='ROPIS';
        workOrderTransRecord.paymentStatus ='Unpaid';
        workOrderTransRecord.isArticlesCarryOut = true;
        workOrderTransRecord.isReturnForService = true;
        workOrderTransRecord.comments ='Line level Sale Order comments ';
        workOrderTransRecord.salesAssociateId ='7845810';
        workOrderTransRecord.salesAssociateFirstName ='Janice';
        workOrderTransRecord.salesAssociateLastName ='Holker';
        
        phoneInfo.phoneType = 'mobile';
        phoneInfo.phoneCountryCode = '';
        phoneInfo.phoneNumber = '7038140370';
        phoneInfo.phoneExt = '';
        phoneCollection.add(phoneInfo);
        customerInfo.phoneCollection = phoneCollection;
        emailInfo.emailId = 'test@test.com';
        emailInfo.emailType = 'Primary';
        emailCollection.add(emailInfo);
        customerInfo.emailCollection = emailCollection;
        customerInfo.customerVehicleId ='789481';
        customerInfo.customerId ='1234560';
        customerInfo.customerFirstName ='Ashley';
        customerInfo.customerLastName ='Tisdale';
        customerInfo.customerMiddleInitial ='';
        customerInfo.customerType ='B2C';
        customerInfo.arAccountNumber ='789458';
        customerInfo.accountName ='ABC Corp';
        customerInfo.companyName2 ='Ashley';
        customerInfo.dropOffWaitIndicator ='DROP_OFF';
        customerInfo.driverPhone ='703-814-0368';
        workOrderTransRecord.customer = customerInfo;
        workOrderTransRecord.articleCollection = articleCollection;
            
        assemblyInfo.assemblyId = '';
        assemblyInfo.frontWheelSize = '';
        assemblyInfo.rearWheelSize = '';
        assemblyInfo.vehicleFitmentId = '';
        assemblyInfo.factoryTireSizeFront = '';
        assemblyInfo.factoryTireSizeRear = '';
        assemblyCollection.add(assemblyInfo);
        vehicleInfo.assemblyCollection = assemblyCollection;
        
        vehicleTreadDepthInfo.tirePosition = '';
        vehicleTreadDepthInfo.depth = '';
        vehicleTreadDepthCollection.add(vehicleTreadDepthInfo);        
        vehicleInfo.vehicleTreadDepthCollection = vehicleTreadDepthCollection;   
        vehicleInfo.vehicleFitmentId='11645';
        vehicleInfo.vehicleYear='2018';
        vehicleInfo.vehicleMake='Toyota';
        vehicleInfo.vehicleModel='XUV-100';
        vehicleInfo.vehicleTrim='BMW-Z4-1.0-E85-TES';
        vehicleInfo.vehicleColor='Blue';
        vehicleInfo.vehicleMileage='1230';
        vehicleInfo.vehicleType='Generic';
        vehicleInfo.vehicleVin='';
        vehicleInfo.customerVehicleNotes='123456789Z4JV';
        vehicleInfo.vehicleImage='https://cdn.discounttire.com/sys-master/images/hef/hed/8935363346462/VEHICLE_201811210820_5469_8427.png_dt-vehicle-default-format_dt-vehicle-thumbNail';
        vehicleInfo.licensePlate='MH140980';
        vehicleInfo.licensePlateCountry='';
        vehicleInfo.licensePlateState='';
        vehicleInfo.fitmentChassisId='';
        vehicleInfo.fitmentAssemblyId='';
        vehicleInfo.fitmentTrimId='';
        vehicleInfo.genericVehicleCategory='';
        vehicleInfo.genericVehicleSubCategory='';
        workOrderTransRecord.vehicle = vehicleInfo;
        
        
        workOrderTransRecord.scheduling = schedulingInfo;
        schedulingInfo.promiseTimeReservationId='12345';
        schedulingInfo.promiseTimeMin='2022-11-16T02:44:51.281Z';
        schedulingInfo.promiseTimeMax='2022-11-16T02:44:51.281Z';
        schedulingInfo.bayEstimateStartTime='2022-11-16T02:44:51.281Z';
        schedulingInfo.bayEstimateEndTime='2022-11-16T02:44:51.281Z';
        
        /*Start: WOM-2078: Adding Tax related fields*/
        transDiscountInfo1.transactionDiscountAmount = 20;
        transDiscountInfo1.transactionDiscountReceiptName = 'CAP';
        transDiscountInfo2.transactionDiscountAmount = 10;
        transDiscountInfo2.transactionDiscountReceiptName = 'CapG';
        transDiscountInfoList.add(transDiscountInfo1);
        transDiscountInfoList.add(transDiscountInfo2);
        workOrderTransRecord.TransactionDiscountCollection = transDiscountInfoList;
        
        articleInfo.lineItemNumber='';
        articleInfo.returnOrderId='';
        articleInfo.salesOrderId='';
        articleInfo.articleAmount='';
        articleInfo.articleNumber='';
        articleInfo.articleDescription='';
        articleInfo.articleQuantity='';
        articleInfo.articleSize='';
        articleInfo.articleUpc='';
        articleInfo.articleVpn='';
        articleInfo.articleWeight='';
        articleInfo.articleType='';
        articleInfo.extendedAmount = 32.99;
        articleInfo.adjustmentReason = 'Mileage Warranty';
        articleInfo.tireMileageWarranty = '100000';
        articleInfoList.add(articleInfo);
        
        articleDiscountInfo.articleDiscountAmount = 20;
        articleDiscountInfo.articleDiscountReceiptName = 'CAP_Receipt';
        articleDiscountList.add(articleDiscountInfo);
        articleInfoList[0].ArticleDiscountCollection = articleDiscountList;
        workOrderTransRecord.ArticleCollection = articleInfoList;
        /*End: WOM-2078: Adding Tax related fields*/
        
        /*Start: WOM-2450: Data model update to accomodate Print DWO related fields*/
        workOrderTransRecord.alternateRecipientName = 'ALEXANDRA DEVINE';
        workOrderTransRecord.alternateRecipientPhone = '703-814-0368';
        workOrderTransRecord.isTreadwell = false;
        workOrderTransRecord.subtotal = 32.99;
        workOrderTransRecord.totalCredit = 32.99;
        workOrderTransRecord.total = 1232.99;
        workOrderTransRecord.businessPrimaryPhone = '703-814-0368';
        workOrderTransRecord.arPurchasingContact = 'GRACE LEE';
        /*End: WOM-2450: Data model update to accomodate Print DWO related fields*/
        
        return workOrderTransRecord;
    }
    @isTest
    //Successful call for Work Order and WOLI
    static void testInboundCallSuccess() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            WorkOrder wo = [SELECT Id from WorkOrder Limit 1];
            Test.startTest();
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                workOrderTransRecord.isArticlesCarryOut = true;
                
                articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder Creation Failed');
        }
    }
    @isTest
    //Successful call for Work Order and WOLI
    static void testInboundCallSuccessWithArticleQuantity() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            WorkOrder wo = [SELECT Id from WorkOrder Limit 1];
            Test.startTest();
            WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
            workOrderTransRecord.orderType ='SERVICE_APPOINTMENT';
            workOrderTransRecord.isArticlesCarryOut = true;
            workOrderTransRecord.workOrderId =wo.Id;
            articleInfo.lineItemNumber= '1';
            articleInfo.returnOrderId='1065999';
            articleInfo.salesOrderId='0000003721';
            articleInfo.articleAmount='12312';
            articleInfo.articleNumber='512';
            articleInfo.articleDescription='text';
            articleInfo.articleQuantity='2';
            articleInfo.articleSize='4';
            articleInfo.articleUPC='5';
            articleInfo.articleVPN='161653456';
            articleInfo.articleWeight='55';
            articleInfo.articleType='ZSRV';
            articleInfoList.add(articleInfo);
            workOrderTransRecord.ArticleCollection = articleInfoList;
            WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder with WOLI Creation Failed');
        }
    }
    @isTest
    //Cover unsuccessful scenario - 400
    static void testInboundCall400() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
            
            WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
            workOrderTransRecord.orderType ='STORE_ORDER';
            workOrderTransRecord.siteId=null;
            articleInfo.lineItemNumber='';
            articleInfo.returnOrderId='';
            articleInfo.salesOrderId='';
            articleInfo.articleAmount='';
            articleInfo.articleNumber='';
            articleInfo.articleDescription='';
            articleInfo.articleQuantity='';
            articleInfo.articleSize='';
            articleInfo.articleUPC='';
            articleInfo.articleVPN='';
            articleInfo.articleWeight='';
            articleInfo.articleType='';
            articleInfoList.add(articleInfo);
            workOrderTransRecord.ArticleCollection = articleInfoList;
            System.debug(System.LoggingLevel.DEBUG,'REC1'+workOrderTransRecord);
            
            WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION limit 1];
            System.assertEquals('Error',intMessage.Status__c,'OMNIPOS HOST WorkOrder 400 Error Scenario Failed');
        }
    }    
    @isTest
    //Cover unsuccessful scenario - 500
    static void testInboundCall500() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
            
            WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
            workOrderTransRecord.workOrderId='0WO7e000001yCvX';// to cause 500 error
            
            WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION limit 1];
            System.assertEquals('Error',intMessage.Status__c,'OMNIPOS HOST WorkOrder 500 Error Scenario Failed');
        }
    }
    
    @isTest
    //Method to check customerInfo.customerType ='B2B';
    static void testInboundCallB2B() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                
                phoneInfoUpdate.phoneType = 'mobile';
                phoneInfoUpdate.phoneCountryCode = '';
                phoneInfoUpdate.phoneNumber = '7038140370';
                phoneInfoUpdate.phoneExt = '';
                
                phoneInfoHome.phoneType = 'home';
                phoneInfoHome.phoneCountryCode = '';
                phoneInfoHome.phoneNumber = '7038140111';
                phoneInfoHome.phoneExt = '';
                
                phoneInfoWork.phoneType = 'work';
                phoneInfoWork.phoneCountryCode = '';
                phoneInfoWork.phoneNumber = '7038140311';
                phoneInfoWork.phoneExt = '';
                
                phoneListUpdate.add(phoneInfoUpdate);
                customerInfoUpdate.phoneCollection = phoneListUpdate;
                emailInfoUpdate.emailId = 'test@test.com';
                emailInfoUpdate.emailType = 'Primary';
                emailListUpdate.add(emailInfoUpdate);
                customerInfoUpdate.emailCollection = emailListUpdate;  
                customerInfoUpdate.customerVehicleId ='789481';
                customerInfoUpdate.customerId ='1234560';
                customerInfoUpdate.customerFirstName ='Ashley';
                customerInfoUpdate.customerLastName ='Tisdale';
                customerInfoUpdate.customerMiddleInitial ='';
                customerInfoUpdate.customerType ='B2B';
                customerInfoUpdate.arAccountNumber ='789458';
                customerInfoUpdate.accountName ='ABC Corp';
                customerInfoUpdate.companyName2 ='Ashley';
                customerInfoUpdate.dropOffWaitIndicator ='DROP_OFF';
                workOrderTransRecord.customer = customerInfoUpdate;
            
              articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder B2B Scenario Failed');
        }
    }
        
    @isTest
    //Method to cover when there is no WorkOrder ID from OmniPOS
    static void testInboundCallWithWOID() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
            articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
            Test.startTest();
            WorkOrder wo = [SELECT Id from WorkOrder Limit 1];
            if(wo!=null){
                workOrderTransRecord.workOrderId = String.valueOf(wo.Id);
            }
            
            WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder with WorkOrder Id Scenario Failed');
        }
    }
    @isTest
    //Method to check whether the Account Insert fails
    static void testInboundCallNoAccount() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            WorkOrder wo = [SELECT Id from WorkOrder Limit 1];
            Test.startTest();
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                
                phoneInfoUpdate.phoneType = 'mobile';
                phoneInfoUpdate.phoneCountryCode = '';
                phoneInfoUpdate.phoneNumber = '7038140370';
                phoneInfoUpdate.phoneExt = '';
                phoneListUpdate.add(phoneInfoUpdate);
                customerInfoUpdate.phoneCollection = phoneListUpdate;
                emailInfoUpdate.emailId = 'test@test.com';
                emailInfoUpdate.emailType = 'Primary';
                emailListUpdate.add(emailInfoUpdate);
                customerInfoUpdate.emailCollection = emailListUpdate;  
                customerInfoUpdate.customerVehicleId ='789481';
                customerInfoUpdate.customerId ='123123';
                customerInfoUpdate.customerFirstName ='Ashley';
                customerInfoUpdate.customerLastName ='Tisdale';
                customerInfoUpdate.customerMiddleInitial ='';
                customerInfoUpdate.customerType ='B2B';
                customerInfoUpdate.arAccountNumber ='789458';
                customerInfoUpdate.accountName ='';
                customerInfoUpdate.companyName2 ='Ashley';
                customerInfoUpdate.dropOffWaitIndicator ='DROP_OFF';
                workOrderTransRecord.customer = customerInfoUpdate;
            
              articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder No Account Scenario Failed');
        }
    }
    @isTest
    //Method to check whether the Account Insert fails
    static void testInboundCallExistingAccount() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            //Insert an account which matches with the OmniPOS inbound call
            List<Account> acctList = WOM_TestDataUtility.createAccounts(1,'Test Account','B2B');
            acctList[0].Appt3_Customer_Id__c = '1234560';
            Insert acctList;
            
            Test.startTest();
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                
                phoneInfoUpdate.phoneType = 'mobile';
                phoneInfoUpdate.phoneCountryCode = '';
                phoneInfoUpdate.phoneNumber = '7038140370';
                phoneInfoUpdate.phoneExt = '';
                phoneListUpdate.add(phoneInfoUpdate);
                customerInfoUpdate.phoneCollection = phoneListUpdate;
                emailInfoUpdate.emailId = 'test@test.com';
                emailInfoUpdate.emailType = 'Primary';
                emailListUpdate.add(emailInfoUpdate);
                customerInfoUpdate.emailCollection = emailListUpdate;  
                customerInfoUpdate.customerVehicleId ='789481';
                customerInfoUpdate.customerId ='1234560';
                customerInfoUpdate.customerFirstName ='Ashley';
                customerInfoUpdate.customerLastName ='Tisdale';
                customerInfoUpdate.customerMiddleInitial ='';
                customerInfoUpdate.customerType ='B2B';
                customerInfoUpdate.arAccountNumber ='789458';
                customerInfoUpdate.accountName ='';
                customerInfoUpdate.companyName2 ='Ashley';
                customerInfoUpdate.dropOffWaitIndicator ='DROP_OFF';
                workOrderTransRecord.customer = customerInfoUpdate;
              
              articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder Existing Account Scenario Failed');
        }
    }
    @isTest
    //Method to check whether the Account Insert fails
    static void testInboundCallExistingAsset() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Id vehRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();
            
            //Insert an account which matches with the OmniPOS inbound call
            List<Account> acctList = WOM_TestDataUtility.createAccounts(1,'Test Account','B2B');
            acctList[0].Appt3_Customer_Id__c = '1234560';
            Insert acctList;
            
            //Insert an Asset which matches with the OmniPOS inbound call
            Asset assetRec = new Asset();
            assetRec.Name =  '2023 Toyota'; 
            assetRec.AccountId =  acctList[0].Id; 
            assetRec.RecordTypeId =  vehRecordTypeId; 
            assetRec.Assembly_Id__c =  '45AS'; 
            assetRec.Vehicle_Manufacture_Year__c = '2023';
            assetRec.Vehicle_Make__c = 'Toyota';
            assetRec.Vehicle_Model__c = 'XL';
            assetRec.Vehicle_License_Plate__c = 'GK781';
            assetRec.Trim_Id__c = '7845';
            assetRec.Appt3_Customer_Vehicle_Id__c = '789481';
            Insert assetRec;
            
            Test.startTest();
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
            
              articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder Existing Asset Scenario Failed');
        }
    }
    
    @isTest
    //Method to assign an existing ServiceTerritory
    static void testInboundCallServiceTerrAssignment() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WorkOrder woRec = new WorkOrder();
                woRec = [SELECT Id FROM WorkOrder Limit 1];
                
                List <WorkOrderLineItem> woliResults = WOM_TestDataUtility.createWOLI(2, woRec.Id, '2');
                insert woliResults;
                
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                
                articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                workOrderTransRecord.storeCode='06061999';
                workOrderTransRecord.workOrderId = woRec.Id;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Logs__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder for existing Service Territory Scenario Failed');
            
        }
    }    
    @isTest
    //Method to assign an existing ServiceTerritory
    static void testInboundCallIncorrectServiceTerr() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WorkOrder woRec = new WorkOrder();
                woRec = [SELECT Id FROM WorkOrder Limit 1];
                
                List <WorkOrderLineItem> woliResults = WOM_TestDataUtility.createWOLI(2, woRec.Id, '2');
                insert woliResults;
                
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                
                articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                workOrderTransRecord.storeCode='123123';
                workOrderTransRecord.workOrderId = woRec.Id;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
                       
        }
    }    
    @isTest
    //Method to verify incorrect Work order ID from GK
    static void testInboundCallIncorrectWOId() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                workOrderTransRecord.workOrderId = '0WO7e000001XVAtCAO';
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Error',intMessage.Status__c,'OMNIPOS HOST WorkOrder Invalid WO Id Scenario Failed');

        }
    }
    @isTest
    //Method to verify incorrect Asset creation
    static void testInboundCallIncorrectAsset() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                //Sending asset data which should create a new record in Salesforce with failure 
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                vehicleInfo.vehicleFitmentId='7845';
                vehicleInfo.vehicleYear='2014';
                vehicleInfo.vehicleMake='BMW';
                vehicleInfo.vehicleModel='A5';
                vehicleInfo.vehicleTrim='BMW-Z4-1.0-E85-TES';
                vehicleInfo.vehicleColor='Blue';
                vehicleInfo.vehicleMileage='';
                vehicleInfo.vehicleType='Fitment';
                vehicleInfo.vehicleVin='45120';
                vehicleInfo.customerVehicleNotes='notes here';
                
                workOrderTransRecord.vehicle = vehicleInfo;
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            List<Int_Message__c> intMessage = [Select id,Status__c,RecordId__c,Type__c,Create_Time__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.debug('Unique1: '+intMessage);
            //System.assertEquals('Error',intMessage.Status__c,'OMNIPOS HOST WorkOrder Invalid Asset Scenario Failed');
        }
    }
    
    @isTest
    //Method to verify incorrect Asset creation
    static void testInboundCallIncorrectWOLI() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                //Sending incorrect WOLI data from OmniPOS
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                
                articleInfo.lineItemNumber='1';
                articleInfo.returnOrderId='23';
                articleInfo.salesOrderId='12321';
                articleInfo.articleAmount='10';
                articleInfo.articleNumber='7845';
                articleInfo.articleDescription='Random description';
                articleInfo.articleQuantity='Text in Number Field'; //incorrect quantity
                articleInfo.articleSize='3';
                articleInfo.articleUpc='';
                articleInfo.articleVpn='';
                articleInfo.articleWeight='';
                articleInfo.articleType='';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Error',intMessage.Status__c,'OMNIPOS HOST WorkOrder Invalid WOLI Scenario Failed');
        }    
    }
    
    @isTest
    //Method to verify Phone and Email fields for B2B Customer
    static void testInboundCallPhoneEmailB2B() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                
                phoneInfoUpdate.phoneType = 'work';
                phoneInfoUpdate.phoneCountryCode = '';
                phoneInfoUpdate.phoneNumber = '7038140370';
                phoneInfoUpdate.phoneExt = '';
                phoneListUpdate.add(phoneInfoUpdate);
                customerInfoUpdate.phoneCollection = phoneListUpdate;
                emailInfoUpdate.emailId = 'test@test.com';
                emailInfoUpdate.emailType = 'secondary';
                emailListUpdate.add(emailInfoUpdate);
                customerInfoUpdate.emailCollection = emailListUpdate;  
                customerInfoUpdate.customerVehicleId ='789481';
                customerInfoUpdate.customerId ='1234560';
                customerInfoUpdate.customerFirstName ='Ashley';
                customerInfoUpdate.customerLastName ='Tisdale';
                customerInfoUpdate.customerMiddleInitial ='';
                customerInfoUpdate.customerType ='B2B';
                customerInfoUpdate.arAccountNumber ='789458';
                customerInfoUpdate.accountName ='Ltd.';
                customerInfoUpdate.companyName2 ='Ashley';
                customerInfoUpdate.dropOffWaitIndicator ='DROP_OFF';
                workOrderTransRecord.customer = customerInfoUpdate;
            
                articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder Phone Email B2B Scenario Failed');
        }
    }
    @isTest
    //Method to verify Phone and Email fields for B2C Customer
    static void testInboundCallPhoneEmailB2C() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                
                phoneInfoUpdate.phoneType = 'work';
                phoneInfoUpdate.phoneCountryCode = '';
                phoneInfoUpdate.phoneNumber = '7038140370';
                phoneInfoUpdate.phoneExt = '';
                phoneListUpdate.add(phoneInfoUpdate);
                customerInfoUpdate.phoneCollection = phoneListUpdate;
                emailInfoUpdate.emailId = 'test@test.com';
                emailInfoUpdate.emailType = 'secondary';
                emailListUpdate.add(emailInfoUpdate);
                customerInfoUpdate.emailCollection = emailListUpdate;  
                customerInfoUpdate.customerVehicleId ='789481';
                customerInfoUpdate.customerId ='12241060';
                customerInfoUpdate.customerFirstName ='Ashley';
                customerInfoUpdate.customerLastName ='Tisdale';
                customerInfoUpdate.customerMiddleInitial ='';
                customerInfoUpdate.customerType ='B2C';
                customerInfoUpdate.arAccountNumber ='789458';
                customerInfoUpdate.accountName ='';
                customerInfoUpdate.companyName2 ='Ashley';
                customerInfoUpdate.dropOffWaitIndicator ='DROP_OFF';
                workOrderTransRecord.customer = customerInfoUpdate;
            
                articleInfo.lineItemNumber='2';
                articleInfo.returnOrderId='1065999';
                articleInfo.salesOrderId='0000003721';
                articleInfo.articleAmount='1612376715';
                articleInfo.articleNumber='1612371234';
                articleInfo.articleDescription='the very long description';
                articleInfo.articleQuantity='5';
                articleInfo.articleSize='4';
                articleInfo.articleUpc='4';
                articleInfo.articleVpn='161653456';
                articleInfo.articleWeight='55';
                articleInfo.articleType='ZSRV';
                articleInfoList.add(articleInfo);
                workOrderTransRecord.ArticleCollection = articleInfoList;
                
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();
            Int_Message__c intMessage = [Select id,Status__c,Salesforce_Error__c, External_Error__c from Int_Message__c where Type__c=:WOM_APIHelper.TYPE_WOM_WORKORDER_INFORMATION];
            System.assertEquals('Successful',intMessage.Status__c,'OMNIPOS HOST WorkOrder Phone Email B2C Scenario Failed');
        }
    }
    
     /*
    * @Method Name       : minimumPermissionTest
    * @description       : Test method to test whether or not the logged in user have permission to add data to CSL 
    * @author            : Anuradha
    * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
    * @last modified on  : 05-18-2023
    */
    @isTest
    public static void minimumPermissionTest(){
        List<User> usr = WOM_TestDataUtility.createUsers(1,'Test 1','User 1','WOM Service Account',true);
        usr[0].User_Store_Id__c = '123123';
        usr[0].Username = 'user0@test.com';
        insert usr; 
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        try 
        {
            System.runas(u){
            Test.startTest();
                WorkOrder wo = [SELECT Id from WorkOrder Limit 1];
                WOM_WorkOrderOmniPosHOSTAPIWrapper workOrderTransRecord = dataSetup();
                workOrderTransRecord.workOrderId = wo.Id;
                WOM_WorkOrderOmniPosHOSTAPI.ResponseMessageClass  results = WOM_WorkOrderOmniPosHOSTAPI.doWorkOrderPost(workOrderTransRecord);
            Test.stopTest();    
            }
        } 
        catch (Exception ex) 
        {
            System.AssertEquals('List has no rows for assignment to SObject',ex.getMessage(),'Not Expected Exception');
        }
    }
}