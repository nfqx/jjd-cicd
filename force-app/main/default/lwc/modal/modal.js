import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
/******************
 * CUSTOM LABELS
 ******************/

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

export default class Modal extends LightningElement {

    connectedCallback() {
        loadStyle(this, webshopStyle);
    }

    @api name;// Hold the name for the modal window to query it with querySelector
    @api wide = false;
    /*****************************
     * PRIVATE REACTIVE PROPERTIES
     *****************************/
    @track _show = false;
    @track showTagline = false;
    @track noHeader = false;
    @track noFooter = false;

    /*****************************
     * PUBLIC GETTER / SETTER
     *****************************/
    @api
    close(){
        this._show = false;

        this.dispatchEvent(new CustomEvent('close'));
    }

    @api
    open(){
        this._show = true;
    }

    /*****************************
     * PUBLIC GETTER / SETTER & TEMPLATE
     *****************************/
    @api
    get show(){
        return this._show;
    }

    set show(value){
        this._show = value;
    }

    /******************
     * TEMPLATE
     ******************/


    /**
     * Return the actual status if modal is opened or closed. 
     */
    get show()
    {
        return this._show;
    }

    get modalClasses(){
        let classes = this.wide ? 'slds-modal slds-fade-in-open slds-modal_medium' : 'slds-modal slds-fade-in-open';
        return this.show ? classes : classes + ' slds-hide';
    }

    /******************
     * EVENT HANDLER
     ******************/
    handleTaglineChange(event){
        this.showTagline = true;
    }

    handleCloseClickHandler(event){
        this.close();
    }

    // Is trigger from child component in body of c-modal
    handleFooterChange(event)
    {
        console.log('>>>BEGIN: Modal -- handleFooterChange.')
        console.log('>>>event.detail: ' + JSON.stringify(event.detail, null, '\t'));

        //this.querySelector('lightning-button[name=')
        console.log('>>>END: Modal -- handleFooterChange.')
    }

    //Set margin only if a tagline is set.
    //https://salesforce.stackexchange.com/questions/260305/lwc-check-if-slot-is-empty?rq=1
    get taglineClass(){
        return (this.showTagline ? 'slds-m-top_x-small' : '');
    }
}