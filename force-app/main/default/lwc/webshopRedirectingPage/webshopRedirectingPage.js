import { LightningElement, track } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Labels
import Done from '@salesforce/label/c.GeneralDone';
import VerificationSuccess from '@salesforce/label/c.WebshopVerificationSuccess';
import RedirectionMsg1 from '@salesforce/label/c.WebshopRedirectionMsg1';
import RedirectionMsg2 from '@salesforce/label/c.WebshopRedirectionMsg2';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import save from '@salesforce/label/c.GeneralSave';

// Apex
import setPassword from '@salesforce/apex/WebshopLoginController.setPassword';
import loginWithId from '@salesforce/apex/WebshopLoginController.loginWithId';
import checkPendingVerification from '@salesforce/apex/WebshopLoginController.checkPendingVerification';

// Labels

export default class WebshopRedirectingPage extends LightningElement {
    @track countdown = 5;
    @track pwdSuccess = false;
    @track password = '';
    @track isLoading = false;
    @track showData = false;
    @track userid = '';

    label = { 
        Done,
        VerificationSuccess,
        RedirectionMsg1,
        RedirectionMsg2,
        generalError,
        generalErrorMsg,
        save
    }

    get passwordDisabled(){
        return stringIsNotBlank(this.password);
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        this.userid = window.location.href.split("=").pop();
        checkPendingVerification({userÍd: this.userid})
        .then(result => {
            if(result == true){
                this.showData = true;
            } else {
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

    startCountdown(target) {
        const timer = setInterval(() => {
            if (this.countdown > 1) {
                this.countdown -= 1;
            } else {
                clearInterval(timer);
                this.handleRedirect(target);
            }
        }, 1000);
    }

    handleSavePassword(){
        this.isLoading = true;
        setPassword({
            password: this.password    
        }).then(result => {
            if(result == true){
                loginWithId({ userId: this.userid, password: this.password })
                .then((result) => {
                    if(result != null){
                        this.pwdSuccess = true;
                        this.startCountdown(result);
                        this.isLoading = false;
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

    handleChangePassword(event){
        this.password = event.detail;
    }

    handleRedirect(target) {
        window.location.href = target; // replace with the redirect URL
    }
}