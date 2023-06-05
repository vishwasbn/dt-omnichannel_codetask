public with sharing class Fleet_Model_OrderHistorySummary {
    public final static String ID_TRANSDETAIL_CODE = 'TRANSNUMBER';

    public Fleet_Model_OrderHistorySummary() {

    }

    private String transactionType;
    private Decimal totalAmount;
    private String siteId;
    private String businessdayDate;
    private Boolean isCertificateAllowed;
    private String storeName;
    private List<Fleet_Model_Vehicle> vehicles;
    private List<Fleet_Model_TransactionDetails> transactionDetails;
    private String vinNumber;
    private String poNumber;

    // DTFS-348 - Loop through transactionDetails array and find the TRANSNUMBER item, which is the InvoiceId
    // If no TRANSNUMBER item found, return null
    public String getInvoiceId() {
        if (transactionDetails != null && transactionDetails.size() > 0) {
            Boolean idFound = false;
            for (Fleet_Model_TransactionDetails item: transactionDetails) {
                if (item.getName() != null && item.getName() == ID_TRANSDETAIL_CODE) {
                    try {
                        return String.valueOf(Integer.valueOf(item.getValue()));
                    } catch (Exception e) {
                         //Logger logInstance = Logger.getInstance();
                         //logInstance.log('Model Order History Summary', 'Fleet_Model_OrderHistorySummary', e);
                        return item.getValue();
                    }
                }
            }
            //no TRANSNUMBER item found in array of Fleet_Model_TransactionDetails, returning null
            return null;
        } else {
            return null;
        }
    }

    public String getVehicle() {
        if (vehicles != null && vehicles.size() > 0) {
            return vehicles.get(0).getVehicleDescription();
        } else {
            return null;
        }
    }

    public List<Fleet_Model_Vehicle> getVehicles() {
        return this.vehicles;
    }

    public void setVehicles(List<Fleet_Model_Vehicle> vehicles) {
        this.vehicles = vehicles;
    }

    public List<Fleet_Model_TransactionDetails> getTransactionDetails() {
        return this.transactionDetails;
    }

    public void setTransactionDetails(List<Fleet_Model_TransactionDetails> transactionDetails) {
        this.transactionDetails = transactionDetails;
    }


    public String getTransactionType() {
        return this.transactionType;
    }

    public void setTransactionType(String transactionType) {
        this.transactionType = transactionType;
    }

    public Decimal getTotalAmount() {
        return this.totalAmount;
    }

    public void setTotalAmount(Decimal totalAmount) {
        this.totalAmount = totalAmount;
    }

    public String getSiteId() {
        return this.siteId;
    }

    public void setSiteId(String siteId) {
        this.siteId = siteId;
    }

    public String getBusinessdayDate() {
        return this.businessdayDate;
    }

    public void setBusinessdayDate(String businessdayDate) {
        this.businessdayDate = businessdayDate;
    }

    public Boolean getIsCertificateAllowed() {
        return this.isCertificateAllowed;
    }

    public void setIsCertificateAllowed(Boolean isCertificateAllowed) {
        this.isCertificateAllowed = isCertificateAllowed;
    }
    
    public String getStoreName() {
        return this.storeName;
    }

    public void setStoreName(String storeName) {
        this.storeName = storeName;
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


    //---Method to convert from the Inner Class structures to these structures
    public static List<Fleet_Model_OrderHistorySummary> build( List<Fleet_CarSummaryModel.OrderHistorySummary> inputList)
    {
        List<Fleet_Model_OrderHistorySummary> retList = new List<Fleet_Model_OrderHistorySummary>();

        if (inputList != null)
        {
            for (Fleet_CarSummaryModel.OrderHistorySummary inputRow : inputList)
            {
                Fleet_Model_OrderHistorySummary newItem = new Fleet_Model_OrderHistorySummary();
                newItem.transactionType = inputRow.transactionType;
                newItem.totalAmount = inputRow.totalAmount;
                newItem.siteId = inputRow.siteId;
                newItem.businessdayDate = inputRow.businessdayDate;
                newItem.isCertificateAllowed = Boolean.valueOf(inputRow.isCertificateAllowed);

                newItem.vehicles = Fleet_Model_Vehicle.build( inputRow.vehicle);
                newItem.transactionDetails = Fleet_Model_TransactionDetails.build( inputRow.transactionDetails);
                newItem.vinNumber = inputRow.vinNumber;
                newItem.poNumber = inputRow.poNumber;
            
                retList.add( newItem);
            }
        }
    
        return retList;
    }
}