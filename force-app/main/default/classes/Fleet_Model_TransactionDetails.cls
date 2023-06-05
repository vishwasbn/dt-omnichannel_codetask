/**
 * This class represents a Transaction Details object for the CAR invoice API
 */
public with sharing class Fleet_Model_TransactionDetails {
    public Fleet_Model_TransactionDetails() {

    }

    public Fleet_Model_TransactionDetails(String name, String value) {
        this.name = name;
        this.value = value;
    }

    private String name;
    private String value;

	public String getName() {
		return this.name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getValue() {
		return this.value;
	}

	public void setValue(String value) {
		this.value = value;
	}

	//---Method to convert from the Inner Class structures to these structures 
	public static List<Fleet_Model_TransactionDetails> build( List<Fleet_CarDetailModel.TransactionDetails> inputList)
	{
		List<Fleet_Model_TransactionDetails> retList = new List<Fleet_Model_TransactionDetails>();

		if (inputList != null)
		{
			for (Fleet_CarDetailModel.TransactionDetails inputRow : inputList)
			{
				Fleet_Model_TransactionDetails newItem = new Fleet_Model_TransactionDetails();
				newItem.name = inputRow.name;
				newItem.value = inputRow.value;
			
				retList.add( newItem);
			}
		}

		return retList;
	}

	//---Method to convert from the Inner Class structures to these structures 
	public static List<Fleet_Model_TransactionDetails> build( List<Fleet_CarSummaryModel.TransactionDetails> inputList)
	{
		List<Fleet_Model_TransactionDetails> retList = new List<Fleet_Model_TransactionDetails>();

		if (inputList != null)
		{
			for (Fleet_CarSummaryModel.TransactionDetails inputRow : inputList)
			{
				Fleet_Model_TransactionDetails newItem = new Fleet_Model_TransactionDetails();
				newItem.name = inputRow.name;
				newItem.value = inputRow.value;
			
				retList.add( newItem);
			}
		}

		return retList;
	}
}