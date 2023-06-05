/**
 * Created by shashi arrabeli on 4/12/18.
 */

public with sharing class Peak_ChecklistMDTController {
  private static Logger logInstance = Logger.getInstance();

  @AuraEnabled
  /* Save the Task entered in the input text box and on clicking the "Add Task" button*/
  public static Peak_Response saveTask(string newTaskName) {
    Peak_Response peakResponse = new Peak_Response();

    // Query, insert, update your results
    try {
      //Replace the space in the newTaskName variable with an underscore
      String newTaskLabel = newTaskName;
      newTaskName = Peak_Utils.replaceSpace(newTaskName);

      //Check if the new Task already exists -- if so, just activate it
      Boolean reactivate = Peak_ChecklistHelper.checkForDeactivatedTask(
        newTaskName
      );
      system.debug('test');

      // Set up custom metadata to be created in the subscriber org.
      Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();

      customMetadata.fullName = 'Community_Task.' + newTaskName;
      customMetadata.label = newTaskLabel;

      Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();

      //If the Task MDT Exists activate it, otherwise create it
      if (reactivate) {
        customField.field = 'Deactivate__c';
        customField.value = false;
      } else {
        customField.field = 'Description__c';
        customField.value = newTaskName;
      }

      customMetadata.values.add(customField);

      Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

      mdContainer.addMetadata(customMetadata);

      // Setup deploy callback, MyDeployCallback implements
      // the Metadata.DeployCallback interface (code for
      // this class not shown in this example)
      Peak_CustomMetadataCallback callback = new Peak_CustomMetadataCallback();

      // Enqueue custom metadata deployment
      // jobId is the deployment ID
      Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);

      // Add the deploy Job ID to the response. Then JS will query for the Peak Metadata Deploy Result in a loop until it is found (setInterval)
      peakResponse.messages.add(jobId);

      //peakResponse.results.add(checklist);
    } catch (exception e) {
      logInstance.log('Customer Care', 'Peak_ChecklistMDTController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
      system.debug('Error message:' + e.getMessage());
    }
    // Return result and possible error messages
    return peakResponse;
  }

  //  A new method to query Peak Metadata Deploy Result by ID
  @AuraEnabled
  public static Peak_Response getDeployResult(String jobId) {
    Peak_Response peakResponse = new Peak_Response();
    try {
      peakResponse.results = [
        SELECT Success__c, Detailed_Message__c
        FROM Peak_Metadata_Deploy_Result__c
        WHERE Job_ID__c = :jobId
      ];
    } catch (Exception e) {
      logInstance.log('Customer Care', 'Peak_ChecklistMDTController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }
    return peakResponse;
  }

  @AuraEnabled
  /* Delete the Task which was selected by clicking the "Del" hyper link next to the task*/
  public static Peak_Response deleteTask(String taskName, String taskLabel) {
    Peak_Response peakResponse = new Peak_Response();

    try {
      // Set up custom metadata to be created in the subscriber org.
      Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
      customMetadata.fullName = 'Community_Task.' + taskName;
      customMetadata.label = taskLabel;

      Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();

      customField.field = 'Deactivate__c';
      customField.value = true;

      customMetadata.values.add(customField);

      Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

      mdContainer.addMetadata(customMetadata);

      Peak_CustomMetadataCallback callback = new Peak_CustomMetadataCallback();

      Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);

      peakResponse.messages.add(jobId);

      //peakResponse.results.add(checklist);
    } catch (exception e) {
      logInstance.log('Customer Care', 'Peak_ChecklistMDTController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
      system.debug('Error message:' + e.getMessage());
    }
    // Return result and possible error messages
    return peakResponse;
  }
}