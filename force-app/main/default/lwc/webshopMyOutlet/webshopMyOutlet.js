import { LightningElement, track, wire } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub'

// Bootstrap and Leaflet
import { loadScript,  loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import leafl from '@salesforce/resourceUrl/leaflet';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';
import { effectiveAccount } from 'commerce/effectiveAccountApi';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getSingleOutlet from '@salesforce/apex/WebshopDataController.getSingleOutlet';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Labels
import backToList from '@salesforce/label/c.WebshopBackToList';
import active from '@salesforce/label/c.GeneralActive';
import contactDetails from '@salesforce/label/c.WebshopContactDetails';
import accountName from '@salesforce/label/c.WebshopAccountName';
import customerNumber from '@salesforce/label/c.WebshopCustomerNumber';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import mainDeliveryAddress from '@salesforce/label/c.WebshopMainDeliveryAddress';
import additionalDeliveryAddresses from '@salesforce/label/c.WebshopAdditionalDeliveryAddresses';
import switchAccount from '@salesforce/label/c.GeneralSwitchAccount';

var map;
var marker;

export default class WebshopMyOutlet extends LightningElement {    
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track outletData;
    @track isActive = false;
    @track initialized = false;
    @track isLoading = false;
    @track additionalDeliveryAddresses = false;
    @track hasAdditionalDeliveryAddresses = false;

    label = {
        backToList,
        active,
        contactDetails,
        accountName,
        customerNumber,
        generalError,
        generalErrorMsg,
        mainDeliveryAddress,
        additionalDeliveryAddresses,
        switchAccount
    };

    connectedCallback() {
        this.isLoading = true;
        loadStyle(this, BOOTSTRAP); 
        loadStyle(this, webshopStyle);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext?.effectiveAccountId;
                this.recordId = window.location.href.split("=").pop();
                getSingleOutlet({accountId: this.recordId})
                .then(result => {
                    if(result != null){
                        this.outletData = JSON.parse(JSON.stringify(result.outletData));
                        if(stringIsNotBlank(this.outletData.ShippingStreet) && stringIsNotBlank(this.outletData.ShippingCity) && stringIsNotBlank(this.outletData.ShippingPostalCode)){
                            this.outletData.Street = this.outletData.ShippingStreet;
                            this.outletData.City = this.outletData.ShippingCity;
                            this.outletData.PostalCode = this.outletData.ShippingPostalCode;
                        } else {
                            this.outletData.Street = this.outletData.BillingStreet;
                            this.outletData.City = this.outletData.BillingCity;
                            this.outletData.PostalCode = this.outletData.BillingPostalCode;
                        }
                        this.additionalDeliveryAddresses = JSON.parse(JSON.stringify(result.deliveryAddresses));
                        this.hasAdditionalDeliveryAddresses = this.additionalDeliveryAddresses.length > 0;
                        this.isActive = this.outletData.Id.includes(this.accountId);
                        this.showData = true;
                        if (!this.initialized) {
                            this.initialized = true;
                            Promise.all([
                                loadScript(this, leafl + '/leaflet-src.js'),
                                loadStyle(this, leafl + '/leaflet.css'),
                            ])
                            .then(() => {
                                this.initializeLeafLet()
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
    
    handleBackToList(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Outlets__c',
            }
        });
    }

    handleSwitchAccount(){
        sessionStorage.clear();
        getCartSummaryOrCreateCart({accountId: this.outletData.Id})
        .then(result => {
            sessionStorage.setItem('darboven_cartId', result);
            fireEvent(this.pageRef, 'setCartIdEvent', {  });
            effectiveAccount.update(this.outletData.Id, this.outletData.Name);
            window.location.assign('/');
        });
    }

    initializeLeafLet() {
        if (this.outletData.ShippingLatitude != null && this.outletData.ShippingLongitude != null){
            let center = [this.outletData.ShippingLatitude, this.outletData.ShippingLongitude];
            const mapRoot = this.template.querySelector("[data-id=maproot]")
            map = L.map(mapRoot, {
                center: center,
                minZoom: 3,
                zoom: 13,
                setView: true
            });
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                subdomains: ['a','b','c']
            }).addTo( map );
            marker = L.marker(center).addTo(map); // [latitude, longitude]
        } else {
            this.template.querySelector("[data-id=mapholder]").style.display = 'none';
        }
        this.isLoading = false;
    }
}