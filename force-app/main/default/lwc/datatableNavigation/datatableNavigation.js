import LightningDatatable from 'lightning/datatable'
import attachment from './attachment.html'
import badge from './badge.html'
import deleteRow from './deleteRow.html'
import editNum from './editNum.html'
import product from './product.html'
import productSimple from './productSimple.html'
import picklist from './picklist.html'

export default class DatatableNavigationWrapper extends LightningDatatable {
    
    static customTypes = {
        attachment: {
            template: attachment,
            typeAttributes: ['hasAttachment'],
        },
        badge: {
            template: badge,
            typeAttributes: ['value'],
        },
        deleteRow: {
            template: deleteRow,
            typeAttributes: ['rowid'],
        },
        editNum: {
            template: editNum,
            typeAttributes: ['field', 'rowid', 'value', 'digits'],
        },
        productSimple: {
            template: productSimple,
            typeAttributes: ['title', 'subtitle'],
        },
        product: {
            template: product,
            typeAttributes: ['title', 'subtitle', 'productCode', 'origin', 'manual', 'recognized', 'notice'],
        },
        picklist: {
            template: picklist,
            typeAttributes: ['field', 'rowid', 'value', 'picklist'],
        }
    };
}