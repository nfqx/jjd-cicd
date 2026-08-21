import { LightningElement, track } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import LOGO_404 from "@salesforce/resourceUrl/Logo404";

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Labels
import topPicks from '@salesforce/label/c.WebshopDoNotTranslateTopPicks';
import topPicksTranslateable from '@salesforce/label/c.WebshopSliderNameTopPicks';
import firstLine from '@salesforce/label/c.Webshop404FirstLine';
import secondLine from '@salesforce/label/c.Webshop404SecondLine';
import thirdLine from '@salesforce/label/c.Webshop404ThirdLine';

export default class WebshopPageNotFound extends LightningElement {
    @track showSliderHeading = false;

    showHeading(){
        this.showSliderHeading = true;
    }
    
    logo404 = LOGO_404;
    label = {
        firstLine,
        secondLine,
        thirdLine,
        topPicks,
        topPicksTranslateable
    }
    connectedCallback() {
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
    }
}