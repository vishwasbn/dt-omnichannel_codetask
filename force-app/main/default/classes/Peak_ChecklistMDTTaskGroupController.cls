/**
 * Created by shashiarrabeli on 4/18/18.
 */

public with sharing class Peak_ChecklistMDTTaskGroupController {
  private static Logger logInstance = Logger.getInstance();

  @AuraEnabled
  /* Save the TaskGroup entered in the input text box and after clicking the "Add TaskGroup" button*/
  public static Peak_Response saveTaskGroup(string newTaskGroupName) {
    Peak_Response peakResponse = new Peak_Response();

    // Query, insert, update your results
    try {
      //Replace the space in the newTaskGroupName variable with an underscore
      String newTaskGroupLabel = newTaskGroupName;
      newTaskGroupName = Peak_Utils.replaceSpace(newTaskGroupName);

      //Check if the new Task Group already exists -- if so, just activate it
      Boolean reactivate = Peak_ChecklistHelper.checkForDeactivatedTaskGroup(
        newTaskGroupName
      );

      // Set up custom metadata to be created in the subscriber org.
      Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();

      customMetadata.fullName = 'Community_Task_Group.' + newTaskGroupName;
      customMetadata.label = newTaskGroupLabel;

      Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();

      //If the Task Group MDT Exists activate it, otherwise create it
      if (reactivate) {
        customField.field = 'Deactivate__c';
        customField.value = false;
        customMetadata.values.add(customField);
      }

      //customField.field = 'Description__c';
      //customField.value =newTaskGroupName;

      //customMetadata.values.add(customField);

      Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

      mdContainer.addMetadata(customMetadata);

      // Setup deploy callback, MyDeployCallback implements
      // the Metadata.DeployCallback interface (code for
      // this class not shown in this example)
      Peak_CustomMetadataCallback callback = new Peak_CustomMetadataCallback();

      // Enqueue custom metadata deployment
      // jobId is the deployment ID
      Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
      peakResponse.messages.add(jobId);

      //peakResponse.results.add(checklist);
    } catch (exception e) {
      logInstance.log(
        'Customer Care',
        'Peak_ChecklistMDTTaskGroupController',
        e
      );
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }
    // Return result and possible error messages
    return peakResponse;
  }

  //  A new method to query Peak Metadata Deploy Result by ID
  @AuraEnabled
  public static Peak_Response getDeployGroupResult(String jobId) {
    Peak_Response peakResponse = new Peak_Response();
    try {
      peakResponse.results = [
        SELECT Success__c, Detailed_Message__c
        FROM Peak_Metadata_Deploy_Result__c
        WHERE Job_ID__c = :jobId
      ];
    } catch (Exception e) {
      logInstance.log(
        'Customer Care',
        'Peak_ChecklistMDTTaskGroupController',
        e
      );
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }
    return peakResponse;
  }
  @AuraEnabled
  /* Delete the TaskGroup which was selected by clicking the "Del" hyper link next to the TaskGroup*/
  public static Peak_Response deleteTaskGroup(
    String taskGroupName,
    String taskGroupLabel
  ) {
    Peak_Response peakResponse = new Peak_Response();

    try {
      // Set up custom metadata to be created in the subscriber org.
      Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
      customMetadata.fullName = 'Community_Task_Group.' + taskGroupName;
      customMetadata.label = taskGroupLabel;

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
      logInstance.log(
        'Customer Care',
        'Peak_ChecklistMDTTaskGroupController',
        e
      );
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
      system.debug('Error message:' + e.getMessage());
    }
    // Return result and possible error messages
    return peakResponse;
  }
}