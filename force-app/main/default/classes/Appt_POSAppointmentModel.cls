public class Appt_POSAppointmentModel {

    public String action; // CRT
    public String posCustomerId;
    public String hybrisCustomerId;
    public String formType; // BOP, INV, LAY, QUO, WEB
    public String formNumber;
    public String orderDate; 
    public String orderType;
    public String formDate;
    public String hybrisOrderId;
    public String posWebOrderId;
    public String layawayNumber;
    public String quoteNumber;
    public String guid;
    public String customerType; // RT, RS, AR, MA .. 3 CHARACTERS - enum values represent Retail, Resale, A/R, and My Account
    public String firstName;
    public String lastName;
    public String emailAddress;
    public String mobileAreaCode;
    public String mobilePhoneNumber;
    public String homeAreaCode;
    public String homePhoneNumber;
    public String workAreaCode;
    public String workPhoneNumber;
    public String siteId;
    public String textOptIn;
    public String emailAddressOptIn;
    public String address1;
    public String address2;
    public String zipCode;
    public String city;
    public String state;
    public String country;
    public String posCustomerVehicleId;
    public String hybrisCustomerVehicleID;
    public String vehicleType; // Fitment or ''
    public String year;
    public String make;
    public String model;
    public String vehicleId;
    public String trimId;
    public String trimDetails;
    public String assemblyId;
    public String assemblyDetails;
    public String workOrderId; // passed in on VIEW
    public List<Articles> articles;

    public class Articles {
        public Integer quantity;
        public String size;
        public String articleType; // T, W, B, R, F, L, U ... Tire, Wheel, Both , Rotation/Balance, Free Labor, Labor, Used 
        public String articleId;
        public String description;
    }

    
    public static Appt_POSAppointmentModel parse(String json) {
        return (Appt_POSAppointmentModel) System.JSON.deserialize(json, Appt_POSAppointmentModel.class);
    }


    public Appt_CreateAppointmentServiceModel getCreateAppointmentServiceModel(Appt_POSAppointmentModel model) {
        Appt_CreateAppointmentServiceModel serviceModel = new Appt_CreateAppointmentServiceModel();
        serviceModel.posCustomerId = this.posCustomerId;
        serviceModel.hybrisCustomerId = this.hybrisCustomerId;
        serviceModel.formType = this.formType; // BOP, INV, LAY, QUO, WEB
        serviceModel.formNumber = this.formNumber;
        serviceModel.formDate = setToNullIfEmptyString(this.formDate) != null ? getFormattedDateString(this.formDate) : null ;
        serviceModel.hybrisOrderId = this.hybrisOrderId;
        serviceModel.posWebOrderId = this.posWebOrderId;
        serviceModel.layawayNumber = this.layawayNumber;
        serviceModel.quoteNumber = this.quoteNumber;
        serviceModel.customerGuid = this.guid;
        serviceModel.firstName = this.firstName;
        serviceModel.lastName = this.lastName;
        serviceModel.emailAddress = this.emailAddress;
        serviceModel.mobilePhoneNumber = this.mobileAreaCode + this.mobilePhoneNumber;
        serviceModel.homePhoneNumber = this.homeAreaCode + this.homePhoneNumber;
        serviceModel.workPhoneNumber = this.workAreaCode + this.workPhoneNumber;
        serviceModel.siteId = this.siteId;
        //-- SMS and Email Opt-in for CREATE APPOINTMENT should default to true - DTA-555
        serviceModel.textOptIn = (this.textOptIn != null) ? Boolean.valueOf(this.textOptIn): true;
        serviceModel.emailAddressOptIn = (this.emailAddressOptIn != null) ? Boolean.valueOf(this.emailAddressOptIn) : true;
        serviceModel.address1 = this.address1;
        serviceModel.address2 = this.address2;
        serviceModel.zipCode = this.zipCode;
        serviceModel.city = this.city;
        serviceModel.state = this.state;
        serviceModel.country = this.country;
        serviceModel.posCustomerVehicleId = this.posCustomerVehicleId;
        serviceModel.hybrisCustomerVehicleID = this.hybrisCustomerVehicleID;
        serviceModel.vehicleType = this.vehicleType; // Fitment or ''
        serviceModel.year = this.year;
        serviceModel.make = this.make;
        serviceModel.model = this.model;
        serviceModel.vehicleId = this.vehicleId;
        serviceModel.trimId = this.trimId;
        serviceModel.assemblyId = this.assemblyId;
        serviceModel.source = Appt_ConstantValues.APPOINTMENT_SOURCE_POS; // all values set as POS
        serviceModel.orderType = this.orderType; // POS will take fromType and map to: BOPIS, ROPIS, Invoice, Quote, Layaway. They don't have ServiceAppointment.
        serviceModel.customerType = getCustomerType(this.customerType); // RT, RS, AR, MA .. 3 CHARACTERS - enum values represent Retail, Resale, A/R, and My Account
        serviceModel.appointmentStatus = (this.action == 'CRT') ? Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_PENDING : ''; // check for "CRT" in case I use this model for view
        serviceModel.workOrderId = this.workOrderId;
        serviceModel.orderDate = setToNullIfEmptyString(this.orderDate) != null  ? getFormattedDateString(this.orderDate) : null;

        if (articles != null && articles.size() > 0) {
            serviceModel.articles = new List<Appt_CreateAppointmentServiceModel.Articles>();
            
            for (Articles article: articles) {
                Appt_CreateAppointmentServiceModel.Articles a = new Appt_CreateAppointmentServiceModel.Articles();
                a.articleType = article.articleType;
                a.articleSize = article.size;
                a.articleId = article.articleId;
                a.articleDescription = article.description;
                a.articleCount = String.valueOf(article.quantity);

                serviceModel.articles.add(a);
            }
        }
        return serviceModel;
    }


    public Appt_UpdateAppointmentServiceModel getUpdateAppointmentServiceModel(Appt_POSAppointmentModel model) {
        Appt_UpdateAppointmentServiceModel serviceModel = new Appt_UpdateAppointmentServiceModel();
        serviceModel.posCustomerId = this.posCustomerId;
        serviceModel.hybrisCustomerId = this.hybrisCustomerId;
        serviceModel.formType = this.formType; // BOP, INV, LAY, QUO, WEB
        serviceModel.formNumber = this.formNumber;
        serviceModel.formDate = setToNullIfEmptyString(this.formDate) != null  ? getFormattedDateString(this.formDate) : null;
        serviceModel.hybrisOrderId = this.hybrisOrderId;
        serviceModel.posWebOrderId = this.posWebOrderId;
        serviceModel.layawayNumber = this.layawayNumber;
        serviceModel.quoteNumber = this.quoteNumber;
        serviceModel.customerGuid = this.guid;
        serviceModel.firstName = this.firstName;
        serviceModel.lastName = this.lastName;
        serviceModel.emailAddress = this.emailAddress;
        serviceModel.mobilePhoneNumber = this.mobileAreaCode + this.mobilePhoneNumber;
        serviceModel.homePhoneNumber = this.homeAreaCode + this.homePhoneNumber;
        serviceModel.workPhoneNumber = this.workAreaCode + this.workPhoneNumber;
        serviceModel.siteId = this.siteId;
        serviceModel.textOptIn = (!String.isBlank(this.textOptIn)) ? Boolean.valueOf(this.textOptIn) : null;
        serviceModel.emailAddressOptIn = (!String.isBlank(this.emailAddressOptIn)) ? Boolean.valueOf(this.emailAddressOptIn) : null;
        serviceModel.address1 = this.address1;
        serviceModel.address2 = this.address2;
        serviceModel.zipCode = this.zipCode;
        serviceModel.city = this.city;
        serviceModel.state = this.state;
        serviceModel.country = this.country;
        serviceModel.posCustomerVehicleId = this.posCustomerVehicleId;
        serviceModel.hybrisCustomerVehicleID = this.hybrisCustomerVehicleID;
        serviceModel.vehicleType = this.vehicleType; // Fitment or ''
        serviceModel.year = this.year;
        serviceModel.make = this.make;
        serviceModel.model = this.model;
        serviceModel.vehicleId = this.vehicleId;
        serviceModel.trimId = this.trimId;
        serviceModel.assemblyId = this.assemblyId;
        serviceModel.source = Appt_ConstantValues.APPOINTMENT_SOURCE_POS; // all values set as POS
        serviceModel.orderType = this.orderType; // POS will take fromType and map to: BOPIS, ROPIS, Invoice, Quote, Layaway. They don't have ServiceAppointment.
        serviceModel.customerType = getCustomerType(this.customerType); // RT, RS, AR, MA .. 3 CHARACTERS - enum values represent Retail, Resale, A/R, and My Account
        serviceModel.appointmentStatus = (this.action == 'CRT') ? Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED : ''; // check for "CRT" in case I use this model for view
        serviceModel.workOrderId = this.workOrderId;
        serviceModel.orderDate = setToNullIfEmptyString(this.orderDate) != null  ? getFormattedDateString(this.orderDate) : null;

        if (articles != null && articles.size() > 0) {
            serviceModel.articles = new List<Appt_CreateAppointmentServiceModel.Articles>();
            
            for (Articles article: articles) {
                Appt_CreateAppointmentServiceModel.Articles a = new Appt_CreateAppointmentServiceModel.Articles();
                a.articleType = article.articleType;
                a.articleSize = article.size;
                a.articleId = article.articleId;
                a.articleDescription = article.description;
                a.articleCount = String.valueOf(article.quantity);

                serviceModel.articles.add(a);
            }
        }
        return serviceModel;
    }




    // convert 3-char code to order type
    public static string getOrderType(String formType) {
        System.debug('--getOrderType--');
        // BOP, INV, LAY, QUO, WEB
        if (formType.equals('BOP') || formType.equalsIgnoreCase('BOPIS')) return 'BOPIS';
        if (formType.equals('INV') || formType.equalsIgnoreCase('Invoice')) return 'Invoice';
        if (formType.equals('LAY') || formType.equalsIgnoreCase('Layaway')) return 'Layaway';
        if (formType.equals('QUO') || formType.equalsIgnoreCase('Quote')) return 'Quote';
        if (formType.equals('WEB') || formType.equalsIgnoreCase('ROPIS')) return 'ROPIS';

        return 'ServiceAppointment'; // default return value
    }

    // accepts a 3 char customer type
    public static String getCustomerType(String customerType) {
        System.debug('--getCustomerType--');
        // RT (Retail), RS (Resale), AR (A/R), MA (My Account), FL (Fleet).. 3 CHARACTERS
        // NOTE: MA is a subset of Retail
        if (customerType.equals('RT') || customerType.equalsIgnoreCase(Appt_ConstantValues.CUSTOMER_TYPE_RETAIL)) return Appt_ConstantValues.CUSTOMER_TYPE_RETAIL;
        if (customerType.equals('FL') || customerType.equalsIgnoreCase(Appt_ConstantValues.CUSTOMER_TYPE_FLEET)) return Appt_ConstantValues.CUSTOMER_TYPE_FLEET; // DT is not currently sending 'FT' or Fleet
        
        return Appt_ConstantValues.CUSTOMER_TYPE_RETAIL; // default return value
    }

    // Convert String dates from yyyymmdd to yyyy-mm-dd
    public static String getFormattedDateString(String dateString) {
        System.debug('--GetformattedDateString--');
        dateString = dateString.left(4) + '-' + dateString.subString(4, 6) + '-' + dateString.right(2);
        System.debug('newly formatted string= '+dateString);
        if (dateString != null && dateString.length() == 8) return dateString.left(4) + '-' + dateString.subString(4, 6) + '-' + dateString.right(2);
        
        return dateString;
    }

    public static String setToNullIfEmptyString(String inputString){
        return inputString == '' ? null : inputString;
    }
}