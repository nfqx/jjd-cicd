import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getSessionContext } from 'commerce/contextApi';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP_ICONS from '@salesforce/resourceUrl/IconsBootstrap';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';
import { stringIsNotBlank } from 'c/stringHelper';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

// Labels
import generalError from '@salesforce/label/c.WebshopGeneralError';
import generalErrorMsg from '@salesforce/label/c.WebshopGeneralErrorMsg';
import search from '@salesforce/label/c.GeneralSearch';

export default class WebshopSearchMask extends NavigationMixin(LightningElement) {
    @track showSearchMask = false;
    connectedCallback() {
        loadStyle(this, BOOTSTRAP_ICONS);
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
        getSessionContext()
        .then(sessionContext => {
            if(sessionContext && sessionContext.effectiveAccountId && sessionContext.effectiveAccountId != null){
                this.showSearchMask = true;
            }
        })
        .catch(error => {
            setTimeout(() => {this.template.querySelector('c-webshop-toast').toast = {
                title: this.label.generalError,
                message: this.label.generalErrorMsg + ': ' + error,
                variant: 'error',
            };
            this.template.querySelector('c-webshop-toast').show = true;});
        });
    }

    label = {
        search,
        generalError,
        generalErrorMsg
    }

    handleKeypress(event) {
        let searchTerm = event.target.value;
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            this.launchSearch(searchTerm);
        }
    }


    handleInput(event) {
        let searchTerm = event.target.value;
        this.launchSearch(searchTerm);
    }

    launchSearch(searchTerm){
        if(stringIsNotBlank(searchTerm) && searchTerm.length > 2){
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__search',
                state: {
                    term: searchTerm
                }
            })
            .then(url => {
                window.location.replace(url);
            })
        }
    }

    handleSearch() {
        const searchEvent = new CustomEvent('search', {
            detail: this.searchQuery,
        });
        this.dispatchEvent(searchEvent);
    }
}