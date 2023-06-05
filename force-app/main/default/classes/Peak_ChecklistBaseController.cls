public class Peak_ChecklistBaseController {
  private static Logger logInstance = Logger.getInstance();
  private static final Boolean AUTO_CREATE_NEW_GENERAL_LIST = false; // automatically create new task list for any user who doesn't already have one?

  /*
        Get checklists for user, and optionally create one if they don't have any already
        tests done
     */
  @AuraEnabled
  public static Peak_Response getChecklistForUser(String userIdString) {
    Peak_Response peakResponse = new Peak_Response();

    // Return List
    List<Peak_Checklist__c> returnList = Peak_ChecklistHelper.getChecklistForUser(
      Id.valueOf(userIdString),
      true
    );
    if (!Peak_Utils.isNullOrEmpty(returnList)) {
      peakResponse.results = returnList;
    }

    // If choosing to auto-create new lists, and if none already found, create default list (this allows for real-time provisioning essentially)
    if (AUTO_CREATE_NEW_GENERAL_LIST && returnList.isEmpty()) {
      // Optionally modify code here to select a certain Group name (instead of null) to assign certain task groups to certain Users by Business Logic (like values of fields on their Profile)
      peakResponse = createChecklistAndTasksForUser(userIdString, null);
    }

    return peakResponse;
  }

  /*
        Creates a new Checklist and a set of tasks based on task group for a User
     */
  public static Peak_Response createChecklistAndTasksForUser(
    String userIdString,
    Id taskGroupId
  ) {
    Peak_Response peakResponse = new Peak_Response();

    // New checklist - only continue if this is successful
    peakResponse = createChecklistForUser(userIdString);
    if (!peakResponse.success) {
      return peakResponse;
    }

    // Grab a reference to that recently inserted Checklist
    Peak_CheckList__c peakChecklist = (Peak_CheckList__c) peakResponse.results[0];

    // Grab Tasks for groupName Task Group
    List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> wrapperTasksForGroup = Peak_ChecklistHelper.getTasksForGroups(
      new List<Id>{ taskGroupId }
    );

    // Format MDT task wrappers as objects to insert
    List<Peak_Checklist_Task__c> newTaskList = Peak_ChecklistHelper.formatTasksFromMDTWrapper(
      wrapperTasksForGroup,
      peakChecklist.Id
    );

    // Try inserting newTaskList for User
    try {
      insert newTaskList;
    } catch (Exception e) {
      logInstance.log('Customer Care', 'Peak_ChecklistBaseController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }

    return peakResponse;
  }

  /*
        Create an empty Checklist for a user
        test done
     */
  public static Peak_Response createChecklistForUser(String userIdString) {
    Peak_Response peakResponse = new Peak_Response();

    // New checklist
    Peak_CheckList__c peakChecklist = new Peak_CheckList__c(
      User__c = userIdString
    );

    // Try inserting new checklist for User
    try {
      insert peakChecklist;
      peakResponse.results.add(peakChecklist);
    } catch (Exception e) {
      logInstance.log('Customer Care', 'Peak_ChecklistBaseController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }

    return peakResponse;
  }

  /*
        Update a task
     */
  @AuraEnabled
  public static Peak_Response updateTask(Peak_Checklist_Task__c task) {
    Peak_Response peakResponse = new Peak_Response();
    try {
      update task;
    } catch (Exception e) {
      logInstance.log('Customer Care', 'Peak_ChecklistBaseController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }
    return peakResponse;
  }

  /*
        Return all task groups
     */
  @AuraEnabled
  public static List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper> getTaskGroups() {
    List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper> returnList = Peak_ChecklistHelper.getTaskGroups();

    return returnList;
  }

  /*
        Return all tasks for admin selection
     */
  @AuraEnabled
  public static List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> getTasks() {
    List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> returnList = Peak_ChecklistHelper.getTasks();

    return returnList;
  }

  /*
        Create new tasks for user based on admin input (admin can choose a new Task Group, or Individual Tasks)
        Do not create duplicate tasks, so first query existing tasks for user before inserting
     */
  @AuraEnabled
  public static Peak_Response createTasksFromFormForUser(
    String userIdString,
    String tasksJSONString,
    String taskGroupsJSONString
  ) {
    Peak_Response peakResponse = new Peak_Response(); // to return
    Id checkListId; // user's active checklist ID
    List<String> existingTaskNames = new List<String>(); // Track existing Tasks for User

    // Deserialize tasks
    List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> tasks = (List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper>) JSON.deserialize(
      tasksJSONString,
      List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper>.class
    );

    // Deserialize groups
    List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper> taskGroups = (List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper>) JSON.deserialize(
      taskGroupsJSONString,
      List<Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper>.class
    );

    // Grab User's Checklist, if they have one
    Peak_Response checklistResponse = getChecklistForUser(userIdString);

    // If user does not have a checklist, create a new one
    if (Peak_Utils.isNullOrEmpty(checklistResponse.results)) {
      checklistResponse = createChecklistForUser(userIdString);
    } else {
      // Otherwise, note tasks they already have (if this list is not empty!)
      Peak_Checklist__c userChecklist = (Peak_Checklist__c) checklistResponse.results[0]; //cast it
      if (!Peak_Utils.isNullOrEmpty(userChecklist.Peak_Checklist_Tasks__r)) {
        for (
          Peak_Checklist_Task__c task : userChecklist.Peak_Checklist_Tasks__r
        ) {
          existingTaskNames.add(task.Name);
        }
      }
    }

    // Assign checklist Id - either the initially queried or newly created checklist
    checkListId = checklistResponse.results[0].Id;

    // Set of Task Groups that the admin selected to assign to this user
    List<Id> taskGroupIds = new List<Id>();
    for (
      Peak_CommunityTaskGroupMDTWrapper.Peak_CommunityTaskGroupWrapper taskGroup : taskGroups
    ) {
      if (taskGroup.isSelected == true) {
        taskGroupIds.add(taskGroup.id);
      }
    }

    // For selected task groups, get all related tasks and add to existing "tasks" list
    if (!Peak_Utils.isNullOrEmpty(taskGroupIds)) {
      // Grab Tasks for groupName Task Group
      List<Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper> wrapperTasksForGroup = Peak_ChecklistHelper.getTasksForGroups(
        taskGroupIds
      );
      // Add results to the tasks List for a single comparison/add of both individually added and group-added tasks

      // Default these tasks to isSelected
      for (
        Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper groupTask : wrapperTasksForGroup
      ) {
        groupTask.isSelected = true;
      }

      // Add these group tasks to list of all tasks
      tasks.addAll(wrapperTasksForGroup);
    }

    // Build list of new tasks to insert by comparing the values from the form to what we already have for user
    Set<String> newTaskNames = new Set<String>();

    // Also build Map of Task Names and their corresponding Order__c
    Map<String, Decimal> newTaskNameOrderMap = new Map<String, Decimal>();

    for (Peak_CommunityTaskMDTWrapper.Peak_CommunityTaskWrapper task : tasks) {
      // If task from form is selected, and if user does not already have this task, add it to the set
      if (task.isSelected && !existingTaskNames.contains(task.label)) {
        newTaskNames.add(task.label);
        newTaskNameOrderMap.put(task.label, task.order);
      }
    }

    // Finally, build list of Peak_Checklist_Task__c from our set of new task names, and Order__c for the checklist ID
    List<Peak_Checklist_Task__c> newListOfTasks = new List<Peak_Checklist_Task__c>();
    for (String taskName : newTaskNames) {
      newListOfTasks.add(
        new Peak_Checklist_Task__c(
          Peak_Checklist__c = checkListId,
          Name = taskName,
          Order__c = newTaskNameOrderMap.get(taskName)
        )
      );
    }

    try {
      insert newListOfTasks;
    } catch (Exception e) {
      logInstance.log('Customer Care', 'Peak_ChecklistBaseController', e);
      peakResponse.success = false;
      peakResponse.messages.add(e.getMessage());
    }

    return peakResponse;
  }
}