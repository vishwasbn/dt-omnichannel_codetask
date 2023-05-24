public class Int_Values
{
    public static String lprefix = 'Int_Values';

    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_QUEUED = 'Queued';
    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String STATUS_SUCCESSFUL = 'Successful';
    public static final String STATUS_ACKNOWLEDGED = 'Acknowledged';
    public static final String STATUS_ERROR = 'Error';

    public static final String TYPE_FLEET_OAUTH = 'FLEET_OAUTH';
    public static final String TYPE_CAR_LIST = 'CAR_LIST';

    public static final String TYPE_ACCOUNT_ECC = 'ECC_OUTBOUND_ACCOUNT';
    public static final String TYPE_CONTACT_ECC = 'ECC_OUTBOUND_CONTACT';
    public static final String TYPE_B2BCUSTOMER_INCOMING = 'B2B_CUSTOMER_INCOMING';
    public static final String TYPE_B2BCUSTOMER_OUTBOUND_REQUEST = 'B2B_CUSTOMER_OUTBOUND_REQUEST';

    public static final String TYPE_INVOICE_DETAIL_HYBRIS_NUMBER = 'INVOICE_DETAIL_HYBRIS_ORD_NUM';
    public static final String TYPE_INVOICE_DETAIL_INVOICE_NUMBER = 'INVOICE_DETAIL_INVOICE_NUM';
    public static final String TYPE_INVENTORY = 'INVENTORY';

    public static String createGUID() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,16);
        System.debug(lprefix+'createGUID() EXIT with return GUID=' + guid);
        return guid;
    }

    //---Create static list of timings to be available across a user context
    public static List<Int_Timing> TimingList {get; set;}

    //---Create an object for timings
    public class Int_Timing
    {
        public String Name {get; set;}
        public Decimal Timing {get; set;}

        public Int_Timing(String inpName, Decimal inpTiming)
        {
            Name = inpName;
            Timing = inpTiming;
        }
    }

    //---Quick add to timings
    public static void addTiming(String name, Decimal timing)
    {
        if (TimingList == null) TimingList = new List<Int_Timing>();
        TimingList.add( new Int_Timing(name, timing));
    }

    //---Quick add to timings
    public static void addTiming(String name, DateTime startTime, Datetime endTime)
    {
        addTiming(name, getDuration(startTime,endTime));
    }

    //---Get the Duration 
    public static Integer getDuration(DateTime startTime, Datetime endTime)
    {
        Integer elapsedMinutes = endTime.minute() - startTime.minute();
        Integer elapsedSeconds = endTime.second() - startTime.second();
        Integer elapsedMiliseconds = endTime.millisecond() - startTime.millisecond();

        Integer totalMili =  (elapsedMinutes * 60 * 1000) + (elapsedSeconds * 1000) + elapsedMiliseconds;

        return totalMili;
    }

    //---Write the timings to a cominged log message
    public static String getTimingLog()
    {
        String returnVal = '';

        if (TimingList != null)
        {
            for(Int_Timing row : TimingList)
            {
                if (returnVal != '') returnVal += '\n';
                returnVal += row.Name + ': ' + row.Timing;
            } 
        }
        
        return returnVal;
    }
}