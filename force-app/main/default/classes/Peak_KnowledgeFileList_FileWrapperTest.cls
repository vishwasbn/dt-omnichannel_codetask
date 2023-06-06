/**
 * Created by francoiskorb on 2019-06-12.
 */

@IsTest
private class Peak_KnowledgeFileList_FileWrapperTest
{
	@IsTest
	static void testKnowledgeFileList_FileWrapper()
	{
		String fakeIdString = Peak_TestUtils.getFakeId(ContentDocument.SObjectType);
		Id fakeId = Id.valueOf(fakeIdString);

		Datetime modified = Datetime.now();
		Peak_KnowledgeFileList_FileWrapper wrapper = new Peak_KnowledgeFileList_FileWrapper(
			fakeId, 'Title', modified, 1000, 'ext');
		System.assertNotEquals(null, wrapper);
	}
}