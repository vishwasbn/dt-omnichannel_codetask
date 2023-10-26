// Store entry screen object simplified for LWC
public without sharing class Appt_StoreConfigs {   
    
    public string serviceTerritory;
    public List<Appt_Time_Slot_Capacity__c> ApptTimeSlotCapacities = new List<Appt_Time_Slot_Capacity__c>();
    public List<Day> days = new List<Day>();
    public Boolean success;
    public string errorMessage;
    public date minEffectiveDate;
    public date maxEffectiveDate;

    public Appt_StoreConfigs(String serviceTerritory, String selectedDay){
        System.debug('start generating Appt_StoreConfigs');
        System.debug('Service Territory Id:' + serviceTerritory);
        this.serviceTerritory = serviceTerritory;
        getDays();
        getApptTimeSlotCapacities(selectedDay);
        getEffectiveDates();
        this.success = true;     
        System.debug('end generating Appt_StoreConfigs');   
    }


    // gets the stors days of the week and their operating hours
    public void getDays(){
        System.debug('start getDays');
        ServiceTerritory store = [SELECT id, OperatingHoursId FROM ServiceTerritory WHERE id = :serviceTerritory];
        id operatingHoursId = store.OperatingHoursId;
        System.debug('Operating Hours Id:' + operatingHoursId);

        List<TimeSlot> daysOfWeek = [SELECT id, DayOfWeek, StartTime, EndTime FROM TimeSlot WHERE OperatingHoursId = :operatingHoursId]; 
        System.debug('Operating Hours Time Slots:' + daysOfWeek);
        // Create the day object
        for(TimeSlot slot: daysOfWeek){

            String storeHours = '';
            Integer startHour = slot.StartTime.hour();
            Integer endHour = slot.EndTime.hour();
            Integer startMinute = slot.StartTime.minute();
            Integer endMinute = slot.EndTime.minute();
            String startMin = '';
            String endMin = '';


            // Format the start time minute
            if(startMinute == 0){
                startMin = '00';
            } else if(startMinute > 0 && startMinute < 10) {
                startMin = '0' + String.valueOf(startMinute);
            } else{
                startMin = String.valueOf(startMinute);
            }

            // Format the end time minute
            if(endMinute == 0){
                endMin = '00';
            } else if(endMinute > 0 && endMinute < 10) {
                endMin = '0' + String.valueOf(endMinute);
            } else{
                endMin = String.valueOf(endMinute);
            }

            // Format the start time String
            if(startHour < 12){
                storeHours = String.valueOf(startHour) +':'+ startMin +'AM - ';
            } else {
                storeHours = String.valueOf(startHour) +':'+ startMin +'PM - ';
            }

            // Format the start time String
            if(endHour < 12){
                storeHours += String.valueOf(endHour) +':'+ endMin +'AM';
            } else {
                endHour -= 12;
                storeHours += String.valueOf(endHour) +':'+ endMin +'PM';
            }                       

            Day newDay = new Day(slot.DayOfWeek,storeHours);
            days.add(newDay);

        }
        
        System.debug('Days' + days); 
        System.debug('End getDays');
    }

    // gets the stores time slots for the day selected
    public void getApptTimeSlotCapacities(String selectedDay){
        System.debug('Start getApptTimeSlotCapacities');

        ApptTimeSlotCapacities = [SELECT 
                                    id, 
                                    Start_Time__c, 
                                    End_Time__c,
                                    Day_of_Week__c,
                                    BSF_Capacity__c, 
                                    BSR_Capacity__c, 
                                    BWF_Capacity__c, 
                                    BWR_Capacity__c, 
                                    FSF_Capacity__c, 
                                    FSR_Capacity__c, 
                                    FWF_Capacity__c, 
                                    FWR_Capacity__c 
                                FROM Appt_Time_Slot_Capacity__c 
                                WHERE Service_Territory__c = :serviceTerritory 
                                AND Day_of_Week__c = :selectedDay ORDER BY Start_Time__c];
    /*Added as part of SO-856: Consolidate Fleet Buckets Start*/
    if(Appt_AppointmentUtil.checkConsolidateFleetCapacityFlag() && ApptTimeSlotCapacities != null && ApptTimeSlotCapacities.size()>0)
    {
        ApptTimeSlotCapacities=Appt_AppointmentUtil.consolidateFleetCapacities(ApptTimeSlotCapacities);
    }
    /*Added as part of SO-856: Consolidate Fleet Buckets End*/                                 
    System.debug('Capacities' + ApptTimeSlotCapacities);     
    System.debug('End getApptTimeSlotCapacities');    
    }

    // Sets the min and max effective dates allowed for this store
    public void getEffectiveDates(){
        System.debug('Start getEffectiveDates');
        minEffectiveDate = Date.today().addDays(1);
        List<Appt_Time_Slot__c> maxDate = [SELECT id, End_Time__c FROM Appt_Time_Slot__c WHERE Service_Territory__c = :serviceTerritory ORDER BY End_Time__c DESC LIMIT 1];
        
        if(maxDate.size() > 0){
            maxEffectiveDate = date.newinstance(maxDate[0].End_Time__c.year(), maxDate[0].End_Time__c.month(), maxDate[0].End_Time__c.day()); 
            if(maxEffectiveDate <= minEffectiveDate){maxEffectiveDate =  minEffectiveDate;}
        } else {
            maxEffectiveDate =  minEffectiveDate;
        }        

        System.debug('Min Date' + minEffectiveDate);
        System.debug('Max Date' + maxEffectiveDate);
        System.debug('End getEffectiveDates');
    }   

    // Default empty constructor
    public Appt_StoreConfigs(){
        
    }

    // Inner class for response object
    public class Day{
        public string day;
        public String operatingHours;
        public Integer dayOrder = 0;

        public Day(string day, String operatingHours){
            this.day = day;
            this.operatingHours = operatingHours;

            if(day.toUpperCase().contains('SUN')){
                this.dayOrder = 0;
            }
            if(day.toUpperCase().contains('MON')){
                this.dayOrder = 1;
            }
            if(day.toUpperCase().contains('TUE')){
                this.dayOrder = 2;
            }
            if(day.toUpperCase().contains('WED')){
                this.dayOrder = 3;
            }
            if(day.toUpperCase().contains('THU')){
                this.dayOrder = 4;
            }
            if(day.toUpperCase().contains('FRI')){
                this.dayOrder = 5;
            }
            if(day.toUpperCase().contains('SAT')){
                this.dayOrder = 6;
            }

        }
    }
}