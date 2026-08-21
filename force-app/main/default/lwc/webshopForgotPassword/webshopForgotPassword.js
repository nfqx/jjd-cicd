import { LightningElement, track } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import { stringIsNotBlank } from 'c/stringHelper';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// APEX
import forgotPassword from '@salesforce/apex/WebshopLoginController.forgotPassword';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// LABELS
import SUCCESS from '@salesforce/label/c.WebshopGeneralSuccess';
import USERNAME from '@salesforce/label/c.WebshopLoginUsernamePlaceholder';
import ForgotYourPassword from '@salesforce/label/c.WebshopForgotYourPasswordQuestion'
import EnterYourEmail from '@salesforce/label/c.WebshopEnterYourEmail'
import NewToDarbovenQuestion from '@salesforce/label/c.WebshopNewToDarbovenQuestion'
import CreateYourAccount from '@salesforce/label/c.WebshopCreateYourAccount'
import BackToLogin from '@salesforce/label/c.WebshopBackToLogin'
import PasswordResetButtonLabel from '@salesforce/label/c.WebshopPasswordResetButtonLabel'
import Login from '@salesforce/label/c.WebshopLoginButtonLabel';
import PasswordResetSuccess from '@salesforce/label/c.WebshopPasswordResetSuccess';
import PasswordResetSuccessMsg from '@salesforce/label/c.WebshopPasswordResetSuccessMsg';
import Resend from '@salesforce/label/c.WebshopPasswordResendEmail';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';

export default class WebshopForgotPassword extends LightningElement {

    @track username;
    @track showSuccess = false;
    @track successMessage = '';
    @track resendDisabled = true;
    @track isLoading = false;

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
    }
    
    label = {
        SUCCESS,
        USERNAME,
        ForgotYourPassword,
        EnterYourEmail,
        NewToDarbovenQuestion,
        CreateYourAccount,
        BackToLogin,
        PasswordResetButtonLabel,
        Login,
        PasswordResetSuccess,
        PasswordResetSuccessMsg,
        Resend,
        generalError,
        generalErrorMsg
    }

    get passwordResetSuccessMsg(){
        return this.label.PasswordResetSuccessMsg.split('{0}').join(this.username);
    }

    handleUsernameChange(event) {
        this.showSuccess = false;
        this.showError = false;
        this.username = event.target.value;
    }

    delayEnableResend(){
        let self = this;
        setTimeout(function(){
            self.resendDisabled = false;
        }, 30000);
    }

    resend(event){
        this.isLoading = true;
        this.showError = false;
        this.resendDisabled = true;
        if(stringIsNotBlank(this.username)){
            event.preventDefault();
            this.runResetPasswordLogic();
        } else {
            // Some exception handling different than below because username is empty. MO
        }
    }
    
    handleResetPassword(event) {
        this.isLoading = true;
        this.showSuccess = false;
        this.resendDisabled = true;
        if(stringIsNotBlank(this.username)){
            event.preventDefault();
            this.runResetPasswordLogic();
        } else {
            // Some exception handling different than above because username is empty. MO
        }
    }

    runResetPasswordLogic(){
        forgotPassword({ username: this.username.trim().replace('\t', '') + this.label.SUFFIX })
        .then((result) => {
            if (result === true) {
                this.successMessage = 'We have sent you a password reset email';
                this.showSuccess = true;
                this.delayEnableResend();
            } else {
                forgotPassword({ username: this.username.trim().replace('\t', '') })
                .then((innerResult) => {
                    if (innerResult === true) {
                        this.successMessage = 'We have sent you a password reset email';
                        this.showSuccess = true;
                        this.delayEnableResend();
                        this.isLoading = false;
                    } else {
                        setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                            title: this.label.generalError,
                            message: this.label.generalErrorMsg,
                            variant: 'error',
                        };
                        this.template.querySelector('c-webshop-toast').show = true;}); 
                        this.isLoading = false;
                    }
                })
                .catch(error => {
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                    this.isLoading = false;
                });
            }
        })
        .catch(error => {
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
            this.isLoading = false;
        });
    }


}