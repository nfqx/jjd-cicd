import { LightningElement, api, track } from 'lwc';

// BOOTSTRAP
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import { getSessionContext } from 'commerce/contextApi';

// LABELS
import modalTitle from '@salesforce/label/c.WebshopDoubleOptInModalTitle';
import modalBody from '@salesforce/label/c.WebshopDoubleOptInModalBody';
import yes from '@salesforce/label/c.WebshopDoubleOptInModalYes';
import no from '@salesforce/label/c.WebshopDoubleOptInModalNo';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

// APEX
import getShowDoubleOptIn from '@salesforce/apex/WebshopDataController.getShowDoubleOptIn';
import setDoubleOptInModalSeen from '@salesforce/apex/WebshopDataController.setDoubleOptInModalSeen';
import setDoubleOptIn from '@salesforce/apex/WebshopDataController.setDoubleOptIn';

export default class WebshopDoubleOptinModal extends LightningElement {
    @api show = false;

    @track accountId;
    @track subject;
    @track message;

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                getShowDoubleOptIn({})
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
        modalTitle,
        modalBody,
        yes,
        no,
        generalError,
        generalErrorMsg
    };

    handleClose(){
        this.show = false;
        setDoubleOptInModalSeen({})
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

    handleConfirm(event){
        this.show = false;
        setDoubleOptIn({doubleOptIn: true})
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