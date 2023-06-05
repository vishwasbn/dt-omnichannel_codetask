@isTest
public with sharing class Fleet_UserUtilTest {
    @IsTest 
    public static void unlockUserNegativeTest() {

        Test.startTest();
        String result = Fleet_UserUtil.unlockUser('0033F00000TetizQAB');
        System.debug(result);
        Test.stopTest();

        System.assert(result == 'No Users Found', 'Negative Test');
    }


    @IsTest 
    public static void deactivateUserNegativeTest() {

        Test.startTest();
        String result = Fleet_UserUtil.deactivateUser('0033F00000TetizQAB');
        System.debug(result);
        Test.stopTest();

        System.assert(result == 'error', 'Negative Test');
    }
}