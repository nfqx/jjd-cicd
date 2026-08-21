import { LightningElement, track } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';

// Bootstrap & Style
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// APEX
import getCurrentUserInfo from '@salesforce/apex/WebshopDataController.getCurrentUserInfo';
import setCurrentUserInfo from '@salesforce/apex/WebshopDataController.setCurrentUserInfo';
import setConsents from '@salesforce/apex/WebshopDataController.setConsent';
import setPersonal from '@salesforce/apex/WebshopDataController.setPersonal';
import setPassword from '@salesforce/apex/WebshopLoginController.setPassword';

// Labels
import backToShop from '@salesforce/label/c.WebshopBackToShop';
import settingsHeader from '@salesforce/label/c.WebshopSettingsHeader';
import personal from '@salesforce/label/c.GeneralPersonal';
import settingsSubHeader from '@salesforce/label/c.WebshopSettingsSubHeader';
import accountSecurity from '@salesforce/label/c.WebshopAccountSecurity';
import settings from '@salesforce/label/c.GeneralSettings';
import consents from '@salesforce/label/c.GeneralConsents';
import edit from '@salesforce/label/c.GeneralEdit';
import save from '@salesforce/label/c.GeneralSave';
import password from '@salesforce/label/c.GeneralPassword';
import passwordWarning from '@salesforce/label/c.WebshopChangeYourPasswordWarning';
import passwordPlaceholder from '@salesforce/label/c.GeneralPasswordPlaceholder';
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import url from '@salesforce/label/c.WebshopDoNotTranslateUrl';

export default class WebshopMySettings extends LightningElement {  
    @track accountId;
    @track language;
    @track originalLanguage;
    @track timezone;
    @track firstName;
    @track lastName;
    @track mobile;
    @track phone;
    @track email;
    @track optOut;
    @track abandonedCart;
    @track userdata;
    @track userId;
    @track contactId;
    @track password = '';
    @track isLoading = false;
    @track passwordDisabled = false;

    @track editModePersonal = false;
    @track editModeSecurity = false;
    @track editModeSettings = false;
    @track editModeConsents = false;

    @track showPersonalSection = true;
    @track showSecuritySection = false;
    @track showSettingsSection = false;
    @track showConsentsSection = false;
    @track activeSection = 'personal'; // Default active section

    label = {
        backToShop,
        settingsHeader,
        settingsSubHeader,
        personal,
        accountSecurity,
        settings,
        consents,
        edit,
        save,
        password,
        passwordWarning,
        passwordPlaceholder,
        generalError,
        generalErrorMsg,
        url
    }

    resetEditMode(){
        this.editModePersonal = false;
        this.editModeSecurity = false;
        this.editModeSettings = false;
        this.editModeConsents = false;
    }

    handleClickBackToShop(){
        window.location.assign('/');
    }

    handleEditPersonal(){       
        this.editModePersonal = true;
    }
    handleEditSecurity(){       
        this.editModeSecurity = true;
    }
    handleEditSettings(){       
        this.editModeSettings = true;
    }
    handleEditConsents(){       
        this.editModeConsents = true;
    }

    handleShowPersonalSection(){
        this.activeSection = 'personal';
        this.showPersonalSection = true;
        this.showSecuritySection = false;
        this.showSettingsSection = false;
        this.showConsentsSection = false;
        this.resetEditMode();
    }
    handleShowSecuritySection(){
        this.activeSection = 'security';
        this.showPersonalSection = false;
        this.showSecuritySection = true;
        this.showSettingsSection = false;
        this.showConsentsSection = false;
        this.resetEditMode();
    }
    handleShowSettingsSection(){
        this.activeSection = 'settings';
        this.showPersonalSection = false;
        this.showSecuritySection = false;
        this.showSettingsSection = true;
        this.showConsentsSection = false;
        this.resetEditMode();
    }
    handleShowConsentsSection(){
        this.activeSection = 'consents';
        this.showPersonalSection = false;
        this.showSecuritySection = false;
        this.showSettingsSection = false;
        this.showConsentsSection = true;
        this.resetEditMode();
    }

