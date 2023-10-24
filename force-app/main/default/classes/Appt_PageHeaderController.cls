public with sharing class Appt_PageHeaderController {
    public final static string lprefix  = 'Appt_PageHeaderController: ';

    @AuraEnabled
    public static string retrieveSiteIdAddressStringBySiteId(string siteId){
        try {
            System.debug('start Appt_PageHeaderController::retrieveSiteIdAddressStringBySiteId');
            List<Account> siteAccount = [SELECT Store_ID__c, ShippingStreet, Store_DBA_Name__c FROM Account WHERE SAP_STORE_ID__c = :siteId];
            System.debug('Appt_PageHeaderController::retrieveSiteIdAddressStringBySiteId records: ' + siteAccount.size());
			 if ( Test.isRunningTest() )
            {
                if(siteId.contains('exception')){
                    throw new Appt_ApptDayOfReminderSchedulerException(); 
                }
            }
            if(siteAccount.size() == 0 ){
                return 'No Store Found';
            }

            String returnString = '';
            if(siteAccount[0].Store_ID__c == NULL){
                returnString += 'No Store Id Found';
            }
            else {
                returnString += siteAccount[0].Store_ID__c;
            }

            returnString += ' - ';

            if(siteAccount[0].ShippingStreet == NULL){
                returnString += 'No Store Address Found';
            }
            else {
                returnString +=siteAccount[0].ShippingStreet;
            }

            returnString += '--';
            
            System.debug('Appt_PageHeaderController::retrieveSiteIdAddressStringBySiteId::Brand: ' + siteAccount[0].Store_DBA_Name__c);
            if( String.isNotBlank(siteAccount[0].Store_DBA_Name__c) && 
                siteAccount[0].Store_DBA_Name__c.contains('AMERICA') ){
                returnString += 'AMERICAS TIRE';
            } else {
                returnString += 'DISCOUNT TIRE';
            }

            System.debug('end Appt_PageHeaderController::retrieveSiteIdAddressStringBySiteId');
            
            return returnString;
        }
       catch (Exception e) {        
           //Addedd for SO-41: Added logInstance 
           Logger logInstance = Logger.getInstance();
           
           String errDetails = 'Cause: '+ e.getCause() +'\n';
           errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
           errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
           errDetails = errDetails + 'Message: '+ e.getMessage();
           logInstance.Log(LPREFIX, Appt_PageHeaderController.class.getName(), errDetails); // SO-41 END
            throw new AuraHandledException(e.getMessage());
            
        }
    }
}