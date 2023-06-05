@isTest
public class LoggerTest {
    
    Static testMethod void LoggerTest(){
        Account Acc = new Account(Name='test');
        insert Acc;
        
        LogEvent__e lge = new LogEvent__e();
        Logger logg = new Logger(true);
        Logger logg1 = new Logger(true,false);
        
        List<Logger.Log> logs=new List<Logger.Log>();
         User u = Fleet_CommunityUtil.getUserInfo();
        Logger.Log log = new Logger.Log('identifier', 'className', 'log', 'objectName', 'objectIds', 'message', 'stackTrace', 'inJSON', u.id);
        logs.add(log);
        logg1.write(logs);
        logg.finalize();
        logg.pruneLogs();
        //only log line cover
        logg1.log( 'identifier', 'className', 'e');
        logg1.log('identifier', 'className', 'e', 'inJSON');
        logg1.log('identifier', 'className', Logger.Level.DEBUG, 'inJSON');
        logg1.log('identifier', 'className', Logger.Level.DEBUG, 'message', 'inJSON');
        //log line with list use cover
        List<Id> objectIdList = new List<Id>();
        objectIdList.add(Acc.Id);
        logg1.log('identifier', 'className', 'Account', objectIdList, 'message');
        logg1.log('identifier', 'className', Logger.Level.DEBUG, 'Account', objectIdList, 'message');
        
        //set log line cover 
        set<id> objectIdSet = new set<id>();
        objectIdSet.add(Acc.Id);
        logg1.log('identifier', 'className', 'Account', objectIdSet, 'message');
        logg1.log('identifier', 'className', Logger.Level.DEBUG, 'Account', objectIdSet, 'message');
        
        //Exception Hendling log line cover
        logg1.log('identifier', 'className', new DmlException());
        logg1.log('identifier', 'className', 'Account',new DmlException());
        logg1.log('identifier', 'className', 'Account', new DmlException(), 'inJSON');
         logg1.log('identifier', 'className', new DmlException(),'inJSON');
        
        //DataBase save Result line cover
        //insert 
        Account[] accts = new List<Account>{
        new Account(Name='Account1'),
        new Account()};
        Database.SaveResult[] srList = Database.insert(accts, false);
        logg1.log('identifier', 'className', 'objectName',srList);
        //update
        Account[] accts1 = new List<Account>{
        new Account(Name='Accounttest'),
        new Account()};
        List<Database.UpsertResult> updateList = Database.upsert(accts1, false);
        logg1.log('identifier', 'className', 'objectName',updateList);
        Logger.getInstance(true, true);
    }
}