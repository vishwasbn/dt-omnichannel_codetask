@IsTest
public without sharing class Appt_TestUtil 
{
    
    final static string lprefix = 'LOG Appt_TestUtil: ';
    @IsTest
    public static List<ServiceAppointment> basicAppointment_StoreConfiguration ()
    {
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED);
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING );
        FSL.GlobalAPIS.addStatusTransition(Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED, Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED );

        User sysUser = Appt_TestUtil.getTestAdminUser( 'John', 'Smith');

        Account acctObj = Appt_TestUtil.getSiteAccount('Test Account', sysUser.id);

        OperatingHours operHours =  Appt_TestUtil.getOperatingHours('EST 8-6 Store Hours', 'America/New_York', 'Store Hours');
        OperatingHours fbTmeSltConfig =  Appt_TestUtil.getOperatingHours('20 Minute Time Slots', 'America/Phoenix', 'Bucket Capacity');

        FSL__Scheduling_Policy__c schPol = Appt_TestUtil.getSchedulingPolicy('Appointment Policy', sysUser.id);

        WorkType fntWrkTyp = Appt_TestUtil.getWorkType('Front Office', sysUser.id, 'Front Office Work Type', 20, 4320);
        WorkType bckWrkTyp = Appt_TestUtil.getWorkType('Back Office', sysUser.id, 'Back Office Work Type', 20, null);

        // Service Territory setup
        ServiceTerritory servTerr =  Appt_TestUtil.getServiceTerritory('RIP05', sysUser.Id, operHours.Id, schPol.Id, fbTmeSltConfig.Id, acctObj.Id, fntWrkTyp.Id, bckWrkTyp.Id);

        // Store hours... open(startTime)... close(endTime) ...close Saturday (endTimeSaturday)
        Time startTime = Time.newInstance(8,0,0,0);
        Time endTime = Time.newInstance(18,0,0,0);
        Time endTimeSaturday = Time.newInstance(17,0,0,0);

        TimeSlot tsMonday = Appt_TestUtil.createTimeSlotWeekday(operHours.Id, 'Monday', 'Normal', startTime, endTime);
        TimeSlot tsTuesday = Appt_TestUtil.createTimeSlotWeekday(operHours.Id, 'Tuesday', 'Normal', startTime, endTime);
        TimeSlot tsWednesday = Appt_TestUtil.createTimeSlotWeekday(operHours.Id, 'Wednesday', 'Normal', startTime, endTime);
        TimeSlot tsThursday = Appt_TestUtil.createTimeSlotWeekday(operHours.Id, 'Thursday', 'Normal', startTime, endTime);
        TimeSlot tsFriday = Appt_TestUtil.createTimeSlotWeekday(operHours.Id, 'Friday', 'Normal', startTime, endTime);
        TimeSlot tsSaturday = Appt_TestUtil.createTimeSlotWeekday(operHours.Id, 'Saturday', 'Normal', startTime, endTimeSaturday);
        // System.debug(lprefix + 'Weekday Time Slots: complete');

        // Time Slots Begin (stEnd) and End (stEnd) slot time
        Time stEnd = startTime;
        List<TimeSlot> dailyTimeSlots = new List<TimeSlot>();
        For (Time stStart = startTime; stStart < endTime; stStart = stStart.addMinutes(20)) 
        {
            stEnd = stEnd.addMinutes(20);
            // System.debug(lprefix + 'Daily: Time Slot, start: ' + stStart + ' end: ' + stEnd);
            dailyTimeSlots.add(Appt_TestUtil.createTimeSlotDaily(fbTmeSltConfig.Id, 'Monday', 'Normal', stStart, stEnd, 4));
            dailyTimeSlots.add(Appt_TestUtil.createTimeSlotDaily(fbTmeSltConfig.Id, 'Tuesday', 'Normal', stStart, stEnd, 4));
            dailyTimeSlots.add(Appt_TestUtil.createTimeSlotDaily(fbTmeSltConfig.Id, 'Wednesday', 'Normal', stStart, stEnd, 4));
            dailyTimeSlots.add(Appt_TestUtil.createTimeSlotDaily(fbTmeSltConfig.Id, 'Thursday', 'Normal', stStart, stEnd, 4));
            dailyTimeSlots.add(Appt_TestUtil.createTimeSlotDaily(fbTmeSltConfig.Id, 'Friday', 'Normal', stStart, stEnd, 4));
            if (stStart < endTimeSaturday){
                dailyTimeSlots.add(Appt_TestUtil.createTimeSlotDaily(fbTmeSltConfig.Id, 'Saturday', 'Normal', stStart, stEnd, 4));
            }
        }
        insert dailyTimeSlots;

        // Monthly generated Appt Time Slots... Begin (atsStart) ... End  (atsEnd) slot time
        // move up the date if it is sunday
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();
        Datetime atsEnd = Datetime.newInstance(currentDate, startTime); // setup the single slot end datetime
        Datetime endDateTime = Datetime.newInstance(currentDate.addDays(27), endTime); // setup the month end datetime
        System.debug(lprefix + 'Weekday: ' + currentDate + ' End: ' + atsEnd + ' MonthEnd: ' + endDateTime + ' StartTime: ' + startTime + ' EndTime: ' + endTime);

        List<Appt_Time_Slot__c> apptTimeSlots = new List<Appt_Time_Slot__c>();
        For (Datetime atsStart = Datetime.newInstance(currentDate, startTime); atsStart < endDateTime; atsStart = atsStart.addMinutes(20))
        {
            // jump over sunday, saturday early close
            // at close time, jump to open the next day...
            String weekDay = atsStart.format('u');
            // System.debug(lprefix + 'Weekday: ' + weekDay + ' : ' + atsStart);
            if ( ( weekDay == '6' ) && ( atsStart.time() >= endTimeSaturday ) ) {
                // System.debug(lprefix + 'Weekday - Saturday');
                atsStart = Datetime.newInstance( atsStart.date().addDays(2), startTime); // jump to monday
            } else if ( atsStart.time() >= endTime ) {
                // System.debug(lprefix + 'Weekday - next day');
                atsStart = Datetime.newInstance( atsStart.date().addDays(1), startTime); // jump to next workday
            }

            atsEnd = atsStart.addMinutes(20);
            // System.debug(lprefix + ' StartTime: ' + atsStart + ' EndTime: ' + atsEnd);
            Appt_Time_Slot__c nextTimeSlot = Appt_TestUtil.createApptTimeSlot(servTerr.Id, atsStart.date(), atsStart, atsEnd, 'Front Room');
            apptTimeSlots.add(nextTimeSlot);
            nextTimeSlot = Appt_TestUtil.createApptTimeSlot(servTerr.Id, atsStart.date(), atsStart, atsEnd, 'Back Room');
            apptTimeSlots.add(nextTimeSlot);
            // System.debug(lprefix + 'ApptTimeSlot: ' + nextTimeSlot.Start_Time__c + ' to ' + nextTimeSlot.End_Time__c);
        }
        insert apptTimeSlots;

        // generate the rest of the slots 30 days out
        // Appt_GenerateCleanupApptTimeSlotsBatch.process();

        User resourceUser = Appt_TestUtil.getStandardUser('Tom', 'Jones');

        ServiceResource servResource = Appt_TestUtil.getServiceResource('Resource Back', sysUser.Id , resourceUser.Id, 'T', 'Back Room');

        ServiceTerritoryMember servTerritoryMember = Appt_TestUtil.getServiceTerritoryMember(servTerr.Id, servResource.Id, 'P', Datetime.now().addMonths(-2));

        Account custAccount = Appt_TestUtil.getCustomerAccount( sysUser.Id, 'Sam', 'Spade');

        List<Contact> custContacts = [SELECT Id FROM Contact WHERE AccountId =: custAccount.Id];
        
        System.assertEquals(1, custContacts.size(), 'No Contact was created by the Person Account creation');

        Asset vehicleAsset = Appt_TestUtil.getVehicle_Asset( sysUser.Id, custAccount.Id, custContacts[0].Id);

        WorkType orderWorkType = Appt_TestUtil.getWorkOrderType('20 Minute Appointment', sysUser.Id, 20, 4320);

        WorkOrder customerWrkOrder = Appt_TestUtil.getWorkOrder( sysUser.Id, custAccount.Id, custContacts[0].Id, 'Two tire change', orderWorkType.Id, servTerr.Id, 'ROPIS', 'WEB', Date.valueOf('2021-01-14'), Date.valueOf('2021-01-14'), vehicleAsset.Id);

        FSL__Scheduling_Policy__c schedulePolicy = Appt_TestUtil.getSchedulingPolicy(sysUser.Id, 'Appointment Policy');

        // can't use current time, the test may not run during "business hours", so there would be no Time Slots
        Time apptStartTime = Time.newInstance(8,0,0,0);
        Time apptEndTime = Time.newInstance(8,20,0,0);
        Datetime apptStartDateTime = Datetime.newInstance(currentDate, apptStartTime);
        Datetime apptEndDateTime = Datetime.newInstance(currentDate, apptEndTime);
        Integer localTimeZoneOffset = -7;
        Integer appointmentDuration = 20;

        // List<ServiceAppointment> servApptList = new List<ServiceAppointment>();
        ServiceAppointment fntServiceAppt = Appt_TestUtil.getServiceAppointment( sysUser.Id, customerWrkOrder.Id, custAccount.Id, orderWorkType.Id, custContacts[0].Id, servTerr.Id, acctObj.SAP_STORE_ID__c, apptStartDateTime, apptEndDateTime, localTimeZoneOffset, appointmentDuration, 'Front Room', schedulePolicy.Id);
        ServiceAppointment bckServiceAppt = Appt_TestUtil.getServiceAppointment( sysUser.Id, customerWrkOrder.Id, custAccount.Id, orderWorkType.Id, custContacts[0].Id, servTerr.Id, acctObj.SAP_STORE_ID__c, apptStartDateTime.addMinutes(20), apptEndDateTime.addMinutes(20), localTimeZoneOffset, appointmentDuration, 'Back Room', schedulePolicy.Id);
        // fntServiceAppt.Related_Appointment__c = bckServiceAppt.Id;
        // bckServiceAppt.Related_Appointment__c = fntServiceAppt.Id;
        // servApptList.add(fntServiceAppt);
        // servApptList.add(bckServiceAppt);
        // insert servApptList;

        List<ServiceAppointment> servAppts = [SELECT Id, Status, ParentRecordId FROM ServiceAppointment];

        System.assertEquals(2, servAppts.size(), 'No Service Appointment was created by the Work Order creation');
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, servAppts[0].Status, 'Front Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING);
        System.assertEquals( Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING, servAppts[1].Status, 'Back Room Appointment is the wrong Status, S/B ' + Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING);        

        return servAppts;
    }


    // public static void bulkAppointments()
    // {
    //     List<User> userList = [SELECT Id, Name FROM User];
    //     System.debug('UserList: ' + userList);

    //     List<WorkOrder> woList = [SELECT Id FROM WorkOrder];
    //     System.debug('woList: ' + woList);

    //     List<WorkType> wtList = [SELECT Id FROM WorkType];
    //     System.debug('wtList: ' + wtList);

    //     // Person Account and Site
    //     List<Account> acctList = [SELECT Id FROM Account];
    //     System.debug('acctList: ' + acctList);

    //     List<Contact> custContacts = [SELECT Id FROM Contact];
    //     System.debug('custContacts: ' + custContacts);

    //     List<ServiceTerritory> servTerrList = [SELECT Id FROM ServiceTerritory];
    //     System.debug('servTerrList: ' + servTerrList);

    //     List<FSL__Scheduling_Policy__c> schedulePolicyList = [SELECT Id FROM FSL__Scheduling_Policy__c];
    //     System.debug('schedulePolicyList: ' + schedulePolicyList);

    //     Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();
    //     // can't use current time, the test may not run during "business hours", so there would be no Time Slots
    //     Time apptStartTime = Time.newInstance(8,0,0,0);
    //     Time apptEndTime = Time.newInstance(8,20,0,0);
    //     Datetime apptStartDateTime = Datetime.newInstance(currentDate, apptStartTime);
    //     Datetime apptEndDateTime = Datetime.newInstance(currentDate, apptEndTime);
    //     Integer localTimeZoneOffset = -7;
    //     Integer appointmentDuration = 20;

    //     // List<ServiceAppointment> servApptList = new List<ServiceAppointment>();
    //     // ServiceAppointment fntServiceAppt = Appt_TestUtil.getServiceAppointment( sysUser.Id, customerWrkOrder.Id, custAccount.Id, orderWorkType.Id, custContacts[0].Id, servTerr.Id, acctObj.SAP_STORE_ID__c, apptStartDateTime, apptEndDateTime, localTimeZoneOffset, appointmentDuration, 'Front Room', schedulePolicy.Id);
    //     // ServiceAppointment bckServiceAppt = Appt_TestUtil.getServiceAppointment( sysUser.Id, customerWrkOrder.Id, custAccount.Id, orderWorkType.Id, custContacts[0].Id, servTerr.Id, acctObj.SAP_STORE_ID__c, apptStartDateTime.addMinutes(20), apptEndDateTime.addMinutes(20), localTimeZoneOffset, appointmentDuration, 'Back Room', schedulePolicy.Id);

    // }


    /**
    * @Description Helper method to build & insert the user record.
    * @param profileName - Name of the profile to give to the new user.
    * @param firstName - first name to give the new user
    * @param lastName - last name to give the new user
    */
    private static User getUser(String profileName, String firstName, String lastName)
    {
        User newUser = new User();
        newUser.FirstName = firstName;
        newUser.LastName = lastName;
        newUser.Email = 'test@example.com';
        newUser.Phone = '5555555555';
        newUser.LocaleSidKey = 'en_US';
        newUser.Alias = '' + firstName.left(1).toLowerCase() + firstName.left(4).toLowerCase();
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.EmailEncodingKey = 'ISO-8859-1';
        newUser.UserName = firstName + '.' + lastName + '@apexTest' + UserInfo.getUsername().substringAfter('@');
        newUser.LanguageLocaleKey = 'en_US';

        if (String.isNotBlank(profileName))
        {
            List<Profile> profileList = [select Id from Profile where Name = :profileName];
            if (!profileList.isEmpty())
            {
                newUser.ProfileId = profileList[0].Id;
            }
            else  //-- the profile was not found. this is an error.
            {
                System.debug(lprefix + 'Appt_TestUtil:getUser Unit test has failed to find the ' + profileName + ' profile');
                return null;
            }
        }

        insert newUser;

        return newUser;
    }


    /**
    * @Description This method will get a test user that has the System Administrator profile.
    * @param firstName - first name to give the new user
    * @param lastName - last name to give the new user
    */
    public static User getTestAdminUser(String firstName, String lastName)
    {
        return getUser('System Administrator', firstName, lastName);
    }

    /**
    * @Description This method will get a test user that has the Standard User profile.
    * @param firstName - first name to give the new user
    * @param lastName - last name to give the new user
    */
    public static User getStandardUser(String firstName, String lastName)
    {
        return getUser('Standard User', firstName, lastName);
    }


    public static Account getSiteAccount(String aName, Id ownerId)
    {
        Id apptRecType = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Site').getRecordTypeId();

        Account acct = new Account (
            Name = aName,
            Type = null,
            RecordTypeId = apptRecType,
            ParentId = null,
            BillingStreet = null,
            BillingCity = null,
            BillingState = null,
            BillingPostalCode = null,
            BillingCountry = 'United States',
            BillingStateCode = null,
            BillingCountryCode = 'US',
            BillingLatitude = null,
            BillingLongitude = null,
            BillingGeocodeAccuracy = null,
            ShippingStreet = '123 Test',
            ShippingCity = 'Goodyear',
            ShippingState = null,
            ShippingPostalCode = '85389',
            ShippingCountry = 'United States',
            ShippingStateCode = 'AZ',
            ShippingCountryCode = 'US',
            ShippingLatitude = null,
            ShippingLongitude = null,
            ShippingGeocodeAccuracy = null,
            Store_Public_Phone__c = '5555555555',
            Phone = null,
            Fax = null,
            AccountNumber = null,
            Website = null,
            Sic = null,
            Industry = null,
            AnnualRevenue = null,
            NumberOfEmployees = null,
            ownership = null,
            TickerSymbol = null,
            Description = null,
            Rating = null,
            Site = null,
            ownerId = ownerId,
            PersonMailingStreet = null,
            PersonMailingCity = null,
            PersonMailingState = null,
            PersonMailingPostalCode = null,
            PersonMailingCountry = null,
            PersonMailingStateCode = null,
            PersonMailingCountryCode = null,
            PersonMailingLatitude = null,
            PersonMailingLongitude = null,
            PersonMailingGeocodeAccuracy = null,
            PersonMobilePhone = null,
            PersonHomePhone = null,
            PersonEmail = null,
            PersonTitle = null,
            PersonDepartment = null,
            PersonLeadSource = null,
            PersonEmailBouncedReason = null,
            PersonEmailBouncedDate = null,
            PersonIndividualId = null,
            Jigsaw = null,
            AccountSource = null,
            SicDesc = null,
            OperatingHoursId = null,
            Account_Type__c = null,
            Accounting_Clerk__c = null,
            Assigned_Date__c = null,
            AutoIntegrate__c = null,
            Credit_Hold__c = false,
            Credit_Limit__c = null,
            Credit_Reject_Reasons__c = null,
            ECC_Account_Company__c = null,
            ECC_Account_Number__c = null,
            ECC_AutoIntegrate__c = null,
            ECC_Corporate_Group__c = null,
            ECC_Industry_Key__c = null,
            ECC_State__c = null,
            ECC_Street_4__c = null,
            Email__c = null,
            External_Created_Date__c = null,
            Fleet_AR_App_Sent_Date__c = null,
            Fleet_AR_App_Status__c = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING,
            Fleet_AR_Notification_Comments__c = null,
            Fleet_Account_Approval_Emails_Sent__c = false,
            Fleet_Account_Status__c = 'Prospect',
            Fleet_Additional_Comments__c = null,
            Fleet_Application_Type__c = null,
            Selected_State__c = null,
            Fleet_Credit_App_Status__c = null,
            Fleet_Customer_Type__c = null,
            Fleet_How_Hear_Other__c = null,
            Fleet_How_Hear__c = null,
            Fleet_Invoice_Customer_Req_Metadata__c = null,
            Fleet_Is_Active__c = false,
            Fleet_Lead_Source_Other__c = null,
            Fleet_Lead_Source__c = null,
            Fleet_Lost_Account__c = false,
            Fleet_NonCredit_App_Status__c = null,
            Fleet_Number_of_Vehicles__c = null,
            Fleet_POS_Notes__c = null,
            Fleet_Primary_Contact__c = null,
            Fleet_Private_Notes__c = null,
            Fleet_Public_Notes__c = null,
            Fleet_Specialist__c = null,
            Fleet_Use_Certificates__c = false,
            Fleet_Vehicle_Type__c = null,
            Fleet_Years_Business__c = null,
            Group_Key__c = null,
            Industry_Type__c = null,
            Invoice_Copy_Sent__c = false,
            Is_Notify_AR_Application_Received__c = false,
            Legal_Name__c = null,
            PO_Required__c = true,
            Payment_Key_Terms__c = null,
            Payment_Type__c = null,
            Preferred_Store__c = null,
            SAP_Created_Date__c = null,
            SAP_STORE_ID__c = '1235',
            Store_DBA_Name__c = null,
            Store_ID__c = 'RIP05',
            Tax_Classification__c = null,
            Fleet_POS_Notes_Display__c = null,
            Source__c = null,
            Appt_Customer_Type__c = null,
            GUID__c = null,
            POS_Customer_Id__c = null,
            Hybris_Customer_Id__c = null,
            Primary_Key__c = '6514654654'
                        
        );

        insert acct;

        return acct;
    } // End of getAccount()


    public static ServiceTerritory getServiceTerritory(String aName, Id ownerId, Id opHrsId, Id schedulePolicyId, Id tmeSlotCnfgId, Id siteAcctId, Id frontWrkTypId, Id backWrkTypId)
    {
        Date oneWeekAgo = Date.today();
        oneWeekAgo = oneWeekAgo.addDays(-3);
        
        ServiceTerritory servTerr = new ServiceTerritory(
            ownerId = ownerId,
            Name = aName, //'RIP05',
            Description = null,
            OperatingHoursId = opHrsId, //'0OH7c0000004LObGAM',
            Street = null,
            City = null,
            State = null,
            PostalCode = null,
            Country = 'United States',
            StateCode = null,
            CountryCode = 'US',
            Latitude = null,
            Longitude = null,
            GeocodeAccuracy = null,
            IsActive = true,
            Date_Last_Slot_Generated__c = oneWeekAgo,
            TypicalInTerritoryTravelTime = null,
            FSL__Hide_Emergency_Map__c = false,
            FSL__Internal_SLR_Geolocation__Latitude__s = null,
            FSL__Internal_SLR_Geolocation__Longitude__s = null,
            FSL__NumberOfServicesToDripFeed__c = null,
            FSL__Service_Cluster_Min_Size__c = null,
            FSL__Service_Cluster_Proximity__c = null,
            FSL__System_Jobs__c = null,
            FSL__TerritoryLevel__c = 1,
            Scheduling_Policy__c = schedulePolicyId, // 'a0u7c00000197SdAAI',
            Front_Time_Slot_Configuration__c = tmeSlotCnfgId, // '0OH7c0000004LOlGAM',
            Back_Time_Slot_Configuration__c = tmeSlotCnfgId, // '0OH7c0000004LOlGAM',
            Site_Account__c = siteAcctId, // '0017c00000lFiZMAA0',
            Front_Appointment_Work_Type__c = frontWrkTypId, // '08q7c000000KyqMAAS',
            Back_Appointment_Work_Type__c = backWrkTypId // '08q7c000000KyqHAAS'

        );
        insert servTerr;

        return servTerr;
    } // End of getServiceTerritory()


    // OperatingHoursId (Name ='EST 8-6 Store Hours', TimeZone = 'America/New_York')
    // Back/Front_Time_Slot_Configuration__c (Name = '20 Minute Time Slots', TimeZone = 'America/Phoenix')
    public static OperatingHours getOperatingHours(String aName, String tmeZne, String atype)
    {
        OperatingHours opHrs = new OperatingHours(
            Name =  aName,
            Description = null,
            TimeZone = tmeZne,
            Type__c = atype
        );
        insert opHrs;

        return opHrs;
    } // End of getOperatingHours()


    public static FSL__Scheduling_Policy__c getSchedulingPolicy(String aName, Id ownerId)
    {
        FSL__Scheduling_Policy__c schPol = new FSL__Scheduling_Policy__c(
            ownerId = ownerId, //'0056g000005mQWMAA2',
            Name = aName, // 'Appointment Policy',
            FSL__Commit_Mode__c = 'AlwaysCommit',
            FSL__Daily_Optimization__c = false,
            FSL__Description__c = null,
            FSL__Fix_Overlaps__c = false,
            FSL__Service_Clustering_Weight__c = null,
            FSL__Service_Priority_Weight__c = null,
            FSL__Travel_Mode__c = false            
        );
        insert schPol;

        return schPol;
    } // End of getSchedulingPolicy()


    // 'Front Office' - 'Front Office Work Type'  /  'Back Office' - 'Back Office Work Type'
    public static WorkType getWorkType(String aName, Id ownerId, String descStr, Integer durNum, Integer ddOffsetNum)
    {
        WorkType wrkTyp = new WorkType (
            ownerId = ownerId,
            Name = aName,
            Description = descStr,
            EstimatedDuration = durNum, // 20
            DurationType = 'Minutes',
            ShouldAutoCreateSvcAppt = false,
            ServiceReportTemplateId = null,
            MinimumCrewSize = null,
            RecommendedCrewSize = null,
            FSL__Due_Date_Offset__c = ddOffsetNum, // 4320,
            FSL__Exact_Appointments__c = false            
        );
        insert wrkTyp;

        return wrkTyp;
    } // End of getWorkType()


    // WorkType (20 Minute Appointment / 08q7c0000008UnzAAE)
    public static WorkType getWorkOrderType(String aName, Id ownerId, Integer durNum, Integer ddOffsetNum)
    {
        WorkType wrkTyp = new WorkType (
            OwnerId = ownerId,
            Name = aName, // '20 Minute Appointment',
            Description = null,
            EstimatedDuration = durNum, // 20,
            DurationType = 'Minutes',
            ShouldAutoCreateSvcAppt = false,
            ServiceReportTemplateId = null,
            MinimumCrewSize = null,
            RecommendedCrewSize = null,
            FSL__Due_Date_Offset__c = ddOffsetNum, // 4320,
            FSL__Exact_Appointments__c = false
        );
        insert wrkTyp;

        return wrkTyp;
    } // End of getWorkOrderType()


    // week day hours
    public static TimeSlot createTimeSlotWeekday(Id OperHrsId, String dayOfWeek, String type, Time startTime, Time endTime)
    {
        TimeSlot tmeSlt = new TimeSlot(
            OperatingHoursId = OperHrsId,
            DayOfWeek = dayOfWeek, // 'Monday'
            Type = type, // 'Normal'
            StartTime = startTime, // '08:00:00.000Z',
            EndTime = endTime, // '18:00:00.000Z',
            BSF_Capacity__c = null,
            BSR_Capacity__c = null,
            BWF_Capacity__c = null,
            BWR_Capacity__c = null,
            FSF_Capacity__c = null,
            FSR_Capacity__c = null,
            FWF_Capacity__c = null,
            FWR_Capacity__c = null,
            FSL__Designated_Work_Boolean_Fields__c = null,
            FSL__Slot_Color__c = null            
        );
        insert tmeSlt;

        return tmeSlt;
    } // End of createTimeSlotWeekday()

    
    // daily slots
    public static TimeSlot createTimeSlotDaily(Id OperHrsId, String dayOfWeek, String type, Time startTime, Time endTime, Integer capacity)
    {
        TimeSlot tmeSlt = new TimeSlot(
            OperatingHoursId = OperHrsId,
            DayOfWeek = dayOfWeek, //'Tuesday',
            Type = type, //'Normal',
            StartTime = startTime, //'13:20:00.000Z',
            EndTime = endTime, //'13:40:00.000Z',
            BSF_Capacity__c = capacity, // 4,
            BSR_Capacity__c = capacity, // 4,
            BWF_Capacity__c = capacity, // 4,
            BWR_Capacity__c = capacity, // 4,
            FSF_Capacity__c = capacity, // 4,
            FSR_Capacity__c = capacity, // 4,
            FWF_Capacity__c = capacity, // 4,
            FWR_Capacity__c = capacity, // 4,
            FSL__Designated_Work_Boolean_Fields__c = null,
            FSL__Slot_Color__c = null
        );

        return tmeSlt;
    } // End of createTimeSlotDaily()


    public static Appt_Time_Slot__c createApptTimeSlot(Id serviceTerritoryID, Date dayDate, Datetime startTime, DateTime endTime, String type)
    {
        Appt_Time_Slot__c aTmeSlt = new Appt_Time_Slot__c(
            isBackUnavailable__c = false,
            Service_Territory__c = serviceTerritoryID,
            Date__c = dayDate, // '2021-02-20',
            BSF_Capacity__c = (type == 'Front Room') ? 0 : 2,
            BSR_Capacity__c = (type == 'Front Room') ? 0 : 4,
            BWF_Capacity__c = (type == 'Front Room') ? 0 : 2,
            BWR_Capacity__c = (type == 'Front Room') ? 0 : 4,
            FSF_Capacity__c = (type == 'Front Room') ? 2 : 0,
            FSR_Capacity__c = (type == 'Front Room') ? 4 : 0,
            FWF_Capacity__c = (type == 'Front Room') ? 2 : 0,
            FWR_Capacity__c = (type == 'Front Room') ? 4 : 0,
            Start_Time__c = startTime, // '2021-02-20T20:40:00.000+0000',
            End_Time__c = endTime, // '2021-02-20T21:00:00.000+0000',
            IsFrontUnavailable__c = false,
            Type__c = type
        );

        return aTmeSlt;
    } // End of createApptTimeSlot()


    public static ServiceResource getServiceResource(String aName, Id ownerId, Id userId, String resourceType, String type)
    {
        ServiceResource servRes = new ServiceResource(
            OwnerId = ownerId, // '0056g000005mQWMAA2',
            Name = aName, //'RIP05Back',
            RelatedRecordId = userId, // '0057c000006hP3uAAE',
            ResourceType = resourceType, // 'T',
            Description = null,
            IsActive = true,
            IsCapacityBased = false,
            IsOptimizationCapable = false,
            LastKnownLatitude = null,
            LastKnownLongitude = null,
            LocationId = null,
            ServiceCrewId = null,
            AccountId = null,
            FSL__Efficiency__c = null,
            FSL__GanttLabel__c = type, // 'Back Room',
            FSL__Online_Offset__c = null,
            FSL__Picture_Link__c = null,
            FSL__Priority__c = null,
            FSL__Travel_Speed__c = null,
            Type__c = type // 'Back Room'
                        
        );
        insert servRes;

        return servRes;
    } // End of getServiceResource()


    public static ServiceTerritoryMember getServiceTerritoryMember(Id serviceTerritoryID, Id serviceResourceId, String territoryType, Datetime effStartDate)
    {
        ServiceTerritoryMember servTerr = new ServiceTerritoryMember(

            ServiceTerritoryId = serviceTerritoryID,
            ServiceResourceId = serviceResourceId,
            TerritoryType = territoryType, // 'P',
            EffectiveStartDate = effStartDate, // '2021-01-08T20:11:00.000+0000',
            EffectiveEndDate = null,
            Street = null,
            City = null,
            State = null,
            PostalCode = null,
            Country = 'United States',
            StateCode = null,
            CountryCode = 'US',
            Latitude = null,
            Longitude = null,
            GeocodeAccuracy = null,
            OperatingHoursId = null,
            FSL__Internal_SLR_HomeAddress_Geolocation__Latitude__s = null,
            FSL__Internal_SLR_HomeAddress_Geolocation__Longitude__s = null           
        );
        insert servTerr;

        return servTerr;
    } // End of getServiceTerritoryMember()


    /**
    * @Description Method to get a Person Account related to a customer
    */
    public static Account getCustomerAccount(Id ownerId, String FirstName, String LastName) 
    {
        Id apptRecType = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        System.debug(lprefix + 'Person Account RecType: ' + apptRecType);

        Account acc = new Account(
            OwnerId = ownerId,
            FirstName = FirstName,
            LastName = LastName,
            RecordTypeId = apptRecType,
            Phone = '5555555555',
            ShippingCity = 'Any City',
            ShippingState = 'Arizona',
            ShippingStreet = 'Any Street',
            ShippingPostalCode = '47040',
            PersonMobilePhone = '5555555555',
            PersonEmail = 'test@test.com',
            BillingCity = 'Any City',
            BillingStreet = 'Any Street',
            BillingState = 'Arizona',
            PersonLeadSource = 'Online Inquiry Form',
            AccountSource = 'Online Inquiry Form',
            Fleet_AR_App_Status__c = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING,
            Fleet_Account_Status__c = 'Prospect',
            Appt_Customer_Type__c = 'Retail',
            POS_Customer_Id__c = '15645564',
            Hybris_Customer_Id__c = '15641654d',
            Appt_Email_Opt_In__pc = true,
            Appt_SMS_Opt_In__pc = true
        );

        insert acc;

        System.debug(lprefix + 'Person Account: ' + acc.Id + ' recType: ' + acc.RecordTypeId);

        return acc;
    } // End of getCustomerAccount()


    public static Asset getVehicle_Asset(Id ownerId, Id acctId, Id cntctId)
    {
        Id vehicleRecType = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByName().get('Vehicle').getRecordTypeId();

        Asset vehicle = new Asset(
            Name = '2010 ' + 'Toyota ' + 'Corrola' , // apptModel.year + ' ' + apptModel.make + ' ' + apptModel.model;
            ContactId = cntctId, // '0037c00000y4U7kAAE',
            AccountId = acctId, // '0017c00000lFjCYAA0',
            ParentId = null,
            Product2Id = null,
            IsCompetitorProduct = false,
            SerialNumber = null,
            InstallDate = null,
            PurchaseDate = null,
            UsageEndDate = null,
            Status = null,
            Price = null,
            Quantity = null,
            Description = null,
            OwnerId = ownerId, // '0056g000005K4UhAAK',
            RecordTypeId = vehicleRecType, // '0126g000000XChdAAG',
            LocationId = null,
            AssetProvidedById = null,
            AssetServicedById = null,
            IsInternal = false,
            VIN__c = 'ASF58F68E1D56S415',
            Vehicle_License_Plate__c = 'AZ5465465s',
            Vehicle_Make__c = 'Toyota',
            Vehicle_Model__c = 'Corrola',
            Vehicle_Year__c = null,
            Vehicle_Manufacture_Year__c = '2010',
            Vehicle_Type_Other__c = 'LT',
            Vehicle_Type__c = 'Light Truck',
            POS_Customer_Vehicle_Id__c = '165646',
            Hybris_Customer_Vehicle_Id__c = '5484645',
            Vehicle_Id__c = '654685',
            Trim_Id__c = '154',
            Assembly_Id__c = 'B',
            Vehicle_Class__c = null            
        );
        insert vehicle;

        return vehicle;
    } // End of getVehicle-Asset()


    public static WorkOrder getWorkOrder(Id ownerId, Id personAccountId, Id personAccountContactId, String Subject, Id workTypeId, Id servTerritoryId, String orderType, String source, Date formOrderDate, Date orderDate, Id vehicleId)
    {
        WorkOrder wrkOdr = new  WorkOrder(
            OwnerId = ownerId,
            AccountId = personAccountId, // '0017c00000lFjCYAA0', // Person Account for customer
            ContactId = personAccountContactId, // '0037c00000y4U7kAAE', // Person Account contact`
            CaseId = null,
            AssetId = null,
            Street = null,
            City = null,
            State = null,
            PostalCode = null,
            Country = null,
            StateCode = null,
            CountryCode = null,
            Latitude = null,
            Longitude = null,
            GeocodeAccuracy = null,
            Description = null,
            StartDate = null,
            EndDate = null,
            Subject = Subject, // 'Two tire change',
            // RootWorkOrderId = '0WO7c0000011nM6GAI',
            Status = 'None',
            Priority = 'Low',
            Tax = null,
            Pricebook2Id = null,
            ParentWorkOrderId = null,
            BusinessHoursId = null,
            Duration = 20,
            DurationType = 'Minutes',
            WorkTypeId = workTypeId, // '08q7c0000008UnzAAE', //  Work Type - 20 Minute Appointment
            ServiceTerritoryId = servTerritoryId, //'0Hh7c0000004L6gCAE',
            LocationId = null,
            MaintenancePlanId = null,
            SuggestedMaintenanceDate = null,
            MinimumCrewSize = null,
            RecommendedCrewSize = null,
            ServiceReportTemplateId = null,
            ReturnOrderLineItemId = null,
            ServiceReportLanguage = null,
            FSL__IsFillInCandidate__c = true,
            FSL__Prevent_Geocoding_For_Chatter_Actions__c = false,
            FSL__VisitingHours__c = null,
            Order_Type__c = orderType, // 'ROPIS',
            Source__c = source, // 'WEB',
            Appointment_Comments__c = 'We need to meet you out front',
            Cancel_Reason_Code__c = '01',
            Cancel_Reason__c = 'No longer need Tires',
            Email_Confirmation_Sent_Date__c = null,
            SMS_Confirmation_Sent_Date__c = null,
            Form_Type__c = 'Special',
            Form_Number__c = '13135',
            Form_Date__c = formOrderDate, // '2021-01-14',
            Hybris_Order_Id__c = '65465481',
            POS_Web_Order_Id__c = '33548',
            Layaway_Number__c = '645646',
            Quote_Number__c = '464648',
            Invoice_Number__c = '65465465',
            Order_Date__c = orderDate, // '2021-01-14',
            Vehicle__c = vehicleId // '02i7c000007wHGaAAM',
            //Alternate_Contact__c = '0037c00000y5BUXAA2'
            
        );
        insert wrkOdr;

        return wrkOdr;
    } // End of getWorkOrder()


    public static FSL__Scheduling_Policy__c getSchedulingPolicy(Id ownerId, String aName)
    {
        FSL__Scheduling_Policy__c aSchPol = new FSL__Scheduling_Policy__c(
            OwnerId = ownerId,
            Name = aName, // 'Appointment Policy',
            FSL__Commit_Mode__c = 'AlwaysCommit',
            FSL__Daily_Optimization__c = false,
            FSL__Description__c = null,
            FSL__Fix_Overlaps__c = false,
            FSL__Service_Clustering_Weight__c = null,
            FSL__Service_Priority_Weight__c = null,
            FSL__Travel_Mode__c = false            
        );
        insert aSchPol;

        return aSchPol;
    } // End of getSchedulingPolicy()


    public static ServiceAppointment getServiceAppointment(Id ownerId, Id workOrderId, Id accountId, Id worktypeId, Id contactId, Id serviceTerrId, String siteId, Datetime startTime, Datetime endTime, Integer timeZoneOffset, Integer durationValue, String activityTypeStr, Id SchedulingPolicyId)
    {
        ServiceAppointment servAppt = new ServiceAppointment(

            OwnerId = ownerId, // '0056g000005K4UhAAK',
//            AppointmentNumber = 'SA-0022', // 'SA-0024',
            ParentRecordId = workOrderId, // '0WO7c0000011nM6GAI', // work order
//            ParentRecordType = 'WorkOrder',
//            AccountId = accountId, // '0017c00000lFjCYAA0',
//            WorkTypeId = worktypeId, // '08q7c0000008UnzAAE',
            ContactId = contactId, // '0037c00000y4U7kAAE',
            Street = null,
            City = null,
            State = null,
            PostalCode = null,
            Country = 'United States',
            StateCode = null,
            CountryCode = 'US',
            Latitude = null,
            Longitude = null,
            GeocodeAccuracy = null,
            Description = null,
            EarliestStartTime = (  Datetime.now().format('u') == '7' ) ? Datetime.now().addDays(1) : Datetime.now(), // '2021-01-14T16:27:00.000+0000',
            DueDate = Datetime.now().addDays(3), // '2021-01-17T16:27:00.000+0000',
            Duration = durationValue, // 20,
            ArrivalWindowStartTime = startTime, // '2021-01-15T13:00:00.000+0000',
            ArrivalWindowEndTime = endTime, // '2021-01-15T13:20:00.000+0000',
            Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING,
            SchedStartTime = startTime, // '2021-01-15T13:00:00.000+0000',
            SchedEndTime = endTime, // '2021-01-15T13:20:00.000+0000',
            ActualStartTime = null,
            ActualEndTime = null,
            ActualDuration = null,
            DurationType = 'Minutes',
//            DurationInMinutes = 20,
            ServiceTerritoryId = serviceTerrId, // '0Hh7c0000004L6gCAE',
            Subject = 'Two tire change',
//            ParentRecordStatusCategory = 'New',
//            StatusCategory = 'Scheduled',
            ServiceNote = null,
            Activity_Type__c = activityTypeStr, // 'Front Room',
            Order_Type__c = null,
            Priority__c = null,
//            Appt_Appointment_Last_Modified_Date__c = '2021-01-15T20:23:29.000+0000',
            FSL__Appointment_Grade__c = 100,
            FSL__Auto_Schedule__c = false,
//            FSL__Duration_In_Minutes__c = 20,
            FSL__Emergency__c = false,
            FSL__GanttColor__c = null,
            FSL__GanttIcon__c = null,
            FSL__GanttLabel__c = null,
            FSL__Gantt_Display_Date__c = null,
            FSL__InJeopardyReason__c = null,
            FSL__InJeopardy__c = false,
            FSL__InternalSLRGeolocation__Latitude__s = null,
            FSL__InternalSLRGeolocation__Longitude__s = null,
//            FSL__InternalSLRGeolocation__c = null,
            FSL__IsFillInCandidate__c = true,
            FSL__IsMultiDay__c = false,
            FSL__MDS_Calculated_length__c = null,
            FSL__MDT_Operational_Time__c = null,
            FSL__Pinned__c = false,
            FSL__Prevent_Geocoding_For_Chatter_Actions__c = false,
            FSL__Related_Service__c = null,
            FSL__Same_Day__c = false,
            FSL__Same_Resource__c = false,
            FSL__Schedule_Mode__c = 'Automatic',
            FSL__Schedule_over_lower_priority_appointment__c = false,
            FSL__Scheduling_Policy_Used__c = SchedulingPolicyId, // 'a0u7c00000197SdAAI',
            FSL__Time_Dependency__c = null,
            FSL__UpdatedByOptimization__c = false,
            FSL__Use_Async_Logic__c = false,
            FSL__Virtual_Service_For_Chatter_Action__c = false,
            Work_Order__c = workOrderId, // '0WO7c0000011nM6GAI',
//            Related_Appointment__c = '08p7c0000006nBrAAI', // Service Appointment
            Date_String__c = startTime.format('yyyy-MM-dd'), // '2021-01-15',
            Start_Time_String__c = startTime.format('HHmm'), // '0800',
            End_Time_String__c = endTime.format('HHmm'), // '0820',
            Source__c = null,
            Customer_Type__c = null,
            Site_Id__c = siteId,  // beware really is SAP_STORE_ID__c
            Timezone_Offset__c = timeZoneOffset // -7 // beware of TZ
        );
        insert servAppt;

        return servAppt;
    } // End of getServiceAppointment()


