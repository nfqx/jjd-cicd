import { LightningElement, track } from 'lwc';

// Apex
import getCategoryById from '@salesforce/apex/WebshopDataController.getCategoryById';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Labels
import category from '@salesforce/label/c.WebshopCategory';
import featuredProducts from '@salesforce/label/c.WebshopFeaturedProducts';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopProductCategoryNew extends LightningElement {
    @track recordId;
    @track showData = false;
    @track record = {};
    @track path = [];
    @track showSliderHeading = false;

    showHeading(){
        this.showSliderHeading = true;
    }

    label = {
        category,
        featuredProducts,
        generalError,
        generalErrorMsg
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        this.recordId = window.location.href.split("=").pop();
        getCategoryById({categoryId: this.recordId})
        .then(result => {
            if(result != null){
                this.record = result.category;
                this.path = result.breadcrumbs;
                this.showData = true;
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
}