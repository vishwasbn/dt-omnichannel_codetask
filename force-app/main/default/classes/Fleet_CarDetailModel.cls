//---This class was generated from http://json2apex.herokuapp.com/ using data returned from CAR
public class Fleet_CarDetailModel
{
    public class ResponseDetail {
        public List<OrderHistoryDetails> orderHistoryDetails;
    }

    public class LineItems {
        public String articleNumber;
        public Double retailQuantity;
        public String storeSize;
        public String storeDescription;
        public Double actualUnit_price;
        public Double fet;
        public Double totalSalesAmount;
        public String vehicleMake;
        public String vehicleModel;
        public String vehicleYear;
        public String mileage;
        public String poNumber;
        public List<Discounts> discounts;
    }

    public ResponseDetail responseDetail;

    public class ArFields {
        public String driverName;
        public String companyName;
        public String streetAdd;
        public String arVehicleYear;
        public String arVehicleMake;
        public String arVehicleModel;
        public String arLicensePlateNumber;
        public String arLicensePlateState;
        public String vin;
        public String arMileage;
        public String fleetCardNumber;
        public String stockNumber;
        public String unitNumber;
        public String fleetNumber;
        public String fleetCardExpDt;
        public String id_JobNumber;
        public String arDriverLicense;
        public String arCity;
        public String arState;
        public String arZip;
    }

    public class OrderHistoryDetails {
        public String siteId;
        public Double totalAmount;
        public String businessdayDate;
        public String invoiceNumber;
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String zipCode;
        public String county;
        public String workPhone;
        public String arCustomerAccountNumber;
        public String arCustomerAccountName;
        public String taxId;
        public Double taxAmount;
        public Double discountAmount;
        public String employeeName;
        public String timeStamp;
        public List<TenderDetails> tenderDetails;
        public List<TransactionDetails> transactionDetails;
        public List<LineItems> lineItems;
        public ArFields arFields;
    }

    public class Discounts {
        public String typeCode;
        public String reasonCode;
        public String itemDescription;
    }

    public class TransactionDetails {
        public String name;
        public String value;
    }

    public class TenderDetails {
        public String tenderTypeCode;
        public Double tenderAmount;
    }
    
    public static Fleet_CarDetailModel parse(String json) {
        System.debug('json :::::' + json);
        return (Fleet_CarDetailModel) System.JSON.deserialize(json, Fleet_CarDetailModel.class);
    }
}