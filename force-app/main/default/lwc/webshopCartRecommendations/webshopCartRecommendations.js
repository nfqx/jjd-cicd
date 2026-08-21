import { LightningElement, track, api } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Commerce API
import { getSessionContext } from 'commerce/contextApi';

// LABELS
import recommendedProducts from '@salesforce/label/c.WebshopRecommendedProducts';

export default class WebshopCartRecommendations extends LightningElement {
    @track accountId;
    @track hasData = false;

    label = {
        recommendedProducts
    };

    connectedCallback() {
        loadStyle(this, webshopStyle);
        loadStyle(this, BOOTSTRAP);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.accountId = sessionContext.effectiveAccountId;
            }
        });
    }

    showHeading(){
        this.hasData = true;
    }
}