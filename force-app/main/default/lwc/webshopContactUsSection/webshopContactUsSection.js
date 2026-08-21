import { LightningElement } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// LABELS
import contactEmail from '@salesforce/label/c.WebshopContactEmail';
import contactPhone from '@salesforce/label/c.WebshopContactPhone';
import contactUsTitle from '@salesforce/label/c.WebshopContactUsTitle';
import contactUsSubtitle from '@salesforce/label/c.WebshopContactUsSubtitle';
import emailUs from '@salesforce/label/c.WebshopContactUsEmailUs';
import emailUsSubtitle from '@salesforce/label/c.WebshopContactUsEmailUsSubtitle';
import phoneUs from '@salesforce/label/c.WebshopContactUsPhoneUs';
import phoneUsSubtitle from '@salesforce/label/c.WebshopContactUsPhoneUsSubtitle';

export default class WebshopContactUsSection extends LightningElement {

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
    }

    label = {
        contactUsTitle,
        contactUsSubtitle,
        emailUs,
        emailUsSubtitle,
        phoneUs,
        phoneUsSubtitle,
        contactEmail,
        contactPhone
    }

    get contactEmailMailto(){
        return 'mailto:' + this.label.contactEmail;
    }
}