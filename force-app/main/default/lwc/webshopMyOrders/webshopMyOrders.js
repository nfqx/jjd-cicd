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
import getAllOrders from '@salesforce/apex/WebshopDataController.getAllOrders';
import reorder from '@salesforce/apex/WebshopDataController.reorder';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Labels
import backToShop from '@salesforce/label/c.WebshopBackToShop';
import myOrders from '@salesforce/label/c.WebshopMyOrders';
import myOrdersSubtitle from '@salesforce/label/c.WebshopMyOrdersSubtitle';
import orderNumber from '@salesforce/label/c.WebshopOrderNumber';
import orderDate from '@salesforce/label/c.WebshopOrderDate';
import totalAmount from '@salesforce/label/c.WebshopTotalAmount';
import viewDetails from '@salesforce/label/c.WebshopViewDetails';
import orderAgain from '@salesforce/label/c.WebshopOrderAgain';
import searchByOrderNumber from '@salesforce/label/c.WebshopSearchByOrderNumber';
import last7Days from '@salesforce/label/c.WebshopLast7Days';
import last30Days from '@salesforce/label/c.WebshopLast30Days';
import last365Days from '@salesforce/label/c.WebshopLast365Days';
import lastAll from '@salesforce/label/c.WebshopLastAll';
import cancelled from '@salesforce/label/c.GeneralCancelled';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopMyOrders extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track orderHistory = [];
    @track ordersDisplayed = [];
    @track showBadge = false;
    @track errorRecords = [];                 
    @track showErrorBadge = false;
    @track daysVal = 7;
    @track searchTerm = '';
    @track isLoading = false;
    @track showPrices = true;
    @track cartId = null;

    label = {
        backToShop,
        myOrders,
        myOrdersSubtitle,
        orderNumber,
        orderDate,
        totalAmount,
        viewDetails,
        orderAgain,
        last7Days,
        last30Days,
        last365Days,
        lastAll,
        searchByOrderNumber,
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
        let allOrders = JSON.parse(JSON.stringify(this.orderHistory));
        if(this.daysVal  != 0){
            let today = new Date();
            allOrders = allOrders.filter((order) =>  (today - new Date(order.CreatedDate.substring(0, 10)))/(1000*60*60*24) <= this.daysVal );
            if(stringIsNotBlank(this.searchTerm)){
                allOrders = allOrders.filter((order) => order.OrderNumber.includes(this.searchTerm) );
            }
        }
        this.ordersDisplayed = JSON.parse(JSON.stringify(allOrders));
        this.isLoading = false;
    }

    changeSearchTerm(event){
        this.isLoading = true;
        this.searchTerm = event.target.value;
        let allOrders = JSON.parse(JSON.stringify(this.orderHistory));
        if(stringIsNotBlank(this.searchTerm)){
            allOrders = allOrders.filter((order) => order.OrderNumber.includes(this.searchTerm) );
            if(this.daysVal  != 0){
                let today = new Date();
                allOrders = allOrders.filter((order) =>  (today - new Date(order.CreatedDate.substring(0, 10)))/(1000*60*60*24) <= this.daysVal );
            }
        }
        this.ordersDisplayed = JSON.parse(JSON.stringify(allOrders));
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
        getAllOrders({accountId: this.accountId, lmt: null})
        .then(result => {
            if(result != null){
                this.orderHistory = JSON.parse(JSON.stringify(result));
                this.orderHistory.forEach(item => {
                    item.isCancelled = item.Status == 'Cancelled';
                    item.TotalAmount = item.TotalAmount?.toFixed(2);
                    item.CurrencyIsoCode = item.CurrencyIsoCode == 'EUR' ? '€' : item.CurrencyIsoCode;
                    item.OrderDate = item.CreatedDate != null ? new Date(item.CreatedDate.substring(0, 10)).toLocaleDateString() : '';
                })
                let allOrders = JSON.parse(JSON.stringify(this.orderHistory));
                let today = new Date();
                allOrders = allOrders.filter((order) => (today - new Date(order.CreatedDate.substring(0, 10)))/(1000*60*60*24) <= this.daysVal );
                this.ordersDisplayed = JSON.parse(JSON.stringify(allOrders));
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

    handleClickOrder(event){
        let templateOrder = event.currentTarget.dataset.orderid;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Order__c',
            },
            state: {
                c__orderNumber: templateOrder
            }
        });
    }

    handleClickBackToShop(){
        window.location.assign('/');
    }

    handleReorder(event){
        let templateOrder = event.currentTarget.dataset.orderid;
        reorder({orderId: templateOrder, accountId: this.accountId, cartId: this.cartId})
        .then(result => {
            if(result != null){
                let self = this;
                setTimeout(function (){
                    this.showBadge = true;
                    fireEvent(self.pageRef, 'refreshCartDataEvent', {  });
                }, 1500);
                setTimeout(function (){
                    self.showBadge = false;
                }, 10000);
                if(result.length > 0){   
                    this.errorRecords = result;                 
                    this.showErrorBadge = true;
                    setTimeout(function (){
                        self.showErrorBadge = false;
                    }, 10000);
                }
            } else {
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            }
        })
        .catch(error => {
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        });
    }

}