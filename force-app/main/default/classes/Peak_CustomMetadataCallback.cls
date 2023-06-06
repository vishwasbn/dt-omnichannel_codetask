/**
 * Created by kentheberling on 7/9/18.
 */

public class Peak_CustomMetadataCallback implements Metadata.DeployCallback {

    public void handleResult(Metadata.DeployResult result,
            Metadata.DeployCallbackContext context) {

        Peak_Metadata_Deploy_Result__c deployResult = new Peak_Metadata_Deploy_Result__c();
        deployResult.Job_ID__c = result.Id;
        deployResult.Name = 'Job ' + result.Id;

        if (result.status == Metadata.DeployStatus.Succeeded) {
            deployResult.Success__c = true;
        } else {
            deployResult.Success__c = false;

            // Build a string to return (well, build a List which will turn into a string)
            List<String> errorMessages = new List<String>();

            // For each deploy message, grab the problem
            for(Metadata.DeployMessage thisMessage : result.details.componentFailures){
                errorMessages.add(thisMessage.problem);
            }
            // Format list into string
            deployResult.Detailed_Message__c = Peak_Utils.buildStringFromList(errorMessages);
        }

        insert deployResult;
    }
}