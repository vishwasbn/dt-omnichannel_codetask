@IsTest
public class Peak_KnowledgeFile_FileWrapperTest {
    @IsTest
    public static void wrapperTest() {
        Peak_KnowledgeFile_FileWrapper wr = new Peak_KnowledgeFile_FileWrapper('0017900000LI8qFAAT' ,'test title', DateTime.newInstance(1997, 1, 31, 7, 8, 16) , 2, '.pdf');
        wr.id = '0027900000LI8qFAAT';
        wr.title = 'file2';
        wr.lastModifiedDate = DateTime.newInstance(1997, 1, 31, 7, 8, 16);
        wr.contentSize = 12;
        wr.fileExtension = '.xls';
        system.assertNotEquals(wr, null);
    }
}