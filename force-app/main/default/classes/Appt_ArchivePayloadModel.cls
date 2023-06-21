/******************************************************************************************************
* Project : Appointment3.0
*******************************************************************************************************
* Business Owner : 
* Purpose        : This class is used to convert service appointment data to insert in Master Big Objects
*******************************************************************************************************
* Version   Date          Updated By            		 	Test        Target        Comments
* 1.0       01/12/2023    prakhar.shukla@capgemini.com   	100% 
********************************************************************************************************///
public class Appt_ArchivePayloadModel {
	public String storageType;
	public String appointmentId;
	public String appointmentStatus;
	public String relatedAppointmentId;
	public String salesforceAppointmentId;
	public String salesforceAcccountId;
	public String posCustomerId;
	public String hybrisCustomerId;
	public String siteId;
	public String source;
	public String orderType;
	public String appointmentDate;
	public String consultStartTime;
	public String consultEndTime;
	public String backOfficeStartTime;
	public String backOfficeEndTime;
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
	public String salesforceContactId;
	public String originalDateString;
	public String originalEndTimeString;
	public String originalStartTimeString;
	public String posCustomerVehicleId;
	public String hybrisCustomerVehicleId;
	public String vehicleType;
	public String year;
	public String make;
	public String model;
	public String vehicleId;
	public String trimId;
	public String assemblyId;
	public String comments;
	public String cancelReason;
	public String cancelReasonText;
	public String cancelReasonCode;
	public Boolean apptRescheduled;
	public String apptLastModifiedBy;
	public String apptLastModifiedDate;
    
    // Appt 3.0 Changes - Start (New fields added for Appointment 3)
    public String appt3AAAMembership;
    public String appt3CompanyName;
    public String appt3PrivateLabelCardholder;
    public String appt3Military;
    public String appt3FleetNumber;
    public String appt3SalesOrderId;
    public String appt3CustomerId;
    public String appt3FitmentLiftId;
    public String appt3FrontTireSize;
    public String appt3RearTireSize;
    public String appt3FrontTireDiameter;
    public String appt3RearTireDiameter;
    public String appt3AssemblyType;
    public String appt3Color;
    public String appt3GenericVehicleCategory;
    public String appt3GenericVehicleSubCategory;
    public String appt3CustomerVehicleId;
    public String appt3TypeOfVehicle;
    public List<Articles> articles;

    public class Articles {
		public String articleId;
		public String articleType;
		public String articleQuantity;
		public String articleSize;
        public String articleDescription;
        public Boolean tredWell;
        
	}
    // Appt 3.0 Changes - End

	
	public static Appt_ArchivePayloadModel parse(String json) {
		return (Appt_ArchivePayloadModel) System.JSON.deserialize(json, Appt_ArchivePayloadModel.class);
	}

