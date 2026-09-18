import { LightningElement, api } from 'lwc';

export default class DatatableEditNum extends LightningElement {
    @api rowId;
    @api value;
    @api digits = 0;
    @api field;

    get step() {
        return 10 ** -Number(this.digits);
    }

    handleChange(event) {
        const input = event.target;
        if (!input.checkValidity()) return;

        const rawValue = input.value;

        this.dispatchEvent(new CustomEvent('changerow', {
            detail: {
                rowid: this.rowId,
                field: this.field,
                value: rawValue === '' ? null : Number(rawValue)
            },
            bubbles: true,
            composed: true
        }));
    }
}