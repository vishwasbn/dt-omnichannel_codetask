import { LightningElement, wire, track } from 'lwc';
import getAccounts from '@salesforce/apex/Appt_ResourceAbsenceController.getAllStores';
import createAbsence from '@salesforce/apex/Appt_ResourceAbsenceController.createAbsenceRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const columns = [
    { label: 'Name', fieldName: 'Name', hideDefaultActions: 'true' },
    { label: 'Operating Hours', fieldName: 'OpeartingHours', hideDefaultActions: 'true' },
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
    @track dateParty = '';
    @track checkedRows = [];
    //data = [];
    recordsData = [];
    selectedRows = [];
    searchKey = '';
    columns = columns;
    RBColumns = RBColumns;
    secondScreenColumns = secondScreenColumns;
    isSuccess = false;
    disableButton = true;
    get disableButton() {
        return this.checkedRows.length > 0 ? false : true;
    }//enable or disable but

    /*get disableButton(){
        console.log('Inside disableButton getter '+this.checkedRows+' '+this.dateParty);
        return (!this.checkedRows.length > 0 && !this.dateParty != '');
    }*/
    connectedCallback() {
        //today  = new Date().getFullYear() + '-' + (new Date().getMonth()+1) + '-' + new Date().getDate();
        this.today = new Date().toLocaleString();
    }
    getSelectedStore(event) {

        if (event.target.checked && (this.checkedRows.indexOf(event.target.value) === -1)) {
            this.checkedRows.push(event.target.value);
        } else if ((!event.target.checked) && (this.checkedRows.indexOf(event.target.value) !== -1)) {
            this.checkedRows.splice(this.checkedRows.indexOf(event.target.value), 1);
        }
        if (this.dateParty != '' && this.checkedRows.length > 0) {
            this.disableButton = false;
        } else {
            this.disableButton = true;
        }//enable or disable btn
    }
    getDateParty(event) {

        this.dateParty = event.target.value;
        if (this.dateParty != '' && this.checkedRows.length > 0) {
            this.disableButton = false;
        } else {
            this.disableButton = true;
        }//enable or disable btn
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
    rowSelected(event) {

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
    }
    searchKeyChanged(event) {

        //this.checkedRows = [];
        this.searchKey = event.target.value;
        this.selectedRows = this.template.querySelector("lightning-datatable").getSelectedRows();
        /*JSON.parse(JSON.stringify(this.selectedRows)).forEach(currentItem => {
            this.checkedRows.push(currentItem.serviceTeritoryId);
        });*/

    }
    @wire(getAccounts, { searchKey: '$searchKey' }) wiredAccounts({ data, error }) {
        if (data) {

            this.allData = [];
            data.forEach(currentItem => {
                //TODO : currentItem

                let objSR = new Object();
                objSR.serviceTeritoryId = currentItem.Id;
                objSR.Name = currentItem.Name;
                objSR.StoreId = currentItem.Site_Account__r.Store_ID__c;
                objSR.OpeartingHours = currentItem.OperatingHours.Name;
                //objSR.StartTime = "09:30:00.000Z";
                //objSR.EndTime = "18:30:00.000Z";
                objSR.StartTime = null;
                objSR.EndTime = null;
                objSR.id = currentItem.Id;
                objSR.StoreTimeZone = currentItem.OperatingHours.TimeZone;
                objSR.StoreDate = new Date().toISOString();
                if (this.checkedRows.indexOf(objSR.id) === -1) {
                    objSR.isChecked = false;
                } else {
                    objSR.isChecked = true;
                }
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

    get todaysDate() {
        var today = new Date();
        return today.toISOString();
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
            if (this.checkedRows.indexOf(currentItem.id) !== -1) {
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
                    this.isSuccess = true;
                    this.isSecondScreen = false;
                    this.isThirdScreen = true;
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

}