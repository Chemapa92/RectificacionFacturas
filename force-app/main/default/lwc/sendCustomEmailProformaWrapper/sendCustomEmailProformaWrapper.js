import { LightningElement, wire} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

export default class SendCustomEmailProformaWrapper extends NavigationMixin(LightningElement) {
    recordId;
    mostrarEmailPanel = true;
    isQuickAction = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
            console.log('recordId vía CurrentPageReference:', this.recordId);
        }
    }
    
    handleCloseEmailPanel() {
        this.mostrarEmailPanel = false;
        console.log('Panel ocultado desde evento hijo');

    }

    handleGoBack() {
        window.history.back();
    }
}