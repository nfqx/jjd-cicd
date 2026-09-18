import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class ReturnOrderMaskAction extends LightningElement {    
    @api recordId;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.loaded = true;
        }
    }
}