public with sharing class Logger {

    public Enum Level {ERROR, WARN, DEBUG, INFO}

    private static Logger LOGGER_INSTANCE = null;

    private Boolean allowMultiple = false;
    private Settings settings;
    private List<Log> logs;
    private List<LogEvent__e> logEvents;

    /**
     * Private constructor that sets the allowing of multiple logs, and gets the settings
     * @param  inMultiple TRUE if we allow multiple logs in one instance, FALSE if we want to publish immediately
     */
    @TestVisible private Logger(Boolean inMultiple) {
        this.allowMultiple = inMultiple;
        this.logEvents = new List<LogEvent__e>();
        this.settings = new Settings(false);
        this.logs = new List<Log>();
    }

   /**
     * Private constructor same as above - added platformEvent parameter to pass it to LoggerSettings
     * @param  inMultiple TRUE if we allow multiple logs in one instance, FALSE if we want to publish immediately
     *         platformEvent  TRUE to bypass Platform Event for unit testing
     */
     @TestVisible private Logger(Boolean inMultiple, Boolean platformEvent) {
        this.allowMultiple = inMultiple;
        this.logEvents = new List<LogEvent__e>();
        this.settings = new Settings(platformEvent);
        this.logs = new List<Log>();
    }

    /**
     * Public getter of an instance. Really used to get the same instance across multiple classes like triggers
     * @param  inMultiple TRUE if we allow multiple logs in one instance, FALSE if we want to publish immediately
     * @return            A Logger instance
     */
    public static Logger getInstance(Boolean inMultiple) {
        if (LOGGER_INSTANCE == null) {
            LOGGER_INSTANCE = new Logger(inMultiple);
        }
        return LOGGER_INSTANCE;
    }

    /**
     * Public getter of an instance same as above. Really used to get the same instance across multiple classes like triggers
     * @param  inMultiple TRUE if we allow multiple logs in one instance, FALSE if we want to publish immediately
     *         platformEvent  TRUE to bypass Platform Event for unit testing
     * @return            A Logger instance
     */
    public static Logger getInstance(Boolean inMultiple, Boolean platformEvent) {
        if (LOGGER_INSTANCE == null) {
            LOGGER_INSTANCE = new Logger(inMultiple, platformEvent);
        }
        return LOGGER_INSTANCE;
    }
    public static Logger getInstance() {
        return Logger.getInstance(false);
    }

    /**
     * Creates a Log Platform Event if bypass Platform event is false and logging is enabled, that will then create a Log object outside of the current process or
     * create a Log Object if bypass Platform event is true and logging is enabled, that will then create a Log object within current process
     * @param  className    Class Name (where this action happened)
     * @param  level        Level enum (ERROR, WARN, DEBUG, INFO)
     * @param  objectName   Object Name (if we are doing DML statements)
     * @param  objectIdList List of Object IDs Affected
     * @param  message      Message
     * @param  stackTrace   Exception Stack Trace
     * @param  inJSON       JSON From API
     */
    public void log(String identifier, String className, Level level, String objectName, List<Id> objectIdList, String message, String stackTrace, String inJSON) {
        String objectIds;
        if (objectIdList != null && objectIdList.size() > 0) {
            objectIds = String.join(objectIdList, ',');
        }

        Log log = new Log(identifier, className, level.name(), objectName, objectIds, message, stackTrace, inJson, userInfo.getUserId());

        if (settings.logToSystemDebug) {
            System.debug(JSON.serialize(log));
        }

        if (settings.enableLogging) {
            if (settings.enablePlatformEvents) {
                LogEvent__e le = log.toPlatformEvent();

                if (this.allowMultiple) {
                    logEvents.add(le);
                } else {
                    EventBus.publish(le);
                }
            } else {
                if (this.allowMultiple) {
                    logs.add(log);
                } else {
                    List<Log> logList = new List<Log>{log};
                    write(logList);
                }
            }
        }
    }

    /**
     * Called at the end of an execution context to bulkify the publishing of log events/logs in the case of allowMultiple = TRUE
     */
    public void finalize() {
        if (this.allowMultiple) {
            if (!logEvents.isEmpty()) {
                EventBus.publish(logEvents);
            }
            if (!logs.isEmpty()) {
                write(logs);
            }
        }
    }

    // Overrides
    public void log(String identifier, String className, String message) {
        log(identifier, className, Level.ERROR, null, null, message, null, null);
    }
    public void log(String identifier, String className, Level level, String message) {
        log(identifier, className, level, null, null, message, null, null);
    }
    public void log(String identifier, String className, String message, String inJSON) {
        log(identifier, className, Level.ERROR, null, null, message, null, inJSON);
    }
    public void log(String identifier, String className, Level level, String message, String inJSON) {
        log(identifier, className, level, null, null, message, null, inJSON);
    }
    public void log(String identifier, String className, String objectName, List<Id> objectIdList, String message) {
        log(identifier, className, Level.ERROR, objectName, objectIdList, message, null, null);
    }
    public void log(String identifier, String className, String objectName, Set<Id> objectIdSet, String message) {
        List<Id> objectIdList;
        if (objectIdSet != null) {
            objectIdList = new List<Id>(objectIdSet);
        }
        log(identifier, className, Level.ERROR, objectName, objectIdList, message, null, null);
    }
    public void log(String identifier, String className, Level level, String objectName, List<Id> objectIdList, String message) {
        log(identifier, className, level, objectName, objectIdList, message, null, null);
    }
    public void log(String identifier, String className, Level level, String objectName, Set<Id> objectIdSet, String message) {
        List<Id> objectIdList;
        if (objectIdSet != null) {
            objectIdList = new List<Id>(objectIdSet);
        }
        log(identifier, className, level, objectName, objectIdList, message, null, null);
    }

    // Exception handling
    public void log(String identifier, String className, Exception e) {
        log(identifier, className, Level.ERROR, null, null, e.getMessage(), e.getStackTraceString(), null);
    }
    public void log(String identifier, String className, Exception e, String inJSON) {
        log(identifier, className, Level.ERROR, null, null, e.getMessage(), e.getStackTraceString(), inJSON);
    }
    public void log(String identifier, String className, String objectName, Exception e) {
        log(identifier, className, Level.ERROR, objectName, null, e.getMessage(), e.getStackTraceString(), null);
    }
    public void log(String identifier, String className, String objectName, Exception e, String inJSON) {
        log(identifier, className, Level.ERROR, objectName, null, e.getMessage(), e.getStackTraceString(), inJSON);
    }

    // DML Error Handling
    public Boolean log(String identifier, String className, String objectName, List<Database.SaveResult> results) {
        Boolean result = true;
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                String errorMsg = '';
                for (Database.Error err : sr.getErrors()) {
                    errorMsg += err.getMessage() + '\n';
                }
                log(identifier, className, Level.ERROR, objectName, null, errorMsg, null, null);
                result = false;
            }
        }
        return result;
    }
    public Boolean log(String identifier, String className, String objectName, List<Database.UpsertResult> results) {
        Boolean result = true;
        for (Database.UpsertResult sr : results) {
            if (!sr.isSuccess()) {
                String errorMsg = '';
                for (Database.Error err : sr.getErrors()) {
                    errorMsg += err.getMessage() + '\n';
                }
                log(identifier, className, Level.ERROR, objectName, null, errorMsg, null, null);
                result = false;
            }
        }
        return result;
    }

    /**
     * Check the custom metadata type if pruning is enabled to prevent org limits
     */
    public void pruneLogs() {
        // If it's off, end here
        if (!settings.enablePruning) {
            return;
        }

        if (settings.maxAgeLogs != null && settings.maxAgeLogs > 0) {

        }

        Integer logCount = [SELECT COUNT() FROM Log__c LIMIT :settings.maxLogs];
        // If it's less than the max, end here
        if (logCount < settings.maxLogs) {
            return;
        }

        Log__c firstLogToPrune;

        // Get the CreatedDate of the first log to prune
        try {
            firstLogToPrune = [SELECT CreatedDate FROM Log__c ORDER BY CreatedDate DESC LIMIT 1 OFFSET :settings.maxLogs];
        } catch (Exception e) {
            // If this throws an exception, then there's a mismatch or some other race condition. Just exit and it'll correct
            // itself on the next run.
            return;
        }

        // Seed the Queueable and queue it up
        LogPruneQueueable lpq = new LogPruneQueueable(firstLogToPrune.CreatedDate);
        System.enqueueJob(lpq);
    }

    /**
     * Check the custom metadata type for the interfaced classes and call them in order
     * @param  logs updated from Log method
     */
    public void write(List<Log> logs) {
        if (logs.size() > 0) {
            List<String> values = settings.classOrder.split(',');

            for (String value : values) {
                try {
                    LogWriter logWriter = (LogWriter) Type.forName(value).newInstance();
                    logWriter.write(logs);
                } catch (Exception e) {
                    System.debug(e.getMessage());
                }
            }
        }
    }

    public class Log {

        public String identifier {get; set;}
        public String className {get; set;}
        public String level {get; set;}
        public String objectName {get; set;}
        public String objectIds {get; set;}
        public String message {get; set;}
        public String stackTrace {get; set;}
        public String inJson {get; set;}
        public String user {get; set;}

        public Log(String identifier, String className, String level, String objectName, String objectIds, String message, String stackTrace, String inJSON, String user) {
            this.identifier = identifier;
            this.className = className;
            this.level = level;
            this.objectName = objectName;
            this.objectIds = objectIds;
            this.message = message;
            this.stackTrace = stackTrace;
            this.inJson = inJson;
            this.user = user;
        }

        public Log(LogEvent__e le) {
            this.identifier = le.Identifier__c;
            this.className = le.ClassName__c;
            this.level = le.Level__c;
            this.objectName = le.ObjectName__c;
            this.objectIds = le.ObjectIDs__c;
            this.message = le.Message__c;
            this.stackTrace = le.StackTrace__c;
            this.inJson = le.JSON__c;
            this.user = le.CreatedbyId;
        }

        public LogEvent__e toPlatformEvent() {
            return new LogEvent__e(
                Identifier__c = this.identifier,
                ClassName__c = this.className,
                Level__c = this.level,
                ObjectName__c = this.objectName,
                ObjectIDs__c = this.objectIds,
                Message__c = this.message,
                StackTrace__c = this.stackTrace,
                JSON__c = this.inJSON
            );
        }

        public Log__c toLogObject() {
            return new Log__c(
                Identifier__c = this.identifier,
                ClassName__c = this.className,
                Level__c = this.level,
                ObjectName__c = this.objectName,
                ObjectIDs__c = this.objectIds,
                Message__c = this.message,
                StackTrace__c = this.stackTrace,
                JSON__c = this.inJson,
                User__c = this.user
            );
        }

    }

    public with sharing class Settings {

        public Boolean enableLogging;
        public Boolean enablePruning;
        public String classOrder;
        public Integer maxLogs;
        public Integer maxAgeLogs;
        public Boolean enablePlatformEvents;
        public Boolean logToSystemDebug;

        public Settings(Boolean platformEvent) {
            // If in a unit test, fake the settings. Custom Metadata requires running with SeeAllData=true.
            if (Test.isRunningTest()) {
                this.enableLogging = true;
                this.enablePruning = true;
                this.classOrder = 'LogToObject';
                this.maxLogs = 10;
                this.enablePlatformEvents = true;
                if (platformEvent) {
                    this.enablePlatformEvents = false;
                }
                this.logToSystemDebug = false;
            } else {
                Log_Settings__mdt lsSettings = [SELECT Enable_Logging__c, Enable_Pruning__c, Interfaced_Class_Order__c, Max_Number_Of_Logs__c, Max_Age_Of_Logs__c, Enable_Platform_Events__c, Log_To_System_Debug__c FROM Log_Settings__mdt ORDER BY Created_Date__c DESC LIMIT 1];
                this.enableLogging = lsSettings.Enable_Logging__c;
                this.enablePruning = lsSettings.Enable_Pruning__c;
                this.classOrder = lsSettings.Interfaced_Class_Order__c;
                this.maxLogs = Integer.valueOf(lsSettings.Max_Number_Of_Logs__c);
                this.maxAgeLogs = Integer.valueOf(lsSettings.Max_Age_Of_Logs__c);
                this.enablePlatformEvents = lsSettings.Enable_Platform_Events__c;
                this.logToSystemDebug = lsSettings.Log_To_System_Debug__c;
            }
        }

    }

}