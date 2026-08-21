import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';
import { fireEvent } from 'c/pubsub'

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';
import { effectiveAccount } from 'commerce/effectiveAccountApi';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getSelfServiceStats from '@salesforce/apex/WebshopDataController.getSelfServiceStats';
import getAllOrders from '@salesforce/apex/WebshopDataController.getAllOrders';
import getAllOutlets from '@salesforce/apex/WebshopDataController.getAllOutlets';
import reorder from '@salesforce/apex/WebshopDataController.reorder';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Labels
import goodMorning from '@salesforce/label/c.WebshopFrontpageGoodMorning';
import goodAfternoon from '@salesforce/label/c.WebshopFrontpageGoodAfternoon';
import goodEvening from '@salesforce/label/c.WebshopFrontpageGoodEvening';
import orders from '@salesforce/label/c.GeneralOrders';
import totalItemsOrdered from '@salesforce/label/c.WebshopTotalItemsOrdered';
import ordersInProgress from '@salesforce/label/c.WebshopOrdersInProgress';
import myOutlets from '@salesforce/label/c.WebshopMenuOutlets';
import myOrders from '@salesforce/label/c.WebshopMenuOutlets';
import recentOrders from '@salesforce/label/c.WebshopRecentOrders';
import noOrders from '@salesforce/label/c.WebshopMyAccNoOrders';
import noOrderSubTitle from '@salesforce/label/c.WebshopMyAccNoOrderSubtitle';
import shopNow from '@salesforce/label/c.WebshopShopNow';
import orderNumber from '@salesforce/label/c.WebshopOrderNumber';
import orderDate from '@salesforce/label/c.WebshopOrderDate';
import active from '@salesforce/label/c.GeneralActive';
import switchAccount from '@salesforce/label/c.GeneralSwitchAccount';
import outlet from '@salesforce/label/c.WebshopOutlet';
import totalAmount from '@salesforce/label/c.WebshopTotalAmount';
import viewDetails from '@salesforce/label/c.WebshopViewDetails';
import orderAgain from '@salesforce/label/c.WebshopOrderAgain';
import viewAllOrders from '@salesforce/label/c.WebshopViewAllOrders';
import cancelled from '@salesforce/label/c.GeneralCancelled';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopMyAccount extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track isLoading = false;
    @track showStats = false;
    @track hasOrders = false;
    @track showOrders = false;
    @track showOutlets = false;
    @track showBadge = false;
    @track errorRecords = [];                 
    @track showErrorBadge = false;
    @track firstName;
    @track stats;
    @track orders = [];
    @track outlets = [];
    @track isLoading = false;
    @track showPrices = true;
    @track cartId = null;

    label = {
        goodMorning,
        goodAfternoon,
        goodEvening,
        orders,
        totalItemsOrdered,
        ordersInProgress,
        myOutlets,
        recentOrders,
        noOrderSubTitle,
        shopNow,
        noOrders,
        myOrders,
        orderNumber,
        orderDate,
        outlet,
        totalAmount,
        viewDetails,
        orderAgain,
        viewAllOrders,
        generalError,
        generalErrorMsg,
        active,
        switchAccount,
        cancelled
    };

    get greeting(){
        let d = new Date();
        let hour = d.getHours();
        if(hour >= 0 && hour < 12){
            return this.label.goodMorning;
        } else if(hour < 18){
            return this.label.goodAfternoon;
        } else {
            return this.label.goodEvening;
        }
    }

    handleSwitchAccount(event){
        let accountId = event.target.dataset.recordid;
        let accountName = event.target.dataset.recordname;
        sessionStorage.clear();
        getCartSummaryOrCreateCart({accountId: accountId})
        .then(result => {
            sessionStorage.setItem('darboven_cartId', result);
            fireEvent(this.pageRef, 'setCartIdEvent', {  });
            this.cartId = result;
            effectiveAccount.update(accountId, accountName);
            // Handle retrieve cart
            window.location.assign('/');
        });
    }

    handleClickOutlet(event){
        let outletId = event.currentTarget.dataset.outlet;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Outlet__c',
            },
            state: {
                c__recordId: outletId
            }
        });
    }

    handleClickOrder(event){
        let orderId = event.currentTarget.dataset.orderid;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Order__c',
            },
            state: {
                c__recordId: orderId
            }
        });
    }

    handleViewAllOrders(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Orders__c',
            }
        });
    }

    handleReorder(event){
        let orderId = event.currentTarget.dataset.orderid;
        reorder({orderId: orderId, accountId: this.accountId, cartId: this.cartId})
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

    handleClickHome(){
        window.location.assign('/');
    }

    connectedCallback() {
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.firstName = sessionContext.profile?.firstName;
                this.accountId = sessionContext.effectiveAccountId;
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
        getSelfServiceStats({accountId: this.accountId})
        .then(result => {
            if(result != null){
                this.stats = JSON.parse(JSON.stringify(result));
                this.showStats = true;
                this.hasOrders = this.stats.orderCount > 0 || this.stats.ordersInProgressCount > 0;
                this.isLoading = !this.showOrders || !this.showOutlets || !this.showStats;
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
        getAllOrders({accountId: this.accountId, lmt: 5})
        .then(result => {
            if(result != null){
                this.orders = JSON.parse(JSON.stringify(result));                    
                this.orders.forEach(item => {
                    item.isCancelled = item.Status == 'Cancelled';
                    item.TotalAmount = item.TotalAmount?.toFixed(2);
                    item.CurrencyIsoCode = item.CurrencyIsoCode == 'EUR' ? '€' : item.CurrencyIsoCode;
                    item.OrderDate = item.CreatedDate != null ? new Date(item.CreatedDate.substring(0, 10)).toLocaleDateString() : '';
                })
                this.showOrders = true;
                this.isLoading = !this.showOrders || !this.showOutlets || !this.showStats;
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
        getAllOutlets({accountId: this.accountId, lmt: null})
        .then(result => {
            if(result != null){
                this.outlets = JSON.parse(JSON.stringify(result));
                this.outlets.forEach(outlet => {
                    outlet.isActive = outlet.Id.includes(this.accountId);
                    if(stringIsNotBlank(outlet.ShippingStreet) && stringIsNotBlank(outlet.ShippingCity) && stringIsNotBlank(outlet.ShippingPostalCode)){
                        outlet.Street = outlet.ShippingStreet;
                        outlet.City = outlet.ShippingCity;
                        outlet.Country = outlet.ShippingCountry;
                        outlet.PostalCode = outlet.ShippingPostalCode;
                    } else {
                        outlet.Street = outlet.BillingStreet;
                        outlet.City = outlet.BillingCity;
                        outlet.Country = outlet.BillingCountry;
                        outlet.PostalCode = outlet.BillingPostalCode;
                    }
                })
                this.showOutlets = true;
                this.isLoading = !this.showOrders || !this.showOutlets || !this.showStats;
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
}