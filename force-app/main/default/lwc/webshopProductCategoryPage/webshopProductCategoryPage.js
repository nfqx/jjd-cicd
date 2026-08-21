import { LightningElement, track, wire } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';

// Apex
import getCategoryById from '@salesforce/apex/WebshopDataController.getCategoryById';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Labels
import category from '@salesforce/label/c.WebshopCategory';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopProductCategoryPage extends LightningElement {
    @track recordId;
    @track showData = false;
    @track record = {};
    @track path = [];
    @track showSliderHeading = false;
    @track myItemsOnly = false;

    showHeading(){
        this.showSliderHeading = true;
    }

    label = {
        category,
        generalError,
        generalErrorMsg
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        this.recordId = window.location.href.split("/").pop();
        this.myItemsOnly = true;
        if(this.recordId.includes('?')){
            this.recordId = this.recordId.split('?')[0];
            this.myItemsOnly = this.recordId.split('?')[1] == 'all';
        }
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