//     public static ServiceAppointment createServiceAppointment(Id ownerId, Id workOrderId, Id accountId, Id worktypeId, Id contactId, Id serviceTerrId, String siteId, Datetime startTime, Datetime endTime, Integer timeZoneOffset, Integer durationValue, String activityTypeStr, Id SchedulingPolicyId)
//     {
//         ServiceAppointment servAppt = new ServiceAppointment(

//             OwnerId = ownerId, // '0056g000005K4UhAAK',
// //            AppointmentNumber = 'SA-0022', // 'SA-0024',
//             ParentRecordId = workOrderId, // '0WO7c0000011nM6GAI', // work order
// //            ParentRecordType = 'WorkOrder',
// //            AccountId = accountId, // '0017c00000lFjCYAA0',
// //            WorkTypeId = worktypeId, // '08q7c0000008UnzAAE',
//             ContactId = contactId, // '0037c00000y4U7kAAE',
//             Street = null,
//             City = null,
//             State = null,
//             PostalCode = null,
//             Country = 'United States',
//             StateCode = null,
//             CountryCode = 'US',
//             Latitude = null,
//             Longitude = null,
//             GeocodeAccuracy = null,
//             Description = null,
//             EarliestStartTime = (  Datetime.now().format('u') == '7' ) ? Datetime.now().addDays(1) : Datetime.now(), // '2021-01-14T16:27:00.000+0000',
//             DueDate = Datetime.now().addDays(3), // '2021-01-17T16:27:00.000+0000',
//             Duration = durationValue, // 20,
//             ArrivalWindowStartTime = startTime, // '2021-01-15T13:00:00.000+0000',
//             ArrivalWindowEndTime = endTime, // '2021-01-15T13:20:00.000+0000',
//             Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING,
//             SchedStartTime = startTime, // '2021-01-15T13:00:00.000+0000',
//             SchedEndTime = endTime, // '2021-01-15T13:20:00.000+0000',
//             ActualStartTime = null,
//             ActualEndTime = null,
//             ActualDuration = null,
//             DurationType = 'Minutes',
// //            DurationInMinutes = 20,
//             ServiceTerritoryId = serviceTerrId, // '0Hh7c0000004L6gCAE',
//             Subject = 'Two tire change',
// //            ParentRecordStatusCategory = 'New',
// //            StatusCategory = 'Scheduled',
//             ServiceNote = null,
//             Activity_Type__c = activityTypeStr, // 'Front Room',
//             Order_Type__c = null,
//             Priority__c = null,
// //            Appt_Appointment_Last_Modified_Date__c = '2021-01-15T20:23:29.000+0000',
//             FSL__Appointment_Grade__c = 100,
//             FSL__Auto_Schedule__c = false,
// //            FSL__Duration_In_Minutes__c = 20,
//             FSL__Emergency__c = false,
//             FSL__GanttColor__c = null,
//             FSL__GanttIcon__c = null,
//             FSL__GanttLabel__c = null,
//             FSL__Gantt_Display_Date__c = null,
//             FSL__InJeopardyReason__c = null,
//             FSL__InJeopardy__c = false,
//             FSL__InternalSLRGeolocation__Latitude__s = null,
//             FSL__InternalSLRGeolocation__Longitude__s = null,
// //            FSL__InternalSLRGeolocation__c = null,
//             FSL__IsFillInCandidate__c = true,
//             FSL__IsMultiDay__c = false,
//             FSL__MDS_Calculated_length__c = null,
//             FSL__MDT_Operational_Time__c = null,
//             FSL__Pinned__c = false,
//             FSL__Prevent_Geocoding_For_Chatter_Actions__c = false,
//             FSL__Related_Service__c = null,
//             FSL__Same_Day__c = false,
//             FSL__Same_Resource__c = false,
//             FSL__Schedule_Mode__c = 'Automatic',
//             FSL__Schedule_over_lower_priority_appointment__c = false,
//             FSL__Scheduling_Policy_Used__c = SchedulingPolicyId, // 'a0u7c00000197SdAAI',
//             FSL__Time_Dependency__c = null,
//             FSL__UpdatedByOptimization__c = false,
//             FSL__Use_Async_Logic__c = false,
//             FSL__Virtual_Service_For_Chatter_Action__c = false,
//             Work_Order__c = workOrderId, // '0WO7c0000011nM6GAI',
// //            Related_Appointment__c = '08p7c0000006nBrAAI', // Service Appointment
//             Date_String__c = startTime.format('yyyy-MM-dd'), // '2021-01-15',
//             Start_Time_String__c = startTime.format('HHmm'), // '0800',
//             End_Time_String__c = endTime.format('HHmm'), // '0820',
//             Source__c = null,
//             Customer_Type__c = null,
//             Site_Id__c = siteId,  // beware really is SAP_STORE_ID__c
//             Timezone_Offset__c = timeZoneOffset // -7 // beware of TZ
//         );

