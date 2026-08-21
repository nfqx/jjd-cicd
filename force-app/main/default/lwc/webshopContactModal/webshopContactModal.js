import { LightningElement, api, track } from 'lwc';

// BOOTSTRAP
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import { stringIsNotBlank } from 'c/stringHelper';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// LABELS
import modalTitle from '@salesforce/label/c.WebshopContactModalTitle';
import modalBody from '@salesforce/label/c.WebshopContactModalBody';
import success from '@salesforce/label/c.WebshopContactModalSuccess';
import cancel from '@salesforce/label/c.GeneralCancel';
import send from '@salesforce/label/c.GeneralSend';
import name from '@salesforce/label/c.GeneralName';
import email from '@salesforce/label/c.GeneralEmail';
import phone from '@salesforce/label/c.GeneralPhone';
import invalidNameLabel from '@salesforce/label/c.WebshopInvalidName';
import invalidEmailLabel from '@salesforce/label/c.WebshopContactInvalidEmail';
import invalidPhoneLabel from '@salesforce/label/c.WebshopContactInvalidPhone';

import valProblem from '@salesforce/label/c.WebshopContactModalValueProblem';
import valFeature from '@salesforce/label/c.WebshopContactModalValueFeature';
import valQuestion from '@salesforce/label/c.WebshopContactModalValueQuestion';
import valTraining from '@salesforce/label/c.WebshopContactModalValueTraining';
import valGeneral from '@salesforce/label/c.WebshopContactModalValueGeneral';
import valInteressent from '@salesforce/label/c.WebshopContactModalValueInteressent';
import valAngebote from '@salesforce/label/c.WebshopContactModalValueAngebote';
import valOrder from '@salesforce/label/c.WebshopContactModalValueOrder';
import valLogistik from '@salesforce/label/c.WebshopContactModalValueLogistik';
import valReklamation from '@salesforce/label/c.WebshopContactModalValueReklamation';
import valLead from '@salesforce/label/c.WebshopContactModalValueLead';
import valEndkundenanfrage from '@salesforce/label/c.WebshopContactModalValueEndkundenanfrage';
import valNeukundenanlage from '@salesforce/label/c.WebshopContactModalValueNeukundenanlage';
import valAndere from '@salesforce/label/c.WebshopContactModalValueAndere';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// APEX
import sendMessageNotLoggedIn from '@salesforce/apex/WebshopDataController.sendMessageNotLoggedIn';
import sendMessage from '@salesforce/apex/WebshopDataController.sendMessage';

export default class WebshopContactModal extends LightningElement {
    @track _show = false; 
    @api liteOptions = false;

    @api
    get show() {
      return this._show;
    }
    set show(value) {
      this._show = value;
    }

    @track _isLead = false; 
    
    @api
    get isLead() {
      return this._isLead;
    }
    set isLead(value) {
      this._isLead = value;
    }

    @api anonymous = false;

    @track accountId;
    @track subject = '-';
    @track message = '';
    @track subjectIsOther = false;
    @track isSuccess = false;
    @track sendDisabled = true;
    @track isLoading = false;
    @track name = '';
    @track email = '';
    @track phone = '';

    @track invalidName = false;
    @track invalidEmail = false;
    @track invalidPhone = false;

