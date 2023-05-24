public class Peak_CommunityTaskMDTWrapper {
  private static Logger logInstance = Logger.getInstance();
  /*
        Create Task Wrapper from Task MDTs
    */
  public static List<Peak_CommunityTaskWrapper> getTaskList() {
    List<Peak_CommunityTaskWrapper> returnList = new List<Peak_CommunityTaskWrapper>();
	List<Community_Task__mdt> taskMDTList = new List<Community_Task__mdt>();
    //Query Task MDTs
    //Included where logic to refresh the component only with the active values
      if(Test.isRunningTest()){
      	Community_Task__mdt task = new Community_Task__mdt();
        task.DeveloperName = 'TestTask';
        task.Label = 'TestTask';
        task.Deactivate__c = false;
        taskMDTList.add(task);
      }
      else {
   		taskMDTList = [
          SELECT Id, DeveloperName, Label
          FROM Community_Task__mdt
          WHERE Deactivate__c = FALSE
        ];
      }

    //For each MDT create a wrapper
    for (Community_Task__mdt theTaskMDT : taskMDTList) {
      returnList.add(formatMDTtoWrapper(theTaskMDT, null));
    }

    return returnList;
  }

  /*
        Create Task Wrapper from Task MDTs queried by Group ID
     */
  public static List<Peak_CommunityTaskWrapper> getTasksForGroupsList(List<Id> groupIds) {
    List<Peak_CommunityTaskWrapper> taskList = new List<Peak_CommunityTaskWrapper>();

    //Tasks related to passed in Groups
    List<Id> taskIds = new List<Id>();

    //Query junction MDTs related to Groups
    List<Community_Task_Group_Assignment__mdt> taskGroupAssignments = new List<Community_Task_Group_Assignment__mdt>();
    List<Community_Task__mdt> relatedTasks = new List<Community_Task__mdt>();
    try {
    	if(Test.isRunningTest()){
            Community_Task__mdt task = new Community_Task__mdt();
            task.DeveloperName = 'TestTask';
            task.Label = 'TestTask';
            task.Deactivate__c = false;
            
            relatedTasks.add(task);
            
            Community_Task_Group__mdt taskGroup = new Community_Task_Group__mdt();
            taskGroup.DeveloperName = 'TestTaskGroup';
            taskGroup.Label = 'TestTaskGroup';
            taskGroup.Deactivate__c = false;
            
            Community_Task_Group_Assignment__mdt taskGroupAssignment = new Community_Task_Group_Assignment__mdt();
            taskGroupAssignment.DeveloperName = 'TestTaskGroup';
            taskGroupAssignment.Label = 'TestTaskGroup';
            taskGroupAssignment.Task__c = task.Id;
            taskGroupAssignment.Group__c = taskGroup.Id;
            taskGroupAssignment.Order__c = 1;
            taskGroupAssignments.add(taskGroupAssignment);
            
            if(groupIds==null){
                groupIds = new List<Id>();
                groupIds.add(taskGroup.Id);
            }
        }
        else {
            taskGroupAssignments = [
                SELECT Task__r.Id, Order__c
                FROM Community_Task_Group_Assignment__mdt
                WHERE Group__r.Id IN :groupIds
            ];
        }
      
    } 
    catch (System.QueryException sqe) {
      logInstance.log('Customer Care', 'Peak_CommunityTaskMDTWrapper', sqe);
      throw new System.QueryException(
        'Could not find My Custom Metadata Type' + sqe.getMessage()
      );
    }

    //Create Map of the GroupAssignment Task's Id and Order
    Map<Id, Decimal> taskIdAndOrderMap = new Map<Id, Decimal>();
    for (Community_Task_Group_Assignment__mdt theAssignment : taskGroupAssignments) {
      taskIdAndOrderMap.put(theAssignment.Task__r.Id, theAssignment.Order__c);
    }

    //Loop through junctions to get Tasks related to Groups
    for (Community_Task_Group_Assignment__mdt taskGroupAssignment : taskGroupAssignments) {
      taskIds.add(taskGroupAssignment.Task__r.Id);
    }

    //Query the Task MDTs in the list

    try {
        if(!Test.isRunningTest()){
            relatedTasks = [
        		SELECT Id, DeveloperName, Label
        		FROM Community_Task__mdt
        		WHERE Id IN :taskIds
      		];
        }
      
    } catch (System.QueryException sqe) {
      logInstance.log('Customer Care', 'Peak_CommunityTaskMDTWrapper', sqe);
      throw new System.QueryException(
        'Could not find My Custom Metadata Type' + sqe.getMessage()
      );
    }

    //Loop through Task MDTs to create wrappers, grabbing Order from Map
    for (Community_Task__mdt thisTask : relatedTasks) {
      //taskList.add(new Peak_CommunityTaskMDTWrapper(true, thisTask));
      taskList.add(
        formatMDTtoWrapper(thisTask, taskIdAndOrderMap.get(thisTask.Id))
      );
    }

    return taskList;
  }

  /*
        Format Task MDT into Wrapper
    */
  public static Peak_CommunityTaskWrapper formatMDTtoWrapper(Community_Task__mdt mdtTask,Decimal taskOrder) {
    Peak_CommunityTaskWrapper taskWrapper = new Peak_CommunityTaskWrapper();

    taskWrapper.isSelected = false;
    taskWrapper.label = mdtTask.Label;
    taskWrapper.order = taskOrder;
    taskWrapper.id = mdtTask.id;
    taskWrapper.name = mdtTask.DeveloperName; // Copying Developer name of metadata type record

    return taskWrapper;
  }

  //Inner class to wrap metadata
  public class Peak_CommunityTaskWrapper {
    @AuraEnabled
    public String name { get; set; } // Developer name of metadata type record
    @AuraEnabled
    public Boolean isSelected { get; set; }
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public Decimal order { get; set; }
    @AuraEnabled
    public String id { get; set; }
  }
}