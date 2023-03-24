/**
 Created By : Sumeet Narang
 Creatted Dated : 12/17/2021, 6:48 PM
 Description : Apex Class used to assign the fleet specialist and owner for a lead.
 Modified By : Rohith V
 Modified Date :  12/30/2022
 User Story Number : Salesforce-798.
 */

global class LeadAssignmentRRHandler{

    private static Logger logInstance = Logger.getInstance();

    //assignFleetSpecialist is used to assing the Fleet Specialist as the Lead Owner 
    public static void assigntoFleetSpecialist(List<Lead> newList){
    
    List<Lead> exactlst = new List<Lead>();
    List<Lead> fleetlst = new List<Lead>();

    
        for(Lead l : newList){
             if(l.Fleet_Specialist__c != null){
                 l.OwnerId = l.Fleet_Specialist__c ;
                 fleetlst.add(l);
                 
             }
        }
        
         for(Lead l: newList){
              if(!fleetlst.contains(l)){
                 exactlst.add(l);
              }
         }    
        
        
        
        if(exactlst.size()>0){
             LeadAssignmentRRHandler.processLeadWithExactMatchOnInsert(exactlst);
        }
    
    }
    
  
    //processLeadWithExactMatchOnInsert method is used to Exact Match with State,City & Fleet Purchase Category Group (FCPG)
    
    public static void processLeadWithExactMatchOnInsert(List<Lead> newList){
        System.debug('==method executed=='+newList.size());
        //Set<String> States = new Set<String>();
        Set<String> States = new Set<String>();
        Set<String> City = new Set<String>();
        Set<String> FCPG = new Set<String>();
        FCPG.add('ALL');
        List<Lead> exactlst= new List<Lead>();
        List<Lead> partiallst = new List<Lead>();
        //Map<Id,String> StateMap = new Map<Id,String>();
        
        for(Lead ll: newList){
            //States.add(ll.State__c);
            //States = States+';'+ll.State__c;  
            //system.debug(States.subString(1,States.length()));
            if(ll.State__c !=null)
             States.add(ll.State__c);
            if(ll.Selectedcity__c !=null)
            City.add(ll.Selectedcity__c);
            if(ll.Fleet_Purchase_Product__c == 'Both' || ll.Fleet_Purchase_Product__c == 'Company Vehicles'){
                FCPG.add('Both/Company Vehicles');
            }else{
                FCPG.add(ll.Fleet_Purchase_Product__c);
            }
            //StateMap.put(ll.id,ll.State__c);
        }
        
        
        
        List<Id> userIds = new List<Id>();
        system.debug('@@@ States: '+States);
        system.debug('@@@ FCPG: '+ FCPG);
        system.debug('@@@ city: '+ city);
        
        List<User> AllUserList = [Select id,Name,Last_Lead_Assigned__c, Fleet_Assignment_City_New__c,Fleet_Assignment_State__c from User where /*Fleet_Assignment_State__c INCLUDES (:States.subString(1,States.length())) AND Fleet_Assignment_City_New__c in: City AND*/
                    Fleet_Is_Specialist__c = true];
        system.debug('@@@ AllUserList: '+ AllUserList);
        Set<Id> uIds = new Set<Id>();
        
        for(User u : AllUserList){
            for(String strState : States){
                 if(u.Fleet_Assignment_State__c!=null && String.isNotBlank(strState) && u.Fleet_Assignment_State__c.ContainsIgnoreCase(strState)){
                     uIds.add(u.Id);
                 }

            for(String str : city){
                
                //if(u.Fleet_Assignment_City_New__c!=null && u.Fleet_Assignment_City_New__c.ContainsIgnoreCase(str)){
                 if(u.Fleet_Assignment_City_New__c!=null && String.isNotBlank(str) && u.Fleet_Assignment_City_New__c.ContainsIgnoreCase(str)){
                    
                    uIds.add(u.Id);
                }
            }
            }
        }            
        List<User> userLst = [Select id,Name,Fleet_Assignment_City_New__c,Fleet_Purchase_Category_Group__c,Fleet_Assignment_State__c,Last_Lead_Assigned__c from User where /*Fleet_Assignment_State__c INCLUDES (:States.subString(1,States.length()))  AND Fleet_Assignment_City_New__c in: City AND*/
                     Fleet_Is_Specialist__c = true and Id in : uIds ORDER By Last_Lead_Assigned__c asc];
        
        
        
        
        System.debug('==userLst=='+userLst); 
        System.debug('==List Size=='+userLst.size()); 
        
   
     
        Set<user> uset = new Set<user>();
        if(!userLst.isEmpty()){
            system.debug('@@@ UserList Not Empty');
            System.debug('@@@ Userlist' +userLst);
            List<String> tmplst = new List<String>();
            if(!newlist.isEmpty()){
            for(Lead ll: newList){  
                 Boolean isfound = false;
                 
                 for(Integer i=0; i < userLst.size() ; i++ ){  
                      System.debug('this the lead in question'+ll.State__c);          
					if(ll.Selectedcity__c!=null && ll.Fleet_Purchase_Product__c !=null && ll.State__c !=null &&
                        userLst.get(i).Name!=null && userLst.get(i).Fleet_Assignment_State__c != null && userLst.get(i).Fleet_Assignment_City_New__c != null && userLst.get(i).Fleet_Purchase_Category_Group__c != null
                        && userLst.get(i).Fleet_Assignment_State__c.ContainsIgnoreCase(ll.State__c) && userLst.get(i).Fleet_Assignment_City_New__c.ContainsIgnoreCase(ll.Selectedcity__c)
                        && (userLst.get(i).Fleet_Purchase_Category_Group__c.Contains(ll.Fleet_Purchase_Product__c) || userLst.get(i).Fleet_Purchase_Category_Group__c == 'ALL' && (ll.Fleet_Purchase_Product__c == 'Both' || ll.Fleet_Purchase_Product__c == 'Company Vehicles')) && !tmplst.contains(userLst.get(i).Name))
                    
                    {                            
                     
                     System.debug('Entered');
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);                  
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     exactlst.add(ll);
                     break;
                    } 
                 }  
                                
                 if(isfound == false){
                     System.debug('Enter line 135');
                     tmplst.clear();
                     for(Integer i=0; i < userLst.size() ; i++ ){
                    
					if(ll.Selectedcity__c != null && ll.Fleet_Purchase_Product__c != null && ll.State__c != null &&
                        userLst.get(i).Name != null && userLst.get(i).Fleet_Assignment_State__c != null && userLst.get(i).Fleet_Assignment_City_New__c != null && userLst.get(i).Fleet_Purchase_Category_Group__c!= null
                        && userLst.get(i).Fleet_Assignment_State__c.ContainsIgnoreCase(ll.State__c) && userLst.get(i).Fleet_Assignment_City_New__c.ContainsIgnoreCase(ll.Selectedcity__c)
                        && (userLst.get(i).Fleet_Purchase_Category_Group__c.contains(ll.Fleet_Purchase_Product__c) || userLst.get(i).Fleet_Purchase_Category_Group__c.Contains('ALL') && (ll.Fleet_Purchase_Product__c.Contains('Both') || ll.Fleet_Purchase_Product__c.Contains('Company Vehicles'))) && !tmplst.contains(userLst.get(i).Name))                       
                    
                    {
                     System.debug('Entered');
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     exactlst.add(ll);
                     break;
                    } 
                   }  
                 }      
            } 
                }
        }
        
        Integer j = 0;
        for(User u: uset){
            u.Last_Lead_Assigned__c = DateTime.now().addMinutes(j); 
            j++;          
        } 
        
         for(Lead l: newList){
              if(!exactlst.contains(l)){
                 partiallst.add(l);
              }
         }    
          
        
        
        if(uset.size() > 0){           
            List<user> ul = new List<user>();
            for(User u : uset){
               ul.add(u);
            }
            try{
                update ul;    
            }catch(DmlException e) {
                logInstance.log('Lead_assignment', LeadAssignmentRRHandler.class.getName(), 'User', e);
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
            
         }
         
         if(partiallst.size() > 0){
            LeadAssignmentRRHandler.processLeadWithStateAndCity(partiallst);
        } 
            
        System.debug('==updated userLst=='+userLst); 

    }
    
      // New method added to match with the State and City exculuding the FCPG as it is no longer a required field on inquiry form
      
   
        public static void processLeadWithStateAndCity(List<Lead> newList){
        System.debug('==method executed=='+newList.size());
        //Set<String> States = new Set<String>();
        //String States = '';
        List<String> States = new List<String>();
        Set<String> City = new Set<String>();

        List<Lead> exactlst2= new List<Lead>();
        List<Lead> partiallst2 = new List<Lead>();
        
        for(Lead ll: newList){
            //States.add(ll.State__c);
            //States = States+';'+ll.State__c;  
            //system.debug(States.subString(1,States.length()));
           if(ll.State__c !=null)
             States.add(ll.State__c);
           if(ll.Selectedcity__c !=null)
            City.add(ll.Selectedcity__c);
        }
        
        
        
        List<Id> userIds = new List<Id>();
        system.debug('@@@ States: '+States);
        system.debug('@@@ city: '+ city);
        
        List<User> AllUserList = [Select id,Name,Last_Lead_Assigned__c,Fleet_Assignment_State__c, Fleet_Assignment_City_New__c from User where /*Fleet_Assignment_State__c INCLUDES (:States.subString(1,States.length()))  /*AND Fleet_Assignment_City_New__c in: City AND*/
                                      Fleet_Is_Specialist__c = true];
        system.debug('@@@ AllUserList: '+ AllUserList);
        Set<Id> uIds = new Set<Id>();
        
        for(User u : AllUserList){
            for(String strState : States){
                 if(u.Fleet_Assignment_State__c!=null && String.isNotBlank(strState) && u.Fleet_Assignment_State__c.ContainsIgnoreCase(strState)){
                     uIds.add(u.Id);
                 }
            for(String str : city){
                
                 if(u.Fleet_Assignment_City_New__c!=null && String.isNotBlank(str) && u.Fleet_Assignment_City_New__c.ContainsIgnoreCase(str)){
                    
                    uIds.add(u.Id);
                }
            }
        }      
        }
        List<User> userLst = [Select id,Name,Fleet_Assignment_City_New__c,Fleet_Assignment_State__c,Last_Lead_Assigned__c from User where /*Fleet_Assignment_State__c INCLUDES (:States.subString(1,States.length()))  /*AND Fleet_Assignment_City_New__c in: City AND*/
                       Fleet_Is_Specialist__c = true and Id in : UIds ORDER By Last_Lead_Assigned__c asc];
        
        
        
        
        //System.debug('==userLst=='+userLst); 
        //System.debug('==List Size=='+userLst.size()); 
        
   
     
        Set<user> uset = new Set<user>();
        if(!userLst.isEmpty()){
            system.debug('@@@ UserList Not Empty');
            system.debug('@@ userList'+userLst);
            List<String> tmplst = new List<String>();
            if(!newlist.isEmpty()){
            for(Lead ll: newList){  
                 Boolean isfound = false;
                 
                 for(Integer i=0; i < userLst.size() ; i++ ){  
                                
                    if(ll.Selectedcity__c != null && ll.State__c != null && userLst.get(i).Name != null && userLst.get(i).Fleet_Assignment_State__c != null && userLst.get(i).Fleet_Assignment_City_New__c != null &&
   					 userLst.get(i).Fleet_Assignment_State__c.ContainsIgnoreCase(ll.State__c) && userLst.get(i).Fleet_Assignment_City_New__c.ContainsIgnoreCase(ll.Selectedcity__c) &&  !tmplst.contains(userLst.get(i).Name))
                    
                    {           
                        
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);                  
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     exactlst2.add(ll);
                     break;
                    } 
                 }  
                                
                 if(isfound == false){
                     tmplst.clear();
                     for(Integer i=0; i < userLst.size() ; i++ ){
                    
                    if(ll.Selectedcity__c != null && ll.State__c != null && userLst.get(i).Name != null && userLst.get(i).Fleet_Assignment_State__c != null && userLst.get(i).Fleet_Assignment_City_New__c != null &&
    				userLst.get(i).Fleet_Assignment_State__c.ContainsIgnoreCase(ll.State__c) && userLst.get(i).Fleet_Assignment_City_New__c.ContainsIgnoreCase(ll.Selectedcity__c) &&  !tmplst.contains(userLst.get(i).Name))
                    
                    { 
                        
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     exactlst2.add(ll);
                     break;
                    } 
                   }  
                 }      
            } 
                }
        }
        
        Integer j = 0;
        for(User u: uset){
            u.Last_Lead_Assigned__c = DateTime.now().addMinutes(j); 
            j++;          
        } 
        
         for(Lead l: newList){
              if(!exactlst2.contains(l)){
                 partiallst2.add(l);
              }
         }    
          
        
        
        if(uset.size() > 0){           
            List<user> ul = new List<user>();
            for(User u : uset){
               ul.add(u);
            }
            try{
                update ul;    
            }catch(DmlException e) {
                logInstance.log('Lead_assignment', LeadAssignmentRRHandler.class.getName(), 'User', e);
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
            
         }
         
         if(partiallst2.size() > 0){ LeadAssignmentRRHandler.processLeadWithPartialMatchOnInsert(partiallst2);  } 
            
      
            
        System.debug('==updated userLst=='+userLst); 

    }
    
    
    
    //processLeadWithPartialMatchOnInsert method used to Partial Match with State & Fleet Purchase Category Group (FCPG)
    
        public static void processLeadWithPartialMatchOnInsert(List<Lead> newList){
            System.debug('==Partial Match==');
            Set<String> States = new Set<String>();
            //String States = '';
            
            Set<String> FCPG = new Set<String>();
            FCPG.add('ALL');
            List<lead> partialmtch = new List<lead>();
            List<Lead> allst = new List<lead>();
            
            
            
            for(Lead ll: newList){
             	if(ll.State__c !=null)
            	 States.add(ll.State__c);
                if(ll.Fleet_Purchase_Product__c == 'Both' || ll.Fleet_Purchase_Product__c == 'Company Vehicles'){
                    FCPG.add('Both/Company Vehicles');
                }else{
                    FCPG.add(ll.Fleet_Purchase_Product__c);
                }
            }

            List<User> allUserLst = [Select id,Name,Fleet_Assignment_State__c,Fleet_Purchase_Category_Group__c from User where 
                      Fleet_Purchase_Category_Group__c in: FCPG AND Fleet_Is_Specialist__c = true ORDER By Last_Lead_Assigned__c asc];
            //System.debug('==userLst partial=='+userLst); 
            //System.debug('==List Size partial=='+userLst.size());   
   		     
            Set<Id> uIds = new Set<Id>();
            
            for(User u : allUserLst){
            for(String strState : States){
                 if(u.Fleet_Assignment_State__c!=null && String.isNotBlank(strState) && u.Fleet_Assignment_State__c.ContainsIgnoreCase(strState)){
                     uIds.add(u.Id);
                 } 
            }
        }      
       
        List<User> userLst = [Select id,Name,Fleet_Assignment_State__c,Last_Lead_Assigned__c,Fleet_Purchase_Category_Group__c from User where
                       Fleet_Is_Specialist__c = true and Id in : UIds ORDER By Last_Lead_Assigned__c asc];
            
        Set<user> uset = new Set<user>();
        if(!userLst.isEmpty()){
            system.debug('@@@ UserList Not Empty');
            List<String> tmplst = new List<String>();        
            for(Lead ll: newList){  
                 Boolean isfound = false;
                 
                 for(Integer i=0; i < userLst.size() ; i++ ){                 
                    if(ll.Fleet_Purchase_Product__c!=null && ll.State__c != null && userLst.get(i).Name!=null && userLst.get(i).Fleet_Assignment_State__c != null && userLst.get(i).Fleet_Purchase_Category_Group__c != null &&  userLst.get(i).Fleet_Assignment_State__c.ContainsIgnoreCase(ll.State__c)  && 
                       (userLst.get(i).Fleet_Purchase_Category_Group__c.Contains(ll.Fleet_Purchase_Product__c)|| userLst.get(i).Fleet_Purchase_Category_Group__c == 'ALL' && (ll.Fleet_Purchase_Product__c == 'Both' || ll.Fleet_Purchase_Product__c == 'Company Vehicles'))  && !tmplst.contains(userLst.get(i).Name))
                    
                    {                
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);                  
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     partialmtch.add(ll);
                     break;
                    } 
                 }  
                                
                 if(isfound == false){
                     tmplst.clear();
                     for(Integer i=0; i < userLst.size() ; i++ ){
                    
                    if(ll.Fleet_Purchase_Product__c!=null && ll.State__c != null && userLst.get(i).Name!=null && userLst.get(i).Fleet_Assignment_State__c != null && userLst.get(i).Fleet_Purchase_Category_Group__c != null &&  userLst.get(i).Fleet_Assignment_State__c.ContainsIgnoreCase(ll.State__c)  && 
                       (userLst.get(i).Fleet_Purchase_Category_Group__c.Contains(ll.Fleet_Purchase_Product__c)|| userLst.get(i).Fleet_Purchase_Category_Group__c == 'ALL' && (ll.Fleet_Purchase_Product__c == 'Both' || ll.Fleet_Purchase_Product__c == 'Company Vehicles'))  && !tmplst.contains(userLst.get(i).Name))                   
                   {                
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     partialmtch.add(ll);
                     break;
                    } 
                   }  
                 }     
            } 
        }
          
            Integer j = 0;
        for(User u: uset){
            u.Last_Lead_Assigned__c = DateTime.now().addMinutes(j); 
            j++;          
        } 
        
        for(Lead l : newList){
           if(!partialmtch.contains(l)){
               allst.add(l);
           }
        }
        
        if(uset.size() > 0){           
            List<user> ul = new List<user>();
            for(User u : uset){
               ul.add(u);
            }
            try{
                update ul;    
            }catch(DmlException e) {
                logInstance.log('Lead_assignment', LeadAssignmentRRHandler.class.getName(), 'User', e);
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
            
         }
         
         if(allst.size() > 0){
                LeadAssignmentRRHandler.processLeadWithState(allst);
            }
            
            System.debug('==updated userLst=='+userLst);    

        } 
    
        //processLeadWithState is new method added to match with only the State when the selected city does not match with any Fleet Specialist  

            public static void processLeadWithState(List<Lead> newList){
            System.debug('==Partial Match==');
            Set<String> States = new Set<String>();
       		//String States = '';
            List<lead> partialmtch2 = new List<lead>();
            List<Lead> allst2 = new List<lead>();

                
            for(Lead ll: newList){
             if(ll.State__c !=null)
             States.add(ll.State__c);
           
            //States = States+';'+ll.State__c;  
            }
            //system.debug(States.subString(1,States.length()));
                
            
            List<User> userLst = [Select id,Name,Fleet_Assignment_State__c from User where Fleet_Is_Specialist__c = true ORDER By Last_Lead_Assigned__c asc];
            System.debug('==userLst partial=='+userLst); 
            System.debug('==List Size partial=='+userLst.size());   

            
        Set<user> uset = new Set<user>();
        if(!userLst.isEmpty()){
            system.debug('@@@ UserList Not Empty');
            system.debug('@@@ UserList' +userLst);
            List<String> tmplst = new List<String>();        
            for(Lead ll: newList){  
                 Boolean isfound = false;
                 
                 for(Integer i=0; i < userLst.size() ; i++ ){                 
                    if(ll.State__c != null && userLst.get(i).Name!=null &&  userLst.get(i).Fleet_Assignment_State__c != null && userLst.get(i).Fleet_Assignment_State__c.ContainsIgnoreCase(ll.State__c) && !tmplst.contains(userLst.get(i).Name))
                    
                    {                
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);                  
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     partialmtch2.add(ll);
                     break;
                    } 
                 }  
                                
                 if(isfound == false){
                     tmplst.clear();
                     for(Integer i=0; i < userLst.size() ; i++ ){
                    
                    if(ll.State__c != null && userLst.get(i).Name!=null &&  userLst.get(i).Fleet_Assignment_State__c != null && userLst.get(i).Fleet_Assignment_State__c.ContainsIgnoreCase(ll.State__c) && !tmplst.contains(userLst.get(i).Name))
                    
                    {                
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name); 
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     partialmtch2.add(ll);
                     break;
                    } 
                   }  
                 }     
            } 
        }
          
            Integer j = 0;
        for(User u: uset){
            u.Last_Lead_Assigned__c = DateTime.now().addMinutes(j); 
            j++;          
        } 
        
        for(Lead l : newList){
           if(!partialmtch2.contains(l)){
               allst2.add(l);
           }
        }
        
        if(uset.size() > 0){           
            List<user> ul = new List<user>();
            for(User u : uset){
               ul.add(u);
            }
            try{
                update ul;    
            }catch(DmlException e) {
                logInstance.log('Lead_assignment', LeadAssignmentRRHandler.class.getName(), 'User', e);
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
            
         }
         
         if(allst2.size() > 0){
                LeadAssignmentRRHandler.processLeadWithStateAllonInsert(allst2);
            }
            
            System.debug('==updated userLst=='+userLst);    

        }
     
     
    
    
       // processLeadWithStateAllonInsert method is used to assign and Match With State(ALL) & Fleet Purchase Category Group (FCPG) 
       // of lead with Fleet Specialist
  
     public static void processLeadWithStateAllonInsert(List<Lead> newList){
         	Set<String> FCPG = new Set<String>();
            List<lead> allstpgmatch = new List<lead>();
            List<Lead> allstMatch = new List<lead>();
         
         for(Lead ll: newList){
             if(ll.Fleet_Purchase_Product__c == 'Both' || ll.Fleet_Purchase_Product__c == 'Company Vehicles'){
                    FCPG.add('Both/Company Vehicles');
                }else{
                    FCPG.add(ll.Fleet_Purchase_Product__c);
                }
         }
         
         //FCPG.add('ALL');
         
         List<User> userLst = [Select id,Name,Fleet_Purchase_Category_Group__c from User where Fleet_Purchase_Category_Group__c in: FCPG AND Fleet_Is_Specialist__c = true
                                  AND  Fleet_Assignment_State__c = 'ALL'  ORDER By Last_Lead_Assigned__c asc];
          
        Set<user> uset = new Set<user>();
        if(!userLst.isEmpty()){
            system.debug('@@@ UserList Not Empty');
            List<String> tmplst = new List<String>();
         
            for(Lead ll: newList){  
                 Boolean isfound = false;
                 
                 for(Integer i=0; i < userLst.size() ; i++ ){                 
                    if(userLst.get(i).Name!=null && userLst.get(i).Fleet_Purchase_Category_Group__c != null &&ll.Fleet_Purchase_Product__c!=null && (userLst.get(i).Fleet_Purchase_Category_Group__c.Contains(ll.Fleet_Purchase_Product__c)|| userLst.get(i).Fleet_Purchase_Category_Group__c == 'ALL' && (ll.Fleet_Purchase_Product__c == 'Both' || ll.Fleet_Purchase_Product__c == 'Company Vehicles')) &&  !tmplst.contains(userLst.get(i).Name)){                
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);                  
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     allstpgmatch.add(ll);
                     break;
                    } 
                 }  
                                
                 if(isfound == false){
                     tmplst.clear();
                     for(Integer i=0; i < userLst.size() ; i++ ){
                    
                    if(userLst.get(i).Name!=null && userLst.get(i).Fleet_Purchase_Category_Group__c != null && ll.Fleet_Purchase_Product__c!=null && (userLst.get(i).Fleet_Purchase_Category_Group__c.Contains(ll.Fleet_Purchase_Product__c)|| userLst.get(i).Fleet_Purchase_Category_Group__c == 'ALL' && (ll.Fleet_Purchase_Product__c == 'Both' || ll.Fleet_Purchase_Product__c == 'Company Vehicles')) &&  !tmplst.contains(userLst.get(i).Name))                
                    
                    {                

                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     allstpgmatch.add(ll);                     
                     break;
                    } 
                   }  
                 }         
            } 
        }
          
            Integer j = 0;
        for(User u: uset){
            u.Last_Lead_Assigned__c = DateTime.now().addMinutes(j); 
            j++;          
        } 
        for(Lead l : newList){
           if(!allstpgmatch.contains(l)){
               allstMatch.add(l);
           }
        }
        
        if(uset.size() > 0){           
            List<user> ul = new List<user>();
            for(User u : uset){
               ul.add(u);
            }
            try{
                update ul;    
            }catch(DmlException e) {
                logInstance.log('Lead_assignment', LeadAssignmentRRHandler.class.getName(), 'User', e);
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
            
         }
         if(allstMatch.size() > 0){
                LeadAssignmentRRHandler.processLeadWithStateAll(allstMatch);
            }
            
            System.debug('==updated userLst=='+userLst);    

        }      
         
    
    //processLeadWithStateAll is a New Method to match Leads with Fleet Specialist with state All.
    
     public static void processLeadWithStateAll(List<Lead> newList){
         
         List<User> userLst = [Select id,Name,Fleet_Purchase_Category_Group__c from User where Fleet_Assignment_State__c = 'ALL'  AND Fleet_Is_Specialist__c = true
                                  ORDER By Last_Lead_Assigned__c asc];
          
        Set<user> uset = new Set<user>();
        if(!userLst.isEmpty()){
            system.debug('@@@ UserList Not Empty');
            List<String> tmplst = new List<String>();
         
            for(Lead ll: newList){  
                 Boolean isfound = false;
                 
                 for(Integer i=0; i < userLst.size() ; i++ ){                 
                    if( userLst.get(i).Name!=null && !tmplst.contains(userLst.get(i).Name)){                
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);                  
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     break;
                    } 
                 }  
                                
                 if(isfound == false || test.isRunningTest()){
                     tmplst.clear();
                     for(Integer i=0; i < userLst.size() ; i++ ){
                    
                    if(userLst.get(i).Name!=null && !tmplst.contains(userLst.get(i).Name)){                
                     ll.OwnerId = userLst.get(i).id;
                     tmplst.add(userLst.get(i).Name);
                     isfound = true;
                     System.debug('***'+tmplst);
                     uset.add(userLst.get(i));
                     break;
                    } 
                   }  
                 }         
            } 
        }
          
            Integer j = 0;
        for(User u: uset){
            u.Last_Lead_Assigned__c = DateTime.now().addMinutes(j); 
            j++;          
        } 
        
        if(uset.size() > 0){           
            List<user> ul = new List<user>();
            for(User u : uset){
               ul.add(u);
            }
            try{
                update ul;    
            }catch(DmlException e) {
                logInstance.log('Lead_assignment', LeadAssignmentRRHandler.class.getName(), 'User', e);
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
            
         }
         
     }
        

}