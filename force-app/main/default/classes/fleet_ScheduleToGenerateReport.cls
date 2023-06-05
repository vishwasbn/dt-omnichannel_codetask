global class fleet_ScheduleToGenerateReport implements Schedulable {
   global void execute(SchedulableContext SC) {
     	date myDate = date.today(); 
        Date yesterdayDate=myDate.addDays(-1);          
        Date newDate = myDate.addDays(+1);       
        String today = yesterdayDate.year() + '/' + yesterdayDate.month() + '/' + yesterdayDate.day();
        String tomorrow= newDate.year() + '/' + newDate.month() + '/' + newDate.day();
        Fleet_SendJsonSingleEmail fe= new Fleet_SendJsonSingleEmail(true, today, tomorrow);
        Database.executeBatch(fe,200); 
   }
}