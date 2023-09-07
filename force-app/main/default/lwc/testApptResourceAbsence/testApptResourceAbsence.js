import { LightningElement, wire, track } from 'lwc';
//import getAccounts from '@salesforce/apex/TestResourceAbsenceController.getAllStores';
import getAccounts from '@salesforce/apex/TestResourceAbsenceController.getAllStores2';
import createAbsence from '@salesforce/apex/TestResourceAbsenceController.createAbsenceRecords';
import getOperatingHourOptions from '@salesforce/apex/TestResourceAbsenceController.getOperatingHourOptions';
import getSiteRegions from '@salesforce/apex/TestResourceAbsenceController.getSiteRegions';
import getUserAccountTimezone from '@salesforce/apex/TestResourceAbsenceController.getUserAccountTimezone';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const columns = [
    { label: 'Store Name', fieldName: 'Name', hideDefaultActions: 'true' },
    { label: 'Operating Hours', fieldName: 'OpeartingHours', hideDefaultActions: 'true' },
    { label: 'Store Region', fieldName: 'region', hideDefaultActions: 'true' },
    { label: 'Store Time Zone', fieldName: 'StoreTimeZone', hideDefaultActions: 'true' }
];
const secondScreenColumns = [
    { label: 'Store', fieldName: 'StoreId', type: 'text', hideDefaultActions: 'true' },
    { label: 'Start Time', fieldName: 'StartTime', type: 'time', hideDefaultActions: 'false', editable: true },
    { label: 'End Time', fieldName: 'EndTime', type: 'time', hideDefaultActions: 'false', editable: true },
    { label: 'Date', fieldName: 'StoreDate', type: 'date', hideDefaultActions: 'true', editable: true },
    { label: 'TimeZone', fieldName: 'StoreTimeZone', type: 'text', hideDefaultActions: 'true' },
];

const RBColumns = [
    { label: 'Store', fieldName: 'StoreId', hideDefaultActions: 'true' },
    { label: 'Start Time', fieldName: 'startTime', hideDefaultActions: 'true', type: 'time', editable: true },
    { label: 'End Time', fieldName: 'endTime', hideDefaultActions: 'true', type: 'time', editable: true },
    { label: 'Date', fieldName: 'selectedDate', hideDefaultActions: 'true', type: 'Date', editable: true },
    { label: 'Store Timezone', fieldName: 'timeZone', hideDefaultActions: 'true' },
];
const DELAY = 300;
export default class TestApptResourceAbsence extends LightningElement {
    isFirstScreen = true;
    operatinghourpage = true;
    isSecondScreen;
    isThirdScreen;
    _isValidationError = false;
    buttonLabel = 'Next';
    queryTerm;
    data = [];
    insertableData = [];
    _firstTimeRun = true;
    _firstTimeAllData = [];
    @track
    allData = [];
    today = '';
    dateParty = null;
    checkedRows = [];
    //data = [];
    recordsData = [];
    selectedRows = [];
    searchKey = '';
    columns = columns;
    RBColumns = RBColumns;
    secondScreenColumns = secondScreenColumns;
    isSuccess = false;

    //vishwas disableButton = true;
    operatingHourOptions = [];
    selectedOperatingHourId;
    storeRegionOptions = [];
    selectedRegion = '';
    userTimezone;



    get disableButton() {
        return (this.globalrowvalueselected.length == 0 || this.dateParty == null);
    }

    // get disableregiondropdown(){
    //     return this.selectedOperatingHourId == null || this.storeRegionOptions.length == 0;
    // }

    // get disableregiondropdown(){
    //     return this.storeRegionOptions.length == 0;
    // }

    get disablebtn(){
        return this.selectedRegion == null;
    }

    connectedCallback() {
        //today  = new Date().getFullYear() + '-' + (new Date().getMonth()+1) + '-' + new Date().getDate();
        this.today = new Date().toJSON().slice(0, 10);
    }
    getSelectedStore(event) {

        if (event.target.checked && (this.checkedRows.indexOf(event.target.value) === -1)) {
            this.checkedRows.push(event.target.value);
        } else if ((!event.target.checked) && (this.checkedRows.indexOf(event.target.value) !== -1)) {
            this.checkedRows.splice(this.checkedRows.indexOf(event.target.value), 1);
        }
        if (this.dateParty != '' && this.checkedRows.length > 0) {
            //vishwas this.disableButton = false;
        } else {
            //vishwas this.disableButton = true;
        }
    }
    getDateParty(event) {

        this.dateParty = event.target.value;
        if (this.dateParty != '' && this.checkedRows.length > 0) {
            //vishwas this.disableButton = false;
        } else {
            //vishwas this.disableButton = true;
        }
        this.data = [];
        this.allData.forEach(currentItem => {
            if (this.checkedRows.indexOf(currentItem.id) === -1) {
                currentItem.isChecked = false;
            } else {
                currentItem.isChecked = true;
            }
            this.data.push(currentItem);
        });
    }

