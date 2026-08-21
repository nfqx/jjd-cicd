import { LightningElement, track, wire } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';
import { effectiveAccount } from 'commerce/effectiveAccountApi';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getAllOutlets from '@salesforce/apex/WebshopDataController.getAllOutlets';
import getCartSummaryOrCreateCart from '@salesforce/apex/WebshopDataController.getCartSummaryOrCreateCart';

// Labels
import backToShop from '@salesforce/label/c.WebshopBackToShop';
import searchOutlet from '@salesforce/label/c.WebshopSearchOutlet';
import myOutlets from '@salesforce/label/c.WebshopMyOutlets';
import myOutletsSubtitle from '@salesforce/label/c.WebshopMyOutletsSubtitle';
import active from '@salesforce/label/c.GeneralActive';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import switchAccount from '@salesforce/label/c.GeneralSwitchAccount';

export default class WebshopMyOutlets extends NavigationMixin(LightningElement) {  
    @wire(CurrentPageReference) pageRef;
    @track accountId;
    @track allOutlets = [];
    @track displayedOutlets = [];
    @track isLoading = false;

    label = {
        backToShop,
        searchOutlet,
        myOutlets,
        myOutletsSubtitle,
        active,
        generalError,
        generalErrorMsg,
        switchAccount
    }

    changeSearchTerm(event){
        let searchTerm = event.target.value;
        let allOutlets = JSON.parse(JSON.stringify(this.allOutlets));
        if(stringIsNotBlank(searchTerm)){
            allOutlets = allOutlets.filter((outlet) => outlet.Name.includes(searchTerm) || outlet.Street.includes(searchTerm) || outlet.PostalCode.includes(searchTerm) || outlet.City.includes(searchTerm) );
        }
        this.displayedOutlets = JSON.parse(JSON.stringify(allOutlets));
    }

    connectedCallback() {
        this.isLoading = true;
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext?.effectiveAccountId;
                getAllOutlets({accountId: this.accountId, lmt: null})
                .then(result => {
                    if(result != null){
                        this.allOutlets = JSON.parse(JSON.stringify(result));
                        this.allOutlets.forEach(outlet => {
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
                        });
                        this.displayedOutlets = JSON.parse(JSON.stringify(this.allOutlets));
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
    }

    handleSwitchAccount(event){
        let accountId = event.target.dataset.recordid;
        let accountName = event.target.dataset.recordname;
        sessionStorage.clear();
        getCartSummaryOrCreateCart({accountId: accountId})
        .then(result => {
            sessionStorage.setItem('darboven_cartId', result);
            fireEvent(this.pageRef, 'setCartIdEvent', {  });
            effectiveAccount.update(accountId, accountName);
            window.location.assign('/');
        });
    }

    handleClickBackToShop(){
        window.location.assign('/');
    }
    
    handleClickOutlet(event){
        let outletId = event.currentTarget.dataset.outletid;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Outlet__c',
            },
            state: {
                c__outletNumber: outletId
            }
        });
    }
}