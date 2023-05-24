public class Fleet_WebToLeadAssignmentController
{  
    public static String lprefix = 'FLEET_LEADASSIGN:';
    public static final String FLEET_PUR_GRP_BOTH_OR_COMPANY_VEHICLES='Both/Company Vehicles';
    public static final String FLEET_PUR_GRP_RESALE='Resale';
    public static final String FLEET_PUR_GRP_ALL='ALL';
     
    @InvocableMethod
    public static void assignLead(List<Id> leadIdList)
    {
        System.debug( lprefix + 'Starting Lead Assignmet for the following IDs:' + leadIdList);
        
        // commenting out this code as this method is executed by Process Builder as Guest User, and therefore
        // the IF statemenet below was considered TRUE, resulting in the method return exit, causing defect DTFS-338
        //    if (!((Schema.sObjectType.Lead.isUpdateable()) && 
        //         Schema.sObjectType.User.fields.Fleet_Specialist_Assignment_Group__c.isAccessible() &&
        //         Schema.sObjectType.Group.fields.Id.isAccessible())) 
        //        {
        //            System.debug(lprefix + 'current users lacks the permissions to execute this method');
        //            return;
        //         }
        
        //---Code if to use standard Assignment rules - NOT NEEDED
        //Database.DMLOptions dmo = new Database.DMLOptions(); //dmo.assignmentRuleHeader.useDefaultRule = true; //for(Lead l : leadList) l.setOptions(dmo);
        
        //---Get the list of Leads to assign
        List<Lead> leadList = [SELECT Id, OwnerId, Fleet_Specialist_Id__c, Fleet_Purchase_Product__c,Fleet_Number_of_Vehicles__c,Fleet_Business_Located__c, Fleet_Specialist__c, Fleet_Preferred_Store_Id__c, Preferred_Store__c,city__c FROM Lead WHERE Id IN :leadIdList];
        System.debug( lprefix + 'Loaded the following Leads for processing: ' + leadList);
        //DT0010309-Added the fleet assignment city and state
        //--Get the full list of Fleet Specialists
        
        
        //List<User> fleetSpecialistList = [ SELECT Id, Name, Fleet_Specialist_Assignment_Group__c,Fleet_Assignment_State__c,Fleet_Assignment_City__c FROM User WHERE IsActive = true AND Fleet_Is_Specialist__c = TRUE ];
        // ----
        Map<ID,Integer> updatedListOfFleetSpecialistMap=new Map<ID,Integer>();
        List<User> updatedListOfFleetSpecialist=new List<User>();
        List<User> fleetSpecialistList = [ SELECT Id, Name,Fleet_Purchase_Category_Group__c, Fleet_Specialist_Assignment_Group__c,Fleet_Assignment_State__c,Fleet_Assignment_City__c,LeadAssignmentPriority__c FROM User WHERE
                                          IsActive = true AND Fleet_Is_Specialist__c = TRUE AND Fleet_Purchase_Category_Group__c!=null AND Fleet_Assignment_State__c!=null order by LeadAssignmentPriority__c  ];
        for(User rcd:fleetSpecialistList){
            if(rcd.LeadAssignmentPriority__c==null){
                rcd.LeadAssignmentPriority__c=0;
                updatedListOfFleetSpecialist.add(rcd);
            }else{
                updatedListOfFleetSpecialist.add(rcd);
            }
        }
        // ----
        System.debug( lprefix + 'Loaded the following Fleet Specialists for processing: ' + fleetSpecialistList);
        //---Get the Lead Queue
        Id leadQueueId;
        List<Group> leadGroups = [SELECT Id FROM Group WHERE Type = 'Queue' AND NAME = 'B2B Leads Queue'];
        if (leadGroups != null && leadGroups.size() > 0) leadQueueId = leadGroups[0].Id;
        List<FeedItem> chatterPostList = new List<FeedItem>();
        //---Assign the Leads
        for(Lead newLead : leadList) {
            assignLead(newLead, leadQueueId, fleetSpecialistList, chatterPostList);
            //----
            FleetSpecialistWrapper[] userList = new List<FleetSpecialistWrapper>();
            List<User> newUserList =new List<User>();
            for(User usr:updatedListOfFleetSpecialist){
                if(usr.id==newLead.OwnerId){
                    usr.LeadAssignmentPriority__c=usr.LeadAssignmentPriority__c+1;
                }
                userList.add( new FleetSpecialistWrapper(usr));
            }
            // compareTo method.
            userList.sort();
            for(FleetSpecialistWrapper usrRcd :userList){
                newUserList.add(usrRcd.usr);
            }
            fleetSpecialistList=newUserList;
            updatedListOfFleetSpecialist=fleetSpecialistList;
        }
        
        System.debug( lprefix + 'Updated Leads to save: ' + leadList);
        //---Update
        update leadList;
        //---
        //update fleet specialist
        for(User usrRd:updatedListOfFleetSpecialist){
            updatedListOfFleetSpecialistMap.put(usrRd.Id,(Integer)usrRd.LeadAssignmentPriority__c);
        }
        updateFleetSpecialists(updatedListOfFleetSpecialistMap);
        //---
        // ---Insert Chatter Posts
        // Since this code is executed by Guest User, it doesn't have the rights to post to chatter. Hence this chatter post code 
        //implemented in DTFS-321 broke the lead assignment code. So until a solution for DTFS-321 can be found,
        //I'm commenting out the chatter post INSERT code below to fix defect DTFS-338
        //if (chatterPostList.size() > 0) insert chatterPostList;
        System.debug( lprefix + 'Lead Assignment Complete');
    }
    
    
    //---Process to assign the Leads
    private static void assignLead(Lead newLead, Id queueId, List<User> fleetSpecialistList, List<FeedItem> chatterPostList)
    {  
        Map<Id, User> fltSpecialistMap = new Map<Id, User>();
        for (user fltUser : fleetSpecialistList){
            fltSpecialistMap.put(fltUser.Id, fltUser);
        }
        //  System.debug( lprefix + 'assignLead(Lead newLead...): Starting Assignment for newLead:' + newLead);
        //---Data Update
        if (newLead.Fleet_Preferred_Store_Id__c != null) {
            newLead.Preferred_Store__c = newLead.Fleet_Preferred_Store_Id__c;
            System.debug( lprefix + '     INSIDE IF (Fleet_Preferred_Store_Id__c != null), newLead.Preferred_Store__c=' + newLead.Fleet_Number_of_Vehicles__c);
        }
        Boolean isAssigned = false;
        System.debug( lprefix + '     newLead.Fleet_Number_of_Vehicles__c=' + newLead.Fleet_Number_of_Vehicles__c);
        //---Check if the Fleet Specialist has been selected
        if (!isAssigned && newLead.Fleet_Specialist_Id__c != null)
        {
            //---Matching Specialist has been found
            System.debug( lprefix + 'Found Matching Specialist Id: ' + newLead.Fleet_Specialist_Id__c);
            isAssigned = true;
            newLead.OwnerId = newLead.Fleet_Specialist_Id__c;
            //DTFS-372 - The Fleet_LeadTrigger and Fleet_LeadTriggerHandler is now setting the Fleet_Specialist__c and Assigned_Date__c
            //newLead.Fleet_Specialist__c = newLead.Fleet_Specialist_Id__c;
            //newLead.Assigned_Date__c = Date.today();
            
        }
        
        //DT0010309-City and state based assignment for leads. Assignments for Fleet_Assignment_State__c='ALL'.
        if (!isAssigned && newLead.City__c != null)
        {       
            User selectedCitySpecialist;
            //----
            selectedCitySpecialist=getSpecialistFromPurchaseGroupWithMatchingStateOrCity( fleetSpecialistList, newLead, true);
            //----
            //selectedCitySpecialist=selectedCitySpecialist==null?getSpecialistBasedOnCity( fleetSpecialistList,newLead.City__c,newLead.Fleet_Business_Located__c):selectedCitySpecialist;
            if (selectedCitySpecialist!= null){
                newLead.OwnerId= selectedCitySpecialist.Id;
                
            }
            
            else 
            {
                //---Based on the State, assign to a specific Specialist
                if (!isAssigned && newLead.Fleet_Business_Located__c != null)
                {
                    User selectedSpecialist;
                    //----
                    selectedSpecialist=getSpecialistFromPurchaseGroupWithMatchingStateOrCity( fleetSpecialistList, newLead, false);
                    //----
                    //selectedSpecialist=selectedSpecialist==null?getSpecialistBasedOnState( fleetSpecialistList,newLead.Fleet_Business_Located__c):selectedSpecialist;
                    if (selectedSpecialist!= null){
                        newLead.OwnerId= selectedSpecialist.Id;
                        
                    }
                    else 
                    {//If the entered state is not assigned to fleet specialist
                        //----
                        selectedSpecialist=getSpecialistFromPurchaseGroupWithMatchingAllState( fleetSpecialistList,  newLead);
                        //----
                        //selectedSpecialist=selectedSpecialist==null?getSpecialistBasedOnState( fleetSpecialistList,'ALL'):selectedSpecialist;
                        if (selectedSpecialist!= null){
                            newLead.OwnerId= selectedSpecialist.Id;
                            
                        }
                        else 
                        {
                            //---Based on the Purchase grp of Vehicles, assign to a specific Specialist
                            if (newLead.Fleet_Purchase_Product__c != null)
                            {
                                System.debug( lprefix + 'Looking for matching specialist for Purchase grp : ' + newLead.Fleet_Purchase_Product__c);
                                if (newLead.Fleet_Purchase_Product__c == 'Both'|| newLead.Fleet_Purchase_Product__c == 'Company Vehicles')
                                {
                                    selectedSpecialist = getRandomSpecialistFromPurchaseGroup(fleetSpecialistList, FLEET_PUR_GRP_BOTH_OR_COMPANY_VEHICLES);
                                    if (selectedSpecialist != null)
                                    {
                                        System.debug( lprefix + 'Assigning to '+FLEET_PUR_GRP_BOTH_OR_COMPANY_VEHICLES+ ' grp Specialist: ' + selectedSpecialist);
                                        isAssigned = true;
                                        newLead.OwnerId = selectedSpecialist.Id;
                                        //DTFS-372 - The Fleet_LeadTrigger and Fleet_LeadTriggerHandler is now setting the Fleet_Specialist__c and Assigned_Date__c
                                        //newLead.Fleet_Specialist__c = selectedSpecialist.Id;
                                        //newLead.Assigned_Date__c = Date.today();
                                        
                                    }
                                }
                                else if (newLead.Fleet_Purchase_Product__c == 'Resale')
                                {
                                    selectedSpecialist = getRandomSpecialistFromPurchaseGroup(fleetSpecialistList, FLEET_PUR_GRP_RESALE);
                                    
                                    if (selectedSpecialist != null)
                                    {
                                        System.debug( lprefix + 'Assigning to '+FLEET_PUR_GRP_RESALE+ ' grp Specialist: ' + selectedSpecialist);
                                        isAssigned = true;
                                        newLead.OwnerId = selectedSpecialist.Id;
                                        //DTFS-372 - The Fleet_LeadTrigger and Fleet_LeadTriggerHandler is now setting the Fleet_Specialist__c and Assigned_Date__c
                                        //newLead.Fleet_Specialist__c = selectedSpecialist.Id;
                                        //newLead.Assigned_Date__c = Date.today();
                                    }
                                }
                                if(!isAssigned)
                                {
                                    selectedSpecialist = getRandomSpecialistFromPurchaseGroup(fleetSpecialistList, FLEET_PUR_GRP_ALL);
                                    if (selectedSpecialist != null)
                                    {
                                        System.debug( lprefix + 'Assigning to ALL grp Specialist: ' + selectedSpecialist);
                                        isAssigned = true;
                                        newLead.OwnerId = selectedSpecialist.Id;
                                        //DTFS-372 - The Fleet_LeadTrigger and Fleet_LeadTriggerHandler is now setting the Fleet_Specialist__c and Assigned_Date__c
                                        //newLead.Fleet_Specialist__c = selectedSpecialist.Id;
                                        //newLead.Assigned_Date__c = Date.today();
                                    }
                                }
                            }else {
                                System.debug( lprefix + 'Looking for matching specialist for ALL Purchase grp');
                                
                                selectedSpecialist = getRandomSpecialistFromPurchaseGroup(fleetSpecialistList, FLEET_PUR_GRP_ALL);
                                if (selectedSpecialist != null)
                                {
                                    System.debug( lprefix + 'Assigning to ALL grp Specialist: ' + selectedSpecialist);
                                    isAssigned = true;
                                    newLead.OwnerId = selectedSpecialist.Id;
                                    //DTFS-372 - The Fleet_LeadTrigger and Fleet_LeadTriggerHandler is now setting the Fleet_Specialist__c and Assigned_Date__c
                                    //newLead.Fleet_Specialist__c = selectedSpecialist.Id;
                                    //newLead.Assigned_Date__c = Date.today();
                                    
                                }
                                
                            }
                            if (isAssigned)
                            {
                                System.debug( lprefix + 'Lead Assignment to Specialist complete ');
                                newLead.Assigned_Date__c = Date.today();
                                postFeed(newLead.OwnerId, fltSpecialistMap.get(newLead.OwnerId).Name, newLead.Id, chatterPostList);
                                
                                return;
                            }
                            
                            //---Otherwise, assign to the Queue
                            System.debug( lprefix + 'Lead Assignment to Lead Queue ID=' + queueId);
                            newLead.OwnerId = queueId;
                        }
                    }
                }
            }
        }
        else
        {
            if (!isAssigned && newLead.Fleet_Business_Located__c != null)
            {
                User selectedSpecialist;
                //----
                selectedSpecialist=getSpecialistFromPurchaseGroupWithMatchingStateOrCity( fleetSpecialistList, newLead, false);
                //----
                //selectedSpecialist=selectedSpecialist==null?getSpecialistBasedOnState( fleetSpecialistList,newLead.Fleet_Business_Located__c):selectedSpecialist;
                if (selectedSpecialist!= null)
                    newLead.OwnerId= selectedSpecialist.Id;
                else 
                {//If the entered state is not assigned to fleet specialist
                    //----
                    selectedSpecialist=getSpecialistFromPurchaseGroupWithMatchingAllState( fleetSpecialistList,  newLead);
                    //----
                    //selectedSpecialist=selectedSpecialist==null?getSpecialistBasedOnState( fleetSpecialistList,'ALL'):selectedSpecialist;
                    if (selectedSpecialist!= null)
                        newLead.OwnerId= selectedSpecialist.Id;
                    else 
                    {
                        //---Based on the Purchase grp of Vehicles, assign to a specific Specialist
                        if (newLead.Fleet_Purchase_Product__c != null)
                        {
                            System.debug( lprefix + 'Looking for matching specialist for Purchase grp : ' + newLead.Fleet_Purchase_Product__c);
                            if (newLead.Fleet_Purchase_Product__c == 'Both'|| newLead.Fleet_Purchase_Product__c == 'Company Vehicles')
                            {
                                selectedSpecialist = getRandomSpecialistFromPurchaseGroup(fleetSpecialistList, FLEET_PUR_GRP_BOTH_OR_COMPANY_VEHICLES);
                                if (selectedSpecialist != null)
                                {
                                    System.debug( lprefix + 'Assigning to '+FLEET_PUR_GRP_BOTH_OR_COMPANY_VEHICLES+ ' grp Specialist: ' + selectedSpecialist);
                                    isAssigned = true;
                                    newLead.OwnerId = selectedSpecialist.Id;
                                    //DTFS-372 - The Fleet_LeadTrigger and Fleet_LeadTriggerHandler is now setting the Fleet_Specialist__c and Assigned_Date__c
                                    //newLead.Fleet_Specialist__c = selectedSpecialist.Id;
                                    //newLead.Assigned_Date__c = Date.today();
                                }
                            }
                            else if (newLead.Fleet_Purchase_Product__c == 'Resale')
                            {
                                selectedSpecialist = getRandomSpecialistFromPurchaseGroup(fleetSpecialistList, FLEET_PUR_GRP_RESALE);
                                
                                if (selectedSpecialist != null)
                                {
                                    System.debug( lprefix + 'Assigning to '+FLEET_PUR_GRP_RESALE+ ' grp Specialist: ' + selectedSpecialist);
                                    isAssigned = true;
                                    newLead.OwnerId = selectedSpecialist.Id;
                                    //DTFS-372 - The Fleet_LeadTrigger and Fleet_LeadTriggerHandler is now setting the Fleet_Specialist__c and Assigned_Date__c
                                    //newLead.Fleet_Specialist__c = selectedSpecialist.Id;
                                    //newLead.Assigned_Date__c = Date.today();
                                }
                            }
                            if (!isAssigned)
                            {
                                selectedSpecialist = getRandomSpecialistFromPurchaseGroup(fleetSpecialistList, FLEET_PUR_GRP_ALL);
                                if (selectedSpecialist != null)
                                {
                                    System.debug( lprefix + 'Assigning to ALL grp Specialist: ' + selectedSpecialist);
                                    isAssigned = true;
                                    newLead.OwnerId = selectedSpecialist.Id;
                                    //DTFS-372 - The Fleet_LeadTrigger and Fleet_LeadTriggerHandler is now setting the Fleet_Specialist__c and Assigned_Date__c
                                    //newLead.Fleet_Specialist__c = selectedSpecialist.Id;
                                    //newLead.Assigned_Date__c = Date.today();
                                }
                            }
                        }else{
                             System.debug( lprefix + 'Looking for matching specialist for vehilce count : 0');
                           
                                selectedSpecialist = getRandomSpecialistFromPurchaseGroup(fleetSpecialistList, FLEET_PUR_GRP_ALL);
                                if (selectedSpecialist != null)
                                {
                                    System.debug( lprefix + 'Assigning to ALL grp Specialist: ' + selectedSpecialist);
                                    isAssigned = true;
                                    newLead.OwnerId = selectedSpecialist.Id;
                                    //DTFS-372 - The Fleet_LeadTrigger and Fleet_LeadTriggerHandler is now setting the Fleet_Specialist__c and Assigned_Date__c
                                    //newLead.Fleet_Specialist__c = selectedSpecialist.Id;
                                    //newLead.Assigned_Date__c = Date.today();
                                }
                            
                        }
                        if (isAssigned)
                        {
                            System.debug( lprefix + 'Lead Assignment to Specialist complete ');
                            newLead.Assigned_Date__c = Date.today();
                            postFeed(newLead.OwnerId, fltSpecialistMap.get(newLead.OwnerId).Name, newLead.Id, chatterPostList);
                            
                            return;
                        }
                        
                        //---Otherwise, assign to the Queue
                        System.debug( lprefix + 'Lead Assignment to Lead Queue ID=' + queueId);
                        newLead.OwnerId = queueId;
                    }
                }
            }
        }
        
    }
    @future
    private static void updateFleetSpecialists(Map<Id,Integer> userMap){
        Set<Id>IdSet=new Set<Id>();
        List<User> matchingUsers = new List<User>();
        IdSet=userMap.keySet();
        matchingUsers=[SELECT Id, Name,LeadAssignmentPriority__c FROM User WHERE id in:IdSet];
        for(User usr:matchingUsers){
            if(IdSet.contains(usr.Id)){
                usr.LeadAssignmentPriority__c=userMap.get(usr.Id);
            }
        }
        update matchingUsers;
        
    }
    //DT0010309--Get a specialist based on state
    private static User getSpecialistBasedOnState( List<User> specialistList,String leadState)
    {
        User selectedUser;
        List<User> matchingUsers = new List<User>();
        for(User specialist : specialistList)
        {
            if (specialist.Fleet_Assignment_State__c == leadState && specialist.Fleet_Assignment_City__c==null){
                
                return specialist;
            }
           
        } 
        
         for(User specialist : specialistList)
        {
            if (specialist.Fleet_Assignment_State__c == 'ALL'){
                
                return specialist;
            }
            // matchingUsers.add( specialist);
        } return null;
        
    }
    
    
    //DT0010309--Get a specialist based on city    
    private static User getSpecialistBasedOnCity( List<User> specialistList,String leadCity,String leadState)
    {
        User selectedUser;
        List<User> matchingUsers = new List<User>();
        for(User specialist : specialistList)
        {
            if ((specialist.Fleet_Assignment_City__c!=null)&&(specialist.Fleet_Assignment_City__c.contains(leadCity) && specialist.Fleet_Assignment_State__c == leadState)) {
                return specialist;
            } //matchingUsers.add( specialist);
        } 
        
        for(User specialist : specialistList)
        {
            if (specialist.Fleet_Assignment_State__c == 'ALL') {
              //  return specialist;
            } //matchingUsers.add( specialist);
        } return null;
        
    }
    
      //---Get a random specialist who has the matching Group Value
    public static User getRandomSpecialistFromGroup( List<User> specialistList, String groupValue)
    {
        System.debug( lprefix + 'Get random specialist in group: ' + groupValue);
        system.debug('specialistList++'+specialistList);
        User selectedUser;
        
        List<User> matchingUsers = new List<User>();
        
        //---Build the list of matching specialists
        for(User specialist : specialistList)
        {
            if (specialist.Fleet_Specialist_Assignment_Group__c == groupValue) {
                return specialist;
            }//matchingUsers.add( specialist);
        } return null;
       
    } 
    
    //---Get a random specialist who has the matching Purchase Group Value
    public static User getRandomSpecialistFromPurchaseGroup( List<User> specialistList, String groupValue)
    {
        System.debug( lprefix + 'Get random specialist in group: ' + groupValue);
        system.debug('specialistList++'+specialistList);
        User selectedUser;
        
        List<User> matchingUsers = new List<User>();
        
        //---Build the list of matching specialists
        for(User specialist : specialistList)
        {
            if (specialist.Fleet_Purchase_Category_Group__c == groupValue) {
                return specialist;
            }
        } return null;
       
    }
    //----
 
    
     public static User getSpecialistFromPurchaseGroupWithMatchingAllState( List<User> fleetSpecialistList, Lead newLead){
        User selectedSpecialist;
        List<User> matchingUsers = new List<User>();
        //---Based on the Purchase Group of Vehicles, assign to a specific Specialist
        if (newLead.Fleet_Purchase_Product__c != null)
        {
            System.debug( lprefix + 'Looking for matching specialist for vehilce count : ' + newLead.Fleet_Number_of_Vehicles__c);
            if (newLead.Fleet_Purchase_Product__c == 'Both'|| newLead.Fleet_Purchase_Product__c == 'Company Vehicles')
            {
                matchingUsers = getSpecialistFromPurchaseGroupRange(fleetSpecialistList, FLEET_PUR_GRP_BOTH_OR_COMPANY_VEHICLES);
                selectedSpecialist=getSpecialistBasedOnState( matchingUsers,'ALL');
                
                
                
            }
            else if (newLead.Fleet_Purchase_Product__c == 'Resale')
            {
                matchingUsers = getSpecialistFromPurchaseGroupRange(fleetSpecialistList, FLEET_PUR_GRP_RESALE);
                selectedSpecialist=getSpecialistBasedOnState( matchingUsers,'ALL');
                
            }else
            {
                matchingUsers = getSpecialistFromPurchaseGroupRange(fleetSpecialistList, FLEET_PUR_GRP_ALL);
                selectedSpecialist=getSpecialistBasedOnState( matchingUsers,'ALL');
                
            }
            
        } else{
            System.debug( lprefix + 'Looking for matching specialist for Purchase Group : '+FLEET_PUR_GRP_ALL);
            
            matchingUsers = getSpecialistFromPurchaseGroupRange(fleetSpecialistList, FLEET_PUR_GRP_ALL);
            selectedSpecialist=getSpecialistBasedOnState( matchingUsers,'ALL');
            
            
        }
        return selectedSpecialist;
    }
    
     public static User getSpecialistFromPurchaseGroupWithMatchingStateOrCity( List<User> fleetSpecialistList, Lead newLead,Boolean isCitybased){
        User selectedSpecialist;
        List<User> matchingUsers = new List<User>();
        //---Based on the Purchase Group of Vehicles, assign to a specific Specialist
        if (newLead.Fleet_Purchase_Product__c != null)
        {
            System.debug( lprefix + 'Looking for matching specialist for Purchase Group : ' + newLead.Fleet_Purchase_Product__c);
            if ((newLead.Fleet_Purchase_Product__c == 'Both'|| newLead.Fleet_Purchase_Product__c == 'Company Vehicles'))
            {
                matchingUsers = getSpecialistFromPurchaseGroupRange(fleetSpecialistList, FLEET_PUR_GRP_BOTH_OR_COMPANY_VEHICLES);
                if(isCitybased){
                    selectedSpecialist=getSpecialistBasedOnCity( matchingUsers,newLead.City__c,newLead.Fleet_Business_Located__c);
                }else
                {
                    selectedSpecialist=getSpecialistBasedOnState( matchingUsers,newLead.Fleet_Business_Located__c);
                }
                
                
            }
            else if (newLead.Fleet_Purchase_Product__c == 'Resale')
            {
                matchingUsers = getSpecialistFromPurchaseGroupRange(fleetSpecialistList, FLEET_PUR_GRP_RESALE);
                if(isCitybased){
                    selectedSpecialist=getSpecialistBasedOnCity( matchingUsers,newLead.City__c,newLead.Fleet_Business_Located__c);
                }else
                {
                    selectedSpecialist=getSpecialistBasedOnState( matchingUsers,newLead.Fleet_Business_Located__c);
                }
                
            }else 
            {
                matchingUsers = getSpecialistFromPurchaseGroupRange(fleetSpecialistList, FLEET_PUR_GRP_ALL);
                if(isCitybased){
                    selectedSpecialist=getSpecialistBasedOnCity( matchingUsers,newLead.City__c,newLead.Fleet_Business_Located__c);
                }else
                {
                    selectedSpecialist=getSpecialistBasedOnState( matchingUsers,newLead.Fleet_Business_Located__c);
                }
                
            }
            
        }else{
            System.debug( lprefix + 'Looking for matching specialist for Purchase Group : ' + FLEET_PUR_GRP_ALL);
            
            matchingUsers = getSpecialistFromPurchaseGroupRange(fleetSpecialistList, FLEET_PUR_GRP_ALL);
            if(isCitybased){
                selectedSpecialist=getSpecialistBasedOnCity( matchingUsers,newLead.City__c,newLead.Fleet_Business_Located__c);
            }else
            {
                selectedSpecialist=getSpecialistBasedOnState( matchingUsers,newLead.Fleet_Business_Located__c);
            }
            
            
            
        }
        return selectedSpecialist;
    } 
    //---Get a  List of specialist who has the matching Group Value
 //   private static List<User> getSpecialistFromGroupRange( List<User> specialistList, String groupValue)
   // {
    //    List<User> matchingUsers = new List<User>();
        
        //---Build the list of matching specialists
      //  for(User specialist : specialistList)
      //  {
     //       if (specialist.Fleet_Specialist_Assignment_Group__c == groupValue) {
      //          matchingUsers.add(specialist);
   //         }
   //     } return matchingUsers;
        
 //   } 
    
    //---Get a  List of specialist who has the matching Purchase Group Value
    private static List<User> getSpecialistFromPurchaseGroupRange( List<User> specialistList, String groupValue)
    {
        List<User> matchingUsers = new List<User>();
        
        //---Build the list of matching specialists
        for(User specialist : specialistList)
        {
            if (specialist.Fleet_Purchase_Category_Group__c == groupValue) {
                matchingUsers.add(specialist);
            }
            if (specialist.Fleet_Purchase_Category_Group__c == FLEET_PUR_GRP_ALL) {
                matchingUsers.add(specialist);
            }
        } return matchingUsers;
        
    }
    public static void assignLeads(Lead newLead, Id queueId, List<User> fleetSpecialistList, List<FeedItem> chatterPostList){
        assignLead(newLead, queueId, fleetSpecialistList, chatterPostList);
    }
    //----
    public static void postFeed(Id userID, String userName, Id leadId, List<FeedItem> chatterPostList)
    {
        String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        System.debug('Base URL: ' + sfdcBaseURL );
        String hyperLink = sfdcBaseURL + '/' + leadId;
        
        FeedItem post = new FeedItem();
        post.ParentId = userID;
        post.Title = 'Lead Assignment';
        post.Body = 'A new Lead has been submitted and assigned to you, ' + userName + ' Open the post to see the hyperlink.';
        post.LinkUrl = hyperLink;
        chatterPostList.add(post);
    }
  
}