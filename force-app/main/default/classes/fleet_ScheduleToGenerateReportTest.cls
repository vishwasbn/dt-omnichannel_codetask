@isTest
public class fleet_ScheduleToGenerateReportTest {
    @isTest(SeeAllData=true)
    static void generateReportTest(){
        Test.StartTest();
        fleet_ScheduleToGenerateReport generateReportObj = new fleet_ScheduleToGenerateReport();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Generate Report', sch, generateReportObj);
        Test.stopTest();
    }
}