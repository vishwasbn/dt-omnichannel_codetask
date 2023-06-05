public with sharing class Appt_NotificationEmailPayload {
   
        public String subscriberKey;
        public String emailAddress;
        public String communicationType;
        public String transactionType;
        public String orderNumber;
        public String orderCreatedDate;
        public String customerName;
        public String vehicleId;
        public String vehicleInformation;
        public String streetAddress;
        public String city;
        public String state;
        public String zipCode;
        public String country;
        public String customerPhone;
        public String storeId;
        public String storeName;
        public String storeStreetAddress;
        public String storeCity;
        public String storeState;
        public String storeZipCode;
        public String storePhoneNumber;
        public String appointmentTime;
        public String recipientFirstName;
        public String recipientLastName;
        public String recipientPhone;
        public String recipientEmail;
        public String appointmentDate;
        public String appointmentStatus;
        public String dateAdded;
        public String fleetCompanyName;
        public String fleetAccountNumber;
        public String orderCode;
        public String storeCode;
        public String orderDate;
        public String appointmentId;
        public String vehicleAssemblyId;
        public String clientId;
        public String customerKey;
  
    public static String compose(Appt_NotificationEmailPayload payload){
        return System.JSON.serializePretty(payload);
    }

}