/******************************************************************************************************
* Project : Appointment 3.0
*******************************************************************************************************
* Business Owner : Discount Tire
* Purpose : To get service appointments for the past 30 days from starting from today.
* Business Logic : When a POS user wants to see the list of appointments those were created in past 30 days.
*******************************************************************************************************
* Version   Date          Updated By            		  Test        Target        Comments
* 1.0       12/21/2022    prakhar.a.shukla@capgemini.com   80%            
********************************************************************************************************/

/**
 * @description This controller Class that shows service appointments for the past 30 days from starting from today.
 */
public without sharing class Appt3_AppointmentLogController {
    
    public final static string LPREFIX = 'LOG Appt3_LogController';
    /**
     * @description This method is called from LWC to load the service appointments based on selected filters
     * @return a string of appointments 
     * @param siteId
     * @param startDate
     * @param endDate
     * @param appointmentStatuses
     * @param rescheduleFilter
     */
    @AuraEnabled(cacheable=true)
    public static string getAppointments(String siteId, String startDate, String endDate, List<String> appointmentStatuses, Boolean rescheduleFilter) {
        System.debug(LPREFIX + '---getAppointments---' + 'dates: ' + startDate + ' - ' + endDate + 'status: '+appointmentStatuses);
        try {
            List<ServiceAppointment> apptList = new List<ServiceAppointment>();
            apptList = getServiceAppointments(siteId, appointmentStatuses, startDate, endDate, rescheduleFilter);
            System.debug(LPREFIX + 'apptList: ' + apptList);
            return JSON.serialize(apptList);
        }
        catch (Exception e) {
            Appt3_ApptsPageContainerController.logExceptions(e, Appt3_AppointmentLogController.class.getName(), 'Appointments 3.0');            
            throw new AuraHandledException(e.getMessage());
        }
    }
        
    /**
     * @description This method gets the list of service appointments to be returned to the LWC
     * @return a list of appointments 
     * @param siteId
     * @param appointmentStatuses
     * @param startDate
     * @param endDate
     * @param rescheduleFilter
     */
    public static List<ServiceAppointment> getServiceAppointments( String siteId, List<String> appointmentStatuses, String startDate, String endDate, Boolean rescheduleFilter ) {
        String query;
        String curStatuses='';
        if (siteId == null || startDate == null || endDate == null) {
            throw new AuraHandledException('Invalid Site or Date Parameters: ' + startDate + ' - ' + endDate + ' - Site: ' + siteId);
        }

        for(String strStatus : appointmentStatuses) {
            curStatuses += '\'' + String.escapeSingleQuotes(strStatus) + '\',';
        }

        curStatuses = curStatuses.left(curStatuses.length()-1);
        query = 'SELECT Id, toLabel(Status), Appt3_FormattedRescheduledFlag__c, Work_Order__c, Work_Order__r.Source__c, Work_Order__r.Appt3_Sales_Order_Id__c, Work_Order__r.Contact.Name, Work_Order__r.Contact.Appt3_Formatted_Mobile_Phone__c, Date_String__c, Appt3_Formatted_Appointment_Date__c, Appt3_Formatted_Start_Time_String__c, Start_Time_String__c, Appt3_Formatted_Original_Date_String__c, Work_Order__r.Cancel_Reason_Code__c FROM ServiceAppointment ';
        query = query + 'WHERE ServiceTerritory.Site_Account__r.SAP_STORE_ID__c ='+'\'' + String.escapeSingleQuotes(siteId) +'\'';
        query = query + ' AND Status IN (' + curStatuses +') ';
        query = query + ' AND Date_String__c <= ' + '\'' + String.escapeSingleQuotes(endDate) +'\' AND Date_String__c >=' +'\''+ String.escapeSingleQuotes(startDate) +'\'';

        if (rescheduleFilter != null && (rescheduleFilter == true || rescheduleFilter == false)) {
            query = query + ' AND Appointment_Rescheduled__c = ' + rescheduleFilter ;
        }

        query = query + ' ORDER BY Date_String__c ASC, Start_Time_String__c ASC LIMIT 50000' ; 

        System.debug(LPREFIX + 'Query is ' + query);
        return (List<ServiceAppointment>)Database.query(query);
    }
  
    
    /**
     * @description Method to get counts of total appointments according to the selected filters from LWC
     * @return a returnCountsModel
     * @param siteId
     * @param startDate
     * @param endDate
     * @param appointmentStatuses
     */
    @AuraEnabled
    public static ReturnCountsModel getFilterCounts(String siteId, String startDate, String endDate, List<String> appointmentStatuses) {
        System.debug(LPREFIX + '---getFilterCounts---' + 'dates: ' + startDate + ' - ' + endDate + 'status: '+appointmentStatuses + 'siteId: '+siteId);
        try {
        Appt3_AppointmentLogController.ReturnCountsModel rcm = new Appt3_AppointmentLogController.ReturnCountsModel();
        rcm.statusCountMap = new Map<String, Integer>();
        rcm.rescheduledCountMap = new Map<String, Integer>();
        for(AggregateResult ar : [SELECT Status, Appointment_Rescheduled__c, COUNT(Id) FROM ServiceAppointment 
                                  WHERE ServiceTerritory.Site_Account__r.SAP_STORE_ID__c =:siteId AND
                                  Date_String__c <= :endDate AND
                                  Date_String__c >= :startDate AND
                                  Status IN :appointmentStatuses
                                  GROUP BY Status, Appointment_Rescheduled__c]) {
                                      String status = String.valueOf(ar.get('Status'));
                                      String rescheduled = String.valueOf(ar.get('Appointment_Rescheduled__c'));
                                      Integer count = Integer.valueOf(ar.get('expr0'));
                                      if(rcm.statusCountMap.containsKey(status)) {
                                          rcm.statusCountMap.put(status, rcm.statusCountMap.get(status) + count);
                                      } else {
                                          rcm.statusCountMap.put(status, count);
                                      }
                                      if(rcm.rescheduledCountMap.containsKey(rescheduled)) {
                                          rcm.rescheduledCountMap.put(rescheduled, rcm.rescheduledCountMap.get(rescheduled) + count);
                                      } else {
                                          rcm.rescheduledCountMap.put(rescheduled, count);
                                      } 
        }    
        system.debug('logs:'+rcm);
        return rcm;
        }
        catch (Exception e) {
            Appt3_ApptsPageContainerController.logExceptions(e, Appt3_AppointmentLogController.class.getName(), 'Appointments 3.0');            
            throw new AuraHandledException(e.getMessage());
        }
    }
     
    /**
     * @description wrapper class used to return filter counts back to LWC
     */
    public class ReturnCountsModel {
        /**
         * @description getter and setter method for wrapper class
         */
        @AuraEnabled
        public Map<String, Integer> statusCountMap {get; set;}
        
        /**
         * @description getter and setter method for wrapper class
         */
        @AuraEnabled
        public Map<String, Integer> rescheduledCountMap {get; set;}
    }
}