public class Appt_InventoryService extends Appt_BaseIntegrationService{
    public static String lprefix = 'APT_INVENT_SERV: ';

    public static Boolean isTest = false;
    public static String testPayload = '';

    //---Get Inventory detail for Site and ArticleId - Need to provide Article Id, along with the Side Id
    public static Appt_InventoryModel getInventory(String siteId, String articleId) {
        System.debug(lprefix+'getInventory():ENTRY siteId=' + siteId + ' articleId='+articleId);

        Appt_InventoryModel inventoryModel = new Appt_InventoryModel();

        //-- validate params
        if (String.isBlank(siteId) || String.isBlank(articleId)) {
            inventoryModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_BAD_REQUEST, 'One or more required ID params for getInventory() are null or blank. SiteId:' + siteId + ', articleId:' + articleId);
            System.debug( lprefix + '    ERROR - return inventoryModel: ' + inventoryModel);
            return inventoryModel;
        }

        String endUrl = BaseIntegrationUtil.getSettingValue( Appt_ConstantValues.INTEGRATION_SETTING_INVENTORY_URL, Appt_ConstantValues.INTEGRATION_SETTING_SYSTEM_APPOINTMENT);
        endUrl += siteId + '?articleId='+articleId;
        System.debug( lprefix + '    APPT Inventory Integration endUrl: ' + endUrl);

        Int_Message__c intMsg = new Int_Message__c(Type__c=Int_Values.TYPE_INVENTORY, Status__c=Int_Values.STATUS_PENDING, Url__c=endUrl);

        String body = '';

        if (isTest) {
            body = testPayload;
        } else {
            HttpRequest req = buildAppointmentHttpReq( endUrl);
            System.debug( lprefix + 'HttpRequest: '+req);

            body = BaseIntegrationUtil.getRequestBody(req, intMsg);
            System.debug( lprefix + 'Request Body: '+body);
            upsert intMsg;
            
            if (body == null || body == '') {
                inventoryModel.setError(Appt_ConstantValues.RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR, 'Request for Inventory FAILED for SiteId:' + siteId + ', articleId:' + articleId);
                System.debug( lprefix + '    ERROR - inventoryModel: ' + inventoryModel);
                return inventoryModel;
            } 
        }

        inventoryModel = Appt_InventoryModel.parse(body);
        inventoryModel.status = Appt_ConstantValues.RESPONSE_STATUS_SUCCESS;

        System.debug(lprefix+'getInventory():EXIT - return inventoryModel:' + inventoryModel);
        return inventoryModel;
    }
}