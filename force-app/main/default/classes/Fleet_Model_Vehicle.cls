/**
 * This class represents a Vehicle object for the CAR invoice API
 */
public with sharing class Fleet_Model_Vehicle {
	public static final Integer YEAR_VALUE_MIN = 1883; //Mercedes-Benz – Founded 1883 
	public static final String MAKE_VALUE_NONE = '<NONE>';
	public static final String MODEL_VALUE_NONE = '<NONE>';
	
    public Fleet_Model_Vehicle() {

    }

    public Fleet_Model_Vehicle(Integer year, String make, String model) {
        this.year = year;
        this.make = make;
        this.model = model;
    }

    private Integer year;
    private String make;
    private String model;



	// DTFS-348 - If there are no vehicles associated with the Invoice, then JSON contains {"year": "0000","make": "<NONE>","model": "<NONE>"}
	// If no vehicle JSON received, return null
    public String getVehicleDescription() {

		if (year > YEAR_VALUE_MIN && make != MAKE_VALUE_NONE && model != MODEL_VALUE_NONE) {
			return year + ' ' + make + ' ' + model;
		} else {
			return null;
		}
    }

	public Integer getYear() {
		return this.year;
	}

	public void setYear(Integer year) {
		this.year = year;
	}

	public String getMake() {
		return this.make;
	}

	public void setMake(String make) {
		this.make = make;
	}

	public String getModel() {
		return this.model;
	}

	public void setModel(String model) {
		this.model = model;
	}

	//---Method to convert from the Inner Class structures to these structures
	public static List<Fleet_Model_Vehicle> build( List<Fleet_CarSummaryModel.Vehicle> inputList)
	{
		List<Fleet_Model_Vehicle> retList = new List<Fleet_Model_Vehicle>();

		if (inputList != null)
		{
			for (Fleet_CarSummaryModel.Vehicle inputRow : inputList)
			{
				Fleet_Model_Vehicle newItem = new Fleet_Model_Vehicle();
				newItem.make = inputRow.make;
				newItem.model = inputRow.model;
                if(String.isNotBlank(String.valueOf(inputRow.year)))
					newItem.year = Integer.valueOf( inputRow.year);
			
				retList.add( newItem);
			}
		}

		return retList;
	}
}