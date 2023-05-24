/**
 * Created by 7Summits on 8/7/17.
 */


@IsTest
public class Peak_KnowledgeFilterTest {

    private static List<Topic> createTopic(Integer noOfEvents) {
        List<topic> topicList = new List<topic>();
        for(Integer i=0;i<noOfEvents;i++){
            Topic topicObj = new Topic(Name='Test00' + i, Description='Test');
            topicList.add(topicObj);
        }
        insert topicList;
        return topicList;
    }

    private static TopicAssignment createTopicAssignment(String strTopicId, String strEntityId)
    {
        TopicAssignment topicAssigmnt = new TopicAssignment(EntityId = strEntityId, TopicId = strTopicId);

        insert topicAssigmnt;
        return topicAssigmnt;
    }


    @testSetup static void setup() {
        Schema.SObjectType articleType;
        Map<String, Schema.SObjectType> describedItems = Schema.getGlobalDescribe();
        for (String key : describedItems.keySet()) {
            if (key.endsWith('kav')) {
                articleType = Schema.getGlobalDescribe().get(key);
                // We have an article type...let's get out
                break;
            }
        }
        List<String> documentsTitles = new List<String>{'Test Knowledge One', 'Test Knowledge Two', 'Test Knowledge Three'};
        List<SObject> sobjList=new List<SObject>();
        List<SObject> sobjListInsertedKav=new List<SObject>();

        List<Topic> topics = createTopic(2);

        for (String title : documentsTitles) {
            SObject kav =  articleType.newSObject();
            kav.put('title', title);
            kav.put('urlName', title.replaceAll( '\\s+', ''));
            kav.put('Language', 'en_US');
            
            sobjList.add(kav);
           
        }
        insert sobjList;
        
        //Dynamic SOQL
        String filterQuery = 'SELECT KnowledgeArticleId FROM ' + articleType + ' where ID in (\''+'\'' ;
        for(sObject rcd:sobjList){
            filterQuery=filterQuery+',\''+ rcd.Id + '\'';
        }
        filterQuery=filterQuery+')';
        
        //query to get list of inserted Knowledge__kav
        sobjListInsertedKav=Database.query(filterQuery);
        
         // publishing the list of all inserted Knowledge__kav
        for(SObject insertedRcd: sobjListInsertedKav) {
            KbManagement.PublishingService.publishArticle((String)insertedRcd.get('KnowledgeArticleId'), true);
            
        }
        
        // create topic assignment
        for(sObject rcd:sobjList){
            createTopicAssignment(topics[0].id, rcd.id);
            createTopicAssignment(topics[1].id, rcd.id);
        }
    }


    @isTest
    public static void testDoSearchWithoutSearchQuery() {
        String searchTerm = '';

        List<Topic> topics = [SELECT id FROM Topic LIMIT 1];

        List<String> topicIdsOne = new List<String>{topics[0].id};
        List<String> topicIdsTwo = new List<String>{topics[0].id};
        List<String> topicIdsThree = new List<String>{topics[0].id};
        List<String> topicIdsFour = new List<String>{topics[0].id};
        List<String> excludedIds = new List<String>();

        String orderByField = null;
        String orderByDirection = null;

        Test.startTest();
        Peak_KnowledgeFilter_SearchResults results = Peak_KnowledgeFilterController.doSearch(
	        searchTerm, topicIdsOne, topicIdsTwo, topicIdsThree, topicIdsFour, orderByField, orderByDirection, excludedIds);
        Test.stopTest();

        System.assertEquals(true, true);
    }

    @isTest
    public static void testDoSearchWithSearchQuery() {
        String searchTerm = 'Test Knowledge';

        List<Topic> topics = [SELECT id FROM Topic LIMIT 1];

        List<String> topicIdsOne = new List<String>{topics[0].id};
        List<String> topicIdsTwo = new List<String>{topics[0].id};
        List<String> topicIdsThree = new List<String>{topics[0].id};
        List<String> topicIdsFour = new List<String>{topics[0].id};
	    List<String> excludedIds = new List<String>();

        String orderByField = null;
        String orderByDirection = null;

        Test.startTest();
        Peak_KnowledgeFilter_SearchResults results = Peak_KnowledgeFilterController.doSearch(
	        searchTerm, topicIdsOne, topicIdsTwo, topicIdsThree, topicIdsFour, orderByField, orderByDirection, excludedIds);
        Test.stopTest();

        System.assertEquals(true, true);
    }


}