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
import getOrderInfoByOrderId from '@salesforce/apex/WebshopDataController.getOrderInfoByOrderId';
import reorder from '@salesforce/apex/WebshopDataController.reorder';
import addProductToWishlist from '@salesforce/apex/WebshopDataController.addProductToWishlist';
import removeFromWishlist from '@salesforce/apex/WebshopDataController.removeFromWishlist';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Labels
import orderReference from '@salesforce/label/c.WebshopOrderReferenceNo';
import needHelp from '@salesforce/label/c.WebshopOrderConfirmationNeedHelp';
import orderDate from '@salesforce/label/c.WebshopOrderConfirmationOrderDate';
import shipping from '@salesforce/label/c.WebshopOrderConfirmationShipping';
import shippingAddress from '@salesforce/label/c.WebshopOrderConfirmationShippingAddress';
import subtotal from '@salesforce/label/c.WebshopOrderConfirmationSubtotal';
import total from '@salesforce/label/c.WebshopOrderConfirmationTotal';
import contactUs from '@salesforce/label/c.WebshopContactModalTitle';
import totalItems from '@salesforce/label/c.WebshopTotalItems';
import orderAgain from '@salesforce/label/c.WebshopOrderAgain';
import orderNo from '@salesforce/label/c.WebshopOrderNo';
import backToList from '@salesforce/label/c.WebshopBackToList';
import outlet from '@salesforce/label/c.WebshopOutlet';
import summary from '@salesforce/label/c.WebshopOrderConfirmationOrderSummary';
import purchaser from '@salesforce/label/c.WebshopPurchaser';
import noProducts from '@salesforce/label/c.WebshopNoProducts';
import cancelled from '@salesforce/label/c.GeneralCancelled';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopMyOrder extends  NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track recordId;
    @track orderInfo;
    @track orderProducts;
    @track hasProducts = false;
    @track showOrderInfo = false;
    @track showBadge = false;
    @track errorRecords = [];                 
    @track showErrorBadge = false;
    @track showPrices = true;
    @track orderProductsCount = 0;
    @track isLoading = false;
    @track cartId = null;

    handleContactUs(){
        this.template.querySelectorAll('c-webshop-contact-modal').forEach(element => {
            element.show = true;
        });
    }

    handleReorder(){
        reorder({orderId: this.recordId, accountId: this.accountId, cartId: this.cartId})
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

    handleBackToList(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Orders__c',
            }
        });
    }

    get _shipping(){
        return stringIsNotBlank(this.orderInfo.ShippingCosts__c) ? (this.orderInfo.ShippingCosts__c + ' ' + this.orderInfo.CurrencyIsoCode) : this.label.free;
    }

    label = {
        orderReference,
        backToList,
        orderNo,
        orderAgain,
        totalItems,
        orderDate,
        outlet,
        shippingAddress,
        purchaser,
        summary,
        subtotal,
        shipping,
        total,
        needHelp,
        contactUs,
        noProducts,
        generalError,
        generalErrorMsg,
        cancelled
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
        this.recordId = window.location.href.split("=").pop();
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
        getOrderInfoByOrderId({orderId: this.recordId, accountId: this.accountId})
        .then(result => {
            if(result != null){
                this.itemCount = 0;
                this.orderInfo = result.order ? JSON.parse(JSON.stringify(result.order)) : {};
                this.orderInfo.isCancelled = this.orderInfo.Status == 'Cancelled';
                this.orderInfo.HasReference = stringIsNotBlank(this.orderInfo.CustomerReference__c);
                this.orderInfo.ProductCosts__c = this.orderInfo.ProductCosts__c?.toFixed(2);
                this.orderInfo.ShippingCosts__c = this.orderInfo.ShippingCosts__c?.toFixed(2);
                this.orderInfo.TotalAmount = this.orderInfo.TotalAmount?.toFixed(2);
                this.orderInfo.CurrencyIsoCode = this.orderInfo.CurrencyIsoCode == 'EUR' ? '€' : this.orderInfo.CurrencyIsoCode;
                this.orderInfo.OrderDate = new Date(this.orderInfo.CreatedDate.substring(0, 10)).toLocaleDateString();
                if(stringIsNotBlank(this.orderInfo.ShippingStreet) && stringIsNotBlank(this.orderInfo.ShippingCity) && stringIsNotBlank(this.orderInfo.ShippingCountry) && stringIsNotBlank(this.orderInfo.ShippingPostalCode)){
                    this.orderInfo.Street = this.orderInfo.ShippingStreet;
                    this.orderInfo.City = this.orderInfo.ShippingCity;
                    this.orderInfo.Country = this.orderInfo.ShippingCountry;
                    this.orderInfo.PostalCode = this.orderInfo.ShippingPostalCode;
                } else {
                    this.orderInfo.Street = this.orderInfo.BillingStreet;
                    this.orderInfo.City = this.orderInfo.BillingCity;
                    this.orderInfo.Country = this.orderInfo.BillingCountry;
                    this.orderInfo.PostalCode = this.orderInfo.BillingPostalCode;
                }
                this.orderProducts = result.products ? JSON.parse(JSON.stringify(result.products)) : [];
                this.orderProductsCount = this.orderProducts.length;
                if(this.orderProducts.length > 0){
                    this.orderProducts.forEach(orderProduct => {
                        if(orderProduct.orderProduct && stringIsNotBlank(orderProduct.orderProduct.Product2.WebshopImageURL__c)){
                            orderProduct.imageUrl = '/sfsites/c' + orderProduct.orderProduct.Product2.WebshopImageURL__c;
                            orderProduct.hasImage = true;
                            orderProduct.price = orderProduct.orderProduct.TotalPrice ? orderProduct.orderProduct.TotalPrice?.toFixed(2) : '0.00';
                        }
                    });
                    this.hasProducts = true;
                }
                this.showOrderInfo = this.orderInfo != null;
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

    handleNavigateToProduct(event){
        let recordId = event.currentTarget.dataset.productid;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Product2',
                recordId: recordId,
                actionName: 'view',
            },
        });
    }

    addProductToWishlist(event){
        let productId = event.currentTarget.dataset.productid;
        this.orderProducts.forEach(item => {
            if(item.orderProduct.Product2Id == productId){
                item.inWishlist = true;
            }
        });
        fireEvent(this.pageRef, 'addToWishlistEvent', {  });
        addProductToWishlist({accountId: this.accountId, productId: productId})
        .then(result => {
            if(result == false){
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

    removeFromWishlist(event){
        let productId = event.currentTarget.dataset.productid;
        fireEvent(this.pageRef, 'removeFromWishlistEvent', {  });
        this.orderProducts.forEach(item => {
            if(item.orderProduct.Product2Id == productId){
                item.inWishlist = false;
            }
        })
        removeFromWishlist({accountId: this.accountId, productId: productId})
        .then(result => {
            if(result == false){
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