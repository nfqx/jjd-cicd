import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';
import { getSessionContext } from 'commerce/contextApi';

// APEX
import checkShowGLPage from '@salesforce/apex/WebshopRegisterController.checkShowGLPage';
import checkRegisterUser from '@salesforce/apex/WebshopRegisterController.checkRegisterUser';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// LABELS
import AccountNumber from '@salesforce/label/c.GeneralAccountNumber';
import Continue from '@salesforce/label/c.GeneralContinue';
import profileCreationGLSuccessHeader from '@salesforce/label/c.WebshopProfileCreationGLSuccessHeader';
import profileCreationGLSuccessMsg from '@salesforce/label/c.WebshopProfileCreationSuccessMsg';
import profileCreationGLUnauthorizedHeader from '@salesforce/label/c.WebshopProfileCreationGLUnauthorizedHeader';
import profileCreationGLUnauthorizedMsg from '@salesforce/label/c.WebshopProfileCreationGLUnauthorizedMsg';
import profileCreationGLAlreadyActiveHeading from '@salesforce/label/c.WebshopProfileCreationGLAlreadyActiveHeading';
import profileCreationGLAlreadyActiveMessage from '@salesforce/label/c.WebshopProfileCreationGLAlreadyActiveMessage';
import firstNameLabel from '@salesforce/label/c.GeneralFirstName';
import lastNameLabel from '@salesforce/label/c.GeneralLastName';
import emailLabel from '@salesforce/label/c.GeneralEmail';
import phoneLabel from '@salesforce/label/c.GeneralPhone';
import doneLabel from '@salesforce/label/c.GeneralDone';
import enterInformation from '@salesforce/label/c.WebshopProfileCreationGLEnterInformation';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';


export default class WebshopRegisterInternal extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @track stepTwo = true;
    @track stepThreeSuccess = false;
    @track stepThreeUnauthorized = false;
    @track stepThreeAlreadyActive = false;
    @track verified = false;
    @track showMask = false;

    @track firstName;
    @track lastName;
    @track email;
    @track phone;
    @track accountId;

    handleChangeAccountPostalCode(event){
        this.accountPostalCode = event.target.value;
    }
    handleChangeAccount(event){
        this.accountId = event.target.value;
    }
    handleChangeFirstName(event){
        this.firstName = event.target.value;
    }
    handleChangeLastName(event){
        this.lastName = event.target.value;
    }
    handleChangeEmail(event){
        this.email = event.target.value;
    }
    handleChangePhone(event){
        this.phone = event.target.value;
    }

    get firstStepDisabled(){
        return !stringIsNotBlank(this.accountPostalCode);
    }

    get secondStepDisabled(){
        return !stringIsNotBlank(this.firstName) && !stringIsNotBlank(this.lastName) && !stringIsNotBlank(this.email) && !stringIsNotBlank(this.phone) && !stringIsNotBlank(this.accountId);
    }

    label = {
        AccountNumber,
        Continue,
        firstNameLabel,
        lastNameLabel,
        emailLabel,
        phoneLabel,
        doneLabel,
        profileCreationGLSuccessHeader,
        profileCreationGLSuccessMsg,
        profileCreationGLUnauthorizedHeader,
        profileCreationGLUnauthorizedMsg,
        profileCreationGLAlreadyActiveHeading,
        profileCreationGLAlreadyActiveMessage,
        enterInformation,
        generalError,
        generalErrorMsg
    }
    connectedCallback(){
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
        checkShowGLPage()
        .then(outerResult => {
            if(outerResult != null){
                this.showMask = outerResult;
                getSessionContext()
                .then(sessionContext => {
                    if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                        this.accountId = sessionContext.effectiveAccountId;
                    } else {
                        setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                            title: this.label.generalError,
                            message: this.label.generalErrorMsg,
                            variant: 'error',
                        };
                        this.template.querySelector('c-webshop-toast').show = true;}); 
                    }
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

    handleSubmitStepTwo(){
        checkRegisterUser({
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            phone: this.phone,
            accountId: this.accountId,
            noVerification: true
        })
        .then(result => {
            if(result == 'success'){
                this.stepTwo = false;
                this.stepThreeSuccess = true;
            } else if(result == 'already_active'){
                this.stepTwo = false;
                this.stepThreeAlreadyActive = true;
            } else if(result == 'wrong_account_or_not_webshop_customer' || 'no_account_found'){
                this.stepTwo = false;
                this.stepThreeUnauthorized = true;
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