    /*rowSelected(event) {

        if (this.template.querySelector("lightning-datatable").getSelectedRows().length > 0) {
            this.disableButton = false;
            this.selectedRows = this.template.querySelector("lightning-datatable").getSelectedRows();
            JSON.parse(JSON.stringify(this.selectedRows)).forEach(currentItem => {
                if (this.checkedRows.indexOf(currentItem.serviceTeritoryId) === -1) {
                    this.checkedRows.push(currentItem.serviceTeritoryId);
                }
            });
            if (this.dateParty == '') {
                this.disableButton = true;
            }
        }
        else {
            this.disableButton = true;
        }
        //Vishwas added start
        if(event.detail.config.action == null || event.detail.config.action == 'undefined'){
                var newlist = [];
                newlist.push(...this.checkedRows);
                this.selectedRows = newlist;
        }
        ////Vishwas added end
    }*/

    globalrowvalueselected = [];

    rowSelected(event) {

        var eventdetails = JSON.parse(JSON.stringify(event.detail)).config;
        var temparray = []
        if(eventdetails.action != undefined){
            if(eventdetails.action == 'deselectAllRows'){
                const allSiteIds = this.data.map(site => site.id);
                console.log('deselectAllRows '+allSiteIds);
                allSiteIds.forEach(currentItem => {
                    if (this.globalrowvalueselected.indexOf(currentItem) !== -1) {
                        this.globalrowvalueselected = this.removeElementAt(this.globalrowvalueselected, this.globalrowvalueselected.indexOf(currentItem));
                        console.log('currentItem removed');
                        
                    }
                });
                console.log('After deselectAllRows lenghth : '+this.globalrowvalueselected.length);
                //this.globalrowvalueselected = temparray;
                JSON.stringify('deselectAllRows '+this.globalrowvalueselected);
                this.modifytherowitem();
            }
            else if(eventdetails.action == 'selectAllRows'){
                //const allSiteIds = this.template.querySelector("lightning-datatable").getSelectedRows();
                const allSiteIds = this.data.map(site => site.id);
                console.log('selectAllRows '+allSiteIds);
                allSiteIds.forEach(currentItem => {
                    if (this.globalrowvalueselected.indexOf(currentItem) === -1) {
                        this.globalrowvalueselected.push(currentItem);
                        
                        
                    }
                });
                console.log('After selectAllRows lenghth : '+this.globalrowvalueselected.length);
                JSON.stringify('selectAllRows '+this.globalrowvalueselected);
                this.modifytherowitem();
            }
            else if(eventdetails.action == 'rowDeselect'){
                //var selectedrow = this.template.querySelector("lightning-datatable").getSelectedRows();
                const allSiteIds = this.data.map(site => site.id);
                var selectedrowObj = JSON.parse(JSON.stringify(this.template.querySelector("lightning-datatable").getSelectedRows()));
                var selectedrow = selectedrowObj.map(rowentry => rowentry.id);

                allSiteIds.forEach(currentItem => {
                    if(selectedrow.indexOf(currentItem) === -1){
                        if (this.globalrowvalueselected.indexOf(currentItem) !== -1) {
                            this.globalrowvalueselected = this.removeElementAt(this.globalrowvalueselected, this.globalrowvalueselected.indexOf(currentItem));
                            
                        }
                    }
                    
                });
                console.log('After rowDeselect lenghth : '+this.globalrowvalueselected.length);
            }
            else if (eventdetails.action == 'rowSelect') {
                var selectedrow = this.template.querySelector("lightning-datatable").getSelectedRows();
                JSON.parse(JSON.stringify(selectedrow)).forEach(currentItem => {
                    if (this.globalrowvalueselected.indexOf(currentItem.serviceTeritoryId) === -1) {
                        this.globalrowvalueselected.push(currentItem.serviceTeritoryId);
                        
                    }
                });
                console.log('After rowSelect lenghth : '+this.globalrowvalueselected.length);
                console.log('rowSelect '+this.globalrowvalueselected);
                this.modifytherowitem();
            }
        }
        else{

        }

        // if (this.template.querySelector("lightning-datatable").getSelectedRows().length > 0) {
        //     this.disableButton = false;
        //     this.selectedRows = this.template.querySelector("lightning-datatable").getSelectedRows();
        //     JSON.parse(JSON.stringify(this.selectedRows)).forEach(currentItem => {
        //         if (this.checkedRows.indexOf(currentItem.serviceTeritoryId) === -1) {
        //             this.checkedRows.push(currentItem.serviceTeritoryId);
        //         }
        //     });
        //     if (this.dateParty == '') {
        //         this.disableButton = true;
        //     }
        // }
        // else {
        //     this.disableButton = true;
        // }
        // //Vishwas added start
        // if(event.detail.config.action == null || event.detail.config.action == 'undefined'){
        //         var newlist = [];
        //         newlist.push(...this.checkedRows);
        //         this.selectedRows = newlist;
        // }
        // ////Vishwas added end
    }