    get getPersonalClass() {
        return this.activeSection === 'personal' ? 'section-active me-1 py-2 px-3' : 'my-settings-section me-1 py-2 px-3';
    }
    
    get getSecurityClass() {
        return this.activeSection === 'security' ? 'section-active me-1 py-2 px-3' : 'my-settings-section me-1 py-2 px-3';
    }
    
    get getSettingsClass() {
        return this.activeSection === 'settings' ? 'section-active me-1 py-2 px-3' : 'my-settings-section me-1 py-2 px-3';
    }
    
    get getConsentsClass() {
        return this.activeSection === 'consents' ? 'section-active me-1 py-2 px-3' : 'my-settings-section me-1 py-2 px-3';
    }
    

    connectedCallback() {
        this.isLoading = true;
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext?.effectiveAccountId;
                this.getCurrentUserInfo();
            } else {
                this.isLoading = false;
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

    getCurrentUserInfo(){
        getCurrentUserInfo({})
        .then(result => {
            if(result != null){
                this.userdata = result;
                this.userId = result.Id;
                this.contactId = result.ContactId;
                this.language = result.LanguageLocaleKey;
                this.originalLanguage = result.LanguageLocaleKey;
                this.timezone = result.TimeZoneSidKey;
                this.firstName = result.FirstName;
                this.lastName = result.LastName;
                this.email = result.Email;
                this.phone = result.Phone;
                this.mobile = result.MobilePhone;
                this.optOut = result.Contact?.DoubleOptinRequested__c;
                this.abandonedCart = result.Contact?.DoubleOptInAbandonedCart__c;
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
    }

    toggleEditMode(){
        this.editMode = !this.editMode;
    }

    handleChangeLanguage(event){
        this.language = event.target.value;
    }

    handleChangeTimezone(event){
        this.timezone = event.target.value;
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

    handleChangeMobile(event){
        this.mobile = event.target.value;
    }

    handleChangeNewsletter(event){
        this.optOut = event.target.checked;
    }

    handleChangePassword(event){
        this.password = event.detail;
        this.passwordDisabled = !stringIsNotBlank(this.password);
    }

    handleChangeAbandonedCart(event){
        this.abandonedCart = event.target.value;
    }

    handleSavePersonal(){
        this.isLoading = true;
        this.resetEditMode();
        setPersonal({
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email, 
            mobile: this.mobile  , 
            phone: this.phone  
        }).then(result => {
            if(result == true){
                this.getCurrentUserInfo();
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
    handleSaveConsents(){
        this.isLoading = true;
        this.resetEditMode();
        setConsents({
            optOut: this.optOut,
            abandonedCart: this.abandonedCart    
        }).then(result => {
            if(result == true){
                this.getCurrentUserInfo();
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
    handleSavePassword(){
        this.isLoading = true;
        this.resetEditMode();
        setPassword({
            password: this.password    
        }).then(result => {
            if(result == true){
                this.getCurrentUserInfo();
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
    handleSaveSettings(){
        this.isLoading = true;
        this.resetEditMode();
        setCurrentUserInfo({
            language: this.language,
             timezone: this.timezone    
        }).then(result => {
            if(result == true){
                if(this.language != this.originalLanguage){
                    let originalLanguageString = '/' + this.originalLanguage.replace('_', '-') + '/';
                    let languageString = '/' + this.language.replace('_', '-') + '/';
                    if(window.location.href.includes(originalLanguageString)){
                        let locationString = window.location.href.replace(originalLanguageString, languageString);
                        window.location.replace(locationString);
                    } else {
                        let locationString = window.location.href.replace(this.label.url + '/', this.label.url + languageString);
                        window.location.replace(locationString);
                    }
                } else {
                    this.getCurrentUserInfo();
                }
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