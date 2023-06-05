declare module "@salesforce/apex/Peak_ChecklistBaseController.getChecklistForUser" {
  export default function getChecklistForUser(param: {userIdString: any}): Promise<any>;
}
declare module "@salesforce/apex/Peak_ChecklistBaseController.updateTask" {
  export default function updateTask(param: {task: any}): Promise<any>;
}
declare module "@salesforce/apex/Peak_ChecklistBaseController.getTaskGroups" {
  export default function getTaskGroups(): Promise<any>;
}
declare module "@salesforce/apex/Peak_ChecklistBaseController.getTasks" {
  export default function getTasks(): Promise<any>;
}
declare module "@salesforce/apex/Peak_ChecklistBaseController.createTasksFromFormForUser" {
  export default function createTasksFromFormForUser(param: {userIdString: any, tasksJSONString: any, taskGroupsJSONString: any}): Promise<any>;
}
