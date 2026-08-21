import { LightningElement, api } from 'lwc';

// BOOTSTRAP
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// LABELS
import modalBody from '@salesforce/label/c.WebshopDoubleOptInModalBody';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

// Commerce API

// APEX
import getShowDoubleOptInCheckout from '@salesforce/apex/WebshopDataController.getShowDoubleOptInCheckout';
import setDoubleOptIn from '@salesforce/apex/WebshopDataController.setDoubleOptIn';

export default class WebshopDoubleOptIn extends LightningElement {
    @api show;

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        getShowDoubleOptInCheckout({})
        .then(result => {
            if(result != null){
                this.show = result;
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

    label = {
        modalBody,
        generalError,
        generalErrorMsg
    };

    handleCheckbox(event){
        let checked = event.target.checked;
        setDoubleOptIn({doubleOptIn: checked})
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