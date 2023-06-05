@isTest(SeeAllData=false)

public class Fleet_ModelTest
{
    static testMethod void testDiscount() 
    {
        Test.startTest();

        Fleet_Model_Discounts fmd = new Fleet_Model_Discounts('t1', 'r1', 'd1');
        String type = fmd.getTypeCode();
        String reason = fmd.getReasonCode();
        String description = fmd.getItemDescription();

        fmd.setItemDescription('d2');
        fmd.setReasonCode('r2');
        fmd.setTypeCode('t2');

        System.assertEquals(type, 't1', 'Value does not match');

        Fleet_CarDetailModel.Discounts dis = new Fleet_CarDetailModel.Discounts();
        dis.itemDescription = 'd1';
        dis.reasonCode = 'r1';
        dis.typeCode = 't1';

        List<Fleet_CarDetailModel.Discounts> inputList = new List<Fleet_CarDetailModel.Discounts>();
        inputList.add(dis);

        Fleet_Model_Discounts.build(inputList);

        Test.stopTest();
    }


    static testMethod void testAR() 
    {
        Test.startTest();
     
        Fleet_Model_ARFields obj = new Fleet_Model_ARFields();
        obj.setArCity('x');
        obj.setArDriverLicense('x');
        obj.setArLicensePlateState('x');
        obj.setArLicensePlateNumber('x');
        obj.setArMileage('x');
        obj.setArState('x');
        obj.setArVehicleMake('x');
        obj.setArVehicleModel('x');
        obj.setArVehicleYear('x');
        obj.setArZip('x');
        obj.setCompanyName('x');
        obj.setDriverName('x');
        obj.setFleetCardExpDt('x');
        obj.setFleetCardNumber('x');
        obj.setFleetNumber('x');
        obj.setId_JobNumber('x');
        obj.setStockNumber('x');
        obj.setStreetAdd('x');
        obj.setUnitNumber('x');
        obj.setVin('x');
     
        Test.stopTest();
    }


    static testMethod void testVehicle() 
    {
        Test.startTest();
     
        Fleet_Model_Vehicle obj = new Fleet_Model_Vehicle();
        obj.setYear(1);
        Integer yr = obj.getYear();

        obj.setMake('x');
        String make = obj.getMake();

        obj.setModel('x');
        String model = obj.getModel();


        Fleet_Model_TenderDetails obj2 = new Fleet_Model_TenderDetails('x', 23);
        String tCode = obj2.getTenderTypeCode();
        Decimal amt = obj2.getTenderAmount();


        Fleet_Model_ARFields aObj = new Fleet_Model_ARFields();
        aObj.getArCity();
        aObj.getArDriverLicense();
        aObj.getArLicensePlateState();
        aObj.getArMileage();
        aObj.getArState();
        aObj.getArVehicleMake();
        aObj.getArVehicleModel();
        aObj.getArVehicleYear();
        aObj.getArZip();
        aObj.getCompanyName();
        aObj.getDriverName();
        aObj.getFleetCardExpDt();
        aObj.getFleetCardNumber();
        aObj.getFleetNumber();
        aObj.getId_JobNumber();
        aObj.getStockNumber();
        aObj.getStreetAdd();
        aObj.getUnitNumber();
        aObj.getVin();
        
        Fleet_CarDetailModel.ArFields aRow = new Fleet_CarDetailModel.ArFields();

        Fleet_Model_ARFields.build(aRow);


        Fleet_Model_InvoiceSummaryDisplayable iObj = new Fleet_Model_InvoiceSummaryDisplayable();
        iObj.getVehicle();
        iObj.getTransactionDate();
        iObj.getTotalAmount();
        iObj.getStoreId();
        iObj.getStore();
        iObj.getInvoiceId();
        iObj.getVinNumber();
        iObj.getPoNumber();
        
        

        Fleet_Model_LineItems lObj = new Fleet_Model_LineItems();
        lObj.getActualUnitPrice();
        lObj.getArticleNumber();
        lObj.getDiscounts();
        lObj.getFet();
        lObj.getMileage();
        lObj.getPoNumber();
        lObj.getRetailQuantity();
        lObj.getStoreDescription();
        lObj.getStoreSize();
        lObj.getTotalSalesAmount();
        lObj.getVehicleMake();
        lObj.getVehicleModel();
        lObj.getVehicleYear();

        List<Fleet_CarDetailModel.LineItems> input2 = new List<Fleet_CarDetailModel.LineItems>();
        input2.add(new Fleet_CarDetailModel.LineItems());
        Fleet_Model_LineItems.build(input2);



        Fleet_Model_TenderDetails tObj = new Fleet_Model_TenderDetails('x', 1);
        tObj.setTenderAmount(1);
        tObj.setTenderTypeCode('x');

        List<Fleet_CarDetailModel.TenderDetails> inputList = new List<Fleet_CarDetailModel.TenderDetails>();
        inputList.add(new Fleet_CarDetailModel.TenderDetails());
    
        Fleet_Model_TenderDetails.build( inputList);

   
        Test.stopTest();
    }
}