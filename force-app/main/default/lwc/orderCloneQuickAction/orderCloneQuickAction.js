import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import cloneOrderWithLines from '@salesforce/apex/OrderCloneQuickActionController.cloneOrderWithLines';

export default class OrderCloneQuickAction extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;

    /**
     * Maneja el clic del botón de clonar
     */
    async handleCloneClick() {
        if (!this.recordId) {
            this.showToast('Error', 'No se encontró el ID del pedido', 'error');
            return;
        }

        this.isLoading = true;

        try {
            const result = await cloneOrderWithLines({ originalOrderId: this.recordId });
            
            if (result.success) {
                this.showToast(
                    'Éxito', 
                    `Pedido clonado exitosamente. ${result.clonedLinesCount} líneas copiadas.`, 
                    'success'
                );
                
                // Navegar al nuevo pedido
                this.navigateToRecord(result.clonedOrderId);
            } else {
                this.showToast('Error', result.message || 'Error desconocido al clonar', 'error');
            }
        } catch (error) {
            console.error('Error clonando pedido:', error);
            this.showToast('Error', error.body?.message || error.message || 'Error al clonar el pedido', 'error');
        } finally {
            this.isLoading = false;
            // Cerrar el modal de la Quick Action
            this.closeQuickAction();
        }
    }

    /**
     * Maneja el clic del botón de cancelar
     */
    handleCancelClick() {
        this.closeQuickAction();
    }

    /**
     * Muestra un toast con el mensaje especificado
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

    /**
     * Navega al registro especificado
     */
    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    /**
     * Cierra la Quick Action modal
     */
    closeQuickAction() {
        // Disparar evento para cerrar el modal
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}