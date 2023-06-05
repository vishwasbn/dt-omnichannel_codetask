public class Appt_ResourceAbsenceBatchSchduler implements Schedulable{

    public void execute(SchedulableContext sc) {
      	Appt_ResourceAbsenceBatch AppReABBatch = new Appt_ResourceAbsenceBatch(); 
        database.executebatch(AppReABBatch,25);
      	/*String sch = '0 0 22 * * ?';
		String jobID = system.schedule('Appt_ResourceAbsenceBatch', sch, AppReABBatch);*/
   }
}