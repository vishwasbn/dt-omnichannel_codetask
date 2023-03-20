global without sharing class scheduleToGenerateReport implements Schedulable {
   global void execute(SchedulableContext SC) {
     	date myDate = date.today();
        Date newDate = myDate.addDays(+1);       
        String yesterday = newDate.year() + '/' + newDate.month() + '/' + newDate.day();
        String today= myDate.year() + '/' + myDate.month() + '/' + myDate.day();
        Fleet_SendJsonSingleEmail fe= new Fleet_SendJsonSingleEmail(true, yesterday, today);
        Database.executeBatch(fe,200); 
   }
}