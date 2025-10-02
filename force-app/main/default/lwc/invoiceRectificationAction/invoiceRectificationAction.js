import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import createRectifyingOrder from '@salesforce/apex/OrderRectificationController.createRectifyingOrder';

export default class InvoiceRectificationAction extends LightningElement {
  @api recordId;

  connectedCallback() {
    // Dispara en segundo plano
    createRectifyingOrder({ invoiceId: this.recordId })
      .then(() => {
        this.dispatchEvent(new CloseActionScreenEvent());
      })
      .catch(() => {
        // Cierra igual; si quieres, añade a futuro un toast silencioso
        this.dispatchEvent(new CloseActionScreenEvent());
      });
  }
}