import { LightningElement, wire, track } from 'lwc';

import getAccounts from '@salesforce/apex/TestResourceAbsenceController.getAllStores';
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
    dateParty = null;
    checkedRows = [];
    recordsData = [];
    selectedRows = [];
    searchKey = '';
    columns = columns;
    isSuccess = false;
    showSpinner = false; // to show loading spinner
    operatingHourOptions = [];
    selectedOperatingHourId = '';
    storeRegionOptions = [];
    selectedRegion = '';
    userTimezone;


    get disableButton() {
        return (this.globalrowvalueselected.length == 0 || this.dateParty == null);
    }

    get regionOptDisable(){
        return this.storeRegionOptions.length == 0;
    }

    get disablebtn(){
        return this.selectedRegion == null;
    }

    connectedCallback() {
        this.today = new Date().toJSON().slice(0, 10);
    }

    getDateParty(event) {
        this.dateParty = event.target.value;
    }

    globalrowvalueselected = [];

    rowSelected(event) {

        var eventdetails = JSON.parse(JSON.stringify(event.detail)).config;
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
                JSON.stringify('deselectAllRows '+this.globalrowvalueselected);
                this.modifyCheckedRow();
            }
            else if(eventdetails.action == 'selectAllRows'){
                const allSiteIds = this.data.map(site => site.id);
                console.log('selectAllRows '+allSiteIds);
                allSiteIds.forEach(currentItem => {
                    if (this.globalrowvalueselected.indexOf(currentItem) === -1) {
                        this.globalrowvalueselected.push(currentItem);
                        
                        
                    }
                });
                console.log('After selectAllRows lenghth : '+this.globalrowvalueselected.length);
                JSON.stringify('selectAllRows '+this.globalrowvalueselected);
                this.modifyCheckedRow();
            }
            else if(eventdetails.action == 'rowDeselect'){
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
                this.modifyCheckedRow();
            }
        }
    }

    modifyCheckedRow(){
        this.checkedRows = [];
        this.data.forEach(currentItem => {
            if (this.globalrowvalueselected.indexOf(currentItem.id) !== -1) {
                this.checkedRows.push(currentItem.id);
            }
        });
    }

    @wire(getAccounts, { operatingHourId: '$selectedOperatingHourId', region: '$selectedRegion', searchKey: '$searchKey' }) wiredAccounts({ data, error }) {
        this.showSpinner = true;
        if (data) {

            this.allData = [];
            this.checkedRows = [];
            data.forEach(currentItem => {

                let objSR = new Object();
                objSR.serviceTeritoryId = currentItem.Id;
                objSR.Name = currentItem.Name;
                objSR.StoreId = currentItem.Site_Account__r.Store_ID__c;
                objSR.OpeartingHours = currentItem.OperatingHours.Name;
                objSR.region = currentItem.Site_Account__r.Store_Region__c;
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
                }
                this.allData.push(objSR);
            });

            if (this._firstTimeRun && this.allData.length > 0) {
                this._firstTimeRun = false;
                this._firstTimeAllData = this.allData;
            }
            this.data = this.allData;
            this.showSpinner = false;
        } else if (error) {
            this.showSpinner = false;
        }
    }

    searchStore(evt) {
        this.searchKey = this.template.querySelector('lightning-input[data-id=searchtext]').value;
    }

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.queryTerm = evt.target.value;
        }
    }

    handleFirstScreen() {
        
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
            var options = [{'label' : 'All', 'value' : 'All'}];
            options.push(...data);
            this.operatingHourOptions = options;
        } else if (error) {
            console.log('Not able to get the operating hour options from server');
            this.operatingHourOptions = [];
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
        var valueSeleted = event.detail.value
        this.selectedOperatingHourId = valueSeleted == 'All' ? '' : valueSeleted;
        this.selectedRegion ='';
        this.storeRegionOptions =[];
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