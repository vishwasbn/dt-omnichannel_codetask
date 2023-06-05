public class Fleet_Model_InvoiceSummaryDisplayable {

    public Fleet_Model_InvoiceSummaryDisplayable() {

    }

    private String invoiceId;
    private String transactionDate;
    private String store;
    private String storeId;
    private Decimal totalAmount;
    private String vehicle;
    private Boolean certificate;
	private String vinNumber;
    private String poNumber;

	public String getVehicle() {
		return this.vehicle;
	}

	public void setVehicle(String vehicle) {
		this.vehicle = vehicle;
	}

	public String getInvoiceId() {
		return this.invoiceId;
	}

	public void setInvoiceId(String invoiceId) {
		this.invoiceId = invoiceId;
	}

	public String getTransactionDate() {
		return this.transactionDate;
	}

	public void setTransactionDate(String transactionDate) {
		this.transactionDate = transactionDate;
	}

	public String getStore() {
		return this.store;
	}

	public void setStore(String store) {
		this.store = store;
	}

	public String getStoreId() {
		return this.storeId;
	}

	public void setStoreId(String storeId) {
		this.storeId = storeId;
	}

	public Decimal getTotalAmount() {
		return this.totalAmount;
	}

	public void setTotalAmount(Decimal totalAmount) {
		this.totalAmount = totalAmount;
	}

	public Boolean getCertificate() {
		return this.certificate;
	}

	public void setCertificate(Boolean certificate) {
		this.certificate = certificate;
	}

	public String getVinNumber() {
		return this.vinNumber;
	}

	public void setVinNumber(String vinNumber) {
		this.vinNumber = vinNumber;
	}

	public String getPoNumber() {
		return this.poNumber;
	}

	public void setPoNumber(String poNumber) {
		this.poNumber = poNumber;
	}

}