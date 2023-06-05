public with sharing class Fleet_AccountStatusRefreshController {
    
    public static String lprefix = 'FLEET_INT_UTIL:';

    @AuraEnabled
    public static string updatePageData(String sfAccountId) 
    {
        String returnValue = '';

        System.debug( lprefix + 'Recieved request to update Account :' + sfAccountId + ' from SAP  START');

        if (sfAccountId == null || sfAccountId == '')
        {
            String warningMessage = 'Invalid Account Id received';
            System.debug( lprefix + warningMessage);

            returnValue = warningMessage; 
        }
        else 
        {
            //---Getting the Account
            List<Account> accountList = [SELECT Id, Name, ECC_Account_Number__c FROM Account WHERE Id = :sfAccountId];

            if (accountList == null || accountList.size() == 0)
            {
                String warningMessage = 'No Accounts found for Account Id:' + sfAccountId;
                System.debug( lprefix + warningMessage);

                returnValue = warningMessage;
            }
            else 
            {
                Account selAccount = accountList[0];

                if (selAccount.ECC_Account_Number__c == null || selAccount.ECC_Account_Number__c == '')
                {
                    String warningMessage = 'Selected Account does not have an SAP number: ' + selAccount;
                    System.debug( lprefix + warningMessage);

                    returnValue = warningMessage;
                }
                else 
                {
                    Fleet_B2BCustomerService.getB2BCustomerData(selAccount.ECC_Account_Number__c);    
                }
            }
        }

        System.debug( lprefix + 'Recieved request to update Account END');

       return returnValue;
    }
}