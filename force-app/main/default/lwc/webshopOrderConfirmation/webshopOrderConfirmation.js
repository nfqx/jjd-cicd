import { LightningElement, api, track } from 'lwc';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import { NavigationMixin } from 'lightning/navigation';

// SYSTEM
import { loadStyle } from 'lightning/platformResourceLoader';
import { getSessionContext } from 'commerce/contextApi';
import { stringIsNotBlank } from 'c/stringHelper';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getOrderInfoByOrderId from '@salesforce/apex/WebshopDataController.getOrderInfoByOrderId';
import getShowPriceInfo from '@salesforce/apex/WebshopDataController.getShowPriceInfo';

// LABELS 
import contact from '@salesforce/label/c.GeneralContact';
import print from '@salesforce/label/c.WebshopGeneralPrint';
import contactInformation from '@salesforce/label/c.WebshopOrderConfirmationContactInformation';
import continueShopping from '@salesforce/label/c.WebshopOrderConfirmationContinueShopping';
import needHelp from '@salesforce/label/c.WebshopOrderConfirmationNeedHelp';
import orderCompleted from '@salesforce/label/c.WebshopOrderConfirmationOrderCompleted';
import orderDate from '@salesforce/label/c.WebshopOrderConfirmationOrderDate';
import orderDetails from '@salesforce/label/c.WebshopOrderConfirmationOrderDetails';
import orderInformation from '@salesforce/label/c.WebshopOrderConfirmationOrderInformation';
import orderNumber from '@salesforce/label/c.WebshopOrderConfirmationOrderNumber';
import shipping from '@salesforce/label/c.WebshopOrderConfirmationShipping';
import shippingAddress from '@salesforce/label/c.WebshopOrderConfirmationShippingAddress';
import subtotal from '@salesforce/label/c.WebshopOrderConfirmationSubtotal';
import total from '@salesforce/label/c.WebshopOrderConfirmationTotal';
import thankYou from '@salesforce/label/c.WebshopOrderConfirmationThankYou';
import thankYouSubheader from '@salesforce/label/c.WebshopOrderConfirmationThankYouSubheader';
import yourOrder from '@salesforce/label/c.WebshopOrderConfirmationYourOrder';
import free from '@salesforce/label/c.GeneralFree';
import invalidOrder from '@salesforce/label/c.WebshopInvalidOrder';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopOrderConfirmation extends NavigationMixin(LightningElement) {
    @track hasData = false;
    @track hasProducts = false;
    @track orderInfo = null;
    @track orderProducts = [];
    @track orderProductsCount = 0;
    @track accountId;
    @track showPrices = true;
    @track isLoading = false;

    label = {
        contact,
        print,
        contactInformation,
        continueShopping,
        needHelp,
        orderCompleted,
        orderDetails,
        orderInformation,
        orderNumber,
        shipping,
        shippingAddress,
        subtotal,
        total,
        thankYou,
        thankYouSubheader,
        yourOrder,
        orderDate,
        free,
        invalidOrder,
        generalError,
        generalErrorMsg
    }

    get _shipping(){
        return stringIsNotBlank(this.orderInfo.ShippingCosts__c) ? (this.orderInfo.ShippingCosts__c + ' ' + this.orderInfo.CurrencyIsoCode) : this.label.free;
    }

    connectedCallback(){
        this.isLoading = true;
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        let confirmString = window.location.href.split("/").pop();
        if(confirmString.includes('?c__orderNumber=')){
            let orderNumber = confirmString.split("?c__orderNumber=")[1];
            getSessionContext()
            .then(sessionContext => {
                if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                    this.accountId = sessionContext.effectiveAccountId;
                    let showPriceInfo = sessionStorage.getItem('darboven_showPriceInfo');
                    if(!stringIsNotBlank(showPriceInfo)){
                        getShowPriceInfo({accountId: this.accountId})
                        .then(outerResult => {
                            if(outerResult != null){
                                this.showPrices = outerResult;
                                sessionStorage.setItem('darboven_showPriceInfo', this.showPrices);
                                this.initData(orderNumber);
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
                        this.initData(orderNumber);
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
    }

    initData(orderNumber){
        getOrderInfoByOrderId({
            orderId: orderNumber,
            accountId: this.accountId
        })
        .then(result => {
            if(result != null){
                this.orderInfo = result.order ? JSON.parse(JSON.stringify(result.order)) : {};
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
                    this.hasProducts = true;;
                }
                this.hasData = this.orderInfo != null;
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

    handleContactUs(){
        this.template.querySelectorAll('c-webshop-contact-modal').forEach(element => {
            element.show = true;
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

    handlePrint(){
        let printableElement = this.template.querySelector('.print-section');
         if (printableElement) {
            let clone = printableElement.cloneNode(true);
            let printWindow = window.open('', '_blank');
            if (printWindow) {
                printWindow.document.body.appendChild(clone);
                let style = printWindow.document.createElement('style');
                style.textContent = `
                    @page {
                        size: auto;   /* auto is the initial value */
                        margin: 5mm;  /* this affects the margin in the printer settings */
                    }
                    @media print {
                        body {
                            margin: 0;
                            padding: 0;
                        }
                        .no-print {
                            display: none;
                        }
                    }
                `;
                printWindow.document.head.appendChild(style);
                printWindow.focus();
                printWindow.print();
                printWindow.close();
            } else {
                console.error('Failed to open print window');
            }
        } else {
            console.error('Printable element not found');
        }
    }

    handleContinueShopping(){
        window.location.assign('/');
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