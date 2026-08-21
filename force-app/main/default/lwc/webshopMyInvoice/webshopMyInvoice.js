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
import getInvoiceInfoByInvoiceId from '@salesforce/apex/WebshopDataController.getInvoiceInfoByInvoiceId';
import addProductToWishlist from '@salesforce/apex/WebshopDataController.addProductToWishlist';
import removeFromWishlist from '@salesforce/apex/WebshopDataController.removeFromWishlist';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Labels
import needHelp from '@salesforce/label/c.WebshopOrderConfirmationNeedHelp';
import invoiceDate from '@salesforce/label/c.WebshopInvoiceDate';
import shipping from '@salesforce/label/c.WebshopOrderConfirmationShipping';
import shippingAddress from '@salesforce/label/c.WebshopOrderConfirmationShippingAddress';
import subtotal from '@salesforce/label/c.WebshopOrderConfirmationSubtotal';
import total from '@salesforce/label/c.WebshopOrderConfirmationTotal';
import summary from '@salesforce/label/c.WebshopInvoiceSummary';
import invoiceNo from '@salesforce/label/c.WebshopInvoiceNumber';
import contactUs from '@salesforce/label/c.WebshopContactModalTitle';
import totalItems from '@salesforce/label/c.WebshopTotalItems';
import backToList from '@salesforce/label/c.WebshopBackToList';
import outlet from '@salesforce/label/c.WebshopOutlet';
import purchaser from '@salesforce/label/c.WebshopPurchaser';
import noProducts from '@salesforce/label/c.WebshopNoProducts';
import cancelled from '@salesforce/label/c.GeneralCancelled';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopMyInvoice extends  NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track recordId;
    @track invoiceInfo;
    @track invoiceProducts;
    @track hasProducts = false;
    @track showInvoiceInfo = false;
    @track showBadge = false;
    @track showPrices = true;
    @track invoiceProductsCount = 0;
    @track isLoading = false;
    @track cartId = null;

    handleContactUs(){
        this.template.querySelectorAll('c-webshop-contact-modal').forEach(element => {
            element.show = true;
        });
    }

    handleBackToList(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Invoices__c',
            }
        });
    }

    label = {
        backToList,
        invoiceNo,
        totalItems,
        invoiceDate,
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
        getInvoiceInfoByInvoiceId({invoiceId: this.recordId, accountId: this.accountId})
        .then(result => {
            if(result != null){
                this.itemCount = 0;
                this.invoiceInfo = result.invoice ? JSON.parse(JSON.stringify(result.invoice)) : {};
                this.invoiceInfo.isCancelled = this.invoiceInfo.Status == 'Cancelled';
                this.invoiceInfo.TotalAmount = this.invoiceInfo.TotalAmount?.toFixed(2);
                this.invoiceInfo.CurrencyIsoCode = this.invoiceInfo.CurrencyIsoCode == 'EUR' ? '€' : this.invoiceInfo.CurrencyIsoCode;
                this.invoiceInfo.InvoiceDate = new Date(this.invoiceInfo.CreatedDate.substring(0, 10)).toLocaleDateString();
                if(stringIsNotBlank(this.invoiceInfo.BillingAccount.BillingStreet) && stringIsNotBlank(this.invoiceInfo.BillingAccount.BillingCity) && stringIsNotBlank(this.invoiceInfo.BillingAccount.BillingCountry) && stringIsNotBlank(this.invoiceInfo.BillingAccount.BillingPostalCode)){
                    this.invoiceInfo.Street = this.invoiceInfo.BillingAccount.BillingStreet;
                    this.invoiceInfo.City = this.invoiceInfo.BillingAccount.BillingCity;
                    this.invoiceInfo.Country = this.invoiceInfo.BillingAccount.BillingCountry;
                    this.invoiceInfo.PostalCode = this.invoiceInfo.BillingAccount.BillingPostalCode;
                } else {
                    this.invoiceInfo.Street = this.invoiceInfo.BillingAccount.ShippingStreet;
                    this.invoiceInfo.City = this.invoiceInfo.BillingAccount.ShippingCity;
                    this.invoiceInfo.Country = this.invoiceInfo.BillingAccount.ShippingCountry;
                    this.invoiceInfo.PostalCode = this.invoiceInfo.BillingAccount.ShippingPostalCode;
                }
                this.invoiceProducts = result.products ? JSON.parse(JSON.stringify(result.products)) : [];
                this.invoiceProductsCount = this.invoiceProducts.length;
                if(this.invoiceProducts.length > 0){
                    this.invoiceProducts.forEach(invoiceProduct => {
                        if(invoiceProduct.invoiceProduct && invoiceProduct.invoiceProduct.Product2){
                            if(stringIsNotBlank(invoiceProduct.invoiceProduct.Product2.WebshopImageURL__c)){
                                invoiceProduct.imageUrl = '/sfsites/c' + invoiceProduct.invoiceProduct.Product2.WebshopImageURL__c;
                                invoiceProduct.hasImage = true;
                            }
                            invoiceProduct.price = invoiceProduct.invoiceProduct.LineAmount ? invoiceProduct.invoiceProduct.LineAmount?.toFixed(2) : '0.00';
                        }
                    });
                    this.hasProducts = true;
                }
                this.showInvoiceInfo = this.invoiceInfo != null;
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
        this.invoiceProducts.forEach(item => {
            if(item.invoiceProduct.Product2Id == productId){
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
        this.invoiceProducts.forEach(item => {
            if(item.invoiceProduct.Product2Id == productId){
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