import { LightningElement, track } from 'lwc';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Labels
import topPicks from '@salesforce/label/c.WebshopDoNotTranslateTopPicks';
import topPicksTranslateable from '@salesforce/label/c.WebshopSliderNameTopPicks';
import noMatches from '@salesforce/label/c.WebshopSearchResultsNoMatches';
import tips from '@salesforce/label/c.WebshopSearchResultsTips';
import needMoreHelp from '@salesforce/label/c.WebshopSearchResultsNeedMoreHelp';
import email from '@salesforce/label/c.GeneralEmail';
import callUs from '@salesforce/label/c.GeneralCallUsAt';
import contactEmail from '@salesforce/label/c.WebshopContactEmail';
import contactPhone from '@salesforce/label/c.WebshopContactPhone';
import searchResultsFor from '@salesforce/label/c.WebshopSearchResultsFor';

import { stringIsNotBlank } from 'c/stringHelper';

export default class WebshopSearchResults extends LightningElement {
    @track searchTerm;
    @track showSlider;
    @track noData = false;
    @track showSliderHeading = false;

    label = {
        topPicks,
        topPicksTranslateable,
        noMatches,
        tips,
        needMoreHelp,
        email,
        callUs,
        contactEmail,
        contactPhone,
        searchResultsFor
    };

    connectedCallback() {
        loadStyle(this, BOOTSTRAP );
        loadStyle(this, webshopStyle);
        let searchTerm = window.location.href.split("/").pop();
        this.searchTerm = stringIsNotBlank(searchTerm) ? decodeURI(searchTerm) : '';
        this.showSlider = this.searchTerm && this.searchTerm != null && this.searchTerm.length > 0;
        let self = this;
        setTimeout(function (){
            document.title = self.label.searchResultsFor + ' "' + self.searchTerm + '"';
        }, 500);
    }
    handleHasData(event){
        this.noData = false;
    }
    handleNoData(event){
        this.noData = true;
    }

    get contactEmailMailto(){
        return 'mailto:' + this.label.contactEmail;
    }

    showHeading(){
        this.showSliderHeading = true;
    }

}