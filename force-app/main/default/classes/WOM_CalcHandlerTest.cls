/*========================================================================================================
* @author: Capgemini
* @date: 22nd Sept 2022 
* @description: Test Class for WOM_CalcHandler Class

Modification Log:
------------------------------------------------------------------------------------
Developer      Mod Number  Date                User Story      Description
------------------------------------------------------------------------------------
Akilan         M-001       22nd Sept 2022                       Initial development
Akilan         M-002       20th Oct 2022                        Improve Code Coverage for Bayed out Last Hour
Pradeep        M-003       25th Oct 2022                        Added Code Coverage for Estimated Wait Time
Akilan         M-004       26th Oct 2022                        Added Code Coverage for Checked In Last Hours
Urvi           M-005       28th Dec 2022                        Updated to follow best practices
G Anil         M-006       23th Mar 2023                        updated estimatedwaitime to include sys.assert
========================================================================================================== */
@isTest(SeeAllData=false)
public class WOM_CalcHandlerTest {
    /**
    * @Method Name       : dataSetup
    * @description       : It is used to create data needed for testing 
    * @author            : Akilan
    * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
    * @last modified on  : 05-12-2023
    **/ 
    @testSetup 
    static void dataSetup(){
        Apex_Bypass__c apexCustomSettingRec = new Apex_Bypass__c();
        apexCustomSettingRec.Name = 'Test User';
        apexCustomSettingRec.Work_Order_Trigger__c = false;
        insert apexCustomSettingRec;
        
        //insert User
        List<User> usr = WOM_TestDataUtility.createUsers(1,'Test','User','System Administrator',true);
        usr[0].User_Store_Id__c='123123';
        insert usr;
        
        //insert operating hours
        List<OperatingHours> opHrs = WOM_TestDataUtility.createOpHours(1,'Test Operating Hours');
        insert opHrs;
        
        //insert account
        List<Account> acct = WOM_TestDataUtility.createAccounts(1,'Test Account','Site');
        acct[0].Store_Id__c='123123';
        insert acct;
        
        //insert service territory
        List<ServiceTerritory> servTerr = WOM_TestDataUtility.createServiceTerritory(1,'Test Service Territory',true);
        insert servTerr;
        
        //insert locations
        List<Schema.Location> listBayLocs = WOM_TestDataUtility.createLocation(2,'Test Bay','Available','Flat','Site',false);
        listBayLocs[1].WOM_Multiple_Vehicles__c = true;
        insert listBayLocs;
        
        //insert work orders
        List<WorkOrder> listWOs = WOM_TestDataUtility.createWO(3,'Awaiting Service',-30,listBayLocs[1].Id);
        
        listWOs[0].WOM_Promise_Time_Max__c=System.now().addMinutes(10);
        listWOs[1].WOM_Promise_Time_Max__c=System.now().addMinutes(30);
        listWOs[2].WOM_Promise_Time_Max__c=System.now();
        
        listWOs[0].WOM_AwaitingService_Time__c=System.now().addMinutes(10);
        listWOs[1].WOM_AwaitingService_Time__c=System.now().addMinutes(-30);
        listWOs[2].WOM_AwaitingService_Time__c=System.now().addhours(-1);
        
        listWOs[0].LocationId = listBayLocs[1].Id;
        listWOs[1].LocationId = listBayLocs[1].Id;
        
        /* listWOs[0].Status = 'In Bay';
        listWOs[1].Status = 'In Bay'; */
        insert listWOs;    
    }
    /**
    * @Method Name       : bayInLasthour
    * @description       : It is used to test functionality of the method getCalculations to check noOfVehiclesCheckedIn    
    * @author            : Akilan
    * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
    * @last modified on  : 05-12-2023
    **/ 
    @isTest
    static void bayInLasthour(){
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                Account acct = [SELECT Id,Store_Id__c FROM Account];
                WOM_CalcHandler.wrapperClass results = WOM_CalcHandler.getCalculations(acct.Store_Id__c);
                System.Assertequals(1,results.noOfVehiclesCheckedIn,'Checked In Last Hour Failed');
            Test.stopTest();
        }
    }
    /**
    * @Method Name       : bayOutLastHourNegative
    * @description       : It is used to test negative functionality of the method getCalculations to check noOfVehiclesBayedOut    
    * @author            : Akilan
    * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
    * @last modified on  : 05-12-2023
    **/ 
    
    @isTest
    static void bayOutLastHourNegative(){
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
            Account acct = [SELECT Id,Store_Id__c FROM Account];
            WOM_CalcHandler.wrapperClass results = WOM_CalcHandler.getCalculations(acct.Store_Id__c);
            System.Assertequals(0,results.NoOfVehiclesBayedOut,'Bay Out Last Hour Failed');
            Test.stopTest();
        }
    }
    /**
    * @Method Name       : bayOutLastHourPositive
    * @description       : It is used to test positive functionality of the method getCalculations to check noOfVehiclesBayedOut    
    * @author            : Akilan
    * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
    * @last modified on  : 05-12-2023
    **/ 
    
    @isTest
    static void bayOutLastHourPositive(){
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            
            List<WorkOrder> listWOs = [SELECT Id, LocationID, Location.WOM_Multiple_Vehicles__c,status, Location.WOM_Active_Bay_Assignment__c  FROM WorkOrder WHERE Status ='Awaiting Service' LIMIT 1];
            listWOs[0].Status = 'In Bay';
            update listWOs;
            
            Test.startTest();
                listWOs[0].Status = 'Bay Out';
                update listWOs;
     
                Account acct = [SELECT Id,Store_Id__c FROM Account];
                WOM_CalcHandler.wrapperClass results = WOM_CalcHandler.getCalculations(acct.Store_Id__c);
                // System.Assertequals(1,results.NoOfVehiclesBayedOut,'Bay Out Last Hour');
            Test.stopTest();
        }
    }
    /**
    * @Method Name       : totalBayTimeStore
    * @description       : It is used to test functionality of the method getCalculations to check totalBayTime 
    * @author            : Akilan
    * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
    * @last modified on  : 05-12-2023
    **/ 
    @isTest
    static void totalBayTimeStore(){
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
            Account acct = [SELECT Id,Store_Id__c FROM Account];
            WOM_CalcHandler.wrapperClass results = WOM_CalcHandler.getCalculations(acct.Store_Id__c);
            System.Assertequals(0,results.TotalBayTime,'Total Bay Time Store');
            Test.stopTest();
        }
    }
    /**
    * @Method Name       : estimatedWaitTime
    * @description       : It is used to test functionality of the method getCalculations to check estimatedWaitTime    
    * @author            : Akilan
    * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
    * @last modified on  : 05-12-2023
    **/
    @isTest
    static void estimatedWaitTime(){
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];

        System.runas(u){
            Test.startTest();
            Account acct = [SELECT Id,Store_Id__c FROM Account];
            List<WorkOrder> est = [Select WOM_Promise_Time_Max__c, WOM_AwaitingService_Time__c from WorkOrder];
            WOM_CalcHandler.wrapperClass results = WOM_CalcHandler.getCalculations(acct.Store_Id__c);
            System.Assertequals(40,results.estimatedWaitTime,'estimated WaitTime store');
            
            Test.stopTest();
        }
    }
    
    /*
    * @Method Name       : missingGetAllBayAssignmentsTest
    * @description       : Test method to test whether or not the logged in user have permission to view service queue bay options
    * @author            : Pradeep
    * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
    * @last modified on  : 05-12-2023
    */
    @isTest
    public static void missingGetAllBayAssignmentsTest(){
        List<User> usr = WOM_TestDataUtility.createUsers(1,'Test 1','User 1','WOM Service Account',true);
        usr[0].User_Store_Id__c = '123123';
        usr[0].Username = 'user123@yahoo.com';
        insert usr; 
        User u= [SELECT Id from User where Username ='user123@yahoo.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                WOM_CalcHandler.wrapperClass results = WOM_CalcHandler.getCalculations('123123');
                System.AssertNotEquals(40,results.estimatedWaitTime,'estimated WaitTime store');
            Test.stopTest();
        }
    }
    
    
     /*
    * @Method Name       : missingGetAllWOTest
    * @description       : Test method to test whether or not the logged in user have permission to view service queue bay options
    * @author            : Pradeep
    * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
    * @last modified on  : 05-12-2023
    */
    @isTest
    public static void missingGetAllWOTest(){
        List<User> usr = WOM_TestDataUtility.createUsers(1,'Test 1','User 1','WOM Service Account',true);
        usr[0].User_Store_Id__c = '123123';
        usr[0].Username = 'user123@yahoo.com';
        insert usr; 
        User u= [SELECT Id from User where Username ='user123@yahoo.com' LIMIT 1];
        System.runas(u){
            Test.startTest();
                Map<Id,WorkOrder> workOrderMap = WOM_CalcHandler.getAllWO('123123');
                System.assertNotEquals(1, workOrderMap.size(), 'Some WOs are getting returned');
            Test.stopTest();
        }
    }
    
    
    
}