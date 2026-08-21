import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// APEX
import getActiveBrands from '@salesforce/apex/WebshopDataController.getActiveBrands';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// Labels
import home from '@salesforce/label/c.GeneralHome';
import myBrands from '@salesforce/label/c.WebshopMyBrands'; 
import viewAllProducts from '@salesforce/label/c.WebshopViewAllProducts';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopMyBrands extends NavigationMixin(LightningElement) {
    label = {
        home,
        myBrands,
        viewAllProducts,
        generalError,
        generalErrorMsg
    };

    @track accountId;
    @track myBrands = [];

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
        getSessionContext()
        .then(sessionContext => {
            if (sessionContext.effectiveAccountId) {
                this.accountId = sessionContext.effectiveAccountId;
                getActiveBrands({ accountId: this.accountId })
                .then(result => {
                    if (result) {
                        this.myBrands = [...result]; // Force reactivity
                    }
                })
                .catch(error => {
                    setTimeout(() => {
                        this.template.querySelector('c-webshop-toast').toast = {
                            title: this.label.generalError,
                            message: this.label.generalErrorMsg + ': ' + error,
                            variant: 'error',
                        };
                        this.template.querySelector('c-webshop-toast').show = true;
                    });
                });
            } else {
                console.log('Getting account id failed');
            }
        })
        .catch(error => {
            setTimeout(() => {
                this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + error,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;
            });
        });
    }

    handleClickViewAll(event) {
        const brandId = event.target.dataset.id;

        if (!brandId) {
            console.error('No brandId found for navigation');
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Brand_Products__c',
            },
            state: {
                c__recordId: brandId
            }
        });
    }

    handleClickHome(){
        window.location.assign('/');
    }
}