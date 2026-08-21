import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';

// APEX
import checkAccountNumber from '@salesforce/apex/WebshopRegisterController.checkAccountNumber';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import JJDarbovenLogo from '@salesforce/resourceUrl/JJDLogo';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// LABELS
import AccountNumber from '@salesforce/label/c.GeneralAccountNumber';
import CompanyDetails from '@salesforce/label/c.GeneralCompanyDetails';
import PersonalDetails from '@salesforce/label/c.GeneralPersonalDetails';
import Continue from '@salesforce/label/c.GeneralContinue';
import ContactUsButtonLabel from '@salesforce/label/c.WebshopContactUsButtonLabel';
import NotACustomerMessage from '@salesforce/label/c.WebshopNotACustomerMessage';
import Registration from '@salesforce/label/c.WebshopRegistration';
import RegistrationMessage from '@salesforce/label/c.WebshopRegistrationMsg';
import NextLabel from '@salesforce/label/c.GeneralNextLabel';
import successHeader from '@salesforce/label/c.WebshopRegisterSuccessHeader';
import successBody from '@salesforce/label/c.WebshopRegisterSuccessBody';
import successBody2 from '@salesforce/label/c.WebshopRegisterSuccessBody2';
import sendEmailAgain from '@salesforce/label/c.WebshopSendEmailAgain';
import alreadyInUseHeader from '@salesforce/label/c.WebshopAlreadyInUseHeader';
import existingAccountFound from '@salesforce/label/c.WebshopExistingAccountFound';
import tryToLoginOrContactSupport from '@salesforce/label/c.WebshopTryToLoginOrContactSupport';
import cantFindCustomer from '@salesforce/label/c.WebshopCantFindCustomer';
import login from '@salesforce/label/c.WebshopLoginButtonLabel';
import contactEcommerceSupport from '@salesforce/label/c.WebshopContactEcommerceSupport';
import contactEMail from '@salesforce/label/c.WebshopContactEmail';
import email from '@salesforce/label/c.GeneralYourEmail';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';


export default class WebshopRegister extends NavigationMixin(LightningElement) {
    @track JJDLogo = JJDarbovenLogo ;
    @track stepOne = true;
    @track invalidNumber = false;
    @track stepTwoSuccess = false;
    @track stepTwoAccountExists = false;
    @track accountNumber = '';
    @track email = '';
    @track submitDisabled = true;
    @track isLoading = false;

    jjdLogo = JJDarbovenLogo;

    label= {
        AccountNumber,
        CompanyDetails,
        PersonalDetails,
        Continue,
        ContactUsButtonLabel,
        NotACustomerMessage,
        Registration,
        RegistrationMessage,
        NextLabel,
        successHeader,
        successBody,
        successBody2,
        sendEmailAgain,
        alreadyInUseHeader,
        existingAccountFound,
        tryToLoginOrContactSupport,
        cantFindCustomer,
        contactEMail,
        login,
        contactEcommerceSupport,
        email,
        generalError,
        generalErrorMsg
    }

    get existingAccountFound(){
        return this.label.existingAccountFound  + ' ' + this.accountNumber + '.';
    }

    get successBodyFormatted(){
        return this.label.successBody.replace('{0}', this.email);
    }

    get contactEmailMailto(){
        return 'mailto:' + this.label.contactEMail;
    }
    
    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
    }

    handleOpenContactModal(){
        this.template.querySelectorAll('c-webshop-contact-modal').forEach(element => {
            element.show = true;
        });
    }

    handleGoToLogin(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Login',
            }
        });
    }

    handleChangeAccountNumber(event){
        this.accountNumber = event.target.value;
        this.submitDisabled = !(stringIsNotBlank(this.accountNumber) && stringIsNotBlank(this.email));
    }
    handleChangeEmail(event){
        this.email = event.target.value;
        this.submitDisabled = !(stringIsNotBlank(this.accountNumber) && stringIsNotBlank(this.email));
    }

    handleSubmitAccountNumber(){
        this.isLoading = true;
        checkAccountNumber({
            accountNumber: this.accountNumber,
            email: this.email
        })
        .then(result => {
            if(result == 'not_found'){
                this.invalidNumber = true;
            } else if(result == 'success'){
                this.stepOne = false;
                this.stepTwoSuccess = true;
            } else if(result == 'already_active'){
                this.stepOne = false;
                this.stepTwoAccountExists = true;
            } else {
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + error,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            }
            this.isLoading = false;
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

    handleResendEmail(){
        checkAccountNumber({
            accountNumber: this.accountNumber
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