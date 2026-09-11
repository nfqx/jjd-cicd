import { LightningElement, api, track } from 'lwc';
import getData from '@salesforce/apex/QuoteInstallmentPurchasePlanController.getData';
import handleSaveAccountQuote from '@salesforce/apex/QuoteInstallmentPurchasePlanController.handleSaveAccountQuote';
import findAndConnectLatestQuote from '@salesforce/apex/QuoteInstallmentPurchasePlanController.findAndConnectLatestQuote';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import annualMachineExpectation from '@salesforce/label/c.QuoteInstallmentAnnualMachineExpectation'; 
import headerFirst from '@salesforce/label/c.QuoteInstallmentHeaderFirst';
import headerSecond from '@salesforce/label/c.QuoteInstallmentHeaderSecond';
import headerThird from '@salesforce/label/c.QuoteInstallmentHeaderThird';
import headerFourth from '@salesforce/label/c.QuoteInstallmentHeaderFourth';
import product from '@salesforce/label/c.GeneralProduct';
import reloadQuote from '@salesforce/label/c.QuoteInstallmentReloadQuote';
import tableHeaderSecond from '@salesforce/label/c.QuoteInstallmentTableHeaderSecond';
import tableHeaderThird from '@salesforce/label/c.QuoteInstallmentTableHeaderThird';
import tableHeaderFourth from '@salesforce/label/c.QuoteInstallmentTableHeaderFourth';
import tableHeaderFifth from '@salesforce/label/c.QuoteInstallmentTableHeaderFifth';
import tableHeaderSixth from '@salesforce/label/c.QuoteInstallmentTableHeaderSixth';
import tableHeaderSeventh from '@salesforce/label/c.QuoteInstallmentTableHeaderSeventh';
import tableHeaderSeventhHalf from '@salesforce/label/c.QuoteInstallmentTableHeaderSeventhHalf';
import tableHeaderEighth from '@salesforce/label/c.QuoteInstallmentTableHeaderEighth';
import tableHeaderNinth from '@salesforce/label/c.QuoteInstallmentTableHeaderNinth';
import tableHeaderTenth from '@salesforce/label/c.QuoteInstallmentTableHeaderTenth';
import cyFieldLabel from '@salesforce/label/c.QuoteInstallmentSalesQuantityCYToday';
import lyFieldLabel from '@salesforce/label/c.QuoteInstallmentSalesQuantityLYTotal';
import save from '@salesforce/label/c.GeneralSave';
import quoteInstallmentPurchasePlan from '@salesforce/label/c.QuoteInstallmentPurchasePlan';
import quoteInstallmentProductCalculation from '@salesforce/label/c.QuoteInstallmentProductCalculation';
import errorMsg from '@salesforce/label/c.WebshopGeneralError';
import salesAndLocation from '@salesforce/label/c.QuoteInstallmentSalesAndLocation';
import detailsOfManagingDirector from '@salesforce/label/c.QuoteInstallmentDetailsOfManagingDirector';
import contractDetails from '@salesforce/label/c.QuoteInstallmentContractDetails';
import coffeeSales from '@salesforce/label/c.QuoteInstallmentCoffeeSales';
import loanDetails from '@salesforce/label/c.QuoteInstallmentLoanDetails';
import customerSince from '@salesforce/label/c.QuoteInstallmentCustomerSince';


export default class QuoteInstallmentPurchasePlan extends LightningElement {
    @api recordId;
    @track groupId;
    @track quoteData = {};
    @track contactData = {};
    @track accountData = {};
    @track hasAccount = false;
    @track hasContact = false;
    @track salesQuantityLY = null;
    @track salesQuantityCY = null;
    @track isGLOnly = false;
    @track isAdminOrGL = false;
    @track isAdminOrMachineTeam = false;
    @track showData = false;
    @track products = [];
    @track showProducts = false;
    @track contactDataUpper = {};
    @track accountDataLower = {};
    @track quoteDataUpper = {};
    @track quoteDataLower = {};
    @track upperSendDisabled = true;
    @track lowerSendDisabled = true;
    @track hasPriceConfiguratorQuote;
    @track quoteReloading = false;
    @track annualMachineExpectation = '0';

    get contactStreet(){
        return this.contactData && this.contactData.MachinePrivateAddress__c && this.contactData.MachinePrivateAddress__c.street ? this.contactData.MachinePrivateAddress__c.street : '';
    }
    get contactPostalCode(){
        return this.contactData && this.contactData.MachinePrivateAddress__c && this.contactData.MachinePrivateAddress__c.postalCode ? this.contactData.MachinePrivateAddress__c.postalCode : '';
    }
    get contactCity(){
        return this.contactData && this.contactData.MachinePrivateAddress__c && this.contactData.MachinePrivateAddress__c.city ? this.contactData.MachinePrivateAddress__c.city : '';
    }
    get contactCountry(){
        return this.contactData && this.contactData.MachinePrivateAddress__c && this.contactData.MachinePrivateAddress__c.country ? this.contactData.MachinePrivateAddress__c.country : '';
    }

    handleChangeContactDataUpper(event){
        let columnName = event.target.dataset.column;
        this.contactDataUpper[columnName] = event.target.value;
        this.upperSendDisabled = false;
    }

    handleChangeAccountDataLower(event){
        let columnName = event.target.dataset.column;
        this.accountDataLower[columnName] = event.target.value;
        this.lowerSendDisabled = false;
    }

    handleChangeQuoteDataUpper(event){
        let columnName = event.target.dataset.column;
        this.quoteDataUpper[columnName] = event.target.value;
        this.annualMachineExpectation = this.quoteData.MachineRuntimeInMonths__c != null ? (((this.quoteDataUpper.MachineSalesExpectationCoffee__c ?? this.quoteData.MachineSalesExpectationCoffee__c) / this.quoteData.MachineRuntimeInMonths__c) * 12).toFixed(2) : '0';
        this.upperSendDisabled = false;
    }

    handleChangeQuoteDataLower(event){
        let columnName = event.target.dataset.column;
        this.quoteDataLower[columnName] = event.target.value;
        this.lowerSendDisabled = false;
    }

    handleUpperSend(){
        this.upperSendDisabled = true;
        handleSaveAccountQuote({
            contactId: this.hasContact ? this.contactData.Id : null,
            quoteId: this.recordId,
            accountId: null,
            contactData: this.contactDataUpper,
            quoteData: this.quoteDataUpper,
            accountData: {}
        })
        .then(result => {
            this.contactDataUpper = {};
            this.quoteDataUpper = {};
        })
    }

    handleLowerSend(){
        this.lowerSendDisabled = true;
        handleSaveAccountQuote({
            contactId: null,
            quoteId: this.recordId,
            accountId: this.hasAccount ? this.accountData.Id : null,
            contactData: {},
            quoteData: this.quoteDataLower,
            accountData: this.accountDataLower,
        })
        .then(result => {
            this.accountDataLower = {};
            this.quoteDataLower = {};
        })
    }

    label = {
        headerFirst,
        headerSecond,
        headerThird,
        headerFourth,
        product,
        tableHeaderSecond,
        tableHeaderThird,
        tableHeaderFourth,
        tableHeaderFifth,
        tableHeaderSixth,
        tableHeaderSeventh,
        tableHeaderSeventhHalf,
        tableHeaderEighth,
        tableHeaderNinth,
        tableHeaderTenth,
        cyFieldLabel,
        lyFieldLabel,
        save,
        annualMachineExpectation,
        quoteInstallmentPurchasePlan,
        quoteInstallmentProductCalculation,
        errorMsg,
        reloadQuote,
        salesAndLocation,
        detailsOfManagingDirector,
        contractDetails,
        coffeeSales,
        loanDetails,
        customerSince
    }
    
    get isAdminOrGLOrMachineTeam(){
        return this.isAdminOrGL || this.isAdminOrMachineTeam;
    }

    columns = [
        {
            label: this.label.product,
            fieldName: 'name',
        },
        {
            label: this.label.tableHeaderSecond,
            fieldName: 'vkPriceCustomer',
            type: 'currency',
            typeAttributes: { currencyCode: 'EUR', step: '0.01' },
        },
        {
            label: this.label.tableHeaderThird,
            fieldName: 'vlPrice',
            type: 'currency',
            typeAttributes: { currencyCode: 'EUR', step: '0.01' },
        },
        {
            label: this.label.tableHeaderFourth,
            fieldName: 'rvInPercentDisplay',
            type: 'percent',
        },
        {
            label: this.label.tableHeaderFifth,
            fieldName: 'rvInEuro',
            type: 'currency',
            typeAttributes: { currencyCode: 'EUR', step: '0.01' },
        },
        {
            label: this.label.tableHeaderSixth,
            fieldName: 'wkzEuroPerKg',
            type: 'currency',
            typeAttributes: { currencyCode: 'EUR', step: '0.01' },
        },
        {
            label: this.label.tableHeaderSeventh,
            fieldName: 'rentalContactEuroPerKg',
            type: 'currency',
            typeAttributes: { currencyCode: 'EUR', step: '0.01' },
        },
        {
            label: this.label.tableHeaderSeventhHalf,
            fieldName: 'financingEuroPerKg',
            type: 'currency',
            typeAttributes: { currencyCode: 'EUR', step: '0.01' },
        },
        {
            label: this.label.tableHeaderEighth,
            fieldName: 'netSalePrice',
            type: 'currency',
            typeAttributes: { currencyCode: 'EUR', step: '0.01' },
        },
        {
            label: this.label.tableHeaderNinth,
            fieldName: 'vsPrice',
            type: 'currency',
            typeAttributes: { currencyCode: 'EUR', step: '0.01' },
        },
        {
            label: this.label.tableHeaderTenth,
            fieldName: 'winLossEuroPerKg',
            type: 'currency',
            typeAttributes: { currencyCode: 'EUR', step: '0.01' },
        },
    ]

    connectedCallback(){
        this.getData();
    }

    handleReloadQuote(){
        this.quoteReloading = true;
        findAndConnectLatestQuote({quoteId: this.recordId})
        .then(result => {
            if(result == 'success'){
                this.getData();
            } else {
                this.quoteReloading = false;
            }
        })
    }

    changePriceConfiguratorQuote(event){
        let newVal = event.target.value;
        handleSavePriceConfiguratorQuote({
            quoteId: this.recordId,
            priceConfiguratorQuoteId: newVal
        })
        .then(result => {
            if(result == 'success'){
                this.hasPriceConfiguratorQuote = true;
                this.getData();
            } else {
                const evt = new ShowToastEvent({
                    title: this.label.errorMsg,
                    message: result,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            }
        })
    }

    getData(){
        getData({quoteId: this.recordId})
        .then(result => {
            this.groupId = result.groupId;
            this.quoteData = result.quoteData;
            this.contactData = result.contactData;
            this.accountData = result.accountData;
            this.hasAccount = result.hasAccount;
            this.hasContact = result.hasContact;
            this.isGLOnly = result.isGLOnly;
            this.salesQuantityLY = result.salesQuantityLY;
            this.salesQuantityCY = result.salesQuantityCY;
            this.isAdminOrGL = result.isAdminOrGL;
            this.isAdminOrMachineTeam = result.isAdminOrMachineTeam;
            this.hasPriceConfiguratorQuote = result.hasPriceConfiguratorQuote;
            this.annualMachineExpectation = this.quoteData.MachineRuntimeInMonths__c != null ? ((this.quoteData.MachineSalesExpectationCoffee__c / this.quoteData.MachineRuntimeInMonths__c) * 12).toFixed(2) : '0';
            this.products = result.products;
            this.showProducts = result.products.length > 0;
            this.showData = true;
            this.quoteReloading = false;
        });
    }
}