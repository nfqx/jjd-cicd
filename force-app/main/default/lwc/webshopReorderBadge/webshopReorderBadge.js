import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Labels
import badgeText from '@salesforce/label/c.WebshopReorderBadgeText';
import viewCart from '@salesforce/label/c.WebshopReorderBadgeViewCart';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

export default class WebshopReorderBadge extends NavigationMixin(LightningElement) {
    label = {
        badgeText,
        viewCart
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
    }

    handleClickViewCart(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Current_Cart',
            }
        });
    }
}