@isTest
private class LogToObjectTest {
    Static testMethod void LogToObjectTest1(){
        List<Logger.Log> logs=new List<Logger.Log>();
           User u = Fleet_CommunityUtil.getUserInfo();  
        
        Logger.Log log = new Logger.Log('identifier', 'className', 'log', 'objectName', 'objectIds', 'message', 'stackTrace', 'inJSON', u.id);
        logs.add(log);
        LogToObject logTObj = new LogToObject();
        logTObj.write(logs);
    }
}