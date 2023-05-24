public class Appt_InventoryController {
    public static String lprefix = 'APT_INVENT_CONT: ';


    public static Appt_InventoryModel getInventory(String siteId, String articleId)
    {
        System.debug(lprefix+'getInventory():ENTRY siteId=' + siteId + ', articleId='+articleId);

        return Appt_InventoryService.getInventory(siteId, articleId);
    }    
}