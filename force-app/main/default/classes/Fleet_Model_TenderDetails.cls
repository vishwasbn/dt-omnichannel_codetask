public class Fleet_Model_TenderDetails {
    public Fleet_Model_TenderDetails() {

    }

    public Fleet_Model_TenderDetails(String tenderTypeCode, Decimal tenderAmount) {
        this.tenderTypeCode = tenderTypeCode;
        this.tenderAmount = tenderAmount;
    }

    private String tenderTypeCode;
    private Decimal tenderAmount;

	public String getTenderTypeCode() {
		return this.tenderTypeCode;
	}

	public void setTenderTypeCode(String tenderTypeCode) {
		this.tenderTypeCode = tenderTypeCode;
	}

	public Decimal getTenderAmount() {
		return this.tenderAmount;
	}

	public void setTenderAmount(Decimal tenderAmount) {
		this.tenderAmount = tenderAmount;
	}

	public static List<Fleet_Model_TenderDetails> build( List<Fleet_CarDetailModel.TenderDetails> inputList)
	{
		List<Fleet_Model_TenderDetails> retList = new List<Fleet_Model_TenderDetails>();

		if (inputList != null)
		{
			for (Fleet_CarDetailModel.TenderDetails inputRow : inputList)
			{
				Fleet_Model_TenderDetails newItem = new Fleet_Model_TenderDetails();
				newItem.tenderTypeCode = convertToDisplayFormat(inputRow.tenderTypeCode);
				newItem.tenderAmount = inputRow.tenderAmount;

				retList.add( newItem);
			}
		}

		return retList;
    }
    
    private static String convertToDisplayFormat(String carTenderCode)
    {
        List<Fleet_Invoice_Tender_Code__mdt> codeList = null;
        if ( String.isNotBlank(carTenderCode) ) 
        {
            codeList = [SELECT Id, CAR__c, Display_in_Salesforce__c FROM Fleet_Invoice_Tender_Code__mdt WHERE CAR__c =: carTenderCode];
        }

        return ( ( (codeList == null) || (codeList.size() < 1) ) ? '' : codeList[0].Display_in_Salesforce__c );
    }
}