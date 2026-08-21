import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { stringIsNotBlank } from 'c/stringHelper';

// APEX
import verifyRegistrationActivation from '@salesforce/apex/WebshopRegisterController.verifyRegistrationActivation';
import verifyAccount from '@salesforce/apex/WebshopRegisterController.verifyAccount';
import checkRegisterUser from '@salesforce/apex/WebshopRegisterController.checkRegisterUser';
import notifyViaEmail from '@salesforce/apex/WebshopRegisterController.sendNotification';

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
import YourCompanyDetails from '@salesforce/label/c.WebshopYourCompanyDetails';
import CompanyDetailsMsg from '@salesforce/label/c.WebshopCompanyDetailsMsg';
import YourPersonalDetails from '@salesforce/label/c.WebshopYourPersonalDetails';
import PersonalDetailsMsg from '@salesforce/label/c.WebshopPersonalDetailsMsg';
import profileCreationSuccessHeader from '@salesforce/label/c.WebshopProfileCreationSuccessHeader';
import profileCreationSuccessMsg from '@salesforce/label/c.WebshopProfileCreationSuccessMsg';
import profileCreationPostalHeader from '@salesforce/label/c.WebshopProfileCreationPostalHeader';
import profileCreationPostalMsg from '@salesforce/label/c.WebshopProfileCreationPostalMsg';
import profileCreationUnauthorizedHeader from '@salesforce/label/c.WebshopProfileCreationUnauthorizedHeader';
import profileCreationUnauthorizedMsg from '@salesforce/label/c.WebshopProfileCreationUnauthorizedMsg';
import verificationErrorHeading from '@salesforce/label/c.WebshopProfileCreationVerificationErrorHeading';
import verificationErrorMessage from '@salesforce/label/c.WebshopProfileCreationVerificationErrorMessage';
import profileCreationAlreadyActiveHeading from '@salesforce/label/c.WebshopProfileCreationAlreadyActiveHeading';
import profileCreationAlreadyActiveMessage from '@salesforce/label/c.WebshopProfileCreationAlreadyActiveMessage';
import accountUnknown from '@salesforce/label/c.WebshopRegisterAccountUnknown';
import notActivated from '@salesforce/label/c.WebshopRegisterAccountNotWebshopActivated';
import completeProfile from '@salesforce/label/c.WebshopCompleteProfile';
import NextLabel from '@salesforce/label/c.GeneralNextLabel';
import firstNameLabel from '@salesforce/label/c.GeneralFirstName';
import lastNameLabel from '@salesforce/label/c.GeneralLastName';
import emailLabel from '@salesforce/label/c.GeneralEmail';
import phoneLabel from '@salesforce/label/c.GeneralPhone';
import doneLabel from '@salesforce/label/c.GeneralDone';
import postalCodeLabel from '@salesforce/label/c.GeneralPostalCode';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';


export default class WebshopRegisterLanding extends NavigationMixin(LightningElement) {
    @track JJDLogo = JJDarbovenLogo ;
    @track stepOne = true;
    @track stepTwo = false;
    @track stepThreePostal = false;
    @track stepThreeSuccess = false;
    @track stepThreeUnauthorized = false;
    @track stepThreeAlreadyActive = false;
    @track stepThreeNotActivated = false;
    @track stepThreeNoAccountFound = false;
    @track verified = false;
    @track isLoading = false;

    @track accountPostalCode = '';
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track phone = '';
    @track recordId;

    handleChangeAccountPostalCode(event){
        this.accountPostalCode = event.target.value;
    }
    handleChangeFirstName(event){
        this.firstName = event.target.value;
    }
    handleChangeLastName(event){
        this.lastName = event.target.value;
    }
    handleChangePhone(event){
        this.phone = event.target.value;
    }

    get secondStepDisabled(){
        return !stringIsNotBlank(this.firstName) && !stringIsNotBlank(this.lastName) && !stringIsNotBlank(this.email) && !stringIsNotBlank(this.phone);
    }

    label = {
        AccountNumber,
        CompanyDetails,
        PersonalDetails,
        Continue,
        YourCompanyDetails,
        CompanyDetailsMsg,
        YourPersonalDetails,
        PersonalDetailsMsg,
        profileCreationSuccessHeader,
        profileCreationSuccessMsg,
        profileCreationPostalHeader,
        profileCreationPostalMsg,
        NextLabel,
        firstNameLabel,
        lastNameLabel,
        emailLabel,
        phoneLabel,
        doneLabel,
        completeProfile,
        profileCreationUnauthorizedHeader,
        profileCreationUnauthorizedMsg,
        verificationErrorHeading,
        verificationErrorMessage,
        postalCodeLabel,
        profileCreationAlreadyActiveHeading,
        profileCreationAlreadyActiveMessage,
        generalError,
        generalErrorMsg,
        accountUnknown,
        notActivated
    }
    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
        this.email = window.location.href.split("emailaddress=").pop().split('&')[0];
        this.recordId = window.location.href.split("=").pop();
        verifyRegistrationActivation({accountId: this.recordId})
        .then(result => {
            if(result == true){
                this.verified = result;
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
            this.isLoading = false;
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        });
    }

    handleSubmitStepOne(){
        this.isLoading = true;
        verifyAccount({
            postalCode: this.accountPostalCode,
            accountId: this.recordId
        }).then(result => {
            if(result != null){
                if(result == true){
                    this.showSpinner = false;
                    this.stepOne = false;
                    this.stepTwo = true;
                } else {
                    this.verified = false;
                }
            } else {
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;}); 
            }
            this.isLoading = false;
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

    handleSubmitStepTwo(){
        this.isLoading = true;
        checkRegisterUser({
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            phone: this.phone,
            accountId: this.recordId,
            noVerification: false
        })
        .then(result => {
            if(result == 'postal'){
                this.stepTwo = false;
                this.stepThreePostal = true;t
                notifyViaEmail({
                    notificationText: 'Postal Verification',
                    accountId: this.recordId
                })
                .then(innerResult => {
                    // do nothing
                })
            } else if(result == 'success'){
                this.stepTwo = false;
                this.stepThreeSuccess = true;
                notifyViaEmail({
                    notificationText: 'Self Registration success',
                    accountId: this.recordId
                })
                .then(innerResult => {
                    // do nothing
                })
            } else if(result == 'already_active'){
                this.stepTwo = false;
                this.stepThreeAlreadyActive = true;
                notifyViaEmail({
                    notificationText: 'Account already active',
                    accountId: this.recordId
                })
                .then(innerResult => {
                    // do nothing
                })
            } else if(result == 'no_account_found'){
                this.stepTwo = false;
                this.stepThreeNoAccountFound = true;
                notifyViaEmail({
                    notificationText: 'No Account Found',
                    accountId: this.recordId
                })
                .then(innerResult => {
                    // do nothing
                })
            } else if(result == 'no_contact_or_not_webshop_customer'){
                this.stepTwo = false;
                this.stepThreeUnauthorized = true;
                notifyViaEmail({
                    notificationText: 'No Contact or not a webshop customer',
                    accountId: this.recordId
                })
                .then(innerResult => {
                    // do nothing
                })
            } else {
                setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                    title: this.label.generalError,
                    message: this.label.generalErrorMsg + ': ' + result,
                    variant: 'error',
                };
                this.template.querySelector('c-webshop-toast').show = true;});
            }
            this.isLoading = false;
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