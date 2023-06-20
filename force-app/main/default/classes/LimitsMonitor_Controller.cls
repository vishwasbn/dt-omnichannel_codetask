public with sharing class LimitsMonitor_Controller {
    
    private static List<LimitApp_Streaming_Label__mdt> analyticalLabelMap;
    private static List<LimitApp_Streaming_Label__mdt> streamingLabelMap;
    private static List<LimitApp_Streaming_Label__mdt> otherLabelMap;
    private static List<LimitApp_Streaming_Label__mdt> workflowLabelMap;
    
    static {
        analyticalLabelMap = [select Limit_Label__c, Value__c from LimitApp_Streaming_Label__mdt where Category__c = 'Analytical' and Is_Active__c  = true Order by Id asc];
        streamingLabelMap = [select Limit_Label__c, Value__c from LimitApp_Streaming_Label__mdt where Category__c = 'Streaming' and Is_Active__c  = true Order by Id asc];
        otherLabelMap = [select Limit_Label__c, Value__c from LimitApp_Streaming_Label__mdt where Category__c = 'Other' and Is_Active__c  = true Order by Id asc];
        workflowLabelMap = [select Limit_Label__c, Value__c from LimitApp_Streaming_Label__mdt where Category__c = 'Workflow' and Is_Active__c  = true Order by Id asc];
    }
    
    public static Map<String, OrgLimit> getThisOrgLimits()
    {
        Map<String, OrgLimit> lm = new Map<String, OrgLimit>();
        //if(!Test.isRunningTest()){
        return OrgLimits.getMap();
        //}
        //return lm;
    }
    
    
    private static List<LimitData> getCategorizedData(Map<String, OrgLimit> limitsMap, List< LimitApp_Streaming_Label__mdt> categoryMap){
        List<LimitData> catData = new List<LimitData>();
        Integer i=0;
        for(LimitApp_Streaming_Label__mdt item : categoryMap){
            if(limitsMap.containsKey(item.Limit_Label__c)){
                catData.add(new LimitData(limitsMap.get(item.Limit_Label__c), item.Value__c, i++, 1));
            }
        }
        return catData;
    }
    
    @AuraEnabled
    public static void scheduleAlert(Decimal percent, string schedTime, string email){
        Time sTime = Time.newInstance(Integer.valueOf(schedTime.split(':')[0]), Integer.valueOf(schedTime.split(':')[1]), 0, 0);
        string schedStr = '0 '+sTime.minute()+' '+sTime.hour()+' * * ?';
        LimitsMonitor_Scheduler SC = new LimitsMonitor_Scheduler(percent, email); 
        if(!Test.isRunningTest()){
            system.schedule('LimitsMonitorSchedule', schedStr, SC);
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static AllLimits getOrgLimits(){
        //Make sure your Salesforce instance URL is added in remote site settings
        Map<String, OrgLimit> limitsMap = getThisOrgLimits();
        AllLimits allLimits = new AllLimits();
        
        allLimits.analyticsLimits = getCategorizedData(limitsMap, analyticalLabelMap);
        allLimits.streamingLimits = getCategorizedData(limitsMap, streamingLabelMap);
        allLimits.workflowLimits = getCategorizedData(limitsMap, workflowLabelMap);
        allLimits.otherLimits = getCategorizedData(limitsMap, otherLabelMap);
        
        if(!limitsMap.isEmpty()){
            allLimits.dailyApiLimit = new LimitData(limitsMap.get('DailyApiRequests'), 'Daily API Request', 0, 0);
            allLimits.dailyBulkApiLimit = new LimitData(limitsMap.get('DailyBulkApiBatches'), 'Daily Bulk API Request', 0, 0);
            allLimits.storageLimit = new LimitData(limitsMap.get('DataStorageMB'), 'Data Storage MB', 0, 0);
            allLimits.fileStorageLimit = new LimitData(limitsMap.get('FileStorageMB'), 'File Storage MB', 0, 0);
        }
        
        return allLimits;
    }
    
    @AuraEnabled
    public static List<ObjectLimitData> getObjectLimit(String apiName){
        
        HTTP h = new HTTP();
        HTTPRequest req = new HTTPRequest();
        HttpResponse resp = new HttpResponse();
        
        req.setMethod('GET');
        req.setEndpoint('callout:LimMon_NC/services/data/v45.0/tooling/query/?q=SELECT+Type,+Label,+Remaining,+Max,+EntityDefinitionid+FROM+EntityLimit+where+EntityDefinitionid=\''+apiName+'\'');
        resp = h.send(req);
        
        System.debug(resp.getBody());
        
        if(resp.getStatusCode() == 200 ){
            ObjectLimitResponse limits = (ObjectLimitResponse)JSON.deserialize(resp.getBody(), ObjectLimitResponse.class);
            return limits.records;
        }
        
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<ObjectInfo> getObjectInfo() {
        List<ObjectInfo> objectInfoList = new List<ObjectInfo>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        List<String> objectNames = new List<String>(globalDescribe.keySet());	
        objectNames.sort();
        for (String objectName : objectNames) {
            Schema.SObjectType objectType = globalDescribe.get(objectName);
            if (objectType.getDescribe().isQueryable()) {
                ObjectInfo objectInfo = new ObjectInfo();
                objectInfo.label = objectType.getDescribe().getLabel() +' ( '+objectType.getDescribe().getName()+' )';
                objectInfo.value = objectType.getDescribe().getName();
                objectInfoList.add(objectInfo);
            }
        }
        return objectInfoList;
    }
    
    public class ObjectInfo {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
    }
    
    
    public class AllLimits {
        @AuraEnabled
        public List<LimitData> analyticsLimits;
        @AuraEnabled
        public List<LimitData> streamingLimits;
        @AuraEnabled
        public List<LimitData> workflowLimits;
        @AuraEnabled
        public List<LimitData> otherLimits;
        @AuraEnabled
        public LimitData dailyApiLimit;
        @AuraEnabled
        public LimitData dailyBulkApiLimit;
        @AuraEnabled
        public LimitData storageLimit;
        @AuraEnabled
        public LimitData fileStorageLimit;
        
    }
    
    public class ObjectLimitResponse{
        public List<ObjectLimitData> records;
    }
    
    public class ObjectLimitData{
        
        @AuraEnabled
        public String Type;
        @AuraEnabled
        public Integer Remaining;
        @AuraEnabled
        public Integer Max;
        @AuraEnabled
        public String Label;
    }
    
    public class LimitData {
        
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Integer order;
        @AuraEnabled
        public Decimal score;
        @AuraEnabled
        public Decimal weight;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Decimal max;
        @AuraEnabled
        public Decimal consumed;
        @AuraEnabled
        public String indication;
        
        
        public LimitData(OrgLimit lim, String label, Integer order, Decimal weight){
            this.name = lim.getName();
            this.order= order;
            this.weight = weight;
            this.label = label;
            this.max = lim.getLimit();
            this.consumed = lim.getValue();
            this.score = (this.max != 0)? (this.consumed)/this.max:1;
            system.debug(lim.getName());
            system.debug((this.max - this.consumed));
            this.indication = (this.max - this.consumed) +  ' / ' + this.max;
        }
    }
}