import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Labels
import home from '@salesforce/label/c.GeneralHome';
import myProducts from '@salesforce/label/c.WebshopMyProducts';

export default class WebshopMyProducts extends NavigationMixin(LightningElement)  {
    label = {
        home,
        myProducts
    };

    @track dataLoaded = false;
    @track showSliderHeading = false;

    showHeading(){
        this.showSliderHeading = true;
    }
    
    connectedCallback(){
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        this.recordId = window.location.href.split("=").pop();
    }

    handleClickHome(){
        window.location.assign('/');
    }
}