public virtual class Appt_CreateAppointmentServiceModel extends Appt_BaseModel{
    
    //fields for error response and message
    public String appointmentId;
    public String appointmentStatus;
	public String posCustomerId;
	public String hybrisCustomerId;
    public String siteId;
    public Integer timeZoneOffset;
    public String timeZone;
	public String source;
	public String orderType;
    public Date appointmentDate;
    public String consultAppointmentId;
	public String consultStartTime;
    public String consultEndTime;
    public String consultDuration;
    public String backOfficeAppointmentId;
	public String backOfficeStartTime;
    public String backOfficeEndTime;
    public String backOfficeDuration;
    public String selectedSlotStartTime;
    public String selectedSlotEndTime;
	public String formType;
	public String formNumber;
	public String formDate;
	public String hybrisOrderId;
	public String posWebOrderId;
	public String layawayNumber;
	public String quoteNumber;
	public String invoiceNumber;
	public String orderDate;
	public String customerGuid;
	public String customerType;
	public String firstName;
	public String lastName;
    public String emailAddress;
    public String smsPhoneNumber;
	public String mobilePhoneNumber;
	public String homePhoneNumber;
	public String workPhoneNumber;
	public String address1;
	public String address2;
	public String zipCode;
	public String city;
	public String state;
	public String country;
	public Boolean textOptIn;
	public Boolean emailAddressOptIn;
	public String posCustomerVehicleId;
	public String hybrisCustomerVehicleId;
    public String vehicleClass;
    public String vehicleId;
	public String year;
	public String make;
	public String model;
    public String trimName;
	public String trimId;
	public String assemblyId;
	public String recipientFirstName;
	public String recipientLastName;
	public String recipientEmail;
	public String recipientPhone;
	public String comments;
    public List<Articles> articles;
    public String accountId;
    public String contactId;
    public String alternateContactId;
    public String assetId;
    public String ServiceTerritoryId;
    public String frontroomServiceResourceId;
    public String backroomServiceResourceId;
    public String appointmentRecordOwnerId;
    public String schedulingPolicyId;
    public String frontroomWorkTypeId;
    public String backroomWorkTypeId;
    public String workOrderId;
    public String frontroomServiceAppointmentId;
    public String backroomServiceAppointmentId;
    public String vehicleType;
    public String trimDetails;
    public String assemblyDetails;
    public Date smsConfirmationSent;
    public Date emailConfirmationSent;
    public Boolean checkAvailabilityFirst;
    
    // Appt 3.0 Changes - New Variables added for Account,WorkOrder,Asset as part of Appt 3.0 Project
    public String companyName;
    public String companyName2;
    public String middleInitial;
    public String suffix;
    public String fleetNumber;
    public Boolean showMyAccount;
    public Boolean showAAAMember;
    public Boolean showDTCC;
    public Boolean showMilitary;
    public String customerId;
    public String imageURL;
    public String fitmentLiftId;
    public String frontTireSize;
    public String rearTireSize;
    public String frontTireDiameter;
    public String rearTireDiameter;    
    public String assemblyType;
    public String color;
    public String licensePlate;  
    public String genericVehicleCategory;
    public String genericVehicleSubCategory;    
    public String customerVehicleId;
    public String salesOrderId;
    public Boolean unPaid;
    public Boolean isVisionFeature;
    public List<String> smsNotificationsSent;
    public List<String> emailNotificationsSent; 
    // Appt 3.0 Changes - End
    
    
	public class Articles {
		public String requestType;
		public String articleId;
		public String articleType;
		public String articleCount;
		public String articleSize;
		public String articleDescription;
         // Appt 3.0 Changes - New Variables for WOLI added as part of Appt 3.0 Project
        public Boolean tredWell; 
        // Appt 3.0 Changes - End
	}
    
    // Appt 3.0 Changes - Added this class to Address Notification display on View Appointment Screen. 
    public class Notifications {
        public List<String> smsNotificationSent;
        public List<String> emailNotificationSent;
    }
    // Appt 3.0 Changes - End    
    
    public static Appt_CreateAppointmentServiceModel parseCreateAppointmentRequest(Appt_CreateAppointmentRequest request) {
        
        String requestString = JSON.serialize(request);
       return (Appt_CreateAppointmentServiceModel) System.JSON.deserialize(requestString, Appt_CreateAppointmentServiceModel.class);
               
    }
    
    public Appt_GetAvailabilityServiceModel spawnGetAvailabilityServiceModel(Boolean isAvailbilityCheckOnly) {
        System.debug('Appt_CreateAppointmentServiceModel: spawnGetAvailabilityServiceModel() ENTRY - isAvailbilityCheckOnly'+isAvailbilityCheckOnly);

        Appt_GetAvailabilityServiceModel availModel = new Appt_GetAvailabilityServiceModel();
        availModel.availabilityOnly = isAvailbilityCheckOnly;
        availModel.siteId = this.siteId;
        availModel.appointmentDate = this.appointmentDate;
        availModel.startDate = this.appointmentDate;
        availModel.endDate = this.appointmentDate;
        availModel.orderType = this.orderType;
        availModel.customerType = this.customerType;
        availModel.source = this.source;
        availModel.consultStartTime = this.consultStartTime;
        availModel.consultEndTime = this.consultEndTime;
        availModel.consultDuration = this.consultDuration;
        availModel.backOfficeStartTime = this.backOfficeStartTime;
        availModel.backOfficeEndTime = this.backOfficeEndTime;
        availModel.backOfficeDuration = this.backOfficeDuration;
        availModel.timeZoneOffset = this.timeZoneOffset;
        
        
        // Appt 3.0 Changes - Enable Vision feature for Appt 3.0
        availModel.isVisionFeature = this.isVisionFeature;
        // Appt 3.0 Changes - End
    
        if (articles != null && articles.size() > 0) {
            availModel.items = new List<Appt_GetAvailabilityServiceModel.Items>();
            
            for (Articles article: articles) {
                System.debug('      article:'+article);
                Appt_GetAvailabilityServiceModel.Items item = new Appt_GetAvailabilityServiceModel.Items();
                item.requestType = article.requestType;
                item.articleType = article.articleType;
                item.articleSize = article.articleSize;
                item.articleId = article.articleId;
                item.articleDescription = article.articleDescription;
                item.articleCount = article.articleCount;

                availModel.items.add(item);
            }
        }

        System.debug('Appt_CreateAppointmentServiceModel: spawnGetAvailabilityServiceModel() EXIT - Appt_GetAvailabilityServiceModel:'+availModel);
        return availModel;
    }

    public Appt_GetAvailabilityServiceModel spawnGetAvailabilityServiceModel() {
        return spawnGetAvailabilityServiceModel(true);
    }
}