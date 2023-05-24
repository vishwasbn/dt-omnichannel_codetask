public class Appt_ScheduleModel {
    static String lprefix = 'Appt_ScheduleModel: ';

    public String slotId {get; set;}

    public String startTime { get; set; }
    public String formattedStartTime {get; set;}

    public String endTime { get ; set; }
    public String formattedEndTime {get; set;}

    public String type  { get ; set; }

    // Front Room Store Retail
    public Decimal fsrAvailable { get; set; }
    public Decimal fsrCapacity { get; set; }
    public Boolean noFsrAvailable {get; set;}
    
    // Front Room Store Fleet
    public Decimal fsfAvailable { get; set; }
    public Decimal fsfCapacity { get; set; }
    public Boolean noFsfAvailable {get; set;}

    // Front Room Web Fleet
    public Decimal fwfAvailable { get; set; }
    public Decimal fwfCapacity { get; set; }
    public Boolean noFwfAvailable {get; set;}

    // Front Room Web Retail
    public Decimal fwrAvailable { get; set; }
    public Decimal fwrCapacity { get; set; }
    public Boolean noFwrAvailable {get; set;}

    // Back Room Store Fleet
    public Decimal bsfAvailable { get; set; }
    public Decimal bsfCapacity { get; set; }
    public Boolean noBsfAvailable {get; set;}

    // Back Room Store Retail
    public Decimal bsrAvailable { get; set; }
    public Decimal bsrCapacity { get; set; }
    public Boolean noBsrAvailable {get; set;}

    // Back Room Web Fleet
    public Decimal bwfAvailable { get; set; }
    public Decimal bwfCapacity { get; set; }
    public Boolean noBwfAvailable {get; set;}

    // Back Room Web Retail
    public Decimal bwrAvailable { get; set; }
    public Decimal bwrCapacity { get; set; }
    public Boolean noBwrAvailable {get; set;}

    // Tracks whether ot not this model(time slot) can be selected. False if the date is passed
    public Boolean selectable {get; set;}

    // Total number of front/back capacity and available slots
    public Decimal totalFrontRetailCapacity {get; set;}
    public Decimal totalFrontFleetCapacity {get; set;}
    public Decimal totalBackRetailCapacity {get; set;}
    public Decimal totalBackFleetCapacity {get; set;}

    public Decimal totalFrontRetailAvailable {get; set;}
    public Decimal totalFrontFleetAvailable {get; set;}
    public Decimal totalBackRetailAvailable {get; set;}
    public Decimal totalBackFleetAvailable {get; set;}

    // Back Room available
    public Decimal backRetailAvailable { get; set; }
    public Decimal backFleetAvailable { get; set; }

    // Front Room available
    public Decimal frontRetailAvailable { get; set; }
    public Decimal frontFleetAvailable { get; set; }

    // Total available
    public Decimal backTotalAvailable { get; set; }
    public Decimal frontTotalAvailable { get; set; }
    public Boolean backAvailable { get; set; }
    public Boolean frontAvailable { get; set; }


    public Appt_ScheduleModel() {}

    public Appt_ScheduleModel(Appt_Time_Slot__c timeSlot, String tz) {
        this.slotId = timeSlot.Id;

        this.startTime = timeSlot.Start_Time__c.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', tz);
        this.formattedStartTime = timeSlot.Start_Time__c.format('hh:mm a', tz); 

        this.endTime = timeSlot.End_Time__c.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', tz);
        this.formattedEndTime = timeSlot.End_Time__c.format('hh:mm a', tz);

        this.type = timeSlot.Type__c;

        this.fsrAvailable = timeSlot.FSR_Available__c;
        this.fsrCapacity = timeSlot.FSR_Capacity__c;

        this.fsfAvailable = timeSlot.FSF_Available__c;
        this.fsfCapacity = timeSlot.FSF_Capacity__c;

        // Front Room Web Fleet
        this.fwfAvailable = timeSlot.FWF_Available__c;
        this.fwfCapacity = timeSlot.FWF_Capacity__c;

        // Front Room Web Retail
        this.fwrAvailable = timeSlot.FWR_Available__c;
        this.fwrCapacity = timeSlot.FWR_Capacity__c;

        // Back Room Store Fleet
        this.bsfAvailable = timeSlot.BSF_Available__c;
        this.bsfCapacity = timeSlot.BSF_Capacity__c;

        // Back Room Store Retail
        this.bsrAvailable = timeSlot.BSR_Available__c ;
        this.bsrCapacity = timeSlot.BSR_Capacity__c;

        // Back Room Web Fleet
        this.bwfAvailable = timeSlot.BWF_Available__c ;
        this.bwfCapacity = timeSlot.BWF_Capacity__c;

        // Back Room Web Retail
        this.bwrAvailable = timeSlot.BWR_Available__c;
        this.bwrCapacity = timeSlot.BWR_Capacity__c;

        // Adjusting availability if within 2 hours
        Datetime now = Datetime.now();
        Datetime startTimeDatetime = timeSlot.Start_Time__c;
        Datetime endTimeDatetime = timeSlot.End_Time__c;

        Double diffFromStartTime = getHourDiffBetweenDatetimes(startTimeDatetime, now);
        System.debug(lprefix +'Diff between start time and now: ' +diffFromStartTime);

        // If the difference between now and the start time is within 2 hours, convert the web slots to pos slots
        if(diffFromStartTime > 0 && diffFromStartTime < 2){
            System.debug(lprefix +'Converting web appt slot to store slot for time \'' +startTimeDatetime +'\'');
            
            if(this.type.equals(Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT)){ // Convert front room appts
                System.debug(lprefix +'prev fsf avail: ' +this.fsfAvailable +'...' +'prev fsf capacity: ' +this.fsfCapacity);
                System.debug(lprefix +'prev fsr avail: ' +this.fsrAvailable +'...' +'prev fsr capacity: ' +this.fsrCapacity);

                // Give the available web to available store, web capacity to store capacity
                this.fsfAvailable += this.fwfAvailable;
                this.fsfCapacity += this.fwfCapacity;
                this.fsrAvailable += this.fwrAvailable;
                this.fsrCapacity += this.fwrCapacity;

                // web available and capacity go to 0
                this.fwfAvailable = 0;
                this.fwfCapacity = 0;
                this.fwrAvailable = 0;
                this.fwrCapacity = 0;

                System.debug(lprefix +'new fsf avail: ' +this.fsfAvailable +'...' +'new fsf capacity: ' +this.fsfCapacity);
                System.debug(lprefix +'new fsr avail: ' +this.fsrAvailable +'...' +'new fsr capacity: ' +this.fsrCapacity);
            }
            else { // Convert back room appts
                System.debug(lprefix +'prev bsf avail: ' +this.bsfAvailable +'...' +'prev bsf capacity: ' +this.bsfCapacity);
                System.debug(lprefix +'prev bsr avail: ' +this.bsrAvailable +'...' +'prev bsr capacity: ' +this.bsrCapacity);

                // Give the available web to available store, web capacity to store capacity
                this.bsfAvailable += this.bwfAvailable;
                this.bsfCapacity += this.bwfCapacity;
                this.bsrAvailable += this.bwrAvailable;
                this.bsrCapacity += this.bwrCapacity;

                // web available and capacity go to 0
                this.bwfAvailable = 0;
                this.bwfCapacity = 0;
                this.bwrAvailable = 0;
                this.bwrCapacity = 0;

                System.debug(lprefix +'new bsf avail: ' +this.bsfAvailable +'...' +'new bsf capacity: ' +this.bsfCapacity);
                System.debug(lprefix +'new bsr avail: ' +this.bsrAvailable +'...' +'new bsr capacity: ' +this.bsrCapacity);
            }

            System.debug('\n');
        } 

        this.noFsrAvailable = this.fsrAvailable <= 0;
        //this.fsrAvailable = this.fsrAvailable < 0 ? 0 : this.fsrAvailable;

        this.noFsfAvailable = this.fsfAvailable <= 0;
        //this.fsfAvailable = this.fsfAvailable < 0 ? 0 : this.fsfAvailable;

        this.noFwfAvailable = this.fwfAvailable <= 0;
        //this.fwfAvailable = this.fwfAvailable < 0 ? 0 : this.fwfAvailable;

        this.noFwrAvailable = this.fwrAvailable <= 0;
        //this.fwrAvailable = this.fwrAvailable < 0 ? 0 : this.fwrAvailable;

        this.noBsfAvailable = this.bsfAvailable <= 0;
        //this.bsfAvailable = this.bsfAvailable < 0 ? 0 : this.bsfAvailable;

        this.noBsrAvailable = this.bsrAvailable <= 0;
        //this.bsrAvailable = this.bsrAvailable < 0 ? 0 : this.bsrAvailable;

        this.noBwfAvailable = this.bwfAvailable <= 0;
        //this.bwfAvailable = this.bwfAvailable < 0 ? 0 : this.bwfAvailable;

        this.noBwrAvailable = this.bwrAvailable <= 0;
        //this.bwrAvailable = this.bwrAvailable < 0 ? 0 : this.bwrAvailable;


        // Check to see if this time slot date is before the current date, if so, it is not selectable
        String today = Datetime.now().format('yyyy-MM-dd HH:mm:ss'); // Date today converted to timezone of timeslot
        String startTime = timeSlot.Start_Time__c.format('yyyy-MM-dd HH:mm:ss');

        this.selectable = Datetime.valueOf(today) < Datetime.valueOf(startTime);


        System.debug(lprefix +'fsr capacity: ' +this.fsrCapacity + ', fwr capacity: ' +this.fwrCapacity);
        // Get the total number of capacity and total number of available
        this.totalFrontRetailCapacity = this.fsrCapacity + this.fwrCapacity;
        this.totalFrontFleetCapacity = this.fsfCapacity + this.fwfCapacity;
        this.totalBackRetailCapacity = this.bsrCapacity + this.bwrCapacity;
        this.totalBackFleetCapacity = this.bsfCapacity + this.bwfCapacity;

        System.debug(lprefix +'fsr avail: ' +this.fsrAvailable + ', fwr avail: ' +this.fwrAvailable);
        this.totalFrontRetailAvailable = this.fsrAvailable + this.fwrAvailable;
        this.totalFrontFleetAvailable = this.fsfAvailable + this.fwfAvailable;
        this.totalBackRetailAvailable = this.bsrAvailable + this.bwrAvailable;
        this.totalBackFleetAvailable = this.bsfAvailable + this.bwfAvailable;

        // Back Room available
        this.backRetailAvailable = timeSlot.BSR_Available__c + timeSlot.BWR_Available__c;
        this.backFleetAvailable = timeSlot.BSF_Available__c + timeSlot.BWF_Available__c;
        this.backTotalAvailable = this.backRetailAvailable + this.backFleetAvailable;
        this.backAvailable = (this.backTotalAvailable > 0);

        // Front Room available
        this.frontRetailAvailable = timeSlot.FSR_Available__c + timeSlot.FWR_Available__c;
        this.frontFleetAvailable = timeSlot.FSF_Available__c + timeSlot.FWF_Available__c;
        this.frontTotalAvailable = this.frontRetailAvailable + this.frontFleetAvailable;
        this.frontAvailable = (this.frontTotalAvailable > 0);

        
    }

    static Double getHourDiffBetweenDatetimes(Datetime dt1, Datetime dt2){
        Long dt1Long = dt1.getTime();
        Long dt2Long = dt2.getTime();
        Long milliseconds = dt1Long - dt2Long;
        Double seconds = milliseconds / 1000;
        Double minutes = seconds / 60;
        Double hours = minutes / 60;
        
        return hours;
    }
}