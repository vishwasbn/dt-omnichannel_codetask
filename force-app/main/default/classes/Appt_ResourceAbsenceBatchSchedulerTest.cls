@isTest
public class Appt_ResourceAbsenceBatchSchedulerTest {

@isTest static void executeTest(){
        test.startTest();
        SchedulableContext sc = null;
        Appt_ResourceAbsenceBatchSchduler tsc = new Appt_ResourceAbsenceBatchSchduler();
        tsc.execute(sc);
    	test.stopTest();
         
    }  
    
}