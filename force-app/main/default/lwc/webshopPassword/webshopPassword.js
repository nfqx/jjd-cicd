import { LightningElement, track } from 'lwc';
import { stringIsNotBlank } from 'c/stringHelper';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Labels
import password from '@salesforce/label/c.GeneralPassword';
import repeatPassword from '@salesforce/label/c.GeneralRepeatPassword';
import passwordMinCharacters from '@salesforce/label/c.WebshopPasswordMinCharachters';
import passwordCharacters from '@salesforce/label/c.WebshopPasswordCharachters';

export default class WebshopPassword extends LightningElement {
    @track password = '';
    @track repeatPassword = '';

    connectedCallback() {
        loadStyle(this, BOOTSTRAP )
    }

    label = {
        password,
        repeatPassword,
        passwordCharacters,
        passwordMinCharacters
    }
    passwordMeetsRequirements(element){
        if(element.length < 8){ return false; }
        return element.match(/[a-z]/g) && element.match(/[A-Z]/g) && element.match(/[0-9]/g) && element.match(/[^a-zA-Z\d]/g);
    }

    get passwordCorrect(){
        return this.password.length > 0 && this.passwordMeetsRequirements(this.password);
    }
    get passwordIncorrect(){
        return this.password.length > 0 && !this.passwordMeetsRequirements(this.password);
    }
    get passwordRepeatCorrect(){
        return this.repeatPassword.length > 0 && this.password == this.repeatPassword && this.passwordMeetsRequirements(this.repeatPassword);
    }
    get passwordRepeatIncorrect(){
        return this.repeatPassword.length > 0 && (this.password != this.repeatPassword || !this.passwordMeetsRequirements(this.repeatPassword));
    }

    handleChangePassword(event){
        this.password = event.target.value;
        this.handleCheckPasswordSuccess();
    }

    handleChangeRepeatPassword(event){
        this.repeatPassword = event.target.value;
        this.handleCheckPasswordSuccess();
    }

    handleCheckPasswordSuccess(){
        if(this.passwordCorrect && this.passwordRepeatCorrect){
            const pwdEvent = new CustomEvent('changepassword', {
                detail: this.password,
            });
            this.dispatchEvent(pwdEvent);
        }
    }
}