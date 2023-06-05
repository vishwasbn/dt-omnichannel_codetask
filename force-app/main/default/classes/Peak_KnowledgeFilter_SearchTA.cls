/**
 * Created by 7Summits on 1/30/18.
 */

public without sharing class Peak_KnowledgeFilter_SearchTA {

    public static Set<Id> getTopicAssignments(Set<String> topicIds) {
        List<TopicAssignment> topicAssignments = [SELECT EntityId FROM TopicAssignment WHERE IsDeleted = false AND TopicId IN :topicIds];
        Set<Id> results = new Set<Id>();
        for (TopicAssignment t : topicAssignments) {
            results.add(t.EntityId);
        }
        return results;
    }

}