    connectedCallback() {
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        if(!this.anonymous){
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

    label = {
        modalTitle,
        modalBody,
        cancel,
        send,
        success,
        valProblem,
        valFeature,
        valQuestion,
        valTraining,
        valGeneral,
        valAngebote,
        valOrder,
        valLogistik,
        valReklamation,
        valInteressent,
        valLead,
        valEndkundenanfrage,
        valNeukundenanlage,
        valAndere,
        name,
        email,
        phone,
        invalidNameLabel,
        invalidEmailLabel,
        invalidPhoneLabel
    };

    subjectOptionsAlt = [
        { label: this.label.valAngebote, value: "Angebote" },
        { label: this.label.valInteressent, value: "Interessent" },
        { label: this.label.valNeukundenanlage, value: "Neukundenanlage" }
    ]

    subjectOptionsGeneral = [
        { label: this.label.valQuestion, value: "Question" },
        { label: this.label.valTraining, value: "Trainings Issue" },
        { label: this.label.valGeneral, value: "Allg_Anfragen" },
        { label: this.label.valOrder, value: "Order" },
        { label: this.label.valLogistik, value: "Logistik" },
        { label: this.label.valReklamation, value: "Reklamation" },
        { label: this.label.valProblem, value: "Problem" },
    ]

    subjectOptionsGeneralLite = [
        { label: this.label.valQuestion, value: "Question" },
        { label: this.label.valProblem, value: "Problem" },
    ]

    get subjectOptions(){
        return this.isLead ? this.subjectOptionsAlt : (this.liteOptions ? this.subjectOptionsGeneralLite : this.subjectOptionsGeneral);
    }

    handleClose(){
        this.isSuccess = false;
        this.isLoading = false;
        this.subject = '';
        this.message = '';
        this.subjectIsOther = false;
        this._show = false;
    }

    handleChangeSubject(event){
        this.subject = event.target.value;
        this.subjectIsOther = this.subject == 'Andere';
        this.sendDisabled = 
            this.anonymous 
            ? !(stringIsNotBlank(this.name) && stringIsNotBlank(this.email) && stringIsNotBlank(this.subject) && stringIsNotBlank(this.message) && !this.subjectIsOther)
            : !(stringIsNotBlank(this.subject) && stringIsNotBlank(this.message) && !this.subjectIsOther);
    }
    handleChangeSubjectAlt(event){
        this.subject = event.target.value;
        this.checkSendDisabled();
    }
    handleChangeName(event){
        this.name = event.target.value;
        this.checkSendDisabled();
    }
    handleChangeEmail(event){
        this.email = event.target.value;
        this.checkSendDisabled();
    }
    handleChangePhone(event){
        this.phone = event.target.value;
        this.checkSendDisabled();
    }
    handleChangeMessage(event){
        this.message = event.target.value;
        this.checkSendDisabled();
    }
/*
    checkSendDisabled(){
        const emailPattern = /(.+)@(.+){2,}\.(.+){2,}/;
        this.sendDisabled = 
            this.anonymous 
            ? !(stringIsNotBlank(this.name) && stringIsNotBlank(this.email) && stringIsNotBlank(this.phone) && stringIsNotBlank(this.subject) && stringIsNotBlank(this.message) && emailPattern.test(booking_email))
            : !(stringIsNotBlank(this.subject) && stringIsNotBlank(this.message));
    }
*/  
    checkSendDisabled() {
        const emailPattern = /(.+)@(.+){2,}\.(.+){2,}/;
        if (this.anonymous) {
            this.invalidName = !stringIsNotBlank(this.name);
            this.invalidEmail = !(stringIsNotBlank(this.email) && emailPattern.test(this.email));
            this.invalidPhone = !stringIsNotBlank(this.phone);

            const invalidOtherFields =
                !stringIsNotBlank(this.subject) || !stringIsNotBlank(this.message);

            this.sendDisabled = this.invalidName || this.invalidEmail || this.invalidPhone || invalidOtherFields;
        } else {
            this.sendDisabled = !stringIsNotBlank(this.subject) || !stringIsNotBlank(this.message);
        }
    }

    get nameInputClass() {
        return `form-control ${this.invalidName ? 'is-invalid' : 'mb-3'}`;
    }

    get emailInputClass() {
        return `form-control ${this.invalidEmail ? 'is-invalid' : 'mb-3'}`;
    }

    get phoneInputClass() {
        return `form-control ${this.invalidPhone ? 'is-invalid' : 'mb-3'}`;
    }

    handleSend(event){
        this.sendDisabled = true;
        this.isLoading = true;
        if(stringIsNotBlank(this.subject) && stringIsNotBlank(this.message)){
            if(this.anonymous){
                sendMessageNotLoggedIn({
                    subject: this.subject,
                    subjectIsOther: this.subjectIsOther,
                    message: this.message,
                    accountId: this.accountId,
                    name: this.name,
                    email: this.email,
                    phone: this.phone,
                    isLead: this._isLead
                })
                .then(response => {
                    if(response == true){
                        this.isSuccess = true;
                        this.isLoading = false;
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
                    this.isSuccess = false;
                    this.isLoading = false;
                    setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                        title: this.label.generalError,
                        message: this.label.generalErrorMsg + ': ' + error,
                        variant: 'error',
                    };
                    this.template.querySelector('c-webshop-toast').show = true;}); 
                });
            } else {
                sendMessage({
                    subject: this.subject,
                    subjectIsOther: this.subjectIsOther,
                    message: this.message,
                    accountId: this.accountId
                })
                .then(response => {
                    if(response == true){
                        this.isSuccess = true;
                        this.isLoading = false;
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
                    this.isSuccess = false;
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
    }
}