    modifytherowitem(){
        this.checkedRows = [];
        this.data.forEach(currentItem => {
            if (this.globalrowvalueselected.indexOf(currentItem.id) !== -1) {
                this.checkedRows.push(currentItem.id);
            }
        });
    }


    searchKeyChanged(event) {

        //this.checkedRows = [];
        this.searchKey = event.target.value;
        this.selectedRows = this.template.querySelector("lightning-datatable").getSelectedRows();
        /*JSON.parse(JSON.stringify(this.selectedRows)).forEach(currentItem => {
            this.checkedRows.push(currentItem.serviceTeritoryId);
        });*/

    }
    @wire(getAccounts, { searchKey: '$searchKey', region: '$selectedRegion' }) wiredAccounts({ data, error }) {
        if (data) {

            this.allData = [];
            this.checkedRows = [];//vishwas
            data.forEach(currentItem => {
                //TODO : currentItem

                let objSR = new Object();
                objSR.serviceTeritoryId = currentItem.Id;
                objSR.Name = currentItem.Name;
                objSR.StoreId = currentItem.Site_Account__r.Store_ID__c;
                objSR.OpeartingHours = currentItem.OperatingHours.Name;
                objSR.region = currentItem.Site_Account__r.Store_Region__c;
                //objSR.StartTime = "09:30:00.000Z";
                //objSR.EndTime = "18:30:00.000Z";
                objSR.StartTime = null;
                objSR.EndTime = null;
                objSR.id = currentItem.Id;
                objSR.StoreTimeZone = currentItem.OperatingHours.TimeZone;
                objSR.StoreDate = new Date().toISOString();
                if (this.globalrowvalueselected.indexOf(objSR.id) === -1) {
                    objSR.isChecked = false;
                } else {
                    objSR.isChecked = true;
                }
                
                if(this.globalrowvalueselected.indexOf(objSR.id) !== -1){
                    this.checkedRows.push(objSR.id);
                }//vishwas
                this.allData.push(objSR);
            });

            if (this._firstTimeRun && this.allData.length > 0) {
                this._firstTimeRun = false;
                this._firstTimeAllData = this.allData;
            }
            this.data = this.allData;
        } else if (error) {

        }
    }

