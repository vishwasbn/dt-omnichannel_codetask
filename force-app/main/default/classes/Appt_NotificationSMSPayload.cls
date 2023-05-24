public with sharing class Appt_NotificationSMSPayload {
    String phoneNumber;
    String smsContent;
    String state;
    String requestType;
    String appointmentDate;
    String appointmentTime;
    String storeSAPId;
    String appointmentId;
    String customerName;
    String redirectLink;
    String appointmentStatus;
    //String actionStatus;
    //String failureMessage;


    public Appt_NotificationSMSPayload( String phoneNumber, 
                                        String smsContent, 
                                        String state, 
                                        String requestType, 
                                        String appointmentDate, 
                                        String appointmentTime, 
                                        String storeSAPId,
                                        String appointmentId,
                                        String customerName,
                                        String redirectLink,
                                        String appointmentStatus) {

        this.phoneNumber = phoneNumber;
        this.smsContent = smsContent ;
        this.state = state;
        this.requestType = requestType;
        this.appointmentDate = appointmentDate;
        this.appointmentTime = appointmentTime;
        this.storeSAPId = storeSAPId;
        this.appointmentId = appointmentId;
        this.customerName = customerName;
        this.redirectLink = redirectLink;
        this.appointmentStatus = appointmentStatus;
        //this.actionStatus = actionStatus;
        //this.failureMessage = failureMessage;

    }    
}