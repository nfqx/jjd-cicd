import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';


// CUSTOM LABELS
import YourCompanyDetails from '@salesforce/label/c.WebshopYourCompanyDetails';
import AccountNumber from '@salesforce/label/c.GeneralAccountNumber';
import CompanyDetails from '@salesforce/label/c.GeneralCompanyDetails';
import PersonalDetails from '@salesforce/label/c.GeneralPersonalDetails';
import CompanyDetailsMsg from '@salesforce/label/c.WebshopCompanyDetailsMsg';
import NextLabel from '@salesforce/label/c.GeneralNextLabel';

export default class WebshopRegisterData extends NavigationMixin(LightningElement) {
    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
    }

    label = {
        YourCompanyDetails,
        AccountNumber,
        CompanyDetails,
        PersonalDetails,
        CompanyDetailsMsg,
        NextLabel
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = this.template.querySelectorAll('input');
        const data = Array.from(fields).reduce((acc, field) => {
            acc[field.id] = field.value;
            return acc;
        }, {});
        console.log('Company details:', data);
        // Add your form submission logic here
        // Navigate to the next page
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__personalDetails'
            }
        });
    }

    handleBack() {
        // Navigate to the previous page
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__registerPage'
            }
        });
    }
}