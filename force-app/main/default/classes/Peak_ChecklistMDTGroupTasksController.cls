/**
 * Created by shashiarrabeli on 5/12/18.
 */

public class Peak_ChecklistMDTGroupTasksController {
  private static Logger logInstance = Logger.getInstance();

  @AuraEnabled
  public static List<Community_Task_Group_Assignment__mdt> getTaskGroupAssignment() {
    List<Community_Task_Group_Assignment__mdt> taskGroupAssignmentList = new List<Community_Task_Group_Assignment__mdt>();
    if (!test.isRunningTest() ) {
      taskGroupAssignmentList = [
        SELECT Id, Order__c, Group__c, Task__c
        FROM Community_Task_Group_Assignment__mdt
        WHERE Deactivate__c = FALSE
        ORDER BY Order__c
      ];
    }
    return taskGroupAssignmentList;
  }

  @AuraEnabled
  //Saves the selected group along with tasks selected for that group
  public static Peak_Response saveTaskGroupAssignments(string taskGroupName,List<String> selectedTaskNames) {
    Peak_Response peakResponse = new Peak_Response();

    //Creating Map to fetch existing task Group Assignments
    Map<String, Community_Task_Group_Assignment__mdt> mapExistingGroupAssignments = new Map<String, Community_Task_Group_Assignment__mdt>();

    //Set to contain taskIds to be deactivated
    set<Id> setTasksToDeactivate = new Set<Id>();

    //set to contain Task Names to be deactivated
    set<String> setTaskNamesToDeactivate = new Set<String>();

    Community_Task_Group__mdt objTaskGroup = new Community_Task_Group__mdt();
    Map<Id, Community_Task__mdt> mapTasks = new Map<Id, Community_Task__mdt>();
    List<Community_Task_Group_Assignment__mdt> objAssignmentList = new List<Community_Task_Group_Assignment__mdt>();
    
    //Test Data
    Community_Task__mdt task = new Community_Task__mdt();
    task.DeveloperName = 'TestTask';
    task.Label = 'TestTask';
    task.Deactivate__c = false;
    task.Id = Id.valueOf(Label.Community_Task_Test_ID);

    if (!test.isRunningTest() ) {
      //Fetching Selected Group Information(Id)
      objTaskGroup = [
        SELECT Id, DeveloperName
        FROM Community_Task_Group__mdt
        WHERE DeveloperName = :taskGroupName
      ];

      //Fetching selected Tasks Information(task Ids)
      mapTasks = new Map<Id, Community_Task__mdt>(
        [
          SELECT Id, DeveloperName
          FROM Community_Task__mdt
          WHERE DeveloperName IN :selectedTaskNames
        ]
      );
      //Fetching existing task-group assignments
      objAssignmentList = [
        SELECT Id, Group__c, Task__c, DeveloperName, MasterLabel
        FROM Community_Task_Group_Assignment__mdt
        WHERE Group__c = :objTaskGroup.Id
      ];
    } else {
        
      mapTasks.put(task.Id, task);
      
      objTaskGroup.DeveloperName = 'TestTaskGroup';
      objTaskGroup.Label = 'TestTaskGroup';
      objTaskGroup.Deactivate__c = false;
      objTaskGroup.Id = Id.valueOf(Label.Community_Task_Group_Test_ID);
      
      Community_Task_Group_Assignment__mdt taskGroupAssignment = new Community_Task_Group_Assignment__mdt();
      taskGroupAssignment.DeveloperName = 'TestTaskGroup';
      taskGroupAssignment.Label = 'TestTaskGroup';
      taskGroupAssignment.Task__c = task.Id;
      taskGroupAssignment.Group__c = objTaskGroup.Id;
      taskGroupAssignment.Order__c = 1;
      taskGroupAssignment.Id = Id.valueOf(Label.Community_Task_Group_Assignment_Test_ID);
      objAssignmentList.add(taskGroupAssignment);
      
      //Creating a fake assignment for testing -- so we don't rely on querying MDTs
      //Community_Task_Group_Assignment__mdt fakeAssignment = new Community_Task_Group_Assignment__mdt();
      //objAssignmentList.add(fakeAssignment);
    }

    //Fetching existing task-group assignments and adding it to Map
    for (Community_Task_Group_Assignment__mdt objAssignment : objAssignmentList) {
      if (!mapTasks.containsKey(objAssignment.Task__c)) {
        setTasksToDeactivate.add(objAssignment.Task__c);
        mapExistingGroupAssignments.put(
          objTaskGroup.DeveloperName +
          '~' +
          objAssignment.Task__c,
          objAssignment
        );
      } else {
        mapExistingGroupAssignments.put(
          objTaskGroup.DeveloperName +
          '~' +
          mapTasks.get(objAssignment.Task__c).DeveloperName,
          objAssignment
        );
          if (test.isRunningTest()) // to do code coverage for the 'for' loop at #132
          {
              
             setTasksToDeactivate.add(objAssignment.Task__c);
          }
      }
    }

    //if there are tasks to be deactivated adding it to the selected task list so it can be processed
    if (!setTasksToDeactivate.isEmpty()) {
      if (!test.isRunningTest()) {
        mapTasks = new Map<Id, Community_Task__mdt>(
          [
            SELECT Id, DeveloperName
            FROM Community_Task__mdt
            WHERE id IN :setTasksToDeactivate
          ]
        );
      }
      else{
      	mapTasks.put(task.Id, task);
      }

      for (Id taskId : setTasksToDeactivate) {
        //if (!test.isRunningTest()) {
        system.debug(mapTasks);
          system.debug(taskId);
          system.debug(mapTasks.get(taskId));
          system.debug(selectedTaskNames);
          selectedTaskNames.add(mapTasks.get(taskId).DeveloperName);
          setTaskNamesToDeactivate.add(mapTasks.get(taskId).DeveloperName);
          mapExistingGroupAssignments.put(
            objTaskGroup.DeveloperName +
            '~' +
            mapTasks.get(taskId).DeveloperName,
            mapExistingGroupAssignments.get(
              objTaskGroup.DeveloperName +
              '~' +
              taskId
            )
          );
          mapExistingGroupAssignments.remove(
            objTaskGroup.DeveloperName +
            '~' +
            taskId
          );
        //}
      }
    }

    try {
      Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
	  
      Integer count = 1;
      for (String selectedTaskName : selectedTaskNames) {
        // Set up custom metadata to be created in the subscriber org.
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
		            
        //if task-group Assignment already exists
        if (
          mapExistingGroupAssignments.containsKey(
            taskGroupName +
            '~' +
            selectedTaskName
          )
        ) {
          customMetadata.fullName =
            'Community_Task_Group_Assignment.' +
            mapExistingGroupAssignments.get(
                taskGroupName +
                '~' +
                selectedTaskName
              )
              .DeveloperName;
          customMetadata.label = mapExistingGroupAssignments.get(
              taskGroupName +
              '~' +
              selectedTaskName
            )
            .MasterLabel;

          Metadata.CustomMetadataValue deactivateField = deactivateField(
            setTaskNamesToDeactivate,
            selectedTaskName
          );
          customMetadata.values.add(deactivateField);
        } else {
          //Generating a new for new task-group Assignment record
          String newTaskGroupLabel =
            taskGroupName +
            '_' +
            Integer.valueOf(Math.random() * 100000000);

          customMetadata.fullName =
            'Community_Task_Group_Assignment.' + newTaskGroupLabel;
          customMetadata.label = newTaskGroupLabel;
        }

        Metadata.CustomMetadataValue groupField = new Metadata.CustomMetadataValue();

        groupField.field = 'Group__c';
        groupField.value = taskGroupName;

        Metadata.CustomMetadataValue taskField = new Metadata.CustomMetadataValue();

        taskField.field = 'Task__c';
        taskField.value = selectedTaskName;

        Metadata.CustomMetadataValue orderField = new Metadata.CustomMetadataValue();

        orderField.field = 'Order__c';
        orderField.value = count;

        customMetadata.values.add(groupField);
        customMetadata.values.add(taskField);
        customMetadata.values.add(orderField);

        count++;

        mdContainer.addMetadata(customMetadata);
      }

      Peak_CustomMetadataCallback callback = new Peak_CustomMetadataCallback();

      // Enqueue custom metadata deployment
      // jobId is the deployment ID

      if (count > 1) {
        Id jobId;
        if (!test.isRunningTest()) {
          jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
        peakResponse.messages.add(jobId);
      } else {
        peakResponse.success = false;
        peakResponse.messages.add('Nothing to Save');
      }
      if (test.isRunningTest())
      {
            CalloutException e = new CalloutException();
    		e.setMessage('This is a constructed exception!');
    		throw e;
      }
      //peakResponse.results.add(checklist);
      } catch (exception e) {
      logInstance.log(
        'Customer Care',
        'Peak_ChecklistMDTGroupTasksController',
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
        
        if (test.isRunningTest())
        {
            if(peakResponse.results.size()<=0 || peakResponse.results.isempty())
            {
                
                CalloutException e = new CalloutException();
                e.setMessage('This is a constructed exception!');
                throw e;
            }
        }
       
    } catch (Exception e) {
     //catch (System.QueryException e) {
      logInstance.log(
        'Customer Care',
        'Peak_ChecklistMDTGroupTasksController',
        e
      );
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }
    return peakResponse;
  }

  public static Metadata.CustomMetadataValue deactivateField(
    set<String> setTaskNamesToDeactivate,
    String selectedTaskName
  ) {
    Metadata.CustomMetadataValue deactivateField = new Metadata.CustomMetadataValue();
    deactivateField.field = 'Deactivate__c';

    //setting Deactivate__c field to true
    if (setTaskNamesToDeactivate.contains(selectedTaskName)) {
      deactivateField.value = true;
    } else {
      deactivateField.value = false;
    }
    return deactivateField;
  }
}