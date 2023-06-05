public class Appt_SiteAvailabilityModel extends Appt_BaseModel{
    
    public List<Days> days;
    public Map<String, Days> daysMap;
    public String timeZone;

    public class Days {
        public String scheduleDate;
        public String year;
        public String month;
        public String day;
        public String dayOfWeek;
        public List<TimeSlots> timeSlots;
    }

    public class TimeSlots {
        public String consultStartTime;
        public String consultEndTime;
        public String consultDuration;
        public String backOfficeStartTime;
        public String backOfficeEndTime;
        public String backOfficeDuration;
    }
    
    public Appt_SiteAvailabilityModel() {}
}