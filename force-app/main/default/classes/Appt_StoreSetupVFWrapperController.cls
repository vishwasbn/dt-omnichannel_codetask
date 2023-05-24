/**
 * @author Mitchell Corbin (mitchell.corbin@appsassociates.com)
 * @date 5/19/22
 * @description Controller class used with the Appt_AutomatedStoreSetupVFWrapper Visualforce page
 */

public class Appt_StoreSetupVFWrapperController {
    public String currentUserEmail { get; set; }
    public String selectedStoreSetupImportIdsString { get; set; }

    public Appt_StoreSetupVFWrapperController(ApexPages.StandardSetController stdSetController) {
        //Initialize Strings that will be used to send the current User's Email and the selected Store Setup Import record Ids to the LWC
        currentUserEmail = UserInfo.getUserEmail();
        selectedStoreSetupImportIdsString = '';

        //Retrieve Ids of the Store Setup Import records that were selected from the List View (if any)
        List<String> selectedStoreSetupImportIds = new List<String>();
        for (Store_Setup_Import__c i : (List<Store_Setup_Import__c>)stdSetController.getSelected()) {
            selectedStoreSetupImportIds.add(i.Id);
        }

        if (!selectedStoreSetupImportIds.isEmpty()) {
            //If there are any selected Store Setup Import Ids, then serialize them into a JSON String before passing it to the LWC
            selectedStoreSetupImportIdsString = JSON.serialize(selectedStoreSetupImportIds);
        }
    }
}