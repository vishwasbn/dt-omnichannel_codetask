public without sharing class Appt_AppointmentLogController {
    public final static string lprefix = 'LOG Appt_LogController';

    //Addedd for SO-41
    public static Logger logInstance = Logger.getInstance();

    @AuraEnabled
    public static string getAppointments(String siteId, String startDate, String endDate, List<String> appointmentStatuses, Boolean rescheduleFilter){

        System.debug(lprefix + ' dates: ' + startDate + ' - ' + endDate);
        System.debug('satusList: ' + appointmentStatuses);

        if (!validateDates(startDate, endDate)) {
            throw new AuraHandledException('Invalid Date Parameters: ' + startDate + ' - ' +endDate);
        }

        
        // 1. get ServiceAppointment records
        List<ServiceAppointment> apptList = getServiceAppointments(siteId, appointmentStatuses, startDate, endDate, rescheduleFilter);       

        if (apptList == null) throw new AuraHandledException('Invalid Site or Date Parameters: ' + startDate + ' - ' +endDate + ' - Site: ' + siteId);
        System.debug(lprefix+ 'apptList: ' + apptList);

        // 2. get Archived ServiceAppointment data
        List<Appt_AppointmentLogWrapper> archiveWrapperList = getArchivedServiceAppointments(siteId, appointmentStatuses, startDate, endDate, rescheduleFilter);
        
        try {
            // 3. Convert SA --> Wrapper for LWC display
            List<Appt_AppointmentLogWrapper> logWrapperList = new List<Appt_AppointmentLogWrapper>();
            if (apptList.size() > 0) {
                for (ServiceAppointment sa : apptList) {
                    Appt_AppointmentLogWrapper loggedAppt = new Appt_AppointmentLogWrapper(sa,siteId);
                    logWrapperList.add(loggedAppt);
                    //System.debug(lprefix + ' query date: ' + sa.SchedStartTime);
                }
            }

            // 4. Add both lists to a container to return
            Appt_ArchiveLogContainer wrapperContainer = new Appt_ArchiveLogContainer();
            wrapperContainer.loggedAppointments = logWrapperList;
            wrapperContainer.archivedAppointments = archiveWrapperList;

            return JSON.serialize(wrapperContainer);

        } catch (Exception e) {
            System.debug(e.getMessage());
            // SO-41 START:  Added logInstance 
            String errDetails = 'Cause: '+ e.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ e.getMessage();
            logInstance.Log(LPREFIX, Appt_AppointmentLogController.class.getName(), errDetails); // SO-41 END
            throw new AuraHandledException('Unable to populate table date: ' + e.getMessage());
        }
    }

    public class Appt_ArchiveLogContainer {
        public List<Appt_AppointmentLogWrapper> archivedAppointments { get; set; }
        public List<Appt_AppointmentLogWrapper> loggedAppointments { get; set; }

        public Appt_ArchiveLogContainer() {}
    }

    public class Appt_AppointmentLogWrapper {
        
        public string id { get; set; }
        public string appointmentStatus { get; set; }
        public string activityType { get; set; }
        public string orderType { get; set; }
        public string formType { get; set; }
        public string source { get; set; }
        public string formNumber { get; set; }
        public string firstName { get; set; }
        public string lastName { get; set; }
        public string fullName { get; set; }
        public string mobilePhone { get; set; }
        public string homePhone { get; set; }
        public string workPhone { get; set; }
        public string smsPhone { get; set; }
        public string service { get; set; } // not sure what this is
        public string cancelReason { get; set; }
        public Boolean rescheduleStatus { get; set; } // stores actual value of true or false
        public string rescheduleStatusString { get; set; } // display values as 'Yes' or 'No'
        
        public string apptDateTime { get; set; }
        public Date appointmentDate { get; set; }
        public string appointmentTime { get; set; }

        public string originalAppointmentDateTime { get; set; }
        public string originalAppointmentTime { get; set; }
        public Date originalAppointmentDate { get; set; }

        //so-349 additional parameters required to send payload to POS
        public string orderDate { get; set; }
        public string posCustomerId  {get; set; }
        public string posWebOrderId {get; set; }
        public string siteId { get; set; }
        public string quoteNumber { get; set; }
        public string layawayNumber { get; set; }

        // SO-559: Adding Customer Type field to WRAPPER to display in UI
        public string customerType {get; set;}
        
        public Appt_AppointmentLogWrapper() {}

        public Appt_AppointmentLogWrapper(ServiceAppointment sa, String siteId) {
            //System.debug('wrapper builder 1');
            this.id = sa.Id;
           
            this.appointmentStatus = sa.Status;
            this.source = sa.Work_Order__r?.Source__c;
            this.activityType = sa.Activity_Type__c;
            this.rescheduleStatus = sa?.Appointment_Rescheduled__c;
            this.rescheduleStatusString = (sa.Appointment_Rescheduled__c != null && sa.Appointment_Rescheduled__c == true) ? 'Y':'N';

            //System.debug('wrapper builder 2');
            this.appointmentDate = (sa.Date_String__c != null) ? Date.valueOf(sa.Date_String__c) : null;
            this.appointmentTime = getFormattedTimeString(sa?.Start_Time_String__c);

            //System.debug('wrapper builder 3');
            this.originalAppointmentDate = (sa.Original_Date_String__c != null) ? Date.valueOf(sa.Original_Date_String__c) : null;
            this.originalAppointmentTime = getFormattedTimeString(sa?.Original_Start_Time_String__c);
            
            if (this.originalAppointmentDate != null && this.originalAppointmentTime != null) {
                this.originalAppointmentDateTime = String.valueOf(this.originalAppointmentDate) +', '+this.originalAppointmentTime;
            } else if (this.appointmentDate != null && this.appointmentTime != null) {
                this.originalAppointmentDateTime = String.valueOf(this.appointmentDate) +', '+this.appointmentTime;
            } else {
                this.originalAppointmentDateTime = '';
            }

            // work order
            //System.debug('wrapper builder 4');
            this.orderType = sa.Work_Order__r?.Order_Type__c;

            // Added logic support a dynamic form number based on the order type
            this.formNumber = Appt_AppointmentListPageController.getMappedFormNumber(sa.Work_Order__r.Order_Type__c, sa.Work_Order__r.POS_Web_Order_Id__c, sa.Work_Order__r.Layaway_Number__c, sa.Work_Order__r.Invoice_Number__c, sa.Work_Order__r.Quote_Number__c);

            // changed value to use formtype field to pass back to POS. SO-349
            //this.formType = sa.Work_Order__r.Order_Type__c;
            this.formType = sa.Work_Order__r.Form_Type__c;
            //this.formNumber = sa.Work_Order__r?.Form_Number__c;
            this.cancelReason = sa.Work_order__r?.Cancel_Reason__c;
               
            //this.fullName = sa.Work_Order__r?.Contact?.Name;

            this.fullName = sa.Work_Order__r?.Contact?.Name;
           
            this.mobilePhone = sa.Work_Order__r?.Contact?.MobilePhone;

            //so-349 additional parameters required to send payload to POS
            this.orderDate= Appt_AppointmentListPageController.getOrderDate(sa);
            this.siteId= siteId;
            this.posCustomerId = sa.Work_Order__r.Account.POS_Customer_Id__c;
            this.posWebOrderId =sa.Work_Order__r.POS_Web_Order_Id__c;
            this.quoteNumber =sa.Work_Order__r.Quote_Number__c;
            this.layawayNumber = sa.Work_Order__r.Layaway_Number__c;
        }

        public Appt_AppointmentLogWrapper(Appt_ArchivePayloadModel apm){

            this.appointmentStatus = apm.appointmentStatus;
            //this.activityType = apm.
            this.orderType = apm.orderType;
            this.formType = apm.formType;
            this.source = apm.source;
            // Added logic support a dynamic form number based on the order type
            this.formNumber = Appt_AppointmentListPageController.getMappedFormNumber(apm.orderType, apm.posWebOrderId, apm.layawayNumber, apm.invoiceNumber, apm.quoteNumber);
            //this.formNumber = apm.formNumber;
            this.rescheduleStatus = apm.apptRescheduled;
            this.rescheduleStatusString = (apm.apptRescheduled != null && apm.apptRescheduled == true) ? 'Y':'N';
            this.cancelReason = apm.cancelReason;

            String apptTime = (apm.consultStartTime != null) ? apm.consultStartTime : apm.backOfficeStartTime;
            if (apm.appointmentDate != null) {
                List<String> dateParts = apm.appointmentDate.split('-');
                this.appointmentDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
            }
            
            this.apptDateTime =  apm.appointmentDate;
            this.appointmentTime = getFormattedTimeString(apptTime);

            this.originalAppointmentDate = (apm.originalDateString != null) ? Date.valueOf(apm.originalDateString) : null;
            this.originalAppointmentTime = getFormattedTimeString(apm?.originalStartTimeString);

            if (this.originalAppointmentDate != null && this.originalAppointmentTime != null) {
                this.originalAppointmentDateTime = String.valueOf(this.originalAppointmentDate) +', '+this.originalAppointmentTime;
            } else {
                this.originalAppointmentDateTime = '';
            }

        }

    }

    private static Boolean validateDates(String startDate, String endDate) {
        if (startDate == null || endDate == null) return false;
        
        try {
            Date logStartDate = Date.valueOf(startDate);
            Date logEndDate = Date.valueOf(endDate);
            return true;
        } catch (exception e) {
            System.debug(lprefix+ 'invalid date params: ' + e.getMessage());
            // SO-41 START:  Added logInstance 
            String errDetails = 'Cause: '+ e.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ e.getMessage();
            logInstance.Log(LPREFIX, Appt_AppointmentLogController.class.getName(), errDetails); // SO-41 END
            return false;
        }
    }

    public static String getFormattedTimeString(String timeString) {
        if (timeString != null && timeString.length() == 4) {
            Integer hourInt = Integer.valueOf(timeString.subString(0,2));
            String hour = '';
            String ampm = '';
            // set fmpm and 12 hour time
            if (hourInt >= 12) {
                ampm = 'PM';
            } 
            // time is probably am
            else {
                ampm = 'AM';
            }
        
            // convert hours to string
            if (hourInt > 12) hourInt -= 12;
            hour = String.valueOf(hourInt);
            hour = hour.leftPad(2,'0');
            
            // set the minutes
            String minute = timeString.subString(2);

            return hour+':'+minute + ' ' + ampm;
        }
        return null;
    }

    public static List<ServiceAppointment> getServiceAppointments(String siteId, List<String> appointmentStatuses, String startDate, String endDate, Boolean rescheduleFilter) {
        if (siteId == null || startDate == null || endDate == null) return null;

        if (rescheduleFilter != null && (rescheduleFilter == true || rescheduleFilter == false)) {
            // include reschedule filter
            return [
                    SELECT Id, toLabel(Status), Activity_Type__c, Appointment_Rescheduled__c,
                    SchedStartTime, SchedEndTime, Start_Time_String__c, End_Time_String__c, Date_String__c,  // times
                    Original_Start_Time_String__c, Original_End_Time_String__c, Original_Date_String__c, // original times
                    Work_Order__r.Contact.FirstName, Work_Order__r.Contact.LastName, Work_Order__r.Contact.Name, // name
                    Work_Order__r.Contact.Phone, Work_Order__r.Contact.HomePhone, Work_Order__r.Contact.MobilePhone, // phone
                    Work_Order__r.Source__c, // source
                    Work_Order__r.Order_Type__c,  // order info
                	Work_Order__r.Order_Date__c,Work_Order__r.CreatedDate,
                    Work_Order__r.Hybris_Order_Id__c, Work_Order__r.POS_Web_Order_Id__c, Work_Order__r.Layaway_Number__c, Work_Order__r.Quote_Number__c, Work_Order__r.Invoice_Number__c,
                    Work_Order__r.Form_Type__c, Work_Order__r.Form_Number__c, // form info
                    Work_Order__r.Cancel_Reason__c,Work_Order__r.Account.POS_Customer_Id__c
                    FROM ServiceAppointment
                    WHERE ServiceTerritory.Site_Account__r.SAP_STORE_ID__c = :siteId  
                    AND Status IN :appointmentStatuses
                    AND Date_String__c <= :endDate
                    AND Date_String__c >= :startDate
                    AND Appointment_Rescheduled__c = :rescheduleFilter
                ORDER BY Date_String__c ASC, Start_Time_String__c ASC
            ];            
        } else {
            // ignore rescheduleFilter
            return [
                SELECT Id, toLabel(Status), Activity_Type__c, Appointment_Rescheduled__c,
                    SchedStartTime, SchedEndTime, Start_Time_String__c, End_Time_String__c, Date_String__c,  // times
                    Original_Start_Time_String__c, Original_End_Time_String__c, Original_Date_String__c, // original times
                    Work_Order__r.Contact.FirstName, Work_Order__r.Contact.LastName, Work_Order__r.Contact.Name, // name
                    Work_Order__r.Contact.Phone, Work_Order__r.Contact.HomePhone, Work_Order__r.Contact.MobilePhone, // phone
                    Work_Order__r.Source__c, // source
                    Work_Order__r.Order_Type__c,  // order info
                    Work_Order__r.Order_Date__c,Work_Order__r.CreatedDate,
                    Work_Order__r.Hybris_Order_Id__c, Work_Order__r.POS_Web_Order_Id__c, Work_Order__r.Layaway_Number__c, Work_Order__r.Quote_Number__c, Work_Order__r.Invoice_Number__c,
                    Work_Order__r.Form_Type__c, Work_Order__r.Form_Number__c, // form info
                    Work_Order__r.Cancel_Reason__c,
                    Work_Order__r.Account.POS_Customer_Id__c
                FROM ServiceAppointment
                WHERE ServiceTerritory.Site_Account__r.SAP_STORE_ID__c = :siteId  
                    AND Status IN :appointmentStatuses
                    AND Date_String__c <= :endDate
                    AND Date_String__c >= :startDate
                ORDER BY Date_String__c ASC, Start_Time_String__c ASC
            ];
        } 
        
    }


    public static List<Appt_AppointmentLogWrapper> getArchivedServiceAppointments(String siteId, List<String> appointmentStatuses, String startDate, String endDate, Boolean rescheduleFilter) {

        System.debug('Appt_AppointmentLogController::getArchivedServiceAppointments() start');
        List<String> sdParts = startDate.split('-');
        List<String> edParts = endDate.split('-');
        Time eod = Time.newInstance(23, 59, 59, 0);
        Datetime startDt = Datetime.newInstance(Integer.valueOf(sdParts[0]), Integer.valueOf(sdParts[1]), Integer.valueOf(sdParts[2]));
        System.debug('Start: ' + startDt);
        Datetime endDt = Datetime.newInstance(Date.newInstance(Integer.valueOf(edParts[0]), Integer.valueOf(edParts[1]), Integer.valueOf(edParts[2])), eod);
        System.debug('End: ' + endDt);

        Schema.DescribeFieldResult fieldResult = ServiceAppointment.Status.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();

        Map<String, String> saStatusMap = new Map<String, String>();
        for (Schema.PicklistEntry pick: pList){
            saStatusMap.put( pick.getValue(), pick.getLabel() );
        }

        List<Appt_Archive_d__b> archServAppts = [Select Id, Site_Id__c, SchedStartTime__c, Status__c, Id__c, Payload__c FROM Appt_Archive_d__b WHERE Site_Id__c =: siteId AND (SchedStartTime__c >=: startDt AND SchedStartTime__c <=: endDt)];
        List<Appt_AppointmentLogWrapper> aALW_List = new List<Appt_AppointmentLogWrapper>();

        for (Appt_Archive_d__b aSA : archServAppts){
            // serialize Archive response
            String archJson = JSON.serialize(aSA);
            // System.debug('archive: ' + archJson);

            // convert Arcive payload to Payload Model
            // System.debug('Payload: ' + aSA.Payload__c);
            Appt_AppointmentLogWrapper newApptLog = new Appt_AppointmentLogWrapper(Appt_ArchivePayloadModel.parse(aSA.Payload__c));
            // filter for Reschedule filter, Status, and modify status to be Label not the API Name
            if (appointmentStatuses.contains( newApptLog.appointmentStatus ) &&
                ( (rescheduleFilter == null) || ( newApptLog.rescheduleStatus == rescheduleFilter ) ) ) 
            {
                newApptLog.appointmentStatus = saStatusMap.get(newApptLog.appointmentStatus);
                aALW_List.add(newApptLog);
            } 

        }
        System.debug('ArchivePayloadModel: ' + aALW_List.size());

        System.debug('Appt_AppointmentLogController::getArchivedServiceAppointments() end');
        return aALW_List;
    }
}