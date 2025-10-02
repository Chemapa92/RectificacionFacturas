import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import cloneOrder from '@salesforce/apex/OrderCloneController.cloneOrder';
import diagnoseOrderLines from '@salesforce/apex/OrderCloneController.diagnoseOrderLines';

export default class OrderCloneButton extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;
    showDiagnosis = false;
    diagnosisResult = '';

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
                            message: 'Pedido clonado correctamente',
                            variant: 'success'
                        })
                    );
                    
                    // Navegar al nuevo pedido
                    this.navigateToRecord(result);
                })
                .catch(error => {
                    this.isLoading = false;
                    
                    // Mostrar mensaje de error
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

    handleDiagnoseClick() {
        if (this.recordId) {
            this.isLoading = true;
            
            diagnoseOrderLines({ orderId: this.recordId })
                .then(result => {
                    this.isLoading = false;
                    this.diagnosisResult = result;
                    this.showDiagnosis = true;
                })
                .catch(error => {
                    this.isLoading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error en diagnóstico',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        }
    }

    closeDiagnosis() {
        this.showDiagnosis = false;
        this.diagnosisResult = '';
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