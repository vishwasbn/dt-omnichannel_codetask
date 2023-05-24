global class ScheduleBatchUpdateAccountCaseCheckbox implements Schedulable {
    global void execute(SchedulableContext sc) {
      BatchUpdateAccountMultipleCaseCheckbox b = new BatchUpdateAccountMultipleCaseCheckbox();
      database.executebatch(b);
   }
}