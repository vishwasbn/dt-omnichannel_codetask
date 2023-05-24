public with sharing class Appt_UpdateStoreConfig {
    public String serviceTerritory;
    public String effectiveDate;
    public List<Appt_Time_Slot_Capacity__c> ApptTimeSlotCapacities = new List<Appt_Time_Slot_Capacity__c>();
    public List<SelectedDay> selectedDays = new List<SelectedDay>();   

    public Appt_UpdateStoreConfig() {
    }

    // Inner class for response object
    public class SelectedDay{
        public string selectedDay;
    }
}