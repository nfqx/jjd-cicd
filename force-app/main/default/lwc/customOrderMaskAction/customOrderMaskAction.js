import { LightningElement, api } from 'lwc';

export default class CustomOrderMaskAction extends LightningElement {
    @api recordId;
    @api objectApiName;
}