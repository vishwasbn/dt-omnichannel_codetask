public class Appt_GetAvailabilityServiceModel extends Appt_BaseModel{
    
    public static String lprefix = 'Appt_AvailSM: ';

    public Boolean availabilityOnly;
    public String siteId;
    public Date startDate;
    public Date endDate;
    public String orderType;
    public String customerType;
    public String vehicleClass;
	public String vehicleId;
	public String trimId;
	public String assemblyId;
	public String source;
    public List<Items> items;
    public Integer timeZoneOffset;
    public String timeZone;
    public String consultStartTime;
    public String consultEndTime;
    public String consultDuration;
	public String backOfficeStartTime;
    public String backOfficeEndTime;
    public String backOfficeDuration;
    public Date appointmentDate;
    
    // Appt 3.0 Changes - Start On the fly flag 
    public Boolean isVisionFeature;
    // Appt 3.0 Changes - End
    
	public class Items {
		public String requestType;
		public String articleId;
		public String articleType;
		public String articleCount;
		public String articleSize;
		public String articleDescription;
    }

    public Boolean isProductInItemList(String productId) {
        Boolean returnBool = false;

        if (!String.isBlank(productId) && this.items != null && this.items.size() > 0) {
            for (Items item: this.items) {
                if (!String.isBlank(item.articleId) && item.articleId == productId) {
                    returnBool = true;
                    break;
                }
            }
        }

        System.debug('Appt_GetAvailabilityServiceModel: isProductInItemList() - productId='+productId+', return boolean='+returnBool);
        return returnBool;
    }

    public Integer numberOfItems() {
        if (this.items != null) return this.items.size();
        else return 0;
    }
    
    public static Appt_GetAvailabilityServiceModel parseGetAvailabilityRequest(Appt_GetAvailabilityRequest request) {
        
        String requestString = JSON.serialize(request);
        return (Appt_GetAvailabilityServiceModel) System.JSON.deserialize(requestString, Appt_GetAvailabilityServiceModel.class);

    }

    public String getBucketField(String frontBackChar) {

        String fleetRetailChar;
        if (this.customerType == Appt_ConstantValues.CUSTOMER_TYPE_FLEET) fleetRetailChar = Appt_ConstantValues.APPOINTMENT_SOURCE_CUSTOMER_FLEET_CHAR;
        else fleetRetailChar = Appt_ConstantValues.APPOINTMENT_SOURCE_CUSTOMER_RETAIL_CHAR;

        String storeWebChar;
        if (this.source == Appt_ConstantValues.APPOINTMENT_SOURCE_STORE || this.source == Appt_ConstantValues.APPOINTMENT_SOURCE_POS) storeWebChar = Appt_ConstantValues.APPOINTMENT_SOURCE_STORE_CHAR;
        else storeWebChar = Appt_ConstantValues.APPOINTMENT_SOURCE_WEB_CHAR;

        return frontBackChar + storeWebChar + fleetRetailChar + '_Available__c'; 

    }
}