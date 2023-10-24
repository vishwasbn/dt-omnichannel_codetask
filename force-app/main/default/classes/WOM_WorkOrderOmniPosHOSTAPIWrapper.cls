/*========================================================================================================
* @author: Capgemini
* @date: 18th Jan '23
* @description: OmniPOS to SF: Wrapper class for OmniPOS Inbound Integration

Modification Log:
----------------------------------------------------------------------------------------------------------
Developer       Mod Number      Date                    User Story          Description
----------------------------------------------------------------------------------------------------------
Anuradha Nayak  M-001           18th Jan '23            WOM-92              Initial development
Vishal          M-002           16th Mar '23                                Modified the changes as per the static analysis report
Anuradha Nayak  M-003           03rd Mar '23            WOM-2078            Data model update to accomodate Tax related fields
Vishal          M-004           26th Apr '23                                Added apex doc @description
Anuradha        M-011           29th Jun '23            WOM-2450            Data model update to accomodate Print DWO related fields
========================================================================================================== */

/**
    *  @description : WOM_WorkOrderOmniPosHOSTAPIWrapper
    */
global with sharing class WOM_WorkOrderOmniPosHOSTAPIWrapper {
    global String saleOrderNumber ;
    global String storeCode;
    global String siteId;
    global String vtvInspectionID;
    global String workOrderId;
    global String orderType;
    global String paymentStatus;
    global String comments;
    global Boolean isReturnForService;
    global Boolean isArticlesCarryOut;
    global String salesAssociateId;
    global String salesAssociateFirstName;
    global String salesAssociateLastName;
    global String liftId;
    global Scheduling scheduling;
    global Customer customer;
    global Vehicle vehicle;
    global List<ArticleCollection> articleCollection;
    
    //WOM-2078: Start
    global Double tax;
    global List<TransactionDiscountCollection> transactionDiscountCollection;
    //WOM-2078: End
    
    //WOM-2450: Start
    global String alternateRecipientName;
    global String alternateRecipientPhone;
    global Boolean isTreadwell;
    global Double subtotal;
    global Double totalCredit;
    global Double total;
    global String businessPrimaryPhone;
    global String arPurchasingContact;
    //WOM-2450: End
    
    /**
    *  @description : Vehicle 
    */
    global class Vehicle {
        global String vehicleFitmentId;
        global String vehicleYear;
        global String vehicleMake;
        global String vehicleModel;
        global String vehicleTrim;
        global String vehicleColor;
        global String vehicleMileage;
        global String vehicleType;
        global String vehicleVin;
        global String customerVehicleNotes;
        global String vehicleImage;
        global String licensePlate;
        global String licensePlateCountry;
        global String licensePlateState;
        global String fitmentChassisId;
        global String fitmentAssemblyId;
        global String fitmentTrimId;
        global String genericVehicleCategory;
        global String genericVehicleSubCategory;
        global List<AssemblyCollection> assemblyCollection;
        global List<VehicleTreadDepthCollection> vehicleTreadDepthCollection;
    }


    /**
    *  @description : Customer 
    */
    global class Customer {
        global String customerVehicleId;
        global String customerId;
        global String customerFirstName;
        global String customerLastName;
        global String customerMiddleInitial;
        global String customerType;
        global String arAccountNumber;
        global String accountName;
        global String companyName2;
        global String dropOffWaitIndicator;
        global String driverName;
        global String driverPhone;
        global List<PhoneCollection> phoneCollection;
        global List<EmailCollection> emailCollection;
    }

    /**
    *  @description : ArticleCollection
    */
    global class ArticleCollection {
        global String lineItemNumber;
        global String returnOrderId;
        global String salesOrderId;
        global String articleAmount;
        global String articleNumber;
        
        //WOM-2450: Start
        global Double extendedAmount;
        global String adjustmentReason;
        global String tireMileageWarranty;
        //WOM-2450: End
        
        global String articleDescription;
        global String articleQuantity;
        global String articleSize;
        global String articleUpc;
        global String articleVpn;
        global String articleWeight;
        global String articleType;
        
        //WOM-2078: Start
        global List<ArticleDiscountCollection> articleDiscountCollection;
        //WOM-2078: End
    }

    /**
    *  @description : Scheduling
    */
    global class Scheduling {
        global String promiseTimeReservationId;
        global String promiseTimeMin;
        global String promiseTimeMax;
        global String bayEstimateStartTime;
        global String bayEstimateEndTime;
    }

    /**
    *  @description : VehicleTreadDepthCollection
    */
    global class VehicleTreadDepthCollection {
        global String tirePosition;
        global String depth;
    }

    /**
    *  @description : EmailCollection
    */
    global class EmailCollection {
        global String emailId;
        global String emailType;
    }
    /**
    *  @description : AssemblyCollection
    */
    global class AssemblyCollection {
        global String assemblyId;
        global String frontWheelSize;
        global String rearWheelSize;
        global String vehicleFitmentId;
        global String factoryTireSizeFront;
        global String factoryTireSizeRear;
    }

    /**
    *  @description : PhoneCollection
    */
    global class PhoneCollection {
        global String phoneType;
        global String phoneCountryCode;
        global String phoneNumber;
        global String phoneExt;
    }
    
    
    //WOM-2078: Start
    /**
    *  @description : TransactionDiscountCollection
    */
    global class TransactionDiscountCollection {
        global Double transactionDiscountAmount;
        global String transactionDiscountReceiptName;
    }
    
    /**
    *  @description : ArticleDiscountCollection
    */
    global class ArticleDiscountCollection {
        global Double articleDiscountAmount;
        global String articleDiscountReceiptName;
    }
    //WOM-2078: End
}