    searchStore(evt) {

        this.searchKey = this.template.querySelector('lightning-input[data-id=searchtext]').value;
        /*this.selectedRows = this.template.querySelector("lightning-datatable").getSelectedRows();
        JSON.parse(JSON.stringify(this.selectedRows)).forEach(currentItem => {
            this.checkedRows.push(currentItem.serviceTeritoryId);
        });*/
    }

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.queryTerm = evt.target.value;
        }
    }

    handleFirstScreen() {

        /*this.recordsData = this.template.querySelector("lightning-datatable").getSelectedRows();
        this.isFirstScreen = false;
        this.isSecondScreen = true;
        this.recordsData.forEach(currentItem => {
            currentItem.StoreDate = this.dateParty;
        });*/
        if (new Date(this.dateParty) < new Date()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Select correct date of party.',
                    message: 'Date Party must be in future.',
                    variant: 'error'
                }),
            );
            return;
        }
        this.recordsData = [];
        this._firstTimeAllData.forEach(currentItem => {
            if (this.globalrowvalueselected.indexOf(currentItem.id) !== -1) {
                currentItem.StoreDate = this.dateParty;
                this.recordsData.push(currentItem);
            }
        });
        this.isFirstScreen = false;
        this.isSecondScreen = true;
    }
    goBack() {
        this.isFirstScreen = true;
        this.isSecondScreen = false;
    }
    getSelectedRow() {

    }
    handleSecondScreen() {

        const allValid = [...this.template.querySelectorAll('.absencevalidation')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

            if(allValid){

            this.insertableData = [];
            this.recordsData.forEach(currentItem => {


                if (typeof currentItem.StartTime === 'undefined' || currentItem.StartTime == null) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Some fields are missing.',
                            message: 'Start Time,End Time,Store Date can not be empty, while creating absence records for selected stores.',
                            variant: 'error'
                        }),
                    );
                    this._isValidationError = true;
                } else if (typeof currentItem.EndTime === 'undefined' || currentItem.EndTime == null) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Some fields are missing.',
                            message: 'Start Time,End Time,Store Data can not be empty.',
                            variant: 'error'
                        }),
                    );
                    this._isValidationError = true;
                } else if (typeof currentItem.StoreDate === 'undefined' || currentItem.StoreDate == null) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Please select corrrect Start Time and End Time.',
                            message: 'Start Time,End Time,Store Data can not be empty.',
                            variant: 'error'
                        }),
                    );
                    this._isValidationError = true;
                } else if (parseInt(currentItem.StartTime.substring(0, 5).replace(":", "")) > parseInt(currentItem.EndTime.substring(0, 5).replace(":", ""))) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Please select corrrect Start Time and End Time.',
                            message: 'Start Time can not be greater then End Time.',
                            variant: 'error'
                        }),
                    );
                    this._isValidationError = true;
                }
                if (this._isValidationError) {
                    return;
                }
            });

            if (this._isValidationError) {
                this._isValidationError = false;
                return;
            }
                createAbsence({ requestData: JSON.stringify(this.recordsData) })
                    .then(result => {

                        if (!result.isError) {
                            this.isSuccess = true;
                            this.isSecondScreen = false;
                            this.isThirdScreen = true;
                        } else {
                            this.isSuccess = false;
                            this.isSecondScreen = false;
                            this.isThirdScreen = true;
                        }

                    })
                    .catch(error => {


                        this.isSuccess = false;
                        this.isSecondScreen = false;
                        this.isThirdScreen = true;
                    })
        }


    }

    handleStartTimeChange(event) {

        let element = this.recordsData.find(ele => ele.id === event.currentTarget.dataset.id);
        element.StartTime = event.target.value;
        this.recordsData = [...this.recordsData];

    }
    handleEndTimeChange(event) {

        let element = this.recordsData.find(ele => ele.id === event.currentTarget.dataset.id);
        element.EndTime = event.target.value;
        this.recordsData = [...this.recordsData];

    }
    handleStoreDateChange(event) {

        let element = this.recordsData.find(ele => ele.id === event.currentTarget.dataset.id);
        element.StoreDate = event.target.value;
        this.recordsData = [...this.recordsData];

    }

    @wire(getOperatingHourOptions)
    wiredAccountOptions({ data, error }) {
        if (data) {
            this.operatingHourOptions = data;
        } else if (error) {
            console.log('Not able to get the operating hour options from server');
        }
    }

    getSiteRegions(){
        getSiteRegions({ operatingHourId : this.selectedOperatingHourId })
        .then((result) => {
            console.log('Optained the region'+ result);
            this.storeRegionOptions = result;

        })
        .catch((error) => {
            console.log('Exception on the region fetch' + error);
            this.storeRegionOptions = [];
        });
    }

    handleOperatingHourChange(event) {
        this.selectedOperatingHourId = event.detail.value;
        this.selectedRegion ='';
        this.storeRegionOptions =null;
        this.getSiteRegions();
    }

    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;        
    }

    handleOperatingHourScreen(){
        this.operatinghourpage = false;
        this.isFirstScreen = true;
    }

    removeElementAt(arr, index) {
        console.log('global selected arr length'+arr.length);
        let frontPart = arr.slice(0, index);
        let lastPart  = arr.slice( index+1 ); // index to end of array
        return [...frontPart, ...lastPart];
     }

    @wire(getUserAccountTimezone)
    wiredUserTimezone({ data, error }) {
        if (data) {
            this.userTimezone = data;
        } else if (error) {
            console.error('Error fetching user account timezone', error);
        }
    }

}