import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class InvoiceRectificationAction extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;

    connectedCallback() {
        this.startRectification();
    }

    startRectification() {
        this.isLoading = true;
        
        // Redirigir a la página Visualforce que ya funciona
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/InvoiceRectification?id=' + this.recordId
            }
        });
    }
}