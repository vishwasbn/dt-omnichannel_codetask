@isTest
private class LogToEmailTest {
    Static testMethod void LogToEmail(){
        List<Logger.Log> logs=new List<Logger.Log>();
         User u = Fleet_CommunityUtil.getUserInfo();
        Logger.Log log = new Logger.Log('identifier', 'className', 'log', 'objectName', 'objectIds', 'message', 'stackTrace', 'inJSON', u.id);
        logs.add(log);
        LogToEmail logE = new LogToEmail();
        logE.write(logs);
    }
}