public class Fleet_Model_LineItems {
    public Fleet_Model_LineItems() {}

    private String articleNumber;
    private Decimal retailQuantity;
    private String storeSize;
    private String storeDescription;
    private Decimal actualUnitPrice;
    private Decimal fet;
    private Decimal totalSalesAmount;
    private String vehicleMake;
    private String vehicleModel;
    private String vehicleYear;
    private String mileage;
    private String poNumber;
    private List<Fleet_Model_Discounts> discounts;

	public String getArticleNumber() {
		return this.articleNumber;
	}

	public void setArticleNumber(String articleNumber) {
		this.articleNumber = articleNumber;
	}

	public Decimal getRetailQuantity() {
		return this.retailQuantity;
	}

	public void setRetailQuantity(Decimal retailQuantity) {
		this.retailQuantity = retailQuantity;
	}

	public String getStoreSize() {
		return this.storeSize;
	}

	public void setStoreSize(String storeSize) {
		this.storeSize = storeSize;
	}

	public String getStoreDescription() {
		return this.storeDescription;
	}

	public void setStoreDescription(String storeDescription) {
		this.storeDescription = storeDescription;
	}

	public Decimal getActualUnitPrice() {
		return this.actualUnitPrice;
	}

	public void setActualUnitPrice(Decimal actualUnitPrice) {
		this.actualUnitPrice = actualUnitPrice;
	}

	public Decimal getFet() {
		return this.fet;
	}

	public void setFet(Decimal fet) {
		this.fet = fet;
	}

	public Decimal getTotalSalesAmount() {
		return this.totalSalesAmount;
	}

	public void setTotalSalesAmount(Decimal totalSalesAmount) {
		this.totalSalesAmount = totalSalesAmount;
	}

	public String getVehicleMake() {
		return this.vehicleMake;
	}

	public void setVehicleMake(String vehicleMake) {
		this.vehicleMake = vehicleMake;
	}

	public String getVehicleModel() {
		return this.vehicleModel;
	}

	public void setVehicleModel(String vehicleModel) {
		this.vehicleModel = vehicleModel;
	}

	public String getVehicleYear() {
		return this.vehicleYear;
	}

	public void setVehicleYear(String vehicleYear) {
		this.vehicleYear = vehicleYear;
	}

	public String getMileage() {
		return this.mileage;
	}

	public void setMileage(String mileage) {
		this.mileage = mileage;
	}

	public String getPoNumber() {
		return this.poNumber;
	}

	public void setPoNumber(String poNumber) {
		this.poNumber = poNumber;
	}

	public List<Fleet_Model_Discounts> getDiscounts() {
		return this.discounts;
	}

	public void setDiscounts(List<Fleet_Model_Discounts> discounts) {
		this.discounts = discounts;
	}


	public static List<Fleet_Model_LineItems> build( List<Fleet_CarDetailModel.LineItems> inputList)
	{
		List<Fleet_Model_LineItems> retList = new List<Fleet_Model_LineItems>();

		if (inputList != null)
		{
			for (Fleet_CarDetailModel.LineItems inputRow : inputList)
			{
				Fleet_Model_LineItems newItem = new Fleet_Model_LineItems();
				newItem.articleNumber = inputRow.articleNumber;
				newItem.retailQuantity  = inputRow.retailQuantity;
				newItem.storeSize = inputRow.storeSize;
				newItem.storeDescription = inputRow.storeDescription;
				newItem.actualUnitPrice = inputRow.actualUnit_price;
				newItem.fet = inputRow.fet;
				newItem.totalSalesAmount = inputRow.totalSalesAmount;
				newItem.vehicleMake = inputRow.vehicleMake;
				newItem.vehicleModel = inputRow.vehicleModel;
				newItem.vehicleYear = inputRow.vehicleYear;
				newItem.mileage = inputRow.mileage;
				newItem.poNumber = inputRow.poNumber;

				newItem.discounts = Fleet_Model_Discounts.build( inputRow.discounts);

				retList.add( newItem);
			}
		}

		return retList;
	}

}