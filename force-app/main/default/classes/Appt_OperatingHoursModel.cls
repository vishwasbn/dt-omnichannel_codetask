public class Appt_OperatingHoursModel {
    public String type;
    public Id Id;
    public Map<String, List<TimeSlot>> capacitySlotsPerWeekDayMap;
    public Map<String, TimeSlot> storeHoursPerWeekDayMap;

    public Appt_OperatingHoursModel(Id Id, String type) {
        this.Id = Id;
        this.type = type;
        capacitySlotsPerWeekDayMap = new Map<String, List<TimeSlot>>();
        storeHoursPerWeekDayMap = new Map<String, TimeSlot>();
    } 

    public void addTimeSlot(TimeSlot slot) {
        if (this.type == Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS) {
            storeHoursPerWeekDayMap.put(slot.DayOfWeek, slot);
        } else if (this.type == Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY) {
            List<TimeSlot> capSlotList = capacitySlotsPerWeekDayMap.get(slot.DayOfWeek);

            if (capSlotList != null) capSlotList.add(slot);
            else {
                capSlotList = new List<TimeSlot>();
                capSlotList.add(slot);
                capacitySlotsPerWeekDayMap.put(slot.DayOfWeek, capSlotList);
            }
        }
    }

}