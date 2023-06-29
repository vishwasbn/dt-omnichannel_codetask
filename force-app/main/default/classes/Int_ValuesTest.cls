@IsTest
public with sharing class Int_ValuesTest {

    @IsTest
    static void ConstantTest(){
        Test.startTest();
        System.assertEquals(Int_Values.TYPE_CAR_LIST,'CAR_LIST');
        test.stopTest();
    }

    @IsTest
    static void createGUIDTest(){
        Test.startTest();
        System.assertNotEquals(Int_Values.createGUID(),null);
        test.stopTest();
    }

    @IsTest
    static void timingListTest(){
        Test.startTest();
        DateTime startTime = DateTime.newInstance(1997, 1, 31, 7, 8, 16);
        DateTime endTime = startTime.addHours(1);
        Int_Values.addTiming('First_Time_stamp',startTime, endTime);
        System.assertEquals(Int_Values.timingList.size(),1);
        test.stopTest();
    }

    @IsTest
    static void getDurationTest(){
        Test.startTest();
        DateTime startTime = DateTime.newInstance(1997, 1, 31, 7, 8, 16);
        DateTime endTime = startTime.addHours(1);
        System.assertEquals(Int_Values.getDuration(startTime, endTime),0);
        test.stopTest();
    }

    @IsTest
    static void getTimingLogTest(){
        Test.startTest();
        System.assertEquals(Int_Values.getTimingLog(),'');
        test.stopTest();
    }
}