import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

import home from '@salesforce/label/c.GeneralHome';
import myBrands from '@salesforce/label/c.WebshopMyBrands';
import allProducts from '@salesforce/label/c.WebshopAllProducts';

// APEX
import getBrandData from '@salesforce/apex/WebshopDataController.getBrandData';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopBrandAllProducts extends NavigationMixin(LightningElement)  {
    label = {
        home,
        myBrands,
        allProducts,
        generalError,
        generalErrorMsg
    };

    @track brandData;
    @track brandLoaded = false;
    @track showSliderHeading = false;

    showHeading(){
        this.showSliderHeading = true;
    }
    
    connectedCallback(){
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        this.recordId = window.location.href.split("=").pop();

        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext.effectiveAccountId;
                if(this.recordId != null && this.accountId != null){
                    getBrandData({recordId : this.recordId})
                    .then(result => {
                        if(result != null) {
                            this.brandData = result;
                            this.brandLoaded = true;
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
                } else {
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                }
            }  else {
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

    handleClickBrand(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Webshop_Brand__c',
                recordId: this.recordId,
                actionName: 'view',
            },
        });
    }
}