import { LightningElement, wire, track } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { loadStyle, loadScript  } from "lightning/platformResourceLoader";
import { CurrentPageReference } from 'lightning/navigation';
import custommodalcss from "@salesforce/resourceUrl/custommodalcss";
import removeStyle from '@salesforce/resourceUrl/removeStyle';


export default class MachineConfigurator extends LightningElement {
    @track isLoaded = false;
    @track recordId = null;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        loadStyle(this, custommodalcss);
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.isLoaded = true;
        }
    }

    
    closeModal(){
        loadScript(this, removeStyle)
        .then(result => {
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }
    disconnectedCallback(){
        loadScript(this, removeStyle);
    }
}