import { LightningElement, track, wire } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub'

// Apex
import getActiveAccountInfo from '@salesforce/apex/WebshopDataController.getActiveAccountInfo';
import getUserImage from '@salesforce/apex/WebshopDataController.getUserImage';
import retrieveNewsletterOptIn from '@salesforce/apex/WebshopDataController.retrieveNewsletterOptIn';
import createOrder from '@salesforce/apex/WebshopDataController.createOrder';
import countItemsInCart from '@salesforce/apex/WebshopDataController.countItemsInCart';
import getExternalAddresses from '@salesforce/apex/WebshopDataController.getExternalAddresses';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';
import sendWebCartToERP from '@salesforce/apex/WebshopDataController.sendWebCartToERP';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';
 
// Bootstrap 
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// LABELS
import activeAccount from '@salesforce/label/c.WebshopCheckoutActiveAccount';
import newsletter from '@salesforce/label/c.WebshopCheckoutNewsletter';
import TC from '@salesforce/label/c.WebshopCheckoutTC';
import orderNumber from '@salesforce/label/c.WebshopCheckoutOrderNumber';
import wishes from '@salesforce/label/c.WebshopCheckoutWishes';
import checkout from '@salesforce/label/c.WebshopCheckout';
import accountBilling from '@salesforce/label/c.WebshopAccountBillingInfo';
import shippingAddress from '@salesforce/label/c.WebshopOrderConfirmationShippingAddress';
import shippingInformation from '@salesforce/label/c.WebshopOrderConfirmationShippingInformation';
import orderSummary from '@salesforce/label/c.WebshopOrderConfirmationOrderSummary';
import placeOrder from '@salesforce/label/c.WebshopPlaceOrder';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import paymentConditionsBody from '@salesforce/label/c.WebshopPaymentConditionsBody';
import paymentConditionsHeader from '@salesforce/label/c.WebshopPaymentConditionsHeader';


