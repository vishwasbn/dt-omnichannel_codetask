@isTest(seeAllData=true)
public class Fleet_SendJsonSingleEmailTest {    
    public static testMethod void Fleet_SendJsonSingleEmailTestMethod()
    {
        Id profileId1 = [Select Id From Profile Where Name ='System Administrator'].Id;
        User adminUser = Fleet_TestUtility.createUser('',profileId1,'Pavan','Prathi');
        Test.startTest();        
        System.runAs(adminUser) {  
         Fleet_SendJsonSingleEmail fsJAllDefault = new Fleet_SendJsonSingleEmail();
            Database.executeBatch(fsJAllDefault,100);   
              /*Fleet_SendJsonSingleEmail fsJNoOfDays = new Fleet_SendJsonSingleEmail(1);
            Database.executeBatch(fsJNoOfDays,100);*/
          Fleet_SendJsonSingleEmail fsJDelta = new Fleet_SendJsonSingleEmail(true,'2022/01/02');             
            Database.executeBatch(fsJDelta,100);
            Fleet_SendJsonSingleEmail fsJDeltaFrom = new Fleet_SendJsonSingleEmail(true,null);             
            Database.executeBatch(fsJDeltaFrom,200);
/*Fleet_SendJsonSingleEmail fsJDeltaFrom = new Fleet_SendJsonSingleEmail(true,'2022/01/01');             
            Database.executeBatch(fsJDeltaFrom,200); */
            
                Fleet_SendJsonSingleEmail fsJDeltaRange= new Fleet_SendJsonSingleEmail(true,'2022/01/01','2022/01/21');             
            Database.executeBatch(fsJDeltaRange,100);
            
            Fleet_SendJsonSingleEmail fsJAll = new Fleet_SendJsonSingleEmail(false,null); 
            Database.executeBatch(fsJAll,200); 
            
        }        
        Test.stopTest();       
    }
      /*public static testMethod void Fleet_SendJsonSingleEmailTestMethod2()
    {
        Id profileId1 = [Select Id From Profile Where Name ='System Administrator'].Id;
        User adminUser = Fleet_TestUtility.createUser('',profileId1,'Pavan','Prathi');
        Test.startTest();        
        System.runAs(adminUser) { 
             Fleet_SendJsonSingleEmail fsJNoOfDays = new Fleet_SendJsonSingleEmail(200);
            Database.executeBatch(fsJNoOfDays,200);
           /* Fleet_SendJsonSingleEmail fsJAllDefault = new Fleet_SendJsonSingleEmail();
            Database.executeBatch(fsJAllDefault,200); /*  
             
          /* Fleet_SendJsonSingleEmail fsJDelta = new Fleet_SendJsonSingleEmail(true,null);             
            Database.executeBatch(fsJDelta,200); */
            /* Fleet_SendJsonSingleEmail fsJDeltaFrom = new Fleet_SendJsonSingleEmail(true,null);             
            Database.executeBatch(fsJDeltaFrom,200);*/
/*Fleet_SendJsonSingleEmail fsJDeltaFrom = new Fleet_SendJsonSingleEmail(true,'2022/01/01');             
            Database.executeBatch(fsJDeltaFrom,200); */
            
              /*Fleet_SendJsonSingleEmail fsJDeltaRange= new Fleet_SendJsonSingleEmail(true,'2022/01/01','2022/01/21');             
            Database.executeBatch(fsJDeltaRange,200);
            
           Fleet_SendJsonSingleEmail fsJAll = new Fleet_SendJsonSingleEmail(false,null); 
            Database.executeBatch(fsJAll,200); 
            
        }        
        Test.stopTest();       
    }*/
}