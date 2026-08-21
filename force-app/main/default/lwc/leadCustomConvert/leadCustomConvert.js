import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { loadStyle, loadScript  } from "lightning/platformResourceLoader";
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { stringIsNotBlank } from 'c/stringHelper';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import custommodalcss from "@salesforce/resourceUrl/custommodalcss";
import removeStyle from '@salesforce/resourceUrl/removeStyle';
import leadCelebration from '@salesforce/resourceUrl/LeadConvertCelebration' 

import getContactAccountRelations from '@salesforce/apex/LeadConvertController.getContactAccountRelations';
import getLeadAccountMergeMap from '@salesforce/apex/LeadConvertController.getLeadAccountMergeMap';
import getLeadContactMergeMap from '@salesforce/apex/LeadConvertController.getLeadContactMergeMap';
import getContactRoleOptions from '@salesforce/apex/LeadConvertController.getContactRoleOptions';
import getPotentialContactDuplicates from '@salesforce/apex/LeadConvertController.getPotentialContactDuplicates';
import getPotentialAccountDuplicates from '@salesforce/apex/LeadConvertController.getPotentialAccountDuplicates';
import soslSearchContact from '@salesforce/apex/LeadConvertController.soslSearchContact';
import soslSearchAccount from '@salesforce/apex/LeadConvertController.soslSearchAccount';
import convertLeadWithExistingAccount from '@salesforce/apex/LeadConvertController.convertLeadWithExistingAccount';
import convertLeadWithExistingContact from '@salesforce/apex/LeadConvertController.convertLeadWithExistingContact';
import convertLead from '@salesforce/apex/LeadConvertController.convertLead';

import accLabel from '@salesforce/label/c.GeneralAccount';
import backLabel from '@salesforce/label/c.GeneralBack';
import cancel from '@salesforce/label/c.GeneralCancel';
import convertLeadLabel from '@salesforce/label/c.GeneralConvertLead';
import contact from '@salesforce/label/c.GeneralContact';
import contactRoles from '@salesforce/label/c.GeneralContactRoles';
import createdBy from '@salesforce/label/c.GeneralCreatedBy';
import createdDate from '@salesforce/label/c.GeneralCreatedDate';
import createOpp from '@salesforce/label/c.GeneralCreateOpp';
import oppName from '@salesforce/label/c.GeneralOppName';
import oppLabel from '@salesforce/label/c.GeneralOpportunity';
import search from '@salesforce/label/c.GeneralSearch';
import createAccount from '@salesforce/label/c.GeneralCreateAccount';
import searchAccounts from '@salesforce/label/c.GeneralSearchAccounts';
import searchContacts from '@salesforce/label/c.GeneralSearchContacts';
import leadConverted from '@salesforce/label/c.LeadConverted';
import assignToAccount from '@salesforce/label/c.LeadConvertAssignLeadToAccount';
import assignToContact from '@salesforce/label/c.LeadConvertAssignLeadToContact';
import noDuplicateContact from '@salesforce/label/c.LeadConvertCouldNotFindContact';
import noDuplicateAccount from '@salesforce/label/c.LeadConvertCouldNotFindAccount';
import goToLeads from '@salesforce/label/c.LeadConvertGoToLeads';
import mergeFields from '@salesforce/label/c.LeadConvertMergeFieldValues';
import noAccountDupesFound from '@salesforce/label/c.LeadConvertNoAccountDupesFound';
import noContactDupesFound from '@salesforce/label/c.LeadConvertNoContactDupesFound';
import noAccountSearchResults from '@salesforce/label/c.LeadConvertNoAccountSearchResults';
import noContactSearchResults from '@salesforce/label/c.LeadConvertNoContactSearchResults';
import accountToMergeNotInList from '@salesforce/label/c.LeadConvertAccountToMergeNotInList';
import contactToMergeNotInList from '@salesforce/label/c.LeadConvertContactToMergeNotInList';
import selectForMerge from '@salesforce/label/c.LeadConvertSelectForMerge';
import selectContactAccount from '@salesforce/label/c.LeadConvertSelectContactAccount';
import conversionSuccess from '@salesforce/label/c.LeadConvertSuccess';
import success from '@salesforce/label/c.WebshopGeneralSuccess';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import unsetSelection from '@salesforce/label/c.GeneralUnsetSelection';
import step1 from '@salesforce/label/c.GeneralStep1';
import step2 from '@salesforce/label/c.GeneralStep2';      
import accountShippingStreet from '@salesforce/label/c.GeneralAccountShippingStreet';      

import COMPANY_FIELD from "@salesforce/schema/Lead.Company";

const fields = [COMPANY_FIELD];


export default class LeadCustomConvert extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoaded = false;
    @track passedRecordId = null;
    @track selectedContact = null;
    @track selectedAccount = null;
    @track contactResults = []; // Manual or auto search results List<sObject>
    @track accountResults = [];
    @track contactRoles = [];
    @track contactSingleFieldResults = []; // Results for single record merge and mapping; List<FieldMappingWrapper>
    @track accountSingleFieldResults = [];
    @track contactMappedFields = {}; // Results to submit to Apex, Map<String, String>
    @track accountMappedFields = {};
    @track searchTermAccount = '';
    @track searchTermContact = '';
    @track leadName = '';
    @track createOpp = false;
    @track step = 1;
    @track hasContactResults = false;
    @track hasContactSearch = false;
    @track hasContactSearchResults = false;
    @track hasAccountResults = false;
    @track hasAccountSearch = false;
    @track hasAccountSearchResults = false;
    @track contactSingleMergeMode = false;
    @track accountSingleMergeMode = false;
    @track conversionSuccess = false;
    @track conversionData = {};
    @track oppName = null;
    @track selectedContactAccount = null;
    @track contactAccountSelectionMade = false;
    @track contactRelationOptions = [];
    @track contactAccountSelectedRows = [];
    @track createOpp = true; 
    @track contactRoleOptions = [];
    @track contactMergerLoading = false;
    @track isConverting = false;

    leadConvertCelebration = leadCelebration;

    label = {
        backLabel,
        cancel,
        contactRoles,
        createAccount,
        contact,
        assignToAccount,
        assignToContact,
        noDuplicateContact,
        noDuplicateAccount,
        success,
        generalError,
        conversionSuccess,
        search,
        searchAccounts,
        searchContacts,
        selectForMerge,
        createdBy,
        createdDate,
        createOpp,
        oppName,
        convertLeadLabel,
        noContactDupesFound,
        noAccountDupesFound,
        noContactSearchResults,
        noAccountSearchResults,
        accountToMergeNotInList,
        contactToMergeNotInList,
        accLabel,
        oppLabel,
        leadConverted,
        goToLeads,
        selectContactAccount,
        mergeFields,
        unsetSelection,
        step1,
        step2,
        accountShippingStreet
    }

    _contactColumns = [
        { 
            label: 'Name',
            fieldName: 'idMod',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' }, 
                target: '_blank'
            }, 
        },
        { 
            label: 'Account',
            fieldName: 'accIdMod',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'accName' }, 
                target: '_blank'
            }, 
        },
        { 
            label: this.label.accountShippingStreet,
            fieldName: 'shippingStreet',
        },
        { label: this.label.createdBy, fieldName: 'createdByName', cellAttributes: { class: { fieldName: 'bgClass' }} },
        { label: this.label.createdDate, fieldName: 'CreatedDate', type: 'date' },
    ];
    @track contactColumns = [];
    @track accountColumns = [];
    contactAccColumns = [
        { 
            label: 'Name',
            fieldName: 'idMod',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'accNameMod' }, 
                target: '_blank'
            }, 
        },
        { label: this.label.createdBy, fieldName: 'createdByName', cellAttributes: { class: { fieldName: 'bgClass' }} },
        { label: this.label.createdDate, fieldName: 'createdDate', type: 'date' },
    ];
    _accountColumns = [
        { 
            label: 'Name',
            fieldName: 'idMod',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' }, 
                target: '_blank'
            }, 
        },
        { label: this.label.createdBy, fieldName: 'createdByName', cellAttributes: { class: { fieldName: 'bgClass' }} },
        { label: this.label.createdDate, fieldName: 'CreatedDate', type: 'date' },
    ];

    prepareContactColumns(displayedFields){
        let contactColumns = JSON.parse(JSON.stringify(this._contactColumns));
        Object.keys(displayedFields).forEach(fieldName => {
            let innerObj = {
                label: displayedFields[fieldName],
                fieldName: fieldName
            };
            contactColumns.push(innerObj);
        });
        return contactColumns;
    }

    prepareAccountColumns(displayedFields){
        let returnColumns = JSON.parse(JSON.stringify(this._accountColumns));
        Object.keys(displayedFields).forEach(fieldName => {
            let innerObj = {
                label: displayedFields[fieldName],
                fieldName: fieldName
            };
            returnColumns.push(innerObj);
        });
        return returnColumns;
    }

    // Getters
    get isStepOne(){
        return this.step == 1;
    }
    get isStepTwo(){
        return this.step == 2;
    }
    get isStepThree(){
        return this.step == 3;
    }
    get noContactSearchTerm(){
        return !stringIsNotBlank(this.searchTermContact);
    }
    get noAccountSearchTerm(){
        return !stringIsNotBlank(this.searchTermAccount);
    }
    get noContactSelected(){
        return this.selectedContact == null;
    }
    get noAccountSelected(){
        return this.selectedAccount == null;
    }
    get oppNoName(){
        return this.createOpp && !stringIsNotBlank(this.oppName);
    }
    get contactSingleMergeModeFalse(){
        return !this.contactSingleMergeMode || this.contactRolesMissing || this.oppNoName || (this.createOpp && this.contactAccountSelectionMade == false)
    }
    get accountSingleMergeModeFalse(){
        return !this.accountSingleMergeMode || this.oppNoName;
    }
    get stepOneAndNoContactSelected(){
        return this.isStepOne && this.noContactSelected;
    }
    get createOppAndNoAcc(){
        return this.createOpp && this.contactAccountSelectionMade == true && this.selectedContactAccount == null;
    }
    get contactRolesMissing(){
        return this.createOppAndNoAcc && this.contactRoles.length == 0;
    }

    // Lifecycle
    @wire(getRecord, {
        recordId: "$recordId",
        fields
    })
    lead;

    get companyName() {
        return getFieldValue(this.lead.data, COMPANY_FIELD);
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        loadStyle(this, custommodalcss);
        if (currentPageReference) {
            this.passedRecordId = currentPageReference.state.recordId;
            this.isLoaded = true;
            getContactRoleOptions({})
            .then(outerResult => {
                this.contactRoleOptions = outerResult;
                getPotentialContactDuplicates({leadId: this.passedRecordId})
                .then(innerResult => {
                    this.contactColumns = this.prepareContactColumns(innerResult.displayedFields);
                    this.contactResults = JSON.parse(JSON.stringify(innerResult.records));
                    this.contactResults.forEach(element => {
                        element.idMod = '/' + element.Id;
                        element.accIdMod = '/' + element.AccountId;
                        element.accName = element.Account?.Name;
                        element.shippingStreet = element.Account?.ShippingStreet;
                        element.createdByName = element.CreatedBy?.Name;
                    });
                    if(innerResult.records.length > 0){
                        this.contactResults.unshift({
                            idMod : null,
                            Id : null,
                            createdByName: this.label.unsetSelection,
                            Name: null,
                            shippingStreet: null,
                            CreatedDate: null,
                            bgClass: 'hanging-col2'
                        });
                    }
                    this.hasContactResults = this.contactResults.length > 0;
                })
            });
        }
    }

    disconnectedCallback(){
        loadScript(this, removeStyle);
    }
    
    // Handlers  
    handleGoToLeads(){
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead',
                actionName: 'list'
            }
        });
    }
    handleChangeContactRoles(event){
        this.contactRoles = event.detail.value;     
    }
    handleContactMergerChange(event)  {
        this.contactMappedFields[event.detail.field] = event.detail.value;
    }
    handleAccountMergerChange(event)  {
        this.accountMappedFields[event.detail.field] = event.detail.value;
    }
    handleChangeAccountSearchTerm(event){
        this.searchTermAccount = event.target.value;
    }
    handleSearchAccount(){
        this.accountSingleMergeMode = false;
        this.selectedAccount = null;
        soslSearchAccount({searchTerm: this.searchTermAccount})
        .then(result => {
            this.accountColumns = this.prepareAccountColumns(result.displayedFields);
            this.accountResults = JSON.parse(JSON.stringify(result.records));
            this.accountResults.forEach(element => {
                element.idMod = '/' + element.Id;
                element.createdByName = element.CreatedBy?.Name;
            });
            if(result.records.length > 0){
                this.accountResults.unshift({
                    idMod : null,
                    Id : null,
                    createdByName: this.label.unsetSelection,
                    Name: null,
                    CreatedDate: null,
                    bgClass: 'hanging-col3'
                });
            }
            this.hasAccountSearch = true;
            this.hasAccountSearchResults = this.accountResults.length > 0;
        })
    }
    handleContactKeyDown(event){
        if (event.key === 'Enter' || event.keyCode === 13) {
            this.handleSearchContact();
        }
    }
    handleAccountKeyDown(event){
        if (event.key === 'Enter' || event.keyCode === 13) {
            this.handleSearchAccount();
        }
    }
    handleChangeContactSearchTerm(event){
        this.searchTermContact = event.target.value;
    }
    handleSearchContact(){
        this.contactSingleMergeMode = false;
        this.selectedContact = null;
        soslSearchContact({searchTerm: this.searchTermContact})
        .then(result => {
            this.contactColumns = this.prepareContactColumns(result.displayedFields);
            this.contactResult = [];
            this.contactResults = JSON.parse(JSON.stringify(result.records));
            this.contactResults.forEach(element => {
                element.idMod = '/' + element.Id;
                element.accIdMod = '/' + element.AccountId;
                element.accName = element.Account?.Name;
                element.shippingStreet = element.Account?.ShippingStreet;
                element.createdByName = element.CreatedBy?.Name;
            });
            if(result.records.length > 0){
                this.contactResults.unshift({
                    idMod : null,
                    Id : null,
                    createdByName: this.label.unsetSelection,
                    Name: null,
                    shippingStreet: null,
                    CreatedDate: null,
                    bgClass: 'hanging-col2'
                });
            }
            this.hasContactSearch = true;
            this.hasContactSearchResults = this.contactResults.length > 0;
        })
    }
    handleAccountSelection(event){
        this.accountSingleMergeMode = false;
        const selectedRows = event.detail.selectedRows;
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedAccount = selectedRows[i].Id;
            this.oppName = (selectedRows[i].Name ?? this.companyName) + ' - ';
        }
        this.accountMappedFields = {};
        if(stringIsNotBlank(this.selectedAccount)){
            getLeadAccountMergeMap({
                leadId: this.passedRecordId,
                accountId: this.selectedAccount
            })
            .then(result => {
                this.accountSingleMergeMode = true;
                this.accountSingleFieldResults = JSON.parse(JSON.stringify(result));
            })
        }
    }
    handleContactSelection(event){
        this.contactMergerLoading = true;
        const selectedRows = event.detail.selectedRows;
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedContact = selectedRows[i].Id;
            this.oppName = (selectedRows[i].accName ?? this.companyName) + ' - ';
        }
        this.contactMappedFields = {};
        if(stringIsNotBlank(this.selectedContact)){
            getContactAccountRelations({
                contactId: this.selectedContact
            })
            .then(outerResult => {
                this.contactRelationOptions = [{
                    id : '',
                    Name: null,
                    accNameMod: null,
                    createdByName: this.label.createAccount,
                    createdDate: null,
                    idMod: null,
                    bgClass: 'hanging-col'
                }];
                let contactRelationOptionsPre = JSON.parse(JSON.stringify(outerResult));
                if(this.contactRelationOptions.length > 0){
                    this.contactAccountSelectedRows.push(this.contactRelationOptions[0].AccountId);
                    //this.selectedContactAccount = this.contactRelationOptions[0].AccountId;
                    contactRelationOptionsPre.forEach(element => {
                        element.idMod = '/' + element.AccountId;
                        element.accNameMod = element.Account.Name;
                        element.createdByName = element.Account.CreatedBy?.Name;
                        element.createdDate = element.Account.CreatedDate;
                    });
                    this.contactRelationOptions = this.contactRelationOptions.concat(contactRelationOptionsPre);
                }
                getLeadContactMergeMap({
                    leadId: this.passedRecordId,
                    contactId: this.selectedContact
                })
                .then(result => {
                    this.contactSingleMergeMode = true;
                    this.contactSingleFieldResults = JSON.parse(JSON.stringify(result));
                    this.contactMergerLoading = false;
                })
            });
        }
    }
    handleContactAccountSelection(event){
        const selectedRows = event.detail.selectedRows;
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedContactAccount = selectedRows[i].AccountId;
            this.contactAccountSelectionMade = true;
            this.oppName = (selectedRows[i].Name ?? this.companyName) + ' - ';
        }
    }
    handleChangeCreateOpp(event){
        this.createOpp = event.target.checked;
    }
    handleGoToStepOne(event){
        this.oppName = '';
        this.step = 1;
    }
    handleGoToStepTwo(event){
        this.oppName = this.companyName + ' - ';
        this.step = 2;
        getPotentialAccountDuplicates({leadId: this.passedRecordId})
        .then(result => {
            this.accountColumns = this.prepareAccountColumns(result.displayedFields);
            this.accountResults = JSON.parse(JSON.stringify(result.records));
            this.columns = 
            this.accountResults.forEach(element => {
                element.idMod = '/' + element.Id;
                element.createdByName = element.CreatedBy?.Name;
            });
            if(result.records.length > 0){
                this.accountResults.unshift({
                    idMod : null,
                    Id : null,
                    createdByName: this.label.unsetSelection,
                    Name: null,
                    CreatedDate: null,
                    bgClass: 'hanging-col3'
                });
            }
            this.hasAccountResults = this.accountResults.length > 0;
        })

    }    
    handleChangeOppName(event){
        this.oppName = event.target.value;
    }
    handleConvertLeadWithExistingContactWithOpp(){
        this.handleConvertLeadWithExistingContact(true);
    }
    handleConvertLeadWithExistingContactNoOpp(){
        this.handleConvertLeadWithExistingContact(false);
    }
    handleConvertLeadWithExistingContact(createOpp){
        this.isConverting = true ;
        convertLeadWithExistingContact({
            leadId : this.passedRecordId,
            contactId : this.selectedContact,
            accountId : this.selectedContactAccount,
            contactFieldMapping: this.contactMappedFields,
            withOpp: this.createOpp,
            oppName: this.oppName,
            contactRoles: this.contactRoles
        })
        .then(result => {
            if(!stringIsNotBlank(result.errorMessage)){
                this.handleConversionSuccess(result);
            } else {
                const event = new ShowToastEvent({
                    title: this.label.generalError,
                    message: result.errorMessage,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.isConverting = false;
            }
        })
        .catch(() => {
            this.isConverting = false;
        });
    }
    handleConvertLeadWithExistingAccount(){
        this.isConverting = true ;
        convertLeadWithExistingAccount({
            leadId : this.passedRecordId,
            accountId : this.selectedAccount,
            accountFieldMapping: this.accountMappedFields,
            withOpp: this.createOpp,
            oppName: this.oppName

        })
        .then(result => {
            if(!stringIsNotBlank(result.errorMessage)){
                this.handleConversionSuccess(result);
            } else {
                const event = new ShowToastEvent({
                    title: this.label.generalError,
                    message: result.errorMessage,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.isConverting = false;
            }
        })
        .catch(() => {
            this.isConverting = false;
        });
    }
    handleConvertLead(){
        this.isConverting = true;

        convertLead({
            leadId : this.passedRecordId,
            withOpp: this.createOpp,
            oppName: this.oppName
        })
        .then(result => {
            if(!stringIsNotBlank(result.errorMessage)){
                this.handleConversionSuccess(result);
            } else {
                const event = new ShowToastEvent({
                    title: this.label.generalError,
                    message: result.errorMessage,
                    variant: 'error'
                });
                this.dispatchEvent(event);
                this.isConverting = false;
            }
        })
        .catch(() => {
        this.isConverting = false;
        });
    }
    handleConversionSuccess(result){
        this.conversionSuccess = true;
        this.conversionData = result;
        this.isConverting = false;
        /*const event = new ShowToastEvent({
            title: this.label.success,
            message: this.label.conversionSuccess,
            variant: 'success'
        });
        this.dispatchEvent(event);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                passedRecordId: result.contactId,
                actionName: 'view'
            }
        });*/
    }
    closeModal(){
        loadScript(this, removeStyle)
        .then(result => {
            this.dispatchEvent(new CloseActionScreenEvent());
            if(this.conversionSuccess == true){
                let self = this;
                setTimeout(() => {
                    self[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            passedRecordId: stringIsNotBlank(self.conversionData.opportunityId) ? self.conversionData.opportunityId : self.conversionData.contactId,
                            actionName: 'view'
                        }
                    });
                }, 250);
            }
        });
    }
}