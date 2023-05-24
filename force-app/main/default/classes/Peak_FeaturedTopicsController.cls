/**
 * Created by jonbalza on 12/8/18.
 */

public with sharing class Peak_FeaturedTopicsController {

    // Get a list of featured topics for the active community
    @AuraEnabled
    public static ConnectApi.ManagedTopicCollection getFeaturedTopics() {
        String networkId = Network.getNetworkId();

        if(Test.isRunningTest()){
            List<Network> networks = [SELECT id FROM Network];
            networkId = networks[0].id;
        }

        ConnectApi.ManagedTopicCollection featuredTopics = ConnectAPI.ManagedTopics.getManagedTopics(networkId, ConnectApi.ManagedTopicType.Featured);

        return featuredTopics;
    }

}