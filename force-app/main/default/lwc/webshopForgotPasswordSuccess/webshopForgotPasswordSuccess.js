import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
// LABELS
import Login from '@salesforce/label/c.WebshopLoginButtonLabel';
import PasswordResetSecces from '@salesforce/label/c.WebshopPasswordResetSuccess';
import PasswordResetSeccesMsg from '@salesforce/label/c.WebshopPasswordResetSuccessMsg';

export default class SuccessPage extends NavigationMixin(LightningElement) {
    
    label = {
        Login,
        PasswordResetSecces,
        PasswordResetSeccesMsg
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
    }
    navigateToLogin() {
        // Navigate to the login page
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/webshopLogin'
            }
        });
    }
}