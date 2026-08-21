import { LightningElement, track } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Label
import backToShop from '@salesforce/label/c.WebshopBackToShop';
import myWishlist from '@salesforce/label/c.WebshopMenuWishlist';
import myWishlistSlider from '@salesforce/label/c.WebshopDoNotTranslateWishlist';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopMyWishlist extends LightningElement {  
    @track accountId;

    label = {
        backToShop,
        myWishlist,
        myWishlistSlider,
        generalError,
        generalErrorMsg
    }

    handleClickBackToShop(){
        window.location.assign('/');
    }

    connectedCallback() {
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext?.effectiveAccountId;
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