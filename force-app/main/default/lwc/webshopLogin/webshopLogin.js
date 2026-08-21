import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub'

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import JJD_MARKETING_PHOTO from "@salesforce/resourceUrl/JJDMarketingPhoto";

// APEX
import login from '@salesforce/apex/WebshopLoginController.login';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// LABELS
import AlreadyCustomerMessage from '@salesforce/label/c.WebshopAlreadyCustomerMessage';
import ERROR from '@salesforce/label/c.WebshopGeneralError';
import LOGINHERE from '@salesforce/label/c.WebshopLoginHeader';
import PASSWORD from '@salesforce/label/c.WebshopLoginPwdPlaceholder';
import LOGIN from '@salesforce/label/c.WebshopLoginButtonLabel';
import USERNAME from '@salesforce/label/c.WebshopLoginUsernamePlaceholder';
import SUFFIX from '@salesforce/label/c.LetterCampaignUsernameSuffix';
import SHOWPASSWORD from '@salesforce/label/c.WebshopShowPassword';
import ForgotYourPasswordPreQuestion from '@salesforce/label/c.WebshopForgotYourPasswordPreQuestion';
import ForgotYourPasswordQuestion from '@salesforce/label/c.WebshopForgotYourPasswordQuestion';
import ForgotYourPasswordPostQuestion from '@salesforce/label/c.WebshopForgotYourPasswordPostQuestion'; 
import RegistrationHeader from '@salesforce/label/c.WebshopRegistrationHeader';
import RegistrationDescription from '@salesforce/label/c.WebshopRegistrationDescription';
import RegisterButton from '@salesforce/label/c.WebshopRegisterButtonLabel';
import NotACustomerMessage from '@salesforce/label/c.WebshopNotACustomerMessage';
import ContactUsButton from '@salesforce/label/c.WebshopContactUsButtonLabel';
import needHelp from '@salesforce/label/c.WebshopOrderConfirmationNeedHelp';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import loginSubheader from '@salesforce/label/c.WebshopLoginSubheader';


export default class WebshopLogin extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;

    @track username;
    @track password;
    @track showError = false;
    @track errorMessage = '';
    @track isPasswordVisible = false;
    @track isLoading = false;

    jjdMarketingLogo = JJD_MARKETING_PHOTO;

    label = {
        ERROR,
        LOGINHERE,
        PASSWORD,
        LOGIN,
        USERNAME,
        SUFFIX,
        SHOWPASSWORD,
        AlreadyCustomerMessage,
        ForgotYourPasswordPreQuestion,
        ForgotYourPasswordQuestion,
        ForgotYourPasswordPostQuestion,
        RegistrationHeader,
        RegistrationDescription,
        RegisterButton,
        NotACustomerMessage,
        ContactUsButton,
        needHelp,
        generalError,
        generalErrorMsg,
        loginSubheader

    };
    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
    }

    handlePasswordVisibility() {
        this.template.querySelectorAll('[data-id="password"]').forEach(elem => {
            elem.type = elem.type === "password" ? "text" : "password";
            this.isPasswordVisible = elem.type === "text";
        });
      }

    handleUsernameChange(event) {
        this.showError = false;
        this.username = event.target.value;
    }

    handleClick(){
        this.loginAttempt();
    }

    loginAttempt(){
        this.isLoading = true;
        this.showError = false;
        let password = this.template.querySelector('[data-id="password"]').value;
        if(this.username && stringIsNotBlank(password)){
            login({ username: this.username.trim().replace('\t', '') + this.label.SUFFIX, password: password })
            .then((result) => {
                if (Object.keys(result).includes('url') && this.isValidURL(result.url)) {
                    if(Object.keys(result).includes('cartId') && stringIsNotBlank(result.cartId)){
                        sessionStorage.setItem('darboven_cartId', result.cartId);
                        fireEvent(this.pageRef, 'setCartIdEvent', {  });
                    }
                    window.location.href = result.url;
                } else {
                    login({ username: this.username.trim().replace('\t', ''), password: password })
                    .then((innerResult) => {
                        if (Object.keys(innerResult).includes('url') && this.isValidURL(innerResult.url)) {
                            if(Object.keys(innerResult).includes('cartId') && stringIsNotBlank(innerResult.cartId)){
                                sessionStorage.setItem('darboven_cartId', innerResult.cartId);
                                fireEvent(this.pageRef, 'setCartIdEvent', {  });
                            }
                            window.location.href = innerResult.url;
                        } else if (Object.keys(innerResult).includes('error') && stringIsNotBlank(innerResult.error)){
                            this.errorMessage = innerResult.error;
                            this.showError = true;
                            this.isLoading = false;
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

    isValidURL(url) {
        const urlPattern = /^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$/;
        return urlPattern.test(url);
    }

    handleOpenContactLeadModal(){
        this.template.querySelectorAll('c-webshop-contact-modal').forEach(element => {
            element.isLead = true;
            element.show = true;
        });
    }

    handleOpenContactModal(){
        this.template.querySelectorAll('c-webshop-contact-modal').forEach(element => {
            element.isLead = false;
            element.show = true;
        });
    }

    handlePasswordKeydown(event){
        this.showError = false;
        if (event.key === 'Enter' || event.keyCode === 13) {
            event.preventDefault();
            this.loginAttempt();
        }
    }

    forwardToForgotPassword(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Forgot_Password',
            }
        })
    }

    forwardToRegister(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Register',
            }
        })
    }
}