export default class WebshopCheckout extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track cartId = null;
    // Account Info
    @track account;
    @track smallPhotoUrl = '';
    @track showAccountInfo = false;
    @track showTCSection = false;
    @track showCommentsMask = false;
    @track notOptedIn = false;
    @track placeOrderDisabled = true;

    @track orderNumber = '';
    @track comment = '';
    @track setNewsletter = false;
    @track cartCount = 0;
    @track isLoading = false;
    @track externalAddressId = '';
    @track allAddresses = [];
    @track showAddresses = false;
    @track checkboxStyle = '';
    @track erpDataLoaded = false;

    label = {
        activeAccount,
        newsletter,
        TC,
        orderNumber,
        wishes,
        checkout,
        shippingAddress,
        shippingInformation,
        orderSummary,
        placeOrder,
        generalError,
        generalErrorMsg,
        paymentConditionsBody,
        paymentConditionsHeader,
        accountBilling
    }

    connectedCallback() {
        this.isLoading = true;
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
        getSessionContext()
        .then(sessionContext => {
            this.accountId = sessionContext?.effectiveAccountId;
            if(stringIsNotBlank(this.accountId)){
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
                    sendWebCartToERP({cartId: this.cartId, accountId: this.accountId})
                    .then(erpResult => {
                        console.log(JSON.stringify(erpResult));
                        this.erpResult = JSON.parse(JSON.stringify(erpResult));
                        this.processPrices();
                    });
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

    processPrices(){        
        let showPriceInfo = sessionStorage.getItem('darboven_showPriceInfo');
        if(!stringIsNotBlank(showPriceInfo)){
            getShowPriceInfo({accountId: this.accountId})
            .then(outerResult => {
                if(outerResult != null){
                    this.showPrices = outerResult;
                    sessionStorage.setItem('darboven_showPriceInfo', this.showPrices);
                    this.processData();
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
            this.processData();
        }
    }

    processData(){
        this.showCommentsMask = true;
        this.erpDataLoaded = true;
        retrieveNewsletterOptIn({})
        .then(result => {
            if(result != null){
                this.notOptedIn = result;
                this.showTCSection = true;
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
        getUserImage({})
        .then(outerResult => {
            if(outerResult != 'error'){
                this.smallPhotoUrl= outerResult;
                getActiveAccountInfo({accountId : this.accountId})
                .then(result => {
                    if(result != null){
                        this.account = JSON.parse(JSON.stringify(result));
                        if(stringIsNotBlank(this.account.ShippingStreet) && stringIsNotBlank(this.account.ShippingCity) && stringIsNotBlank(this.account.ShippingPostalCode)){
                            this.account.Street = this.account.ShippingStreet;
                            this.account.City = this.account.ShippingCity;
                            this.account.Country = this.account.ShippingCountry;
                            this.account.PostalCode = this.account.ShippingPostalCode;
                        } else {
                            this.account.Street = this.account.BillingStreet;
                            this.account.City = this.account.BillingCity;
                            this.account.Country = this.account.BillingCountry;
                            this.account.PostalCode = this.account.BillingPostalCode;
                        }
                        if(stringIsNotBlank(this.account.BillingStreet) && stringIsNotBlank(this.account.BillingCity) && stringIsNotBlank(this.account.BillingPostalCode)){
                            this.account.StreetBilling = this.account.BillingStreet;
                            this.account.CityBilling = this.account.BillingCity;
                            this.account.CountryBilling = this.account.BillingCountry;
                            this.account.PostalCodeBilling = this.account.BillingPostalCode;
                        } else {
                            this.account.StreetBilling = this.account.ShippingStreet;
                            this.account.CityBilling = this.account.ShippingCity;
                            this.account.CountryBilling = this.account.ShippingCountry;
                            this.account.PostalCodeBilling = this.account.ShippingPostalCode;
                        }
                        this.showAccountInfo = true;
                        countItemsInCart({accountId: this.accountId, cartId: this.cartId})
                        .then(innerResult => {
                            if(innerResult != null){
                                this.cartCount = innerResult;
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

                getExternalAddresses({accountId: this.accountId})
                .then(result => {
                    if(result != null){
                        this.allAddresses = JSON.parse(JSON.stringify(result));
                        this.showAddresses = true;
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

    handleSetNewsletter(event){
        this.setNewsletter = event.target.checked;
    }

    handleSetTC(event){
        let checked = event.target.checked;
        this.placeOrderDisabled = !checked;
        if(checked){
            this.checkboxStyle = '';
        }
    }

    handleSetOrderNumber(event){
        this.orderNumber = event.target.value;
    }

    handleSetComment(event){
        this.comment = event.target.value;
    }

    handleChangeExternalAddressId(event){
        this.externalAddressId = event.detail.value;
    }

    createOrder(){
        if(!this.placeOrderDisabled){
            this.isLoading = true;
            createOrder({
                accountId: this.accountId, 
                orderNumber: this.orderNumber, 
                comment: this.comment, 
                setNewsletter: this.setNewsletter, 
                externalAddressId: this.externalAddressId, 
                cartId: this.cartId,
                erpResponse: JSON.stringify(this.erpResult)
            })
            .then(result => {
                if(result == null || (result != null && Object.keys(result).includes('error'))) {
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: result == null ? this.label.generalErrorMsg : result.error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                } else if(result != null && Object.keys(result).includes('cartId') && Object.keys(result).includes('orderId')){
                    sessionStorage.setItem('darboven_cartId', result.cartId);
                    fireEvent(this.pageRef, 'setCartIdEvent', {  });
                    this[NavigationMixin.Navigate]({
                        type: 'comm__namedPage',
                        attributes: {
                            name: 'Order',
                        },
                        state: {
                            c__orderNumber: result.orderId
                        }
                    });
                }
            });
        } else {
            this.checkboxStyle = 'red-border';
            let self = this;
            setTimeout(function (){
                self.checkboxStyle = '';
            }, 3000);
        }
    }

    handleOpenModal() {
        this.template.querySelector('.order-modal').classList.remove('d-none');
        this.template.querySelector('.order-modal').classList.add('d-block');
    }
    
    handleCloseModal() {
        this.template.querySelector('.order-modal').classList.remove('d-block');
        this.template.querySelector('.order-modal').classList.add('d-none');
    }
}