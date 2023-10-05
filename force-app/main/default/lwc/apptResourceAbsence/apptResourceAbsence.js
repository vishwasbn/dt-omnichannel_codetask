import { LightningElement, wire, track } from 'lwc';

import getAccounts from '@salesforce/apex/Appt_ResourceAbsenceController.getAllStores';
import createAbsence from '@salesforce/apex/Appt_ResourceAbsenceController.createAbsenceRecords';
import getOperatingHourOptions from '@salesforce/apex/Appt_ResourceAbsenceController.getOperatingHourOptions';
import getSiteRegions from '@salesforce/apex/Appt_ResourceAbsenceController.getSiteRegions';
import getUserAccountTimezone from '@salesforce/apex/Appt_ResourceAbsenceController.getUserAccountTimezone';

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
    storeList = [];
    _firstTimeRun = true;
    _firstTimeAllData = [];
    today = '';
    dateParty = null;
    checkedRows = []; //used to hold the select store id from filter data
    resourceAbsenceRec = [];
    searchKey = '';
    columns = columns;
    isSuccess = false;
    showSpinner = false; // to show loading spinner
    operatingHourOptions = [];
    selectedOperatingHourId = '';
    storeRegionOptions = [];
    selectedRegion = '';
    userTimezone;
    globalRowValueSelected = []; //used to hold all selected stores


    get disableButton() {
        return (this.globalRowValueSelected.length == 0 || this.dateParty == null);
    }

    get regionOptDisable(){
        return this.storeRegionOptions.length == 0;
    }

    //used to get the current date
    connectedCallback() {
        this.today = new Date().toJSON().slice(0, 10);
    }

    /**
     * Used to get the logged in user org timezone
     */
    @wire(getUserAccountTimezone)
    wiredUserTimezone({ data, error }) {
        if (data) {
            this.userTimezone = data;
        } else if (error) {
            this.userTimezone = null;
        }
    }

    /**
     * Used to get the Store operating Hour Value
     * For filter Store based on operating hours
     */
    @wire(getOperatingHourOptions)
    wiredAccountOptions({ data, error }) {
        if (data) {
            var options = [{'label' : 'All', 'value' : 'All'}]; // Add 'All' option to Operating Hour dropdown to query All Stores  
            options.push(...data);
            this.operatingHourOptions = options;
        } else if (error) {
            this.operatingHourOptions = [];
        }
    }

    /**
     * * This wire function is used to get the store and list in ui
     * also handles the filtering option
     * @param 'operatingHourId' Operating hour dropdown value 'selectedRegion' Storeregion from dropdown 'searchKey' Store name
     */
    @wire(getAccounts, { operatingHourId: '$selectedOperatingHourId', region: '$selectedRegion', searchKey: '$searchKey' }) wiredStores({ data, error }) {
        this.showSpinner = true;
        if (data) {

            var storeObjList = [];
            this.checkedRows = [];
            data.forEach(currentItem => {

                let storeObj = new Object();
                storeObj.serviceTeritoryId = currentItem.Id;
                storeObj.Name = currentItem.Name;
                storeObj.StoreId = currentItem.Site_Account__r.Store_ID__c;
                storeObj.OpeartingHours = currentItem.OperatingHours.Name;
                storeObj.region = currentItem.Site_Account__r.Store_Region__c;
                storeObj.StartTime = null;
                storeObj.EndTime = null;
                storeObj.id = currentItem.Id;
                storeObj.StoreTimeZone = currentItem.OperatingHours.TimeZone;
                storeObj.StoreDate = new Date().toISOString();

                if(this.globalRowValueSelected.indexOf(storeObj.id) !== -1){
                    this.checkedRows.push(storeObj.id);
                }

                storeObjList.push(storeObj);
            });

            if (this._firstTimeRun && storeObjList.length > 0) {
                this._firstTimeRun = false;
                this._firstTimeAllData = storeObjList;
            }
            this.storeList = storeObjList;
            this.showSpinner = false;
        } else if (error) {
            this.showSpinner = false;
        }
    }

    // set the selected Party date
    getDateParty(event) {
        this.dateParty = event.target.value;
    }   

    //on search button click sets the search key value, this will trigger wire wiredStores function
    searchStore(evt) {
        this.searchKey = this.template.querySelector('lightning-input[data-id=searchtext]').value;
    }

    //handles Operating hour dropdown value selection
    handleOperatingHourChange(event) {
        var valueSeleted = event.detail.value
        this.selectedOperatingHourId = valueSeleted == 'All' ? '' : valueSeleted;
        this.selectedRegion =''; //resets the Store region selection
        this.storeRegionOptions =[]; //resets the Store region dropdown value
        this.getSiteRegions(); //fetch the Store region associated with the user selected Operating Hour 
    }

    /** function used to get all store region operating on selected Operating Hour dropdown  */
    getSiteRegions(){
        getSiteRegions({ operatingHourId : this.selectedOperatingHourId })
        .then((result) => {
            this.storeRegionOptions = result;

        })
        .catch((error) => {
            this.storeRegionOptions = [];
        });
    }

    //sets the id of Store Region dropdown selectionvalue, this will trigger wire wiredStores function
    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;        
    }


    //Handles the Store selection for the Resource Absence creation
    rowSelected(event) {

        var eventdetails = JSON.parse(JSON.stringify(event.detail)).config; //identifies the user action 
        if(eventdetails.action != undefined){
            if(eventdetails.action == 'deselectAllRows'){
                const allSiteIds = this.storeList.map(site => site.id); // get all stores dispalyed for the users filter
                allSiteIds.forEach(currentItem => {
                    if (this.globalRowValueSelected.indexOf(currentItem) !== -1) {
                        this.globalRowValueSelected = this.removeElementAt(this.globalRowValueSelected, this.globalRowValueSelected.indexOf(currentItem));// remove the Store id from global selection
                        
                    }
                });
                this.modifyCheckedRow();// Update the store selection for current screen
            }
            else if(eventdetails.action == 'selectAllRows'){
                const allSiteIds = this.storeList.map(site => site.id); // get all stores dispalyed for the users filter
                allSiteIds.forEach(currentItem => {
                    if (this.globalRowValueSelected.indexOf(currentItem) === -1) {
                        this.globalRowValueSelected.push(currentItem); //add the Store id to global selection                     
                        
                    }
                });
                this.modifyCheckedRow();// Update the store selection for current screen
            }
            else if(eventdetails.action == 'rowDeselect'){
                const allSiteIds = this.storeList.map(site => site.id); // get all stores dispalyed for the users filter
                var selectedRowObj = JSON.parse(JSON.stringify(this.template.querySelector("lightning-datatable").getSelectedRows())); //get the selected store id from datatable 
                var selectedRowMap = selectedRowObj.map(rowentry => rowentry.id);
                allSiteIds.forEach(currentItem => {
                    if(selectedRowMap.indexOf(currentItem) === -1){
                        if (this.globalRowValueSelected.indexOf(currentItem) !== -1) {
                            this.globalRowValueSelected = this.removeElementAt(this.globalRowValueSelected, this.globalRowValueSelected.indexOf(currentItem));
                            
                        }
                    }
                    
                });
            }
            else if (eventdetails.action == 'rowSelect') {
                var selectedRowMap = this.template.querySelector("lightning-datatable").getSelectedRows(); //get the selected store id from datatable 
                JSON.parse(JSON.stringify(selectedRowMap)).forEach(currentItem => {
                    if (this.globalRowValueSelected.indexOf(currentItem.serviceTeritoryId) === -1) {
                        this.globalRowValueSelected.push(currentItem.serviceTeritoryId); //add the Store id to global selection
                        
                    }
                });
                this.modifyCheckedRow(); // Update the store selection for current screen
            }
        }
    }

    //generic method to remove a value form the array
    removeElementAt(arr, index) {
        let frontPart = arr.slice(0, index);
        let lastPart  = arr.slice( index+1 ); // index to end of array
        return [...frontPart, ...lastPart];
     }

    modifyCheckedRow(){
        this.checkedRows = [];
        this.storeList.forEach(currentItem => {
            if (this.globalRowValueSelected.indexOf(currentItem.id) !== -1) {
                this.checkedRows.push(currentItem.id); // update the row selection for current screen
            }
        });
    }

    //
    handleFirstScreen() {
        // Validate the Party date selection
        if (new Date(this.dateParty).toJSON().slice(0, 10) < new Date().toJSON().slice(0, 10)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Select correct date of party.',
                    message: 'Date Party must be Today or future date.',
                    variant: 'error'
                }),
            );
            return;
        }
        this.resourceAbsenceRec = [];
        this._firstTimeAllData.forEach(currentItem => {
            if (this.globalRowValueSelected.indexOf(currentItem.id) !== -1) {
                currentItem.StoreDate = this.dateParty;
                this.resourceAbsenceRec.push(currentItem); // data for the second screen, add only the Store seleted from first screen 
            }
        });
        this.isFirstScreen = false;
        this.isSecondScreen = true;
    }

    //Used to redirect to Store selection page
    goBack() {
        this.isFirstScreen = true;
        this.isSecondScreen = false;
    }

    handleSecondScreen() {
        //Used to validate the required fields values from the resource absence data capture screen
        const allValid = [...this.template.querySelectorAll('.absencevalidation')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

            if(allValid){
                
                this.resourceAbsenceRec.forEach(currentItem => {
                // Used to validate the resource absence entry data
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
                this.showSpinner = true;
                createAbsence({ requestData: JSON.stringify(this.resourceAbsenceRec) })
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
                        this.showSpinner = false;
                    })
                    .catch(error => {

                        this.isSuccess = false;
                        this.isSecondScreen = false;
                        this.isThirdScreen = true;
                        this.showSpinner = false;
                    })
        }


    }

    // used to handle the start time update for resource absence entry data
    handleStartTimeChange(event) {

        let element = this.resourceAbsenceRec.find(ele => ele.id === event.currentTarget.dataset.id);
        element.StartTime = event.target.value;
        this.resourceAbsenceRec = [...this.resourceAbsenceRec];

    }
    
    // used to handle the end time update for resource absence entry data
    handleEndTimeChange(event) {

        let element = this.resourceAbsenceRec.find(ele => ele.id === event.currentTarget.dataset.id);
        element.EndTime = event.target.value;
        this.resourceAbsenceRec = [...this.resourceAbsenceRec];

    }
    
    // used to handle the date update for resource absence entry data
    handleStoreDateChange(event) {

        let element = this.resourceAbsenceRec.find(ele => ele.id === event.currentTarget.dataset.id);
        element.StoreDate = event.target.value;
        this.resourceAbsenceRec = [...this.resourceAbsenceRec];

    }

    //reload the store selection screen
    reload(){
        location.reload();
    }

}