	public Appt_ArchivePayloadModel(ServiceAppointment sa,List<WorkOrderLineItem> wo) {
		if (sa == null) 
		{
			System.debug('invalid ServiceAppointment');
		} else if (sa.Work_Order__r.ServiceTerritory == null || sa.Work_Order__r.ServiceTerritory.Site_Account__r == null) {
			System.debug('invalid ServiceTerritory/Site Account - Cannot find site Id');
		} else if (sa.Work_Order__r == null) {
			System.debug('invalid Work Order on ServiceAppointment');
		} else if (sa.Work_Order__r.Account == null ) {
			System.debug('invalid Account on Service Appointment');
		} else if (sa.Work_Order__r.Vehicle__r == null) {
			System.debug('invalid vehicle on Service Appointent - vehicle fields are required');
		}

		// service appointment fields
		this.appointmentId = sa.Id;
		this.appointmentDate = sa.Date_String__c;
		this.appointmentStatus = sa.Status;
		this.consultStartTime = sa.Consult_Start_Time__c;
		this.consultEndTime = sa.Consult_End_Time__c;
		this.backOfficeStartTime = sa.Back_Office_Start_Time__c;
		this.backOfficeEndTime = sa.Back_Office_End_Time__c;
		this.relatedAppointmentId = sa.Related_Appointment__c;
		this.salesforceAppointmentId = sa.Id;
		this.apptRescheduled = sa.Appointment_Rescheduled__c;
		this.apptLastModifiedDate = (sa.Appt_Appointment_Last_Modified_Date__c != null)? String.valueOf(sa.Appt_Appointment_Last_Modified_Date__c):'';
		this.apptLastModifiedBy = sa.Appt_Appointment_Last_Modified_By__c;
		this.originalDateString = sa.Original_Date_String__c;
		this.originalEndTimeString = sa.Original_End_Time_String__c; 
		this.originalStartTimeString = sa.Original_Start_Time_String__c;

		// service territory fields
		this.siteId = sa.Work_Order__r.ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;

		// account fields
		this.salesforceAcccountId = sa.Work_Order__r.AccountId;
		this.posCustomerId = sa.Work_Order__r.Account.POS_Customer_Id__c;
		this.hybrisCustomerId = sa.Work_Order__r.Account.Hybris_Customer_Id__c;
		this.customerGuid = sa.Work_Order__r.Account.GUID__c;
		this.customerType = sa.Work_Order__r.Account.Appt_Customer_Type__c;
        // appt3.0 change start
        this.appt3CustomerId = sa.Work_Order__r.Account.Appt3_Customer_Id__c;
        this.appt3FleetNumber = sa.Work_Order__r.Account.Appt3_Fleet_Number__c;
        this.appt3CompanyName = sa.Work_Order__r.Account.Appt3_Company_Name__c;
        this.appt3AAAMembership= (sa.Work_Order__r.Account.Appt3_AAA_Membership__c != null && sa.Work_Order__r.Account.Appt3_AAA_Membership__c == true) ? 'true':'false';
        this.appt3Military= (sa.Work_Order__r.Account.Appt3_Military__c != null && sa.Work_Order__r.Account.Appt3_Military__c == true) ? 'true':'false';
        this.appt3PrivateLabelCardholder= (sa.Work_Order__r.Account.Appt3_Private_Label_Cardholder__c != null && sa.Work_Order__r.Account.Appt3_Private_Label_Cardholder__c == true) ? 'true':'false';
        // appt3.0 change end

		// work order fields
		this.source = sa.Work_Order__r.Source__c;
		this.orderType = sa.Work_Order__r.Order_Type__c;
		this.formType = sa.Work_Order__r.Form_Type__c;
		this.formNumber = sa.Work_Order__r.Form_Number__c;
		this.formDate = (sa.Work_Order__r.Form_Date__c != null) ? String.valueOf(sa.Work_Order__r.Form_Date__c) : '';
		this.hybrisOrderId = sa.Work_Order__r.Hybris_Order_Id__c;
		this.posWebOrderId = sa.Work_Order__r.POS_Web_Order_Id__c;
		this.layawayNumber = sa.Work_Order__r.Layaway_Number__c;
		this.quoteNumber = sa.Work_Order__r.Quote_Number__c;
		this.invoiceNumber = sa.Work_Order__r.Invoice_Number__c;
		this.orderDate = (sa.Work_Order__r.Order_Date__c != null)? String.valueOf(sa.Work_Order__r.Order_Date__c): '';
		this.comments = sa.Work_Order__r.Appointment_Comments__c;
		this.cancelReason = sa.Work_Order__r.Cancel_Reason__c;
		this.cancelReasonCode = sa.Work_Order__r.Cancel_Reason_Code__c;
        
        // appt3.0 changes start
        this.appt3SalesOrderId= sa.Work_Order__r.Appt3_Sales_Order_Id__c;
        this.appt3FitmentLiftId= sa.Work_Order__r.Vehicle__r.Appt3_Fitment_Lift_Id__c; 
        this.appt3FrontTireSize= sa.Work_Order__r.Vehicle__r.Appt3_Front_Tire_Size__c;
        this.appt3FrontTireDiameter= sa.Work_Order__r.Vehicle__r.Appt3_Front_Tire_Diameter__c;
        this.appt3RearTireDiameter= sa.Work_Order__r.Vehicle__r.Appt3_Rear_Tire_Diameter__c;
        this.appt3AssemblyType= sa.Work_Order__r.Vehicle__r.Appt3_Assembly_Type__c;
        this.appt3Color= sa.Work_Order__r.Vehicle__r.Appt3_Color__c;
        this.appt3GenericVehicleCategory= sa.Work_Order__r.Vehicle__r.Appt3_Generic_Vehicle_Category__c; 
        this.appt3GenericVehicleSubCategory= sa.Work_Order__r.Vehicle__r.Appt3_Generic_Vehicle_SubCategory__c;
        this.appt3CustomerVehicleId= sa.Work_Order__r.Vehicle__r.Appt3_Customer_Vehicle_Id__c;
        this.appt3TypeOfVehicle= sa.Work_Order__r.Vehicle__r.Appt3_Type_Of_Vehicle__c;
        // appt3.0 changes end

		this.storageType = Appt_ConstantValues.STORAGE_TYPE_ARCHIVED;

		// vehicle fields
		if (sa.Work_Order__r.Vehicle__r != null) {
			this.posCustomerVehicleId = sa.Work_Order__r.Vehicle__r.POS_Customer_Vehicle_Id__c;
			this.hybrisCustomerVehicleId = sa.Work_Order__r.Vehicle__r.Hybris_Customer_Vehicle_Id__c;
			this.vehicleType = sa.Work_Order__r.Vehicle__r.Vehicle_Type_Other__c;
			this.year = sa.Work_Order__r.Vehicle__r.Vehicle_Manufacture_Year__c;
			this.make = sa.Work_Order__r.Vehicle__r.Vehicle_Make__c;
			this.model = sa.Work_Order__r.Vehicle__r.Vehicle_Model__c;
			this.vehicleId = sa.Work_Order__r.Vehicle__r.Vehicle_Id__c;
			this.trimId = sa.Work_Order__r.Vehicle__r.Trim_Id__c;
			this.assemblyId = sa.Work_Order__r.Vehicle__r.Assembly_Id__c;
		}
        // appt3.0 changes start
        if (wo != null && wo.size() > 0) {
            this.articles = new List<Appt_ArchivePayloadModel.Articles>();
            for (WorkOrderLineItem woli: wo) {
                Appt_ArchivePayloadModel.Articles a = new Appt_ArchivePayloadModel.Articles();
                a.articleId = woli.WOM_Article_Number__c;
                a.articleSize = woli.WOM_ArticleSize__c;
                a.articleType = woli.Appt3_Article_Type__c;
                a.articleQuantity = String.valueOf(woli.WOM_Article_Quantity__c);
                a.tredWell = woli.Appt3_Treadwell__c;
                a.articleDescription = woli.WOM_Article_Description__c;
                this.articles.add(a);
            }
        }  
        // appt3.0 changes end
	}

}