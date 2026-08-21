import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import emailLabel from '@salesforce/label/c.GeneralEmail';
import addressLabel from '@salesforce/label/c.GeneralAddress';
import companyLabel from '@salesforce/label/c.GeneralCompany';
import nameLabel from '@salesforce/label/c.GeneralName';
import selectForMerge from '@salesforce/label/c.LeadConvertSelectForMerge';
import cancel from '@salesforce/label/c.GeneralCancel';
import save from '@salesforce/label/c.GeneralSave';
import leadDuplicates from '@salesforce/label/c.LeadDuplicates';
import companyStreet from '@salesforce/label/c.LeadDuplicateCompanyStreet';
import lastNameCompany from '@salesforce/label/c.LeadDuplicateLastNameCompany';
import noDupes from '@salesforce/label/c.LeadDuplicateNoPotentialDuplicates';
import noFilteredDupes from '@salesforce/label/c.LeadDuplicateNoFilteredDuplicates';
import generalSuccess from '@salesforce/label/c.WebshopGeneralSuccess';
import successMessage from '@salesforce/label/c.LeadDuplicateSuccessMessage';
//import mergeAllComments from '@salesforce/label/c.LeadDuplicateMergeAllComments';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import yes from '@salesforce/label/c.GeneralYes';
import no from '@salesforce/label/c.GeneralNo';

import getPotentialLeadDuplicates from '@salesforce/apex/LeadConvertController.getPotentialLeadDuplicates';
import getLeadLeadMergeMap from '@salesforce/apex/LeadConvertController.getLeadLeadMergeMap';
import saveLeadDuplicates from '@salesforce/apex/LeadConvertController.saveLeadDuplicates';

export default class LeadDuplicateCheck extends LightningElement {
    @api recordId;
    @track isLoaded = false;
    @track isLoading = true;
    @track data = [];
    @track dataDisplayed = [];
    @track saveDisabled = true;
    @track hasData = false;
    @track hasFilteredData = false;
    @track selectForMergeDisabled = true;
    @track selectedRows = [];
    @track selectedRowsCopy = [];
    @track emailFilterSet = true;
    @track companyStreetFilterSet = true;
    @track lastNameCompanyFilterSet = true;
    @track showMergeModal = false;
    @track recordNames = [];
    @track fieldValues = [];
    @track mappedFields = {};
    @track dataLoaded = false;
    //@track mergeAllComments = false;
    @track masterLeadId;
    @track isSaving = false; //my code

    label = {
        emailLabel,
        addressLabel,
        companyLabel,
        nameLabel,
        selectForMerge,
        save,
        cancel,
        generalSuccess,
        generalError,
        leadDuplicates,
        companyStreet,
        lastNameCompany,
        noDupes,
        noFilteredDupes,
        successMessage,
        //mergeAllComments,
        yes,
        no
    }

    columns = [
        { 
            label: this.label.nameLabel,
            fieldName: 'url',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'name' }, 
                target: '_blank'
            }, 
        },
        { label: this.label.emailLabel, fieldName: 'email' },
        { label: this.label.companyLabel, fieldName: 'company' },
        { label: this.label.addressLabel, fieldName: 'address' }
    ];

    connectedCallback(){
        this.masterLeadId = this.recordId;
        this.retrieveData();
    }

    retrieveData(){
        getPotentialLeadDuplicates({ leadId: this.recordId })
        .then(result => {
            this.data = JSON.parse(JSON.stringify(result));
            this.dataDisplayed = JSON.parse(JSON.stringify(result));
            this.hasData = this.data.length > 0;
            this.hasDataDisplayed = this.dataDisplayed.length > 0;
            this.isLoading = false;
            this.isLoaded = true;
        });
    }

    handleRowSelect(event){
        this.dataLoaded = false;
        this.selectedRows = [];
        this.selectForMergeDisabled = true;
        for (let i = 0; i < event.detail.selectedRows.length; i++) {
            this.selectedRows.push(event.detail.selectedRows[i].id);
        }
        this.selectedRows.sort();
        this.selectedRowsCopy = JSON.parse(JSON.stringify(this.selectedRows));
        if(this.selectedRows.length > 0){
            getLeadLeadMergeMap({
                leadId: this.recordId,
                secondLeadIds: this.selectedRows
            }).then(result => {
                this.mappedFields = JSON.parse(JSON.stringify(result.mappedFields));
                this.fieldValues = JSON.parse(JSON.stringify(result.wrappers));
                this.recordNames = JSON.parse(JSON.stringify(result.recordNames));
                this.selectForMergeDisabled = false;
                this.dataLoaded = true;
            })
        }
    }

    /*handleChangeMergeAllComments(event)  {
        this.mergeAllComments = event.target.checked;
    }*/

    handleMergeChange(event)  {
        this.mappedFields[event.detail.field] = event.detail.value;
        console.log('this.mappedFields: ' + JSON.stringify(this.mappedFields));
    }

    toggleEmailFilter(event){
        this.emailFilterSet = !this.emailFilterSet;
        this.filterData();
    }
    get emailCssClass(){
        return this.emailFilterSet ? 'selectedButton' : 'unselectedButton';
    }
    toggleCompanyStreetFilter(event){
        this.companyStreetFilterSet = !this.companyStreetFilterSet;
        this.filterData();
    }
    get companyStreetCssClass(){
        return this.companyStreetFilterSet ? 'selectedButton' : 'unselectedButton';
    }
    toggleLastNameCompanyFilter(event){
        this.lastNameCompanyFilterSet = !this.lastNameCompanyFilterSet;
        this.filterData();
    }
    get lastNameCompanyCssClass(){
        return this.lastNameCompanyFilterSet ? 'selectedButton' : 'unselectedButton';
    }

    filterData(){
        this.selectedRows = [];
        this.selectForMergeDisabled = true;
        let self = this;
        this.dataDisplayed = this.data.filter((row) => (
            (self.emailFilterSet && row.isEmailDupe) ||
            (self.companyStreetFilterSet && row.isCompanyStreetDupe) ||
            (self.lastNameCompanyFilterSet && row.isLastNameCompanyDupe)
        ));
        this.hasDataDisplayed = this.dataDisplayed.length > 0;
    }

    handleSelectForMerge(){
        this.showMergeModal = true;
    }
    handleCloseMergeModal(){
        this.masterLeadId = this.recordId;
        this.showMergeModal = false;
    }
    handleMainRecordChange(event){
        let newMaster = event.detail.recordid;
        if(!this.selectedRows.includes(this.masterLeadId)){
            this.selectedRows.push(this.masterLeadId);
        }
        let index = this.selectedRows.indexOf(newMaster);
        if (index > -1) { 
            this.selectedRows.splice(index, 1); 
        }
        this.selectedRows.sort();
        this.masterLeadId = newMaster;
    }
    handleSave() {
        this.isSaving = true; 
        saveLeadDuplicates({
            masterLeadId: this.masterLeadId,
            duplicateLeadIds: this.selectedRows,
            fieldValues: this.mappedFields,
            //mergeAllComments: this.mergeAllComments
        })
        .then(result => {
            const event = new ShowToastEvent({
                title: result == 'success' ? this.label.success : this.label.generalError,
                message: result == 'success' ? this.label.successMessage : result,
                variant: result == 'success' ? 'success' : 'error'
            });
            this.dispatchEvent(event);
            if (result === 'success') {
                this.showMergeModal = false;
                this.data = [];
                this.dataDisplayed = [];
                requestAnimationFrame(() => {
                    if (this.masterLeadId === this.recordId) {
                        window.location.reload();
                    } else {
                        window.location.assign('/' + this.masterLeadId);
                    }
                });
            } else {
                this.isSaving = false; 
            }
        })
        .catch(() => {
            this.isSaving = false; 
        });
    }
}