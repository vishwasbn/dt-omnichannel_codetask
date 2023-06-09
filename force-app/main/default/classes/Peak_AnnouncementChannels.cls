global class Peak_AnnouncementChannels extends VisualEditor.DynamicPickList{
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('Default', 'Default');
        return defaultValue;
    }
    global override VisualEditor.DynamicPickListRows getValues() {

        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();

        Schema.DescribeFieldResult fieldResult = Community_Announcement__c.Announcement_Channel__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();


        for( Schema.PicklistEntry f : ple)
        {
           myValues.addRow(new VisualEditor.DataRow(f.getLabel(), f.getValue()));
        }
        return myValues;
    }
}