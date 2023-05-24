global class stateCityController {
    public string Selectedstate{get;set;}
    public string Selectedcity{get;set;}
    public String currentRecordId {get;set;}
    
    
    
    private final user user;
    public stateCityController(ApexPages.StandardController stdController) {
        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
        this.user = (user)stdController.getRecord();       
    }     
    
    public list<SelectOption> getState(){
        List<SelectOption> options = new List<SelectOption>(); 
        List<State__c> stateList = [select Name from State__c];
        options.add(new SelectOption('Select State' , 'Select State' ));
        options.add(new SelectOption('ALL' , 'ALL' ));
        for(State__c singleState : stateList){           
            options.add(new SelectOption(singleState.Name , singleState.Name ));
        }     
        return options;
    }
    
    
    public list<SelectOption> getCities(){
        List<SelectOption> options = new List<SelectOption>();
        system.debug('selected State'+ Selectedstate);
        if(Selectedstate!=null && Selectedstate != 'ALL'){
            List<State__c> stateList = [select Name from State__c where Name= :Selectedstate];
            List<City__c> citiList = [Select Name from City__c where State__c = :stateList[0].id]; 
            if(citiList.size()<1000){                              
                for(City__c singleCity : citiList ){        
                    options.add(new SelectOption(singleCity.Name , singleCity.Name ));
                } 
            }else{
                integer i=0;
                
                for(City__c singleCity : citiList ){
                    if(i<1000){
                        i++;        
                        options.add(new SelectOption(singleCity.Name , singleCity.Name ));
                    }
                }
            }
            system.debug('@@@ OPTION: ' +options);
            
            return options;
        }
        
        options.add(new SelectOption('Select State First' , 'Select State First' ));
        return options;
    }
    
    @RemoteAction
    global static List<String> getCitiesOptions(String state){
        List<State__c> StateId = [Select id from state__c where Name= :state];
        Set<String> citiesSet = new Set<String>();
        List<String> citieslst = new List<String>(); 
        List<City__c> cities = [Select Name from City__c where State__c = :StateId[0].id];
        for(City__c city : cities){
            citiesSet.add(city.Name);
        } 
        citieslst.addAll(citiesSet);
        citieslst.sort();
        return citieslst;
    }
                    
    @RemoteAction
    global static void saveStateCity(string State, List<string> cityArray, string recordId) {
        system.debug('@@@ State: '+ State);
        system.debug('@@@ cityArray'+ cityArray);
        system.debug('@@@ recordId'+ recordId);
        string cities='';
        integer citiesLength;
        for(integer i=0; i<cityArray.size();i++){
            citiesLength = cities.length();
            system.debug('@@@ cityArray['+i+']'+ cityArray[i]);
            if(citiesLength==0){
            cities = cities + cityArray[i];   
            }else{
                cities = cities + ', ' +cityArray[i];    
            }
        }   
        system.debug('@@@ cities: '+ cities);
        if(State != 'Select State'){
            List<User> user = new List<User>();
                List<User> userList = [select Fleet_Assignment_State__c , Fleet_Assignment_City_New__c from User where id = :recordId];
                userList[0].Fleet_Assignment_State__c= State;
                if(State == 'ALL'){                   
                    userList[0].Fleet_Assignment_City_New__c= '';                   
                }
                
                if(cities != ''){                                      
                    userList[0].Fleet_Assignment_City_New__c= cities;                   
                }else{                   
                    userList[0].Fleet_Assignment_City_New__c= '';                   
                }
                user.add(userList[0]);
                //system.debug('@@@ user: '+ user);
                if(!Test.isRunningTest())
                    update user;              
        } else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select State and City Value to Proceed.'));
        }           
    }
}