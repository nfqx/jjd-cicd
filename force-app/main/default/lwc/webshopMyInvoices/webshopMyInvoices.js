import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';
import { fireEvent } from 'c/pubsub'

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getAllInvoices from '@salesforce/apex/WebshopDataController.getAllInvoices';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Labels
import backToShop from '@salesforce/label/c.WebshopBackToShop';
import myInvoices from '@salesforce/label/c.WebshopMyInvoices';
import myInvoicesSubtitle from '@salesforce/label/c.WebshopMyInvoicesSubtitle';
import invoiceNumber from '@salesforce/label/c.WebshopInvoiceNumber';
import invoiceDate from '@salesforce/label/c.WebshopInvoiceDate';
import totalAmount from '@salesforce/label/c.WebshopTotalAmount';
import viewDetails from '@salesforce/label/c.WebshopViewDetails';
import searchByInvoiceNumber from '@salesforce/label/c.WebshopSearchByInvoiceNumber';
import last7Days from '@salesforce/label/c.WebshopLast7Days';
import last30Days from '@salesforce/label/c.WebshopLast30Days';
import last365Days from '@salesforce/label/c.WebshopLast365Days';
import lastAll from '@salesforce/label/c.WebshopLastAll';
import cancelled from '@salesforce/label/c.GeneralCancelled';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopMyInvoices extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track invoiceHistory = [];
    @track invoicesDisplayed = [];
    @track daysVal = 7;
    @track searchTerm = '';
    @track isLoading = false;
    @track showPrices = true;
    @track cartId = null;

    label = {
        backToShop,
        myInvoices,
        myInvoicesSubtitle,
        invoiceNumber,
        invoiceDate,
        totalAmount,
        viewDetails,
        last7Days,
        last30Days,
        last365Days,
        lastAll,
        searchByInvoiceNumber,
        generalError,
        generalErrorMsg,
        cancelled
    }

    daysOptions = [
        {value: 7, label: this.label.last7Days},
        {value: 30, label: this.label.last30Days},
        {value: 365, label: this.label.last365Days},
        {value: 0, label: this.label.lastAll},
    ];

    changeDaysFilter(event){
        this.isLoading = true;
        this.daysVal = event.target.value;
        let allInvoices = JSON.parse(JSON.stringify(this.invoiceHistory));
        if(this.daysVal  != 0){
            let today = new Date();
            allInvoices = allInvoices.filter((invoice) =>  (today - new Date(invoice.CreatedDate.substring(0, 10)))/(1000*60*60*24) <= this.daysVal );
            if(stringIsNotBlank(this.searchTerm)){
                allInvoices = allInvoices.filter((invoice) => invoice.ERPInvoiceNumber__c.includes(this.searchTerm) );
            }
        }
        this.invoicesDisplayed = JSON.parse(JSON.stringify(allInvoices));
        this.isLoading = false;
    }

    changeSearchTerm(event){
        this.isLoading = true;
        this.searchTerm = event.target.value;
        let allInvoices = JSON.parse(JSON.stringify(this.invoiceHistory));
        if(stringIsNotBlank(this.searchTerm)){
            allInvoices = allInvoices.filter((invoice) => invoice.ERPInvoiceNumber__c.includes(this.searchTerm) );
            if(this.daysVal  != 0){
                let today = new Date();
                allInvoices = allInvoices.filter((invoice) =>  (today - new Date(invoice.CreatedDate.substring(0, 10)))/(1000*60*60*24) <= this.daysVal );
            }
        }
        this.invoicesDisplayed = JSON.parse(JSON.stringify(allInvoices));
        this.isLoading = false;
    }

    connectedCallback() {
        this.isLoading = true;
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext?.effectiveAccountId;
                let cartId = sessionStorage.getItem('darboven_cartId');
                if(!stringIsNotBlank(cartId) || cartId == 'null'){
                    getCartSummaryOrCreateCart({accountId: this.accountId})
                    .then(result => {
                        sessionStorage.setItem('darboven_cartId', result);
                        fireEvent(this.pageRef, 'setCartIdEvent', {  });
                        window.location.reload();
                    });
                } else {
                    this.cartId = cartId;
                    this.processData();
                }
            } else {
                this.isLoading = false;
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            }
        })
        .catch(error => {
            this.isLoading = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        });
    }

    processData(){
        let showPriceInfo = sessionStorage.getItem('darboven_showPriceInfo');
        if(!stringIsNotBlank(showPriceInfo)){
            getShowPriceInfo({accountId: this.accountId})
            .then(outerResult => {
                if(outerResult != null){
                    this.showPrices = outerResult;
                    sessionStorage.setItem('darboven_showPriceInfo', this.showPrices);
                    this.initData();
                } else {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;});
                }
            })
            .catch(error => {
                this.isLoading = false;
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + error,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            });
        } else {
            this.showPrices = showPriceInfo === true || showPriceInfo == 'true' ? true : false;
            this.initData();
        }
    }

    initData(){
        getAllInvoices({accountId: this.accountId, lmt: null})
        .then(result => {
            if(result != null){
                this.invoiceHistory = JSON.parse(JSON.stringify(result));
                this.invoiceHistory.forEach(item => {
                    item.isCancelled = item.Status == 'Cancelled';
                    item.TotalAmount = item.TotalAmount?.toFixed(2);
                    item.CurrencyIsoCode = item.CurrencyIsoCode == 'EUR' ? '€' : item.CurrencyIsoCode;
                    item.InvoiceDate = item.CreatedDate != null ? new Date(item.CreatedDate.substring(0, 10)).toLocaleDateString() : '';
                })
                let allInvoices = JSON.parse(JSON.stringify(this.invoiceHistory));
                let today = new Date();
                allInvoices = allInvoices.filter((invoice) => (today - new Date(invoice.CreatedDate.substring(0, 10)))/(1000*60*60*24) <= this.daysVal );
                this.invoicesDisplayed = JSON.parse(JSON.stringify(allInvoices));
                this.isLoading = false;
            } else {
                this.isLoading = false;
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            }
        })
        .catch(error => {
            this.isLoading = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;}); 
        });
    }

    handleClickBackToShop(){
        window.location.assign('/');
    }

    handleClickInvoice(event){
        let invoiceId = event.currentTarget.dataset.invoiceid;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Invoice__c',
            },
            state: {
                c__invoiceNumber: invoiceId
            }
        });
    }

}