import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import cloneOrder from '@salesforce/apex/OrderCloneController.cloneOrder';

export default class OrderCloneAction extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;

    handleCloneClick() {
        if (this.recordId) {
            this.isLoading = true;
            
            cloneOrder({ originalOrderId: this.recordId })
                .then(result => {
                    this.isLoading = false;
                    
                    // Mostrar mensaje de éxito
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Éxito',
                            message: 'Pedido clonado correctamente. Redirigiendo al nuevo pedido...',
                            variant: 'success'
                        })
                    );
                    
                    // Navegar al nuevo pedido después de un pequeño delay
                    setTimeout(() => {
                        this.navigateToRecord(result);
                    }, 1000);
                })
                .catch(error => {
                    this.isLoading = false;
                    
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        }
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}