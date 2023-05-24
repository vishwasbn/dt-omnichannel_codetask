public class Fleet_Model_OrderHistoryDetails {

    public Fleet_Model_OrderHistoryDetails() {}

    private String siteId;
    private Decimal totalAmount;
    private String businessdayDate;
    private String invoiceNumber;
    private String addressLine1;
    private String addressLine2;
    private String city;
    private String state;
    private String zipCode;
    private String county;
    private String workPhone;
    private String arCustomerAccountNumber;
    private String arCustomerAccountName;
    private String taxId;
    private Decimal taxAmount;
    private Decimal discountAmount;
    private String employeeName;
    private String timeStamp;
    private List<Fleet_Model_TenderDetails> tenderDetails;
    private List<Fleet_Model_TransactionDetails> transactionDetails;
    private List<Fleet_Model_LineItems> lineItems;
    private Fleet_Model_ARFields arFields;

	public String getSiteId() {
		return this.siteId;
	}

	public void setSiteId(String siteId) {
		this.siteId = siteId;
	}

	public Decimal getTotalAmount() {
		return this.totalAmount;
	}

	public void setTotalAmount(Decimal totalAmount) {
		this.totalAmount = totalAmount;
	}

	public String getBusinessdayDate() {
		return this.businessdayDate;
	}

	public void setBusinessdayDate(String businessdayDate) {
		this.businessdayDate = businessdayDate;
	}

	public String getInvoiceNumber() {
		return this.invoiceNumber;
	}

	public void setInvoiceNumber(String invoiceNumber) {
		this.invoiceNumber = invoiceNumber;
	}

	public String getAddressLine1() {
		return this.addressLine1;
	}

	public void setAddressLine1(String addressLine1) {
		this.addressLine1 = addressLine1;
	}

	public String getAddressLine2() {
		return this.addressLine2;
	}

	public void setAddressLine2(String addressLine2) {
		this.addressLine2 = addressLine2;
	}

	public String getCity() {
		return this.city;
	}

	public void setCity(String city) {
		this.city = city;
	}

	public String getState() {
		return this.state;
	}

	public void setState(String state) {
		this.state = state;
	}

	public String getZipCode() {
		return this.zipCode;
	}

	public void setZipCode(String zipCode) {
		this.zipCode = zipCode;
	}

	public String getCounty() {
		return this.county;
	}

	public void setCounty(String county) {
		this.county = county;
	}

	public String getWorkPhone() {
		return this.workPhone;
	}

	public void setWorkPhone(String workPhone) {
		this.workPhone = workPhone;
	}

	public String getArCustomerAccountNumber() {
		return this.arCustomerAccountNumber;
	}

	public void setArCustomerAccountNumber(String arCustomerAccountNumber) {
		this.arCustomerAccountNumber = arCustomerAccountNumber;
	}

	public String getArCustomerAccountName() {
		return this.arCustomerAccountName;
	}

	public void setArCustomerAccountName(String arCustomerAccountName) {
		this.arCustomerAccountName = arCustomerAccountName;
	}

	public String getTaxId() {
		return this.taxId;
	}

	public void setTaxId(String taxId) {
		this.taxId = taxId;
	}

	public Decimal getTaxAmount() {
		return this.taxAmount;
	}

	public void setTaxAmount(Decimal taxAmount) {
		this.taxAmount = taxAmount;
	}

	public Decimal getDiscountAmount() {
		return this.discountAmount;
	}

	public void setDiscountAmount(Decimal discountAmount) {
		this.discountAmount = discountAmount;
	}

	public String getEmployeeName() {
		return this.employeeName;
	}

	public void setEmployeeName(String employeeName) {
		this.employeeName = employeeName;
	}

	public String getTimeStamp() {
		return this.timeStamp;
	}

	public void setTimeStamp(String timeStamp) {
		this.timeStamp = timeStamp;
	}

	public List<Fleet_Model_TenderDetails> getTenderDetails() {
		return this.tenderDetails;
	}

	public void setTenderDetails(List<Fleet_Model_TenderDetails> tenderDetails) {
		this.tenderDetails = tenderDetails;
	}

	public List<Fleet_Model_TransactionDetails> getTransactionDetails() {
		return this.transactionDetails;
	}

	public void setTransactionDetails(List<Fleet_Model_TransactionDetails> transactionDetails) {
		this.transactionDetails = transactionDetails;
	}

	public List<Fleet_Model_LineItems> getLineItems() {
		return this.lineItems;
	}

	public void setLineItems(List<Fleet_Model_LineItems> lineItems) {
		this.lineItems = lineItems;
	}

	public Fleet_Model_ARFields getArFields() {
		return this.arFields;
	}

	public void setArFields(Fleet_Model_ARFields arFields) {
		this.arFields = arFields;
	}

	public static Fleet_Model_OrderHistoryDetails build( Fleet_CarDetailModel.OrderHistoryDetails inModel)
	{
		Fleet_Model_OrderHistoryDetails outModel = new Fleet_Model_OrderHistoryDetails();
		outModel.setSiteId('' + inModel.siteId);
    	outModel.setTotalAmount(inModel.totalAmount);
    	outModel.setBusinessdayDate(inModel.businessdayDate);
    	outModel.setInvoiceNumber(inModel.invoiceNumber);
    	outModel.setAddressLine1(inModel.addressLine1);
    	outModel.setAddressLine2(inModel.addressLine2);
    	outModel.setCity(inModel.city);
    	outModel.setState(inModel.state);
    	outModel.setZipCode(inModel.zipCode);
    	outModel.setCounty(inModel.county);
    	outModel.setWorkPhone(inModel.workPhone);
    	outModel.setArCustomerAccountNumber(inModel.arCustomerAccountNumber);
    	outModel.setArCustomerAccountName(inModel.arCustomerAccountName);
    	outModel.setTaxId(inModel.taxId);
    	outModel.setTaxAmount(inModel.taxAmount);
    	outModel.setDiscountAmount(inModel.discountAmount);
    	outModel.setEmployeeName(inModel.employeeName);
		outModel.setTimeStamp(inModel.timeStamp);
		
    	outModel.setTenderDetails(Fleet_Model_TenderDetails.build( inModel.tenderDetails));
    	outModel.setTransactionDetails(Fleet_Model_TransactionDetails.build( inModel.transactionDetails));
    	outModel.setLineItems(Fleet_Model_LineItems.build( inModel.lineItems));
    	outModel.setArFields(Fleet_Model_ARFields.build( inModel.arFields));

		return outModel;
	}

}