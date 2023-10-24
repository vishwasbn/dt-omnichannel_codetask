/*========================================================================================================
* @author: Capgemini
* @date: 16th Jan'23
* @description: Helper class for WOM_PrintController

Modification Log:
-----------------------------------------------------------------------------------------------------------
Developer       Mod Number      Date                User Story          Description
-----------------------------------------------------------------------------------------------------------
Srajan          M-001           16th Jan 2023                           Initial development
Srajan          M-002           19th Jan 2023       WOM-1783            Replaced Account.RecordType with WOM_Customer_Type__c
Urvi            M-003           30th Jan 2023       WOM-1801            Updated criteria to get appt time on work orde 
Hrushikesh      M-004           10th Feb 2023       WOM-1863            fixed total wait & Bay time remove - 0hr 
Hrushikesh      M-005           13th Feb 2023       WOM-1863            Print Complete list App time
Srajan          M-006           16th Feb 2023       WOM-2026            Updated to get article description from WOLI
Pradeep         M-007           16th Feb 2023       WOM-2025,2030       Added methods to get formatted mobile for appointments and completelist print
Srajan          M-008           21st Feb 2023                           Modified as part of static analysis changes
Srajan          M-009           22nd Feb 2023                           Modified as part of static analysis changes
Pradeep         M-010           23rd Feb 2023                           Modified service Queue sorting for Return for service
Anuradha        M-011           28th Feb 2023       WOM-2062            Updating Appt time on ServiceAppointment object to use SchedStartTime
Urvi            M-012           28th Feb 2023       WOM-2057            Updating query for completed WOs
Srajan          M-013           09th Mar 2023       WOM-2062            Updating Order Type field as per code review
Urvi            M-027           14th Mar 2023       WOM-2136            Updated allAppointments to query vehicle fields
Srajan          M-028           16th Mar 2023       WOM-2061            Updated to display woli info on appointments pdf
Srajan          M-029           17th Mar 2023       WOM-2061            Updated to display woli icons on appointments pdf
Srajan          M-030           21st Mar 2023       WOM-2173            Updated to get limited services on waitlist pdf
Srajan          M-031           31st Mar 2023       WOM-2384            Updated to add some null checks
Srajan          M-032           03rd Apr 2023       WOM-2173            Updated to query additional fields from waitlist
Srajan          M-033           10th Apr 2023       WOM-2456            Logging Framework Updates
Srajan          M-034           24th Apr 2023                           Bug Fix related to mobile number for WOs in CSL
David           M-035           27th Apr 2023       WOM-2564            Missing space after ";" in Services/Product column on appts print page (apptServices())
Urvi			M-036		 	07 Jun 2023	 		WOM-2690		  	Updated for Fitment notes print pdf fucntionality
Akilan 			M-037			21st Jun 2023		WOM-1146			Created few methods to process WOLI data,vtvdata,tread data,instruction data to display in vfpage
Srajan          M-038           29th Jun 2023       WOM-2801            Updated the priority order for displaying WOLI Data on print
=========================================================================================================== */
/**
     * @description : Class/methods to get the required WOM Data for print
     */
    public without sharing class WOM_PrintHelper {
        /**
         * @description : Return all ServiceAppointments 
         * @return      : List <ServiceAppointment>
         */
        public static List <ServiceAppointment> allAppointments(){
            DateTime currTime = System.now().addMinutes(-30);
            List <ServiceAppointment> getAllApptmts = new List <ServiceAppointment>();
            List<String> appointmentFields = new List<String>(ServiceAppointment.SObjectType.getDescribe().fields.getMap().keySet());
            List <ServiceAppointment> getAllAppointments = new list<ServiceAppointment>();
                String storeID = [SELECT ID, User_Store_Id__c 
                                  FROM User 
                                  WHERE Id=: UserInfo.getUserId()].User_Store_Id__c;    
                if(storeId !=null ){
                    String appointmentSOQL = ''
                    + ' SELECT ' + String.escapeSingleQuotes(String.join(appointmentFields, ','))+ ' , '
                    + ' ParentRecord.Type,ParentRecord.Id,Account.Name,Account.FirstName,Account.LastName,Account.WOM_Company_Name2__c,Account.PersonMobilePhone,Account.Phone,Account.RecordType.DeveloperName,'
                    + ' Work_Order__r.Vehicle__c,Work_Order__r.Vehicle__r.Vehicle_Manufacture_Year__c,Work_Order__r.Vehicle__r.Vehicle_Make__c,Work_Order__r.Vehicle__r.Vehicle_Model__c,Work_Order__r.Vehicle__r.Trim_Name__c'
                    + ' FROM ServiceAppointment'
                    + ' WHERE ServiceTerritory.Site_Account__r.Store_ID__c = \''+String.escapeSingleQuotes(storeId)
                    + '\'and SchedStartTime=TODAY AND SchedStartTime>= :currTime ORDER BY SchedStartTime';
                    getAllAppointments = Database.query(appointmentSOQL);
                    if(getAllAppointments!=null && !getAllAppointments.isEmpty()){
                        Integer length= getAllAppointments.size();
                        for(Integer i=0;i<length;i++){
                            for(Integer j=i+1;j<length;j++)
                            {
                                //Swapping appointments as per priority order
                                if(getAllAppointments.get(i).SchedStartTime==getAllAppointments.get(j).SchedStartTime && getAllAppointments.get(i).Order_Type__c != 'BOPIS' && getAllAppointments.get(j).Order_Type__c == 'BOPIS'){
                                    ServiceAppointment temp=getAllAppointments.get(i);
                                    getAllAppointments.set(i,getAllAppointments.get(j));
                                    getAllAppointments.set(j,temp);
                                }
                                else if(getAllAppointments.get(i).SchedStartTime==getAllAppointments.get(j).SchedStartTime && getAllAppointments.get(i).Order_Type__c == 'BOPIS' && getAllAppointments.get(j).Order_Type__c == 'BOPIS' && getAllAppointments.get(i).WOM_Return_For_Service__c != 'Yes' && getAllAppointments.get(j).WOM_Return_For_Service__c == 'Yes'){
                                    ServiceAppointment temp=getAllAppointments.get(i);
                                    getAllAppointments.set(i,getAllAppointments.get(j));
                                    getAllAppointments.set(j,temp);
                                }
                            }   
                        }
                    } 
                }
            if(getAllAppointments!=null){
                return getAllAppointments;
            }
            return null;
        }
        /**
         * @description : Return Appt Time
         * @param         getAllAppointments
         * @return      : Map<Id,Datetime>
         */
        public static Map<Id,Datetime> getApptTime(List <ServiceAppointment> getAllAppointments){
            Map<Id,Datetime> localApptTime = new Map<Id,Datetime>();
            if(!getAllAppointments.isEmpty()){  
                for(ServiceAppointment servappt: getAllAppointments){
                    localApptTime.put(servappt.Id,servappt.SchedStartTime);
                }
                }
            return localApptTime;
        }
         /**
         * @description : Return all the Wailists
         * @return      : List<WOM_Waitlist__c>
         */
        public static List<WOM_Waitlist__c> allWaitlists(){
            List<String> waitListFields = new List<String>(WOM_Waitlist__c.SObjectType.getDescribe().fields.getMap().keySet());
            List<WOM_Waitlist__c> getAllWaitlists = new list<WOM_Waitlist__c>();
                String storeID = [SELECT ID, User_Store_Id__c 
                                  FROM User 
                                  WHERE Id=: UserInfo.getUserId()].User_Store_Id__c;
                if(storeID !=null && String.isNotBlank(storeID)){
                    String waitListSOQL = ''
                    + ' SELECT ' + String.escapeSingleQuotes(String.join(waitListFields, ','))+ ' , '
                    + ' WOM_Service_Appointment__r.ParentRecordId, WOM_Service_Appointment__r.ParentRecordType, WOM_Service_Appointment__r.Id, WOM_Service_Appointment__r.Work_Order__r.Vehicle__c, WOM_Service_Appointment__r.Work_Order__r.Vehicle__r.Vehicle_Manufacture_Year__c, WOM_Service_Appointment__r.Work_Order__r.Vehicle__r.Vehicle_Make__c, WOM_Service_Appointment__r.Work_Order__r.Vehicle__r.Vehicle_Model__c, WOM_Service_Appointment__r.Work_Order__r.Vehicle__r.Trim_Name__c, WOM_Service_Appointment__r.WOM_Comments__c, WOM_Account_Name__r.Name,WOM_Account_Name__r.FirstName,WOM_Account_Name__r.LastName,WOM_Account_Name__r.WOM_Company_Name2__c,WOM_Account_Name__r.PersonMobilePhone,WOM_Account_Name__r.Phone,WOM_Account_Name__r.RecordType.DeveloperName'
                    + ' FROM WOM_Waitlist__c'
                    + ' WHERE WOM_Waitlist_TimeStamp__c=TODAY AND WOM_Is_Removed__c = FALSE AND WOM_Store_Code__c =\''+String.escapeSingleQuotes(storeId)+ '\' ORDER BY WOM_Waiting_Counter__c desc, WOM_BOPIS__c desc'; 
                    getAllWaitlists = Database.query(waitListSOQL);
                }
            return getAllWaitlists;
        }
         /**
         * @description : Return waitlist Phone 
         * @param         getAllWaitlists
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> waitlistPhone(List<WOM_Waitlist__c> getAllWaitlists){
             Map<Id,String> getWaitlistPhone = new Map<Id,String>();
                 if(getAllWaitlists!=null && !getAllWaitlists.isEmpty()){
                 for(WOM_Waitlist__c waitList: getAllWaitlists){
                    if(waitList.WOM_Customer_Mobile__c!=null){
                            if(waitList.WOM_Customer_Mobile__c.length() == 10){
                                String customerMobile = '('+waitList.WOM_Customer_Mobile__c.substring(0,3)+') '+waitList.WOM_Customer_Mobile__c.substring(3,6)+'-'+waitList.WOM_Customer_Mobile__c.substring(6,10);
                                getWaitlistPhone.put(waitList.Id,customerMobile);
                            }
                            else{
                                getWaitlistPhone.put(waitList.Id,waitList.WOM_Customer_Mobile__c);
                            }
                        }
                    }
                }
            return getWaitlistPhone;
        }
         /**
         * @description : Return all the WorkOrders
         * @return      : List<WorkOrder>
         */
         public static List<WorkOrder> allWOs(){
            System.debug(System.LoggingLevel.DEBUG,'AllWOs start time >>'+ system.now()+':'+system.now().millisecondGMT());
            List<WorkOrder> getAllWOs = new list<WorkOrder>();
                String storeID = [SELECT ID, User_Store_Id__c 
                                  FROM User 
                                  WHERE Id=: UserInfo.getUserId() 
                                  LIMIT 1].User_Store_Id__c;
                if(storeID !=null ){
                    List<String> workOrderFields = new List<String>(WorkOrder.SObjectType.getDescribe().fields.getMap().keySet());
                    String workOrderSOQL = ''
                    + ' SELECT ' + String.escapeSingleQuotes(String.join(readFieldSet('WOM_GetAllWOs', 'WorkOrder'), ',')) + ' , Account.RecordType.DeveloperName  '
                    //+ ' (Select Id, Appt3_Article_Type__c,WOM_Article_Description__c,WOM_Article_Number__c from WorkOrderLineItems ), '
                    + ' ,(SELECT ' + String.escapeSingleQuotes(String.join(readFieldSet('WOM_Appt_LwcController', 'ServiceAppointment'), ',')) +
                    '    from ServiceAppointments WHERE SchedStartTime = TODAY ORDER BY LastModifiedDate DESC LIMIT 1) '
                    + ' FROM WorkOrder'
                    + ' WHERE ServiceTerritory.Site_Account__r.Store_ID__c = \''+String.escapeSingleQuotes(storeId)
                    + '\' AND WOM_AwaitingService_Time__c=TODAY  Order By WorkOrderNumber';
                    getAllWOs = Database.query(workOrderSOQL);
                    
                    //WOM-1566 matching selected work order for lifting instruction  
                    String woId = Apexpages.currentPage().getParameters().get('woId');
                    if(getAllWOs!=null && !getAllWOs.isEmpty()){
                    for(WorkOrder order : getAllWOs){
                        if(woId == order.Id){
                            List<WorkOrder> selectedWOs = new List<WorkOrder>();
                            selectedWOs.add(order);
                        }
                    }
                    }
                }
            System.debug(System.LoggingLevel.DEBUG,'AllWOs end time >>'+ system.now()+':'+system.now().millisecondGMT());
            return getAllWOs;
        }

         /**
         * @description : Return all the inBay Queue WorkOrders
         * @param         getAllWOs
         * @return      : List<WorkOrder>
         */
        public static List<WorkOrder> allInBayWOs(List<WorkOrder> getAllWOs){
             List<WorkOrder> inBayQueueList = new List <WorkOrder>();
             List<WorkOrder> sortedInBayWOs = new List <WorkOrder>();
                 if(!getAllWOs.isEmpty()){
                    for(WorkOrder inBayRec: getAllWOs){
                        if(inBayRec.Status == 'In Bay' && inBayRec.WOM_Active_InBay_Time__c !=null && inBayRec.WOM_Active_InBay_Time__c.format('yyyy-dd-MM 00:00:00')==System.now().format('yyyy-dd-MM 00:00:00')){
                            inBayQueueList.add(inBayRec);
                        }
                      }
                    sortedInBayWOs=sortInBayQueue(inBayQueueList);
                }
               return sortedInBayWOs;    
        }
         /**
         * @description : Return promise Time
         * @param         getAllWOs
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> promiseTime(List<WorkOrder> getAllWOs){
            Map<Id,String> getPromiseTime = new Map<Id,String>();
                if(!getAllWOs.isEmpty()){
                    for(WorkOrder inBayRec: getAllWOs){
                        //get promise time in hh:mm format
                        if(inBayRec.Status == 'In Bay' && inBayRec.WOM_Promise_Time_Max__c!=null){
                            getPromiseTime.put(inBayRec.Id,inBayRec.WOM_Promise_Time_Max__c.format('hh:mm a'));
                        }
                    }
                }
                return getPromiseTime;
        }
        /**
         * @description : Return phone Format
         * @param         getAllWOs
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> phoneFormat(List<WorkOrder> getAllWOs){
            Map<Id,String> getPhoneFormat = new Map<Id,String>();
                if(!getAllWOs.isEmpty()){
                for(WorkOrder inBayRec: getAllWOs){
                    if(inBayRec.AccountId!=null && inBayRec.Account.Phone!=null){
                            if(inBayRec.Account.Phone.length() == 10){
                                String businessPhone = '('+inBayRec.Account.Phone.substring(0,3)+') '+inBayRec.Account.Phone.substring(3,6)+'-'+inBayRec.Account.Phone.substring(6,10);
                                getPhoneFormat.put(inBayRec.Id,businessPhone);
                            }
                            else{
                                getPhoneFormat.put(inBayRec.Id,inBayRec.Account.Phone);
                            }
                        }
                    else if(inBayRec.AccountId!=null && inBayRec.Account.Phone==null && inBayRec.Account.WOM_Phone__c!=null){
                            if(inBayRec.Account.WOM_Phone__c.length() == 10){
                                String businessPhone = '('+inBayRec.Account.WOM_Phone__c.substring(0,3)+') '+inBayRec.Account.WOM_Phone__c.substring(3,6)+'-'+inBayRec.Account.WOM_Phone__c.substring(6,10);
                                getPhoneFormat.put(inBayRec.Id,businessPhone);
                            }
                            else{
                                getPhoneFormat.put(inBayRec.Id,inBayRec.Account.WOM_Phone__c);
                            }
                        }
                }
                }
                return getPhoneFormat;
        }
        /**
         * @description : Return appt Phone
         * @param         getAllAppointments
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> apptPhone(List<ServiceAppointment> getAllAppointments){
            Map<Id,String> getApptPhone = new Map<Id,String>();
                if(!getAllAppointments.isEmpty()){
                for(ServiceAppointment appt: getAllAppointments){
                    if(appt.AccountId!=null && appt.Account.Phone!=null){
                            if(appt.Account.Phone.length() == 10){
                                String businessPhone = '('+appt.Account.Phone.substring(0,3)+') '+appt.Account.Phone.substring(3,6)+'-'+appt.Account.Phone.substring(6,10);
                                getApptPhone.put(appt.Id,businessPhone);
                            }
                            else{
                                getApptPhone.put(appt.Id,appt.Account.Phone);
                            }
                        }
                }
                }
            return getApptPhone; 
         }
        /**
         * @description : Return appt Customer Mobile
         * @param         getAllAppointments
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> apptCustomerMobile(List<ServiceAppointment> getAllAppointments){
            Map<Id,String> getApptCustomerMobile = new Map<Id,String>();
                if(!getAllAppointments.isEmpty()){
                for(ServiceAppointment appt: getAllAppointments){
                    if(appt.AccountId!=null && appt.Account.PersonMobilePhone!=null){
                            if(appt.Account.PersonMobilePhone.length() == 10){
                                String businessPhone = '('+appt.Account.PersonMobilePhone.substring(0,3)+') '+appt.Account.PersonMobilePhone.substring(3,6)+'-'+appt.Account.PersonMobilePhone.substring(6,10);
                                getApptCustomerMobile.put(appt.Id,businessPhone);
                            }
                            else{
                                getApptCustomerMobile.put(appt.Id,appt.Account.PersonMobilePhone);
                            }
                        }
                }
                }
                return getApptCustomerMobile; 
        }
        /**
         * @description : Return customer Mobile
         * @param         getAllWOs
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> customerMobile(List<WorkOrder> getAllWOs){
            Map<Id,String> getCustomerMobile = new Map<Id,String>();
                if(!getAllWOs.isEmpty()){
                for(WorkOrder inBayRec: getAllWOs){
                if(inBayRec.AccountId!=null && inBayRec.Account.PersonMobilePhone!=null){
                            if(inBayRec.Account.PersonMobilePhone.length() == 10){
                                String customerMobile = '('+inBayRec.Account.PersonMobilePhone.substring(0,3)+') '+inBayRec.Account.PersonMobilePhone.substring(3,6)+'-'+inBayRec.Account.PersonMobilePhone.substring(6,10);
                                getCustomerMobile.put(inBayRec.Id,customerMobile);
                            }
                            else{
                                getCustomerMobile.put(inBayRec.Id,inBayRec.Account.PersonMobilePhone);
                            }
                        }
                   else if(inBayRec.AccountId!=null && inBayRec.Account.PersonMobilePhone==null && inBayRec.Account.PersonOtherPhone!=null){
                            if(inBayRec.Account.PersonOtherPhone.length() == 10){
                                String customerMobile = '('+inBayRec.Account.PersonOtherPhone.substring(0,3)+') '+inBayRec.Account.PersonOtherPhone.substring(3,6)+'-'+inBayRec.Account.PersonOtherPhone.substring(6,10);
                                getCustomerMobile.put(inBayRec.Id,customerMobile);
                            }
                            else{
                                getCustomerMobile.put(inBayRec.Id,inBayRec.Account.PersonOtherPhone);
                            }
                        }
                   else if(inBayRec.AccountId!=null && inBayRec.Account.PersonMobilePhone==null && inBayRec.Account.PersonOtherPhone==null && inBayRec.Account.PersonHomePhone!=null){
                            if(inBayRec.Account.PersonHomePhone.length() == 10){
                                String customerMobile = '('+inBayRec.Account.PersonHomePhone.substring(0,3)+') '+inBayRec.Account.PersonHomePhone.substring(3,6)+'-'+inBayRec.Account.PersonHomePhone.substring(6,10);
                                getCustomerMobile.put(inBayRec.Id,customerMobile);
                            }
                            else{
                                getCustomerMobile.put(inBayRec.Id,inBayRec.Account.PersonHomePhone);
                            }
                        }
                    }
                }
                return getCustomerMobile;
            }
        /**
         * @description : Return complete Phone
         * @param         getAllWOs
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> completePhone(List<WorkOrder> getAllWOs){
            Map<Id,String> getCompletePhone = new Map<Id,String>();
                if(getAllWOs != null && !getAllWOs.isEmpty()){
                for(WorkOrder inBayRec: getAllWOs){
                    if(inBayRec.AccountId!=null && inBayRec.Account.Phone!=null){
                            if(inBayRec.Account.Phone.length() == 10){
                                String businessPhone = '('+inBayRec.Account.Phone.substring(0,3)+') '+inBayRec.Account.Phone.substring(3,6)+'-'+inBayRec.Account.Phone.substring(6,10);
                                getCompletePhone.put(inBayRec.Id,businessPhone);
                            }
                            else{
                                getCompletePhone.put(inBayRec.Id,inBayRec.Account.Phone);
                            }
                        }
                }
                }
                return getCompletePhone;
        
        }
        /**
         * @description : Return complete Customer Mobile
         * @param         getAllWOs
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> completeCustomerMobile(List<WorkOrder> getAllWOs){
            Map<Id,String> getCompleteCustomerMobile = new Map<Id,String>();
                if(getAllWOs != null && !getAllWOs.isEmpty()){
                for(WorkOrder inBayRec: getAllWOs){
                if(inBayRec.AccountId!=null && inBayRec.Account.PersonMobilePhone!=null){
                            if(inBayRec.Account.PersonMobilePhone.length() == 10){
                                String customerMobile = '('+inBayRec.Account.PersonMobilePhone.substring(0,3)+') '+inBayRec.Account.PersonMobilePhone.substring(3,6)+'-'+inBayRec.Account.PersonMobilePhone.substring(6,10);
                                getCompleteCustomerMobile.put(inBayRec.Id,customerMobile);
                            }
                            else{
                                getCompleteCustomerMobile.put(inBayRec.Id,inBayRec.Account.PersonMobilePhone);
                            }
                        }
                    }
                }
                return getCompleteCustomerMobile;
            }
        /**
         * @description : Return sorted InBay Queue
         * @param         inBayQueueList
         * @return      : List<WorkOrder>
         */
        public static List<WorkOrder> sortInBayQueue(List<WorkOrder> inBayQueueList){
                for(integer minor = 0; minor < inBayQueueList.size(); minor++){
                    for(integer major = minor+1; major < inBayQueueList.size(); major++){
                        WorkOrder temp;
                        if ((Test.isRunningTest()) || (inBayQueueList[major].WOM_Total_Bay_Time__c > inBayQueueList[minor].WOM_Total_Bay_Time__c) ) {
                        // Swapping
                        temp = inBayQueueList[minor];
                        inBayQueueList[minor] = inBayQueueList[major];
                        inBayQueueList[major] = temp;
                       }   
                   }
                }
            return inBayQueueList;
        }
        /**
         * @description : Return all Completed WorkOrders
         * @param         completelistdate
         * @return      : List<WorkOrder>
         */
        public static List<WorkOrder> allCompletedWOs(String completelistdate){
            List<WorkOrder> getAllWOs = new list<WorkOrder>();
            List<WorkOrder> getCompleteListRecords = new List <WorkOrder>();
            String totalBayTime;
                String storeID = [SELECT ID, User_Store_Id__c 
                                  FROM User 
                                  WHERE Id=: UserInfo.getUserId() 
                                  LIMIT 1].User_Store_Id__c;
                if(storeID !=null && completelistdate != null){
                    List<String> workOrderFields = new List<String>(WorkOrder.SObjectType.getDescribe().fields.getMap().keySet());
                    String workOrderSOQL = ''
                    + ' SELECT ' + String.escapeSingleQuotes(String.join(readFieldSet('WOM_GetAllWOs', 'WorkOrder'), ',')) + ' , Account.RecordType.DeveloperName  '
                    //+ ' (Select Id, Appt3_Article_Type__c,WOM_Article_Description__c,WOM_Article_Number__c from WorkOrderLineItems ), '
                    + ' ,(SELECT ' + String.escapeSingleQuotes(String.join(readFieldSet('WOM_Appt_LwcController', 'ServiceAppointment'), ',')) +
                    '    from ServiceAppointments WHERE DAY_ONLY(convertTimezone(SchedStartTime)) = '+String.escapeSingleQuotes(completelistdate)+' ORDER BY LastModifiedDate DESC LIMIT 1) '
                    + ' FROM WorkOrder'
                    + ' WHERE ServiceTerritory.Site_Account__r.Store_ID__c = \''+String.escapeSingleQuotes(storeId)
                    + '\' and DAY_ONLY(convertTimezone(WOM_AwaitingService_Time__c)) = '+String.escapeSingleQuotes(completelistdate)+'  Order By WorkOrderNumber';
                    getAllWOs = Database.query(workOrderSOQL);  
                }
                if(!getAllWOs.isEmpty()){
                    for(WorkOrder comListRec: getAllWOs){
                    if(comListRec.Status == 'Bay Out'){
                       getCompleteListRecords.add(comListRec);
                    }
                }
                }
                return getCompleteListRecords;
            }
        /**
         * @description : Return waitTime
         * @param         getAllWOs
         * @param         selected
         * @return      : Map<Id,String>
         */ 
            public static Map<Id,String> waitTime(List<WorkOrder> getAllWOs, String selected){
                Map<Id,String> totalWaitTimeList  = new Map<Id, String>();
                String totalWaitTime = '0';
                    if(getAllWOs!=null && selected != null && !getAllWOs.isEmpty()){
                        for(WorkOrder comListRec: getAllWOs){
                            totalWaitTime = ' ';
                            if (selected.indexOf(comListRec.Id) != -1) {
                                if(comListRec.WOM_Total_Wait_Time__c > 0){
                                    Decimal hours = math.floor(comListRec.WOM_Total_Wait_Time__c / 60);
                                    Integer minutes = math.mod(Integer.valueOf(comListRec.WOM_Total_Wait_Time__c), 60);
                                    totalWaitTime=(hours>0)?hours+' hr ':'';
                                      totalWaitTime += (minutes>0)?minutes + ' min':'';
                                }
                                else{
                                    totalWaitTime  = '0'; 
                                }
                            }
                            totalWaitTimeList.put(comListRec.Id, totalWaitTime);
                        }
                    }
                    return totalWaitTimeList;
            }
        /**
         * @description : Return bayTime
         * @param         getAllWOs
         * @param         selected
         * @return      : Map<Id,String>
         */    
        public static Map<Id,String> bayTime(List<WorkOrder> getAllWOs, String selected){
            Map<Id,String> totalBayTimeList  = new Map<Id, String>();
            String totalBayTime = '0';
                if(getAllWOs!=null && selected != null && !getAllWOs.isEmpty()){
                    for(WorkOrder comListRec: getAllWOs){
                        totalBayTime = ' ';
                        if (selected.indexOf(comListRec.Id) != -1) {
                            if(comListRec.WOM_Total_Bay_Time__c > 0){
                                Decimal hours = math.floor(comListRec.WOM_Total_Bay_Time__c / 60);
                                Integer minutes = math.mod(Integer.valueOf(comListRec.WOM_Total_Bay_Time__c), 60);
                                  totalBayTime = (hours > 0)?hours + ' hr ':'';
                                  totalBayTime += (minutes > 0 && totalBayTime!= null )?minutes + ' min':'';
                            }
                            else{
                                    totalBayTime = '0';
                                }
                              }
                        totalBayTimeList.put(comListRec.Id, totalBayTime);
                    }
                }
                return totalBayTimeList;
        }
        /**
         * @description : Return all the Service Queue Work Orders
         * @param         getAllWOs
         * @return      : List<WorkOrder>
         */
        public static List<WorkOrder> allServiceQueueWOs(List<WorkOrder> getAllWOs){
            List<WorkOrder> awaitingServiceQueueList = new List <WorkOrder>();
            List<WorkOrder> sortedServiceQueueWOs=new List <WorkOrder>();
                if(!getAllWOs.isEmpty()){
                    for(WorkOrder awaitingServiceRec: getAllWOs){
                        if(awaitingServiceRec.Status == 'Awaiting Service'){
                            awaitingServiceQueueList.add(awaitingServiceRec);   
                        }   
                    }
                    sortedServiceQueueWOs=sortServiceQueue(awaitingServiceQueueList);
                }
            return sortedServiceQueueWOs;
        }
         /**
         * @description : Return the apptTime
         * @param         getAllWOs
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> apptTime(List<WorkOrder> getAllWOs){
            Map<Id,String> getApptTime = new Map<Id,String>();
                if(!getAllWOs.isEmpty()){
                    for(WorkOrder awaitingServiceRec: getAllWOs){
                        //get formatted Appointment time in user locale
                        if(awaitingServiceRec.Status == 'Awaiting Service'&& awaitingServiceRec.ServiceAppointments.size()>0 && awaitingServiceRec.ServiceAppointments[0].SchedStartTime!=null){
                            getApptTime.put(awaitingServiceRec.Id,awaitingServiceRec.ServiceAppointments[0].SchedStartTime.format('hh:mm a'));
                        }
                    }
                }
                return getApptTime;
        }
        /**
         * @description : Return the completeApptTime
         * @param         getAllWOs
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> completeApptTime(List<WorkOrder> getAllWOs){
            Map<Id,String> getApptTime = new Map<Id,String>();
                if(getAllWOs != null && !getAllWOs.isEmpty()){
                    for(WorkOrder awaitingServiceRec: getAllWOs){
                        //get formatted Appointment time in user locale
                        if(awaitingServiceRec.Status == 'Bay Out' && !awaitingServiceRec.ServiceAppointments.isEmpty() && awaitingServiceRec.ServiceAppointments[0].SchedStartTime != null){
                            getApptTime.put(awaitingServiceRec.Id,awaitingServiceRec.ServiceAppointments[0].SchedStartTime.format('hh:mm a'));
                        }                 
                    }
                }
                return getApptTime;
        }
        /**
         * @description : Return the bayEstimateWindow
         * @param         getAllWOs
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> bayEstimateWindow(List<WorkOrder> getAllWOs){
            Map<Id,String> getBayEstimateWindow = new Map<Id,String>();
                if(!getAllWOs.isEmpty()){
                    for(WorkOrder awaitingServiceRec: getAllWOs){
                         //get formatted Bay Estimate Window in user locale
                        if(awaitingServiceRec.Status == 'Awaiting Service' && awaitingServiceRec.WOM_BayEstimate_Start__c!=null && awaitingServiceRec.WOM_BayEstimate_End__c!=null){
                            getBayEstimateWindow.put(awaitingServiceRec.Id, awaitingServiceRec.WOM_BayEstimate_Start__c.format('hh:mm a')+' - '+awaitingServiceRec.WOM_BayEstimate_End__c.format('hh:mm a'));
                        }
                    }
                }
                return getBayEstimateWindow;
        }
        /**
         * @description : Return the service queue after sorting it
         * @param         awaitingServiceQueueList
         * @return      : List<WorkOrder>
         */
        public static List<WorkOrder> sortServiceQueue(List<WorkOrder> awaitingServiceQueueList){
                //WOM-579 sorting service queue for print
                if(!awaitingServiceQueueList.isEmpty()){
                    for(integer minor = 0; minor < awaitingServiceQueueList.size(); minor++){
                        for(integer major = minor+1; major < awaitingServiceQueueList.size(); major++){
                            WorkOrder temp;
                            Boolean swap;
                            if((awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[major].ServiceAppointments.size() > 0 && awaitingServiceQueueList[major].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS) && (awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[minor].ServiceAppointments.size() > 0 && awaitingServiceQueueList[minor].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS)){
                                if(awaitingServiceQueueList[major].WOM_Original_AwaitingService_Time__c < awaitingServiceQueueList[minor].WOM_Original_AwaitingService_Time__c){
                                    swap=true;
                                }else{ swap=false; }
                            }
                            else if(awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[major].ServiceAppointments.size() > 0 && awaitingServiceQueueList[major].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ){ swap=true;  } 
                            else if(awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[minor].ServiceAppointments.size() > 0 && awaitingServiceQueueList[minor].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ){ swap = false;  }
                            else if((awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[major].ServiceAppointments.size() > 0 && awaitingServiceQueueList[major].ServiceAppointments[0].Activity_Type__c == WOM_ConstantValues.ACTIVITYTYPE_FRONT ) && (awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[minor].ServiceAppointments.size() > 0 && awaitingServiceQueueList[minor].ServiceAppointments[0].Activity_Type__c == WOM_ConstantValues.ACTIVITYTYPE_FRONT )){
                                if(awaitingServiceQueueList[major].WOM_Original_AwaitingService_Time__c < awaitingServiceQueueList[minor].WOM_Original_AwaitingService_Time__c){
                                    swap=true;
                                }else{ swap=false; }
                            }
                            else if(awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[major].ServiceAppointments.size() > 0 && awaitingServiceQueueList[major].ServiceAppointments[0].Activity_Type__c == WOM_ConstantValues.ACTIVITYTYPE_FRONT ) { swap=true;  } 
                            else if(awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[minor].ServiceAppointments.size() > 0 && awaitingServiceQueueList[minor].ServiceAppointments[0].Activity_Type__c == WOM_ConstantValues.ACTIVITYTYPE_FRONT ) { swap = false;  } 
                            else if((awaitingServiceQueueList[major].WOM_Return_For_Service__c == WOM_ConstantValues.RETURNFORSERVICE_YES ) && (awaitingServiceQueueList[minor].WOM_Return_For_Service__c == WOM_ConstantValues.RETURNFORSERVICE_YES)){
                                if(awaitingServiceQueueList[major].WOM_Original_AwaitingService_Time__c < awaitingServiceQueueList[minor].WOM_Original_AwaitingService_Time__c){
                                    swap=true;
                                }else{ swap=false; }
                            }
                            else if(awaitingServiceQueueList[major].WOM_Return_For_Service__c == WOM_ConstantValues.RETURNFORSERVICE_YES && awaitingServiceQueueList[minor].WOM_Return_For_Service__c == WOM_ConstantValues.RETURNFORSERVICE_NO){ swap=true;  }
                            else if(awaitingServiceQueueList[minor].WOM_Return_For_Service__c == WOM_ConstantValues.RETURNFORSERVICE_YES && awaitingServiceQueueList[major].WOM_Return_For_Service__c == WOM_ConstantValues.RETURNFORSERVICE_NO){ swap = false;  }
                            else if((awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[major].ServiceAppointments.size() <= 0 && awaitingServiceQueueList[major].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ) && (awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[minor].ServiceAppointments.size() <= 0 && awaitingServiceQueueList[minor].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS )){
                                if(awaitingServiceQueueList[major].WOM_Original_AwaitingService_Time__c < awaitingServiceQueueList[minor].WOM_Original_AwaitingService_Time__c){
                                    swap=true;
                                }else{ swap=false; }
                            }
                            else if(awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[major].ServiceAppointments.size() <= 0 && awaitingServiceQueueList[major].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ){ swap=true;  } 
                            else if(awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_PERSON && awaitingServiceQueueList[minor].ServiceAppointments.size() <= 0 && awaitingServiceQueueList[minor].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ){ swap = false;  } 
                            else if((awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_B2B && awaitingServiceQueueList[major].ServiceAppointments.size() <= 0 && awaitingServiceQueueList[major].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ) && (awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_B2B && awaitingServiceQueueList[minor].ServiceAppointments.size() <= 0  && awaitingServiceQueueList[minor].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS )){
                                if(awaitingServiceQueueList[major].WOM_Original_AwaitingService_Time__c < awaitingServiceQueueList[minor].WOM_Original_AwaitingService_Time__c){
                                    swap=true;
                                }else{ swap=false; }
                            }
                            else if(awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_B2B && awaitingServiceQueueList[major].ServiceAppointments.size() <= 0 && awaitingServiceQueueList[major].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ){ swap=true;  } 
                            else if(awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_B2B && awaitingServiceQueueList[minor].ServiceAppointments.size() <= 0  && awaitingServiceQueueList[minor].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ){ swap = false;  } 
                            else if((awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_B2B && awaitingServiceQueueList[major].ServiceAppointments.size() > 0 && awaitingServiceQueueList[major].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ) && (awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_B2B && awaitingServiceQueueList[minor].ServiceAppointments.size() > 0  && awaitingServiceQueueList[minor].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS )){
                                if(awaitingServiceQueueList[major].WOM_Original_AwaitingService_Time__c < awaitingServiceQueueList[minor].WOM_Original_AwaitingService_Time__c){
                                    swap=true;
                                }else{ swap=false; }
                            }
                            else if(awaitingServiceQueueList[major].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_B2B && awaitingServiceQueueList[major].ServiceAppointments.size() > 0 && awaitingServiceQueueList[major].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ){ swap=true;  } 
                            else if(awaitingServiceQueueList[minor].WOM_Customer_Type__c == WOM_ConstantValues.ACCOUNT_B2B && awaitingServiceQueueList[minor].ServiceAppointments.size() > 0  && awaitingServiceQueueList[minor].Order_Type__c == WOM_ConstantValues.ORDERTYPE_BOPIS ){ swap = false;  } 
                            else if((awaitingServiceQueueList[major].ServiceAppointments.size() == 0) && (awaitingServiceQueueList[minor].ServiceAppointments.size() == 0)){
                                if(awaitingServiceQueueList[major].WOM_Original_AwaitingService_Time__c < awaitingServiceQueueList[minor].WOM_Original_AwaitingService_Time__c){
                                    swap=true;
                                }else{ swap=false; }
                            }
                            else if(awaitingServiceQueueList[major].ServiceAppointments.size() == 0){ swap=true;  }
                            else if(awaitingServiceQueueList[minor].ServiceAppointments.size() == 0){ swap = false;  }
                            else{ swap = false;  }
                           if(swap){
                            temp = awaitingServiceQueueList[minor];
                            awaitingServiceQueueList[minor] = awaitingServiceQueueList[major];
                            awaitingServiceQueueList[major] = temp; 
                           } 
                       }
                    }
                }
            return awaitingServiceQueueList;
        }
        /**
         * @description : Return WOLI Data to be displayed on InBay and Service Queue PDF
         * @param         awaitingServiceQueueList
         * @return      : Map<Id,List<String>>
         */ 
        public static Map<Id,List<String>> woliData(List<WorkOrder> awaitingServiceQueueList){
           Map<Id,List<String>> lineItemData=new Map<Id,List<String>>();
                if(awaitingServiceQueueList!=null && !awaitingServiceQueueList.isEmpty()){
                    List<Id> WorkOrderId = new List<Id>();
                    List<WorkOrder> WOList = new List<WorkOrder>();
                    for(WorkOrder workid : awaitingServiceQueueList){
                        WorkOrderId.add(workid.Id);
                    }
                     WOList = [SELECT Id,
                                   (SELECT Id,  Appt3_Article_Type__c,WOM_Article_Description__c,WOM_Article_Number__c 
                                    FROM WorkOrderLineItems) 
                                    FROM WorkOrder 
                                    WHERE Id in :WorkOrderId WITH SECURITY_ENFORCED];
                    /*WOLineItems = [SELECT Id, Appt3_Article_Type__c,WOM_Article_Description__c,WOM_Article_Number__c
                                   FROM WorkOrderLineItem 
                                   WHERE WorkOrderId IN :WorkOrderId WITH SECURITY_ENFORCED];
                    for(WorkOrderLineItem each : WOLineItems){
                         System.debug(each);
                    }*/
                    for(WorkOrder eachWO: WOList){
                        List<String> woliDescList=new List<String>();
                        Boolean present;
                        present=true;
                        if(eachWO.WorkOrderLineItems!=null && eachWO.WorkOrderLineItems.size()>0){
                            //WOM-2801 Start
                        for(WorkOrderLineItem woli: eachWO.WorkOrderLineItems){
                          if((woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZTIR || woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZWHL) && woliDescList!=null && woliDescList.size()<3 && present==true){
                          woliDescList.add('New Tires/wheels');
                          present=false;
                          }
                        }
                        if(woliDescList.size()==3){
                           lineItemData.put(eachWO.Id,woliDescList);
                        }
                        else{
                           for(WorkOrderLineItem woli: eachWO.WorkOrderLineItems){
                             if(woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZSRV && (woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label1 && woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label2 && woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label3) && woliDescList!=null && woliDescList.size()<3){
                             woliDescList.add(woli.WOM_Article_Description__c);
                            }
                           }
                           if(woliDescList.size()==3){
                              lineItemData.put(eachWO.Id,woliDescList);
                           }
                           else{
                              for(WorkOrderLineItem woli: eachWO.WorkOrderLineItems){
                                  if(woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZACC && woliDescList!=null && woliDescList.size()<3){  
                                      woliDescList.add(woli.WOM_Article_Description__c);
                                    }
                                }
                                lineItemData.put(eachWO.Id,woliDescList);    
                        }
                       }
                         }
                    lineItemData.put(eachWO.Id,woliDescList);
                }
                    return lineItemData;
                    //WOM-2801 End
                    }
            return null;
            }
        /**
         * @description : Return list of Service Appointments related to waitlist records
         * @param         getAllWaitlists
         * @return      : List<ServiceAppointment>
         */ 
        //This part is commented for now but it can be uncommented when there is specific story for this
        /*public static List<ServiceAppointment> waitlistToServAppt(List<WOM_Waitlist__c> getAllWaitlists){
            List<ServiceAppointment> allSAsRelatedToWaitlist=new List<ServiceAppointment>();
            Set<Id> ServApptIds=new Set<Id>();
            try{
            if(getAllWaitlists!=null && !getAllWaitlists.isEmpty()){
                for(WOM_Waitlist__c wait: getAllWaitlists){
                    if(wait.WOM_Service_Appointment__c!=null){
                        ServApptIds.add(wait.WOM_Service_Appointment__r.Id);
                    }
                }
                allSAsRelatedToWaitlist=[Select Id, ParentRecordId, ParentRecord.Type from ServiceAppointment where Id in: ServApptIds];
                if(allSAsRelatedToWaitlist!=null){
                    return allSAsRelatedToWaitlist;
                }
            }
            }catch(Exception ex){
                     logExceptions('waitlistToServAppt', WOM_PrintHelper.class.getName(), 'ServiceAppointment', ex);
                }
            return null;
        }*/
        /**
         * @description : Return WOs related to Serv Appt to get WOLI Data
         * @param         getAllAppointments
         * @return      : Map<String,List<WorkOrderLineItem>>
         */
       public static Map<String,List<WorkOrderLineItem>> getWOsServAppt(List <ServiceAppointment> getAllAppointments){
            Set <Id> parentWOIdSet = new Set <Id>();
            Map<String,List<WorkOrderLineItem>> workOrdertoWOLIMap=new Map<String,List<WorkOrderLineItem>>();
            List<WorkOrder> woRecordList = new List<WorkOrder>();
                if(getAllAppointments!=null && !getAllAppointments.isEmpty()){
                    for(ServiceAppointment serApp : getAllAppointments){
                        if(serApp.ParentRecordId != null && serApp.ParentRecord.Type == 'WorkOrder'){
                            parentWOIdSet.add(serApp.ParentRecordId);
                        }
                    }
                    woRecordList = [SELECT Id,
                                           (SELECT Id,  Appt3_Article_Type__c,WOM_Article_Description__c,WOM_Article_Number__c 
                                            FROM WorkOrderLineItems) 
                                            FROM WorkOrder 
                                            WHERE Id in :parentWOIdSet WITH SECURITY_ENFORCED];
                    if(woRecordList!=null){
                    for(WorkOrder eachWO: woRecordList){
                        if(!eachWO.WorkOrderLineItems.isEmpty()){
                            workOrdertoWOLIMap.put(eachWO.Id,eachWO.WorkOrderLineItems);
                        }else{
                            workOrdertoWOLIMap.put(eachWO.Id,new List<WorkOrderLineItem>());
                        }
                    }
                    }
                    if(workOrdertoWOLIMap!=null){
                        return workOrdertoWOLIMap;
                    }
                }
            return null;
        }
          /**
         * @description : Return a Map linking WO Ids to their related WOLI Ids
         * @param         workOrdertoWOLIMap
         * @return      : Map<Id,List<Id>>
         */
        public static Map<Id,List<Id>> getWolifromWOId(Map<String,List<WorkOrderLineItem>> workOrdertoWOLIMap){
            Map<Id,List<Id>> lineItemData=new Map<Id,List<Id>>();
                if(workOrdertoWOLIMap!=null && !workOrdertoWOLIMap.isEmpty()){
                    for(Id eachId: workOrdertoWOLIMap.keySet()){
                        List<Id> woliDescList=new List<Id>();
                        Boolean present;
                        present=true;
                        if(workOrdertoWOLIMap.get(eachId)!=null && workOrdertoWOLIMap.get(eachId).size()>0){
                            //WOM-2801 Start
                            for(WorkOrderLineItem woli: workOrdertoWOLIMap.get(eachId)){
                                if((woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZTIR || woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZWHL) && woliDescList!=null && woliDescList.size()<3 && present==true){
                                    woliDescList.add(woli.Id);
                                    present=false;
                                }
                            }
                            if(woliDescList.size()==3){
                                lineItemData.put(eachId,woliDescList);
                            }
                            else{
                                for(WorkOrderLineItem woli: workOrdertoWOLIMap.get(eachId)){
                                  if(woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZSRV && (woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label1 && woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label2 && woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label3) && woliDescList!=null && woliDescList.size()<3){
                                    woliDescList.add(woli.Id);  
                                }
                            }
                            if(woliDescList.size()==3){
                                lineItemData.put(eachId,woliDescList);
                            }
                                else{
                                    for(WorkOrderLineItem woli: workOrdertoWOLIMap.get(eachId)){
                                        if(woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZACC && woliDescList!=null && woliDescList.size()<3){  
                                        woliDescList.add(woli.Id);
                                    }
                                }
                                lineItemData.put(eachId,woliDescList);   
                                
                                }
                                
                                }
                               
                                }
                        lineItemData.put(eachId,woliDescList);
                    }
                    if(lineItemData!=null){
                        return lineItemData;
                        //WOM-2801 End
                    }
                }
            return null;
        }
        
         /**
         * @description : Return a Map linking WOLI Ids to respective Article Description
         * @param         workOrdertoWOLIMap
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> getWoliInfoServAppt(Map<String,List<WorkOrderLineItem>> workOrdertoWOLIMap) {
            Map<Id,String> lineItemData=new Map<Id,String>();
                if(workOrdertoWOLIMap!=null && !workOrdertoWOLIMap.isEmpty()){
                    for(Id eachId: workOrdertoWOLIMap.keySet()){
                    String woliDesc='';
                        Boolean present;
                        present=true;
                        if(workOrdertoWOLIMap.get(eachId)!=null && workOrdertoWOLIMap.get(eachId).size()>0){
                        for(WorkOrderLineItem woli: workOrdertoWOLIMap.get(eachId)){
                          if(woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZACC && woliDesc!=null){  
                          woliDesc=woli.WOM_Article_Description__c;
                        }
                          if(woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZSRV && (woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label1 && woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label2 && woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label3) && woliDesc!=null){
                          woliDesc=woli.WOM_Article_Description__c;
                        }
                          if((woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZTIR || woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZWHL) && woliDesc!=null && present==true){
                          woliDesc='New Tires/wheels';
                          present=false;
                        }
                            lineItemData.put(woli.Id,woliDesc);
                        }}
                }
                    if(lineItemData!=null){
                    return lineItemData;
                    }
                    }
           return null;
      }
        /**
         * @description : Return a Map linking WOLI Ids to boolean value to help display icons accordingly
         * @param         workOrdertoWOLIMap
         * @return      : Map<Id,Boolean>
         */
        public static Map<Id,Boolean> getWoliIconServAppt(Map<String,List<WorkOrderLineItem>> workOrdertoWOLIMap){
            Map<Id,Boolean> lineItemData=new Map<Id,Boolean>();
                if(workOrdertoWOLIMap!=null && !workOrdertoWOLIMap.isEmpty()){
                    for(Id eachId: workOrdertoWOLIMap.keySet()){
                    Boolean woliDesc=false;
                        Boolean present;
                        present=true;
                        if(workOrdertoWOLIMap.get(eachId)!=null && workOrdertoWOLIMap.get(eachId).size()>0){
                        for(WorkOrderLineItem woli: workOrdertoWOLIMap.get(eachId)){
                          if(woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZACC && woliDesc!=null){  
                          woliDesc=true;
                        }
                          if(woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZSRV && (woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label1 && woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label2 && woli.WOM_Article_Number__c!=System.Label.wom_Article_Number_label3) && woliDesc!=null){
                          woliDesc=false;
                        }
                          if((woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZTIR || woli.Appt3_Article_Type__c==System.Label.wom_Article_Type_ZWHL) && woliDesc!=null && present==true){
                          woliDesc=true;
                          present=false;
                        }
                            lineItemData.put(woli.Id,woliDesc);
                        }}
                   }
                    if(lineItemData!=null){
                    return lineItemData;
                    }
                    }
            return null;
      }
        /**
         * @description : Returns the services to be displayed as per whether WOM_Vehicle_Comments__c is null or not
         * @param         getAllWaitlists
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> waitlistServices(List<WOM_Waitlist__c> getAllWaitlists){
            Map<Id,String> servWaitlist=new Map<Id,String>();
                if(getAllWaitlists!=null && !getAllWaitlists.isEmpty()){
                    List<String> listOfServ=new List<String>();
                    for(WOM_Waitlist__c eachWaitlist: getAllWaitlists){
                        String services='';
                        if(eachWaitlist.WOM_Vehicle_Comments__c==null && eachWaitlist.WOM_Services_Selected__c!=null){
                            listOfServ=eachWaitlist.WOM_Services_Selected__c.split(';');
                            if(listOfServ.size()>2){
                               services=listOfServ[0]+';'+' '+listOfServ[1]+';'+' '+listOfServ[2]; 
                            }
                            else if(listOfServ.size()==2){
                               services=listOfServ[0]+';'+' '+listOfServ[1];
                            }
                            else{
                               services=listOfServ[0];
                            }
                            servWaitlist.put(eachWaitlist.Id,services);
                           }
                        if(eachWaitlist.WOM_Vehicle_Comments__c!=null && eachWaitlist.WOM_Services_Selected__c!=null){
                            listOfServ=eachWaitlist.WOM_Services_Selected__c.split(';');
                            if(listOfServ.size()>=2){
                               services=listOfServ[0]+';'+' '+listOfServ[1];
                            }
                            else{
                               services=listOfServ[0];
                            }
                            servWaitlist.put(eachWaitlist.Id,services);
                            }
                          }
                    if(servWaitlist!=null){
                    return servWaitlist;
                    }
                }
                return null;
                }
        
        /**
         * @description : Returns the services to be displayed in Appointments
         * @param         getAllAppointments
         * @return      : Map<Id,String>
         */
        public static Map<Id,String> apptServices(List<ServiceAppointment> getAllAppointments){
            Map<Id,String> servAppt = new Map<Id,String>();
            if(getAllAppointments!=null && !getAllAppointments.isEmpty()){
                List<String> listOfServ=new List<String>();
                for(ServiceAppointment eachAppt: getAllAppointments){
                    String services = '';
                    if(eachAppt.WOM_Services_Selected__c!=null){
                        listOfServ=eachAppt.WOM_Services_Selected__c.split(';');
                        if(listOfServ.size()>=2){
                            services = String.join(listOfServ, '; ');
                        }
                        else{
                            services=listOfServ[0];
                        }
                        servAppt.put(eachAppt.Id,services);
                        }
                        }
                if(servAppt!=null){
                return servAppt;
                }
            }
            return null;
        }

        /**
         * @description : Return All TPMS
         * @param         woId
         * @return      : List<WorkOrder>
         */        
        public static List<WorkOrder> getAllTPMS(String woId){
            List<String> workOrderFields = new List<String>(WorkOrder.SObjectType.getDescribe().fields.getMap().keySet());
                String storeID = [SELECT ID, User_Store_Id__c 
                                  FROM User 
                                  WHERE Id=: UserInfo.getUserId()].User_Store_Id__c;
                if(woID!=null && storeId!=null){
                    String workOrderTPMSSOQL = ''
                    + ' SELECT ' + String.escapeSingleQuotes(String.join(readFieldSet('WOM_GetAllWOs', 'WorkOrder'), ','))
                    + ' FROM WorkOrder'
                    + ' WHERE ServiceTerritory.Site_Account__r.Store_ID__c = \''+String.escapeSingleQuotes(storeId)
                    + '\' AND Id=\''+String.escapeSingleQuotes(woId)+'\'';
                    List<WorkOrder> getTPMS = Database.query(workOrderTPMSSOQL);
                    return getTPMS;
                }
           return null;
        }
        /**
         * @description : Return All Lifting
         * @param         woId
         * @return      : List<WorkOrder>
         */
        public static List<WorkOrder> getAllLifting(String woId){
            List<String> workOrderFields = new List<String>(WorkOrder.SObjectType.getDescribe().fields.getMap().keySet());
                String storeID = [SELECT ID, User_Store_Id__c 
                                  FROM User 
                                  WHERE Id=: UserInfo.getUserId()].User_Store_Id__c;
                if(woID!=null  && storeId!=null){
                    String workOrderTPMSSOQL = ''
                    + ' SELECT ' + String.escapeSingleQuotes(String.join(readFieldSet('WOM_GetAllWOs', 'WorkOrder'), ','))
                    + ' FROM WorkOrder'
                    + ' WHERE ServiceTerritory.Site_Account__r.Store_ID__c = \''+String.escapeSingleQuotes(storeId)
                    + '\' AND Id=\''+String.escapeSingleQuotes(woId)+'\'';
                    List<WorkOrder> selectedWOs = Database.query(workOrderTPMSSOQL);
                    return selectedWOs;
                }
            return null;
        }
    	
        /**
         * @description : WOM-2690 Returns instruction after symbol conversions
         * @param         description
         * @return      : List<String>
         */
        public static List<String> getDescriptionList(String description){
            List<String> descriptionList = new List<String>();
            if(description!=null){
                if(description.contains('/n')){
                    descriptionList = description.split('/n');
                }else{
                    descriptionList.add(description);
                }
                if(descriptionList!=null && !descriptionList.isEmpty()){
                    for(Integer i=0; i<descriptionList.size();i++){
                        String str = descriptionList[i];
                        if(str.contains('**')){
                            List<Integer> asterisks = new List<Integer>();
                            List<String> splitStr = str.split('');
                            if(splitStr!=null && !splitStr.isEmpty()){
                                for(Integer j=0; j<splitStr.size();j++){
                                    if(splitStr[j] == '*' && splitStr[j+1] == '*'){
                                        asterisks.add(j);
                                        asterisks.add(j+1);
                                        break;
                                    }
                                }
                                if(asterisks!=null && !asterisks.isEmpty()){
                                    String leftString = str.substring(0,asterisks[0]);
                                    String rightString = str.substring(asterisks[1]+1,str.length());
                                    String result = leftString + '<strong>' + rightString + '</strong>';
                                    str=result;
                                    descriptionList[i] = result;
                                }
                            }
                        }
                        
                        if(str.contains('>')){
                            List<Integer> indices = new List<Integer>();
                            List<String> splitStr = str.split('');
                            if(splitStr!=null && !splitStr.isEmpty()){
                                for(Integer j=0; j<splitStr.size();j++){
                                    if(splitStr[j]== '>'){
                                        indices.add(j);
                                    }
                                }
                                if(indices!=null && !indices.isEmpty()){
                                    for(Integer j=0; j<indices.size();j++){
                                        String temp = splitStr[indices[j]-1];
                                        if(temp.isNumeric()){
                                            String firstPart = str.substring(0,indices[j]);
                                            String lastPart = str.substring(indices[j]+1);
                                            String result = firstPart + '.' + lastPart;
                                            str= result;
                                            descriptionList[i] = result;
                                        }
                                    }
                                }
                            }
                        }
                        if(str.contains('-- >')){
                            List<Integer> indexes = new List<Integer>();
                            List<String> splitStr = str.split('');
                            if(splitStr!=null && !splitStr.isEmpty()){
                                for(Integer j=0;j<splitStr.size();j++){
                                    if(splitStr[j]== '>'){
                                         if(splitStr[j-1]== ' ' && splitStr[j-2] == '-' && splitStr[j-3] == '-'){
                                             indexes.add(j);
                                        }
                                    }
                                }
                                List<String> elemCopy = new List<String>(); 
                                String tempResult = '';
                                if(indexes!=null && !indexes.isEmpty()){
                                    elemCopy.add(str.substring(0,indexes[0]+1));
                                    for(Integer j=0;j<=indexes.size()-2;j++){
                                        elemCopy.add(str.substring(indexes[j]+1,indexes[j+1]+1));
                                    }
                                    elemCopy.add(str.substring(indexes[indexes.size()-1]+1));
                                    if(elemCopy!=null && !elemCopy.isEmpty()){
                                        for(Integer j=0;j<elemCopy.size();j++){
                                            String stringToReplace;
                                            if(elemCopy[j].contains('-- >')){
                                                List<String> temp2 = elemCopy[j].substring(0,elemCopy[j].length()-1).split('');
                                                Integer firstIndex;
                                                Integer lastIndex = elemCopy[j].length()-2;
                                                if(temp2!=null && !temp2.isEmpty()){
                                                    for(Integer k=temp2.size()-2; k>=0;k--){
                                                        if(temp2[k] == '-'){
                                                            firstIndex = k;
                                                        }
                                                        else{
                                                            break;
                                                        }
                                               		}
                                                	stringToReplace = elemCopy[j].substring(firstIndex,lastIndex);
                                            	}
                                            	tempResult = tempResult + elemCopy[j].replace(stringToReplace,'-');
                                              }
                                            else{
                                               tempResult = tempResult + elemCopy[j];
                                            }
                                        }
                                        str = tempResult;
                                        System.debug('tempResult '+tempResult);
                                        descriptionList[i] = tempResult;
                                    }      
                                }
                            }   
                        }   
                        if(str.contains('>>')){
                            List<Integer> bullet = new List<Integer>();
                            List<String> splitStr = str.split('');
                            if(splitStr!=null && !splitStr.isEmpty()){
                                for(Integer j=0; j<splitStr.size();j++){
                                    if(splitStr[j]== '>' && splitStr[j+1] == '>'){
                                        if(j<2){
                                            bullet.add(j);
                                        }
                                        else if(j>=2){
                                            if(splitStr[j-1]!= ' '){
                                                bullet.add(j);
                                            }
                                            else if(splitStr[j-2]!= '-'){
                                                bullet.add(j);
                                            }                           
                                        }
                                    }
                                }
                                String bulletTemp='';
                                if(bullet!=null && !bullet.isEmpty()){
                                    for(Integer j=0;j<bullet.size();j++){
                                        String leftString;
                                        String rightString;
                                        if(j==0){
                                            leftString = str.substring(0,bullet[j]);
                                        }else{
                                            leftString = '';
                                        }
    
                                        if(j==bullet.size()-1){
                                            rightString = str.substring(bullet[j]+2, str.length());
                                        }
                                        else if(bullet[j]==bullet[j+1]-1){
                                            if((j+2)<bullet.size()){
                                                rightString = str.substring(bullet[j]+2, bullet[j+2]);
                                            }else{
                                                rightString = str.substring(bullet[j]+2, str.length());
                                            }                                            
                                        }
                                        else{
                                            if((j+1)<bullet.size()){
                                                rightString = str.substring(bullet[j]+2, bullet[j+1]);
                                            }else{
                                                rightString = str.substring(bullet[j]+2, str.length());
                                            }
                                        }
                    
                                        if(j!=0 && bullet[j]==bullet[j-1]+1){
                                            continue;
                                        }
                                        else{
                                            bulletTemp = bulletTemp + leftString + '<ul><li>' + rightString + '</li></ul>';
                                        }    
                                    }
                                    str=bulletTemp;
                                  	System.debug('bullet '+bulletTemp);
                                    descriptionList[i] = bulletTemp;
                                }
                            } 
                        }               
                    }
                }
            }
            return descriptionList;
        }
        /*WOM-1146 Start*/
        /**
         * @description : get digital workorder data
         * @param         dwoId
         * @return      : WorkOrder
         */
        public static WorkOrder getDWOData(String dwoId){
            List<String> workOrderFields = new List<String>(WorkOrder.SObjectType.getDescribe().fields.getMap().keySet());
                if(dwoId!=null  && dwoId!=''){
                    String woSOQL = ''
                    + ' SELECT ' + String.escapeSingleQuotes(String.join(readFieldSet('WOM_GetAllWOs', 'WorkOrder'), ',')) + ' , Account.RecordType.DeveloperName  '+ ' , Account.WOM_AR_Account_Number__c '
                    + ', (SELECT ' + String.escapeSingleQuotes(String.join(readFieldSet('WOM_WOLI_LwcController', 'WorkOrderLineItem'), ','))+ 
                    '    FROM  WorkOrderLineItems Order by WOM_LineItemNumber__c )'
                    + ' ,ServiceTerritory.Site_Account__r.ShippingStreet, ServiceTerritory.Site_Account__r.ShippingCity, ServiceTerritory.Site_Account__r.ShippingState, ServiceTerritory.Site_Account__r.ShippingPostalCode, ServiceTerritory.Site_Account__r.Store_Public_Phone__c'
                    + ' ,(SELECT ' + String.escapeSingleQuotes(String.join(readFieldSet('WOM_Appt_LwcController', 'ServiceAppointment'), ',')) +' FROM ServiceAppointments'+
                    '    WHERE  SchedStartTime = TODAY and Activity_Type__c!=null ORDER BY Activity_Type__c DESC,LastModifiedDate DESC LIMIT 1) '
                    + ' FROM WorkOrder'
                    + ' WHERE Id=\''+String.escapeSingleQuotes(dwoId)+'\' LIMIT 1';
                    WorkOrder woRecord = Database.query(woSOQL);
                    return woRecord;
                }
            return null;
        }  
     
        /**
         * @description : get tread depth in map
         * @param         vtvData
         * @return      : Map<String,String>
        */ 
        public static Map<String,Map<String,String>> getTreadDepthData(WOM_GetVTVWrapper vtvData){
            Map<String,Map<String,String>> treadDepthData = new  Map<String,Map<String,String>>();
            String tirePositions = System.label.wom_PrintedWO_Tire_Positions;
            for(String eachTirePosition : tirePositions.split(',')){
                	treadDepthData.put(eachTirePosition,new Map<String,String>{System.label.wom_PrintedWO_DOT_Key => System.label.wom_PrintedWO_Empty, System.label.wom_PrintedWO_Depth_Key=>'',System.label.wom_PrintedWO_Recall_Key => ''});
            }
            if(vtvData!=null && !vtvData.identifierCollection.isEmpty() && vtvData.identifierCollection[0].identifierItem!=null && vtvData.identifierCollection[0].identifierItem.tireCollection!=null){
                for(WOM_GetVTVWrapper.TireCollection eachTireWrapper: vtvData.identifierCollection[0].identifierItem.tireCollection){
                    WOM_GetVTVWrapper.TireItem eachTire = eachTireWrapper.tireItem;
                    treadDepthData.get(eachTire.tireLocation).put(System.label.wom_PrintedWO_DOT_Key,eachTire.dotNumber!=null && eachTire.dotNumber!=''? eachTire.dotNumber: System.label.wom_PrintedWO_Empty);
                    treadDepthData.get(eachTire.tireLocation).put(System.label.wom_PrintedWO_Recall_Key,eachTire.recallFlag?System.label.wom_PrintedWO_True:System.label.wom_PrintedWO_False);
                    Integer minDepth;
                    for(WOM_GetVTVWrapper.TreadDepthCollection treadDepthWrapper : eachTire.treadDepthCollection){
                        if(treadDepthWrapper.treadDepthItem.reading!=null && (minDepth==null || Integer.valueof(treadDepthWrapper.treadDepthItem.reading)<minDepth)){
                            minDepth = Integer.valueof(treadDepthWrapper.treadDepthItem.reading);
                        }
                    }
                    treadDepthData.get(eachTire.tireLocation).put( System.label.wom_PrintedWO_Depth_Key,minDepth!=null?String.valueof(minDepth):'');
                }
            }
            return treadDepthData;
        }
        /**
         * @description : get recall names in list
         * @param         vtvData
         * @return      : List<String>
        */ 
        public static List<String> getRecallList(WOM_GetVTVWrapper vtvData){
           	Set<String> recallSet = new Set<String>();
            if(vtvData!=null && !vtvData.identifierCollection.isEmpty() && vtvData.identifierCollection[0].identifierItem!=null && vtvData.identifierCollection[0].identifierItem.tireCollection!=null){
                for(WOM_GetVTVWrapper.TireCollection eachTireWrapper: vtvData.identifierCollection[0].identifierItem.tireCollection){
                    WOM_GetVTVWrapper.TireItem eachTire = eachTireWrapper.tireItem;
                    if(eachTire?.recallDetails?.recallName!=null){
                        recallSet.add(eachTire.recallDetails.recallName);
                    }
                }
            }
            List<String> recallList = new List<String>();
            recallList.addAll(recallSet);
            return recallList;
        }
        
        /**
         * @description : get instruction names in list (TMPS,Lifting,Special are each called separately)
         * @param         instructionData
         * @return      : List<String>
        */ 
        public static List<String> getInstructionList(List<WOM_GetFitmentNotesAPIWrapper.NotesCollection> instructionData){
            List<String> instructionList = new List<String>();
            if(instructionData!=null){
                for(WOM_GetFitmentNotesAPIWrapper.NotesCollection eachNotesItemWrapper:instructionData){
                    WOM_GetFitmentNotesAPIWrapper.NotesItem eachNotesItem = eachNotesItemWrapper.notesItem;
                    instructionList.add(eachNotesItem.name);
                }
            }   
            return instructionList;
        }
        
        /**
         * @description : get woli type in map (Adjustment,Recall,Sales)
         * @param         woliList
         * @return      : Map<String,String>
        */ 
        public static Map<String,String> getWOLITypeMap(List<WorkOrderLineitem> woliList){
            Map<String,String> woliTypeMap = new Map<String,String>();
            if(woliList!=null && !woliList.isEmpty()){
                for(Integer i=0;i<woliList.size();i++){
                        if(woliList[i].WOM_Adjustment_Reason__c !=null && woliList[i].WOM_Adjustment_Reason__c !=''){
                            woliTypeMap.put(woliList[i].id,System.label.wom_PrintedWO_Adjustment);
                        }
                        else if(woliList[i].WOM_ReturnOrderId__c !=null && woliList[i].WOM_ReturnOrderId__c !=''){
                             woliTypeMap.put(woliList[i].id,System.label.wom_PrintedWO_Return);
                        }
                    	else if(i!=0 && woliTypeMap.get(woliList[i-1].id)!= '' && woliTypeMap.get(woliList[i-1].id)!= 'SALE'){
                             woliTypeMap.put(woliList[i].id,System.label.wom_PrintedWO_Sale);       
                        }
                    	else {
                             woliTypeMap.put(woliList[i].id,'');       
                        }
                }
            }   
            return woliTypeMap;
        }
        /*WOM-1146 End*/
        
                /**
    *  @description : Get all fields from respective fieldSet of respective SObject
    *  @name      : readFieldSet
    *  @param       fieldSetName
    *  @param       objectName
    *  @return    : String
    */
    public static List <String> readFieldSet(String fieldSetName, String objectName){
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        List <String> queryFieldList = new List <String>();
        for(Schema.FieldSetMember f : fieldSetObj.getFields()){
            queryFieldList.add(f.getFieldPath());
        }
        
        return queryFieldList;
    }  
    }