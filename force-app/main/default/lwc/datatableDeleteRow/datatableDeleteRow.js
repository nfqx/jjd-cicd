import { LightningElement, api } from 'lwc';

export default class DatatableDeleteRow extends LightningElement {
    @api rowId;
    handleDelete(){   
        let event = new CustomEvent('deleterow', {
            detail: { 
                rowid : this.rowId
            },
            composed: true,
            bubbles: true
        });
        this.dispatchEvent(event);
    } 
}