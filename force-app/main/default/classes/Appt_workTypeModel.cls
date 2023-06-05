public class Appt_workTypeModel extends Appt_BaseModel{
    
    public String OrderType;
    // type values are "Front", "Back", "Both" - constants in Appt_ConstantValues.WORK_TYPE_TYPE_...
    public String type; 
    public String source;
    public String customerType;
    public Integer frontOfficeDuration;
    public Integer backOfficeDuration;

    public String getOrderType(){
        return this.OrderType;
    }


}