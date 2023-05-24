global class ScheduleBatchDeleteOutgoingAttachments implements Schedulable {
    global void execute(SchedulableContext sc) {
        BatchDeleteOutgoingEmailAttachments b = new BatchDeleteOutgoingEmailAttachments();
        database.executebatch(b);
    }
}