//         return servAppt;
//     } // End of createServiceAppointment()


    // public static Appt_Time_Spot__c getApptTimeSpot(Id apptTimeSlotId, Id serviceAppointmentId, String bucket)
    // {
    //     Appt_Time_Spot__c aTmeSpot = new Appt_Time_Spot__c(
    //         Appt_Time_Slot__c = apptTimeSlotId,
    //         Service_Appointment__c = serviceAppointmentId,
    //         Bucket__c = bucket // 'FWR'            
    //     );
    //     insert aTmeSpot;

    //     return aTmeSpot;
    // } // End of getApptTimeSpot()


    public static ResourceAbsence getResourceAbsence(Id servResourceId, Datetime startDatetime, Datetime endDatetime)
    {
        Id recType = Schema.getGlobalDescribe().get('ResourceAbsence').getDescribe().getRecordTypeInfosByName().get('Non Availability').getRecordTypeId();

        ResourceAbsence rscAbs = new ResourceAbsence (
            RecordTypeId = recType, // '0127c0000005PSkAAM', // Non Availability
            ResourceId = servResourceId,
            Type = 'Vacation',
            Description = 'National Holiday',
            Start = startDatetime,
            End = endDatetime,
            Street = null,
            City = null,
            State = null,
            PostalCode = null,
            Country = 'United States',
            StateCode = null,
            CountryCode = 'US'
            );

        insert rscAbs;

        return rscAbs;

    } // End of getResourceAbsence()


    public static Appt_CreateAppointmentServiceModel getCreateAppointmentServiceModel()
    {
        return getCreateAppointmentServiceModel(true);
    } // getCreateAppointmentServiceModel()


    public static Appt_CreateAppointmentServiceModel getCreateAppointmentServiceModel(Boolean addItems)
    {
        Appt_CreateAppointmentServiceModel.Articles item = new Appt_CreateAppointmentServiceModel.Articles();
        item.articleId = '98911';

        Appt_CreateAppointmentServiceModel.Articles item2 = new Appt_CreateAppointmentServiceModel.Articles();
        item2.articleId = '98977';

        List<Appt_CreateAppointmentServiceModel.Articles> itemss = new List<Appt_CreateAppointmentServiceModel.Articles>();
        itemss.add(item);
        itemss.add(item2); 

        Appt_CreateAppointmentServiceModel model1 = new Appt_CreateAppointmentServiceModel();
        model1.appointmentStatus = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING;
        model1.posCustomerId = '';
        model1.hybrisCustomerId = ''; //0017c00000lGmg2AAC - ApptDev1
        model1.customerGuid = '';
        model1.siteId = '1235';
        model1.source = Appt_ConstantValues.APPOINTMENT_SOURCE_POS;
        model1.orderType = 'ROPIS';
        Date startdate = Date.today().addDays(7);
        Date starteOfWeek = startdate.toStartOfWeek();
        Date tday = starteOfWeek.addDays(1);
        model1.appointmentDate = tday;
        model1.consultStartTime = '1620';
        model1.consultEndTime = '1640';
        model1.backOfficeStartTime = '1640';
        model1.backOfficeEndTime = '1700';
        model1.customerType = Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        model1.firstName = 'Philbert';
        model1.lastName = 'Chapinlysternford';
        model1.emailAddress = 'yup@test.com';
        model1.mobilePhoneNumber = '5555555555';
        model1.homePhoneNumber = '5555555555';
        model1.address1 = '123 Fake St';
        model1.zipCode = '92865';
        model1.city = 'Orange';
        model1.state = 'California';
        model1.country = 'United States';
        model1.year = '2020';
        model1.make = 'Ford';
        model1.model = 'F150';

        if ( addItems ) model1.articles = itemss;

        model1.comments = 'This is a test of the emergency broadcast network';

        return model1;
    } // End of getCreateAppointmentServiceModel(Boolean addItems)


    public static Appt_UpdateAppointmentServiceModel convertServiceAppointmentToModel(ServiceAppointment servAppt)
    {
        System.debug('convertServiceAppointmentToModel::ApppointmentId: ' + servAppt.Id);
        List<Contact> customerInfo;
        if (servAppt.ContactId != null){
            customerInfo = [SELECT Id, FirstName, LastName, Email, HomePhone, MobilePhone, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Id =: servAppt.ContactId];
        }
        System.debug('convertServiceAppointmentToModel::Contact: ' + customerInfo[0]);

        List<WorkOrder> wrkOrdrs;
        if (servAppt.Work_Order__c != null){
            wrkOrdrs = [SELECT Appt_Vehicle_Year__c, Appt_Vehicle_Make__c, Appt_Vehicle_Model__c, Appt_POS_Customer_Id__c, Appt_Hybris_Customer_Id__c, Appt_Account_GUID__c, SMS_Phone__c FROM WorkOrder WHERE Id =: servAppt.Work_Order__c];
        }
        System.debug('convertServiceAppointmentToModel::WorkOrder: ' + wrkOrdrs[0]);

        Appt_UpdateAppointmentServiceModel model1 = new Appt_UpdateAppointmentServiceModel();
        model1.appointmentId = servAppt.Work_Order__c;
        model1.appointmentStatus = servAppt.Status;
        model1.siteId = servAppt.Site_Id__c;
        model1.source = servAppt.Source__c;
        model1.orderType = servAppt.Order_Type__c;

        model1.timeZoneOffset = Integer.valueOf( servAppt.Timezone_Offset__c );
        // model1.timeZone = 

        model1.appointmentDate = servAppt.SchedStartTime.dateGMT();
        model1.consultStartTime = servAppt.Consult_Start_Time__c;
        model1.consultEndTime = servAppt.Consult_End_Time__c;
        model1.backOfficeStartTime = servAppt.Back_Office_Start_Time__c;
        model1.backOfficeEndTime = servAppt.Back_Office_End_Time__c;
        model1.customerType = servAppt.Customer_Type__c;

        if ((customerInfo != null) && (customerInfo.size() > 0))
        {
            model1.firstName = customerInfo[0].FirstName;
            model1.lastName = customerInfo[0].LastName;
            model1.emailAddress = customerInfo[0].Email;
            model1.homePhoneNumber = customerInfo[0].HomePhone;
            model1.mobilePhoneNumber = customerInfo[0].MobilePhone;
            model1.smsPhoneNumber = wrkOrdrs[0].SMS_Phone__c;
            model1.workPhoneNumber = customerInfo[0].Phone;
            model1.address1 = customerInfo[0].MailingStreet;
            model1.city = customerInfo[0].MailingCity;
            model1.state = customerInfo[0].MailingState;
            model1.zipCode = customerInfo[0].MailingPostalCode;
            model1.country = customerInfo[0].MailingCountry;
        }

        if ((wrkOrdrs != null) && (wrkOrdrs.size() > 0))
        {
            model1.workOrderId = wrkOrdrs[0].Id;
            model1.posCustomerId = wrkOrdrs[0].Appt_POS_Customer_Id__c;
            model1.hybrisCustomerId = wrkOrdrs[0].Appt_Hybris_Customer_Id__c;
            model1.customerGuid = wrkOrdrs[0].Appt_Account_GUID__c;

            model1.year = wrkOrdrs[0].Appt_Vehicle_Year__c;
            model1.make = wrkOrdrs[0].Appt_Vehicle_Make__c;
            model1.model = wrkOrdrs[0].Appt_Vehicle_Model__c;
        }
        return model1;

    } // End of convertServiceAppointmentToModel()

}