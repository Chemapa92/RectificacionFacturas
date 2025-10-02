import { LightningElement, api } from 'lwc';
import cloneOrder from '@salesforce/apex/OrderCustomCloneService.cloneOrder';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class CloneOrderCustomAction extends NavigationMixin(LightningElement) {
  @api recordId;

  connectedCallback() { 
    this.doClone(); 
  }

  async doClone() {
    try {
      const res = await cloneOrder({ orderId: this.recordId });
      if (res?.errorMessage) {
        this.toast('Error al clonar', res.errorMessage, 'error');
      } else if (res?.newOrderId) {
        this.toast('Pedido clonado', 'Redirigiendo al nuevo pedido…', 'success');
        this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: {
            recordId: res.newOrderId,
            objectApiName: 'Order__c',
            actionName: 'view'
          }
        });
      } else {
        this.toast('Error', 'Respuesta no válida del servidor.', 'error');
      }
    } catch (e) {
      const msg = e?.body?.message || e?.message || 'Error desconocido.';
      this.toast('Error al clonar', msg, 'error');
    } finally {
      this.dispatchEvent(new CloseActionScreenEvent());
    }
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}