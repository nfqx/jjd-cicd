import { LightningElement, track } from 'lwc';

export default class WebshopOnboarding extends LightningElement {
    @track accountValue;
    @track hashValue;
    connectedCallback() {
        const params = new URLSearchParams(window.location.search);
        this.accountValue = params.get('account');
        this.hashValue = params.get('hash');
    }
}