import { LightningElement, api } from 'lwc';

export default class DatatableEditPicklist extends LightningElement {
    @api rowId;
    @api value;
    @api picklist = [];
    @api field;

    handleChange(event) {
        this.dispatchEvent(new CustomEvent('changerow', {
            detail: {
                rowid: this.rowId,
                field: this.field,
                value: event.detail.value
            },
            bubbles: true,
            composed: true
        }));
    }
}