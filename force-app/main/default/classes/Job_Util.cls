/**
 * @author Steve Simpson (steve.simpson@appsassociates.com)
 * @date 6/9/22
 * @description Job Utility class
 */

public class Job_Util
{

    //---Get a list of the limits, with the total and current values
    public static List<Job_LimitStatus> getLimitListSnapshot()
    {
        List<Job_LimitStatus> limitList = new List<Job_LimitStatus>();
      
        limitList.add( buildLimitStatus('AggregateQueries', Limits.getLimitAggregateQueries(),Limits.getAggregateQueries()));
        limitList.add( buildLimitStatus('AsyncCalls', Limits.getLimitAsyncCalls(),Limits.getAsyncCalls()));
        limitList.add( buildLimitStatus('Callouts', Limits.getLimitCallouts(),Limits.getCallouts()));
        limitList.add( buildLimitStatus('CpuTime', Limits.getLimitCpuTime(),Limits.getCpuTime()));
        limitList.add( buildLimitStatus('DMLRows', Limits.getLimitDMLRows(),Limits.getDMLRows()));
        limitList.add( buildLimitStatus('DMLStatements', Limits.getLimitDMLStatements(),Limits.getDMLStatements()));
        limitList.add( buildLimitStatus('EmailInvocations', Limits.getLimitEmailInvocations(),Limits.getEmailInvocations()));
        limitList.add( buildLimitStatus('FutureCalls', Limits.getLimitFutureCalls(),Limits.getFutureCalls()));
        limitList.add( buildLimitStatus('HeapSize', Limits.getLimitHeapSize(),Limits.getHeapSize()));
        limitList.add( buildLimitStatus('MobilePushApexCalls', Limits.getLimitMobilePushApexCalls(),Limits.getMobilePushApexCalls()));
        limitList.add( buildLimitStatus('PublishImmediateDML', Limits.getLimitPublishImmediateDML(),Limits.getPublishImmediateDML()));
        limitList.add( buildLimitStatus('Queries', Limits.getLimitQueries(),Limits.getQueries()));
        limitList.add( buildLimitStatus('QueryLocatorRows', Limits.getLimitQueryLocatorRows(),Limits.getQueryLocatorRows()));
        limitList.add( buildLimitStatus('QueryRows', Limits.getLimitQueryRows(),Limits.getQueryRows()));
        limitList.add( buildLimitStatus('QueueableJobs', Limits.getLimitQueueableJobs(),Limits.getQueueableJobs()));
        limitList.add( buildLimitStatus('SoslQueries', Limits.getLimitSoslQueries(),Limits.getSoslQueries()));

        return limitList;
    }

    //---Get an initial limit status
    public static Job_LimitStatus buildLimitStatus(String name, Integer limitValue, Integer currentValue)
    {
        //---Create the Limit Status
        Job_LimitStatus newStatus = new Job_LimitStatus();
        newStatus.name = name;
        newStatus.limitValue = limitValue;
        newStatus.currentValue = currentValue;   //---Note, this is writing to Current Value, it can be copied to other fields

        return newStatus;
    }
}