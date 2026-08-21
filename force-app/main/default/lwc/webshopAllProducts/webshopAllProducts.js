import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// Apex
import checkIfAssortmentExtended from '@salesforce/apex/WebshopDataController.checkIfCustomerAssortmentExtended';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Labels
import home from '@salesforce/label/c.GeneralHome';
import allProducts from '@salesforce/label/c.WebshopAllProducts';
import myProducts from '@salesforce/label/c.WebshopMyProducts';

export default class WebshopAllProducts extends NavigationMixin(LightningElement)  {
    label = {
        home,
        allProducts,
        myProducts
    };

    @track dataLoaded = false;
    @track showSliderHeading = false;
    @track isAssortmentExtended = false;
    @track loadData = false;

    showHeading(){
        this.showSliderHeading = true;
    }

    get allProducts(){
        return this.isAssortmentExtended ? this.label.allProducts : this.label.myProducts;
    }
    
    connectedCallback(){
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        this.recordId = window.location.href.split("=").pop();
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext.effectiveAccountId;
                checkIfAssortmentExtended({accountId: this.accountId})
                .then(innerResult => {
                    this.isAssortmentExtended = innerResult;
                    this.loadData = true;
                });
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
                message: this.label.generalErrorMsg,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;}); 
        });
    }

    handleClickHome(){
        window.location.assign('/');
    }
}