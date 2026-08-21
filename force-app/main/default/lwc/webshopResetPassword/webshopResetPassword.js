import { LightningElement, track } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Apex
import setPassword from '@salesforce/apex/WebshopLoginController.setPassword';

// Labels
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import save from '@salesforce/label/c.GeneralSave';
import changeYourPassword from '@salesforce/label/c.WebshopChangeYourPassword';
import changeYourPasswordMsg from '@salesforce/label/c.WebshopChangeYourPasswordMsg';
import success from '@salesforce/label/c.GeneralSuccess';
import changeYourPasswordSuccessMsg from '@salesforce/label/c.WebshopChangeYourPasswordSuccessMsg';

export default class WebshopForgotPassword extends LightningElement {
    @track isLoading = false;
    @track password = '';
    @track success = false;
    
    label = { 
        generalError,
        generalErrorMsg,
        save,
        changeYourPassword,
        changeYourPasswordMsg,
        success,
        changeYourPasswordSuccessMsg
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP_ICONS);
        loadStyle(this, BOOTSTRAP);
    }

    get passwordDisabled(){
        return stringIsNotBlank(this.password);
    }

    handleSavePassword(){
        this.isLoading = true;
        setPassword({
            password: this.password    
        }).then(result => {
            if(result == true){
                this.success = true;
            } else {
                this.isLoading = false;
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + error,
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