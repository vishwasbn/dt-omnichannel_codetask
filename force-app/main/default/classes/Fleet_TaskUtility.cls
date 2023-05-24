/**
 Created By : Ritika Sharma
 Creatted Dated : 12/22/2022
 Description : This Class is called from a flow 'Follow-up with customer regarding approved account' to ,create task with duedate and reminderdate 
 User Story Number : Salesforce-818.
 */
public class Fleet_TaskUtility {
  Public Static final String subject = 'Follow-up with customer regarding approved account';
  Public Static Date Activity_date;
  Public Static Date Activity_date1;
  Public Static Integer count=0;
  Public Static Integer numofholidays=0;
  Public Static DateTime dT1 = system.now();
  Public Static Date myDate1 = date.newinstance(dT1.year(), dT1.month(), dT1.day());
  Public Static Date weekStart1  = myDate1.toStartofWeek();
  Public Static Date Due_date;
    
  Public static boolean holidaylist()
  {  
     list<date> datelist = new list<date>();
     map<ID, StoreHolidays__c> holidayKeyHolidayRecMap = new map<ID, StoreHolidays__c>([SELECT id, Active__c, End__c,Name, Start__c  FROM StoreHolidays__c WHERE Active__c = true 
                                                                                        AND Start__c >= TODAY]); 
     for(StoreHolidays__c sh:holidayKeyHolidayRecMap.values())
      {//To get list of dates have holidays 
         DateTime dT = sh.start__c;
         Date myDate = date.newinstance(dT.year(), dT.month(), dT.day());
         datelist.add(mydate);
     }
   

     Integer todayday = weekStart1.daysBetween(myDate1);
     //Date Due_date;
      //to get due date value
     checktodayday(todayday);

     Due_date=myDate1.addDays(count);
     Date weekStart  = Due_date.toStartofWeek();
      Activity_date1=Due_date;
      //To check how many holidays will be there between duedate and task created date 
     if(datelist.size()>0)
     {
         for(integer i=0;i<datelist.size();i++)
         {
             if(datelist[i]>=myDate1 && datelist[i]<=due_date)
             {
                if(weekStart1.daysbetween(datelist[i])==7||weekStart1.daysbetween(datelist[i])==6)
                {//To check if any holidays is on weekends
                    system.debug('holiday is on weekends' + datelist[i]);
                   
                }
                 else
                 {//To add number of holidays days to duedate 
                     system.debug('holiday is on weekdays'+ datelist[i]);
                     numofholidays++;
                     system.debug(numofholidays);
                 }
             }
            // else
            // {
                // datelist.remove(i);
            // }
          }
         if(weekStart.daysBetween(Due_date)==5 && numofholidays!=0)
             {
                 Activity_date1=Due_date.addDays(numofholidays+2);
             }
         else 
         {
             Activity_date1=Due_date.addDays(numofholidays);
         }
      
         
    }
  return true;
      
 }
   public static void checktodayday(Integer daytoday)
   {
            switch on daytoday {
          when 0 {
               //If num is 3 this block is called
               System.debug('Today is sunday');
               count=5;
           }
          when 1{
               //If num is 5 this block is called
               System.debug('Today is Monday');
               count=4;
           }
          when 2 {
               //If num is 3 this block is called
               System.debug('Today is Tuesday');
               count=6;
           }
          when 3 {
               //If num is 3 this block is called
               System.debug('Today is Wednesday');
               count=6;
           }
          when 4 {
               //If num is 3 this block is called
               System.debug('Today is Thrusday');
               count=6;
           }
          when 5 {
               //If num is 3 this block is called
               System.debug('Today is Friday');
               count=6;
           }
          when else {
               //If num did not match any of the blocks already, this block is called
               System.debug('Today is Saturday');
               count=6;
           }
        } 
       
   }
    
 @InvocableMethod(label='Get account' description='Returns the list of tasks with updated duedate and reminder date.' category='Task')
 public static Void handleaccount(list<id> acclist) 
 {   
     list<task> tasklist= new list<task>();
     list<account> acctlist =new list<account>([select id, ownerid, name,Fleet_Specialist__c from Account where id in: acclist]);
     if(Fleet_TaskUtility.holidaylist())
     {//To check if due date is on weekends 
         Activity_date=Activity_date1;
         Date weekStart  = Activity_date1.toStartofWeek();
         if(weekStart.daysbetween(Activity_date1)==0)
        {   system.debug('Duedate is on sunday');
            Activity_date=Activity_date1.addDays(1);
         } else if(weekStart.daysbetween(Activity_date1)==6)
           {  system.debug('Duedate is on saturday');
              Activity_date=Activity_date1.addDays(2);   
           }else
             { system.debug('Duedate is on weekdays');
              }
         
         for(Account acc : acctlist)
      {   //creating a related task for account 
         Task Tsk= new Task();
         Tsk.whatid= acc.id;
         Tsk.Subject=subject; 
         Tsk.IsReminderSet=true;
         Tsk.ActivityDate= Activity_date;
         Tsk.ReminderDateTime= datetime.newInstance(Activity_date, Time.newInstance(09,00,00,00)); 
         Tsk.OwnerId=acc.Fleet_Specialist__c;
         tasklist.add(Tsk);
       }
     }
     insert tasklist;
 }     
}