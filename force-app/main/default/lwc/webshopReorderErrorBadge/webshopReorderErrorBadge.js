import { LightningElement, api } from 'lwc';

// Labels
import couldNotAddToCart from '@salesforce/label/c.WebshopReorderCouldNotAddToCart';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

export default class WebshopReorderBadge extends LightningElement {
    @api products;

    label = {
        couldNotAddToCart
    }

    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
    }
}