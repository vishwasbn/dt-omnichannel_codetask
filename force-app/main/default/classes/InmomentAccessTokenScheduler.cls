global class InmomentAccessTokenScheduler implements Schedulable, Database.AllowsCallouts {
    global void execute(SchedulableContext SC) {
        InmomentAPIUtility.getAuthToken();
    }
}