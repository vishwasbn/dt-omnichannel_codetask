/*========================================================================================================
* @author: Capgemini
* @date: 08th Apr '23
* @description: test class form PT_PromiseTimeHelper class

Modification Log:
------------------------------------------------------------------------------------
Developer      Mod Number   Date                Description
------------------------------------------------------------------------------------
Jaswanth        M-001       08 Apr '23          Initial developement 
========================================================================================================== */
@isTest
public class PT_PromiseTimeHelperTest {
    /**
    * @Method Name       : dataSetup
    * @description       : It is used to create data needed for testing 
    * @author            : Jaswanth
    **/ 
    @testSetup 
    static void dataSetup(){
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        User posUser = Appt_TestUtil.getPosTerminalUser('TestPos' ,'TerminalTestUser');
    }
    
    /** 
    * @description  : test method to change the ordertype and order related fields"
    **/ 
    @isTest
    static void afterUpdateTest(){
        User posUser = [select id from user where FirstName=:'TestPos' and LastName=:'TerminalTestUser'];
        WorkOrderLineItem woli= new WorkOrderLineItem ();
        WorkType orderWorkType=[select id from WorkType limit 1];
        ServiceTerritory servTerr=[select id from ServiceTerritory limit 1];
        FSL__Scheduling_Policy__c schedulePolicy=[select id from FSL__Scheduling_Policy__c limit 1];
        Contact con=[select id,accountId from contact where AccountId != null limit 1];
        Account acc=[select id,SAP_STORE_ID__c from account where id =: con.AccountId];
        Asset vehicleAsset = Appt_TestUtil.getVehicle_Asset( posUser.Id, acc.Id, con.Id);
        system.runAs(posUser){
            test.startTest();
            //work order insertion
            Workorder wo= Appt_TestUtil.getWorkOrder( posUser.Id, acc.Id, con.Id, 'Two tire change', orderWorkType.Id, servTerr.Id, 'ROPIS', 'WEB', Date.valueOf('2023-05-08'), Date.valueOf('2023-05-08'), vehicleAsset.Id);
            woli.WOM_Article_Number__c='000000000000084838';
            woli.WOM_ArticleSize__c='AIR';
            woli.WOM_Article_Quantity__c=5;
            woli.WOM_Article_Description__c='Test WOLI';
            woli.Appt3_Treadwell__c=TRUE;
            woli.Appt3_Article_Type__c='TEST';
            woli.WorkOrderId=wo.id;
            //woli insertion
            insert woli;
            Integer localTimeZoneOffset = -7;
            Integer appointmentDuration = 20;
            Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();
            Time apptStartTime = Time.newInstance(8,0,0,0);
            Time apptEndTime = Time.newInstance(8,20,0,0);
            Time starttimestring = Time.newInstance(9, 0, 0, 0);
            Time endtimestring = Time.newInstance(9, 20, 0, 0);
            Datetime apptStartDateTime = Datetime.newInstance(currentDate, apptStartTime);
            Datetime apptEndDateTime = Datetime.newInstance(currentDate, apptEndTime);
            Datetime starttimedate = Datetime.newInstance(currentDate, starttimestring);
            Datetime endtimedate = Datetime.newInstance(currentDate, endtimestring);
            //service appointment insertion
            serviceappointment app=Appt_TestUtil.getServiceAppointment( posUser.Id, wo.Id, acc.Id, orderWorkType.Id, con.Id, servTerr.Id, acc.SAP_STORE_ID__c, apptStartDateTime, apptEndDateTime, localTimeZoneOffset, appointmentDuration, 'Front Room', schedulePolicy.Id);
            
            wo.Order_Type__c=Appt_ConstantValues.WORKORDER_ORDERTYPE_BOPIS;
            update wo;
            Workorder updated= [select id, order_type__c from workorder where id=: wo.id];
            Assert.areEqual(Appt_ConstantValues.WORKORDER_ORDERTYPE_BOPIS, updated.order_type__c, 'Order type not changed');
            wo.Hybris_Order_Id__c = '5000145203';
            wo.Invoice_Number__c = '000000';
            wo.Layaway_Number__c ='1179000012';
            wo.Quote_Number__c = '0000536';
            update wo;
            updated= [select id, Hybris_Order_Id__c,Invoice_Number__c,Layaway_Number__c,Quote_Number__c from workorder where id=: wo.id];
            Assert.areEqual('5000145203',updated.Hybris_Order_Id__c, 'Hybris order id not changed');
            Assert.areEqual('000000',updated.Invoice_Number__c,'Invoice number not updated');
            Assert.areEqual('1179000012',updated.Layaway_Number__c,'Layaway number not updated');
            Assert.areEqual('0000536', updated.Quote_Number__c, 'Quote number not updated');
            test.stopTest();
        }
    }
    
    /** 
    * @description  : Test method to cover catch block
    **/
    @isTest
    static void catchblocktest(){
        User posUser = [select id from user where FirstName=:'TestPos' and LastName=:'TerminalTestUser'];
        system.runAs(posUser){
            test.startTest();
            PT_PromiseTimeHelper PThelper = new PT_PromiseTimeHelper();
            PThelper.afterUpdate(null,null);
            test.stopTest();
        }
    }
    
    /** 
    * @description  : Test method to cover delete and undelete events
    **/
    @isTest
    static void deletingWorkOrderTest(){
        User posUser = [select id from user where FirstName=:'TestPos' and LastName=:'TerminalTestUser'];
        WorkOrderLineItem woli= new WorkOrderLineItem ();
        WorkType orderWorkType=[select id from WorkType limit 1];
        ServiceTerritory servTerr=[select id from ServiceTerritory limit 1];
        FSL__Scheduling_Policy__c schedulePolicy=[select id from FSL__Scheduling_Policy__c limit 1];
        Contact con=[select id,accountId from contact where AccountId != null limit 1];
        Account acc=[select id,SAP_STORE_ID__c from account where id =: con.AccountId];
        Asset vehicleAsset = Appt_TestUtil.getVehicle_Asset( posUser.Id, acc.Id, con.Id);
        system.runAs(posUser){
            test.startTest();
            Workorder wo= Appt_TestUtil.getWorkOrder( posUser.Id, acc.Id, con.Id, 'Two tire change', orderWorkType.Id, servTerr.Id, 'ROPIS', 'WEB', Date.valueOf('2023-05-08'), Date.valueOf('2023-05-08'), vehicleAsset.Id);
            List<WorkOrder> workOrderRecord = [SELECT Id, LocationID FROM WorkOrder where id=:wo.Id];
            delete workOrderRecord;
            undelete workOrderRecord;
            system.assertEquals(workOrderRecord.size(), 1,'error');
            test.stopTest();
        }
    }
}