public class Fleet_Model_Discounts {
    public Fleet_Model_Discounts() {}

    public Fleet_Model_Discounts(String typeCode, String reasonCode, String itemDescription) {
        this.typeCode = typeCode;
        this.reasonCode = reasonCode;
        this.itemDescription = itemDescription;
    }

    private String typeCode;
    private String reasonCode;
    private String itemDescription;

	public String getTypeCode() {
		return this.typeCode;
	}

	public void setTypeCode(String typeCode) {
		this.typeCode = typeCode;
	}

	public String getReasonCode() {
		return this.reasonCode;
	}

	public void setReasonCode(String reasonCode) {
		this.reasonCode = reasonCode;
	}

	public String getItemDescription() {
		return this.itemDescription;
	}

	public void setItemDescription(String itemDescription) {
		this.itemDescription = itemDescription;
	}

	public static List<Fleet_Model_Discounts> build( List<Fleet_CarDetailModel.Discounts> inputList)
	{
		List<Fleet_Model_Discounts> retList = new List<Fleet_Model_Discounts>();

		if (inputList != null)
		{
			for (Fleet_CarDetailModel.Discounts inputRow : inputList)
			{
				Fleet_Model_Discounts newItem = new Fleet_Model_Discounts();
				newItem.typeCode = inputRow.typeCode;
				newItem.reasonCode  = inputRow.reasonCode;
				newItem.itemDescription = inputRow.itemDescription;

				retList.add( newItem);
			}
		}

		return retList;
	}
}