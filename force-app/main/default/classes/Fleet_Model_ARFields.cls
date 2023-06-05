public class Fleet_Model_ARFields {

    public Fleet_Model_ARFields() {}

    private String driverName;
    private String companyName;
    private String streetAdd;
    private String arVehicleYear;
    private String arVehicleMake;
    private String arVehicleModel;
    private String arLicensePlateNumber;
    private String arLicensePlateState;
    private String vin;
    private String arMileage;
    private String fleetCardNumber;
    private String stockNumber;
    private String unitNumber;
    private String fleetNumber;
    private String fleetCardExpDt;
    private String id_JobNumber;
    private String arDriverLicense;
    private String arCity;
    private String arState;
    private String arZip;

	public String getDriverName() {
		return this.driverName;
	}

	public void setDriverName(String driverName) {
		this.driverName = driverName;
	}

	public String getCompanyName() {
		return this.companyName;
	}

	public void setCompanyName(String companyName) {
		this.companyName = companyName;
	}

	public String getStreetAdd() {
		return this.streetAdd;
	}

	public void setStreetAdd(String streetAdd) {
		this.streetAdd = streetAdd;
	}

	public String getArVehicleYear() {
		return this.arVehicleYear;
	}

	public void setArVehicleYear(String arVehicleYear) {
		this.arVehicleYear = arVehicleYear;
	}

	public String getArVehicleMake() {
		return this.arVehicleMake;
	}

	public void setArVehicleMake(String arVehicleMake) {
		this.arVehicleMake = arVehicleMake;
	}

	public String getArVehicleModel() {
		return this.arVehicleModel;
	}

	public void setArVehicleModel(String arVehicleModel) {
		this.arVehicleModel = arVehicleModel;
	}

	public String getArLicensePlateNumber() {
		return this.arLicensePlateNumber;
	}

	public void setArLicensePlateNumber(String arLicensePlateNumber) {
		this.arLicensePlateNumber = arLicensePlateNumber;
	}

	public String getArLicensePlateState() {
		return this.arLicensePlateState;
	}

	public void setArLicensePlateState(String arLicensePlateState) {
		this.arLicensePlateState = arLicensePlateState;
	}

	public String getVin() {
		return this.vin;
	}

	public void setVin(String vin) {
		this.vin = vin;
	}

	public String getArMileage() {
		return this.arMileage;
	}

	public void setArMileage(String arMileage) {
		this.arMileage = arMileage;
	}

	public String getFleetCardNumber() {
		return this.fleetCardNumber;
	}

	public void setFleetCardNumber(String fleetCardNumber) {
		this.fleetCardNumber = fleetCardNumber;
	}

	public String getStockNumber() {
		return this.stockNumber;
	}

	public void setStockNumber(String stockNumber) {
		this.stockNumber = stockNumber;
	}

	public String getUnitNumber() {
		return this.unitNumber;
	}

	public void setUnitNumber(String unitNumber) {
		this.unitNumber = unitNumber;
	}

	public String getFleetNumber() {
		return this.fleetNumber;
	}

	public void setFleetNumber(String fleetNumber) {
		this.fleetNumber = fleetNumber;
	}

	public String getFleetCardExpDt() {
		return this.fleetCardExpDt;
	}

	public void setFleetCardExpDt(String fleetCardExpDt) {
		this.fleetCardExpDt = fleetCardExpDt;
	}

	public String getId_JobNumber() {
		return this.id_JobNumber;
	}

	public void setId_JobNumber(String id_JobNumber) {
		this.id_JobNumber = id_JobNumber;
	}

	public String getArDriverLicense() {
		return this.arDriverLicense;
	}

	public void setArDriverLicense(String arDriverLicense) {
		this.arDriverLicense = arDriverLicense;
	}

	public String getArCity() {
		return this.arCity;
	}

	public void setArCity(String arCity) {
		this.arCity = arCity;
	}

	public String getArState() {
		return this.arState;
	}

	public void setArState(String arState) {
		this.arState = arState;
	}

	public String getArZip() {
		return this.arZip;
	}

	public void setArZip(String arZip) {
		this.arZip = arZip;
	}

	public static Fleet_Model_ARFields build( Fleet_CarDetailModel.ArFields inputRow)
	{
		Fleet_Model_ARFields newItem = new Fleet_Model_ARFields();
		newItem.driverName = inputRow.driverName;
		newItem.companyName  = inputRow.companyName;
		newItem.streetAdd = inputRow.streetAdd;
		newItem.arVehicleYear = inputRow.arVehicleYear;
		newItem.arVehicleMake = inputRow.arVehicleMake;
		newItem.arVehicleModel = inputRow.arVehicleModel;
		newItem.arLicensePlateNumber = inputRow.arLicensePlateNumber;
		newItem.arLicensePlateState = inputRow.arLicensePlateState;
		newItem.vin = inputRow.vin;
		newItem.arMileage = inputRow.arMileage;
		newItem.fleetCardNumber = inputRow.fleetCardNumber;
		newItem.stockNumber = inputRow.stockNumber;
		newItem.unitNumber = inputRow.unitNumber;
		newItem.fleetNumber = inputRow.fleetNumber;
		newItem.fleetCardExpDt = inputRow.fleetCardExpDt;
		newItem.id_JobNumber = inputRow.id_JobNumber;
		newItem.arDriverLicense = inputRow.arDriverLicense;
		newItem.arCity = inputRow.arCity;
		newItem.arState = inputRow.arState;
		newItem.arZip = inputRow.arZip;

		return newItem;
	}
}