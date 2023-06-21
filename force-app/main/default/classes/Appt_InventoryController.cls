public class Appt_InventoryController {
    public static String lprefix = 'APT_INVENT_CONT: ';


    public static Appt_InventoryModel getInventory(String siteId, String articleId)
    {
        System.debug(lprefix+'getInventory():ENTRY siteId=' + siteId + ', articleId='+articleId);

        return Appt_InventoryService.getInventory(siteId, articleId);
    }    
    
    //Appt 3.0 - Pass through method that calls another method to fetch on hand inventory details from CAR  
    public static Appt3_InventoriesModelResponse getInventoryItems(Appt3_InventoriesModelRequest inventoryLineItems)
    {
        System.debug(lprefix+'Appt_InvoiceDetailModel():ENTRY inventoryLineItems' + inventoryLineItems);
        return Appt_InventoryService.getInventoryDetails(inventoryLineItems);
    }        
}