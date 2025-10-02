import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import loadTemplate from '@salesforce/apex/CustomEmailController.loadOrderTemplate';
import sendCustomEmail from '@salesforce/apex/CustomEmailController.sendCustomEmail';

export default class SendCustomEmailOrdenCarga extends NavigationMixin(LightningElement) {

    toAddress = '';
    subject = '';
    body = '';
    ccAddressesString = '';
    ccAddresses = [];
    isLoading = false;
    @api isQuickAction;

    _recordId;
    _hasLoaded = false;

    @api
    set recordId(value) {
        this._recordId = value;
        if (this._recordId && !this._hasLoaded) {
            this._hasLoaded = true;
            this.initData();
        }
    }

    get recordId() {
        return this._recordId;
    }
    get ccAddressesString() {
        return this.ccAddresses.join('; ');
    }

    initData() {
        this.isLoading = true;
        loadTemplate({ orderId: this.recordId })
            .then(result => {
                this.toAddress = result.toAddress;
                this.ccAddresses = result.ccAddresses || [];
                this.ccAddressesString = this.ccAddresses.join('; ');
                this.subject = result.subject;
                this.body = result.body;
            })
            .catch(error => {
                this.showToast('Error al cargar plantilla', error.body?.message || 'Error desconocido', 'error');
            })
            .finally(() => {
            this.isLoading = false;
            });
    }
                
    handleToChange(event) {
        this.toAddress = event.detail.value;
    }

    handleCcChange(event) {
        this.ccAddressesString = event.detail.value;
        this.ccAddresses = this.ccAddressesString.split(';').map(addr => addr.trim()).filter(addr => addr);
    }

    handleSubjectChange(event) {
        this.subject = event.detail.value;
    }

    handleBodyChange(event) {
        this.body = event.detail.value;
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    sendEmail() {
        if (!this.toAddress || !this.subject || !this.body) {
            this.showToast('Campos incompletos', 'Por favor, completa todos los campos obligatorios: Para, Asunto y Mensaje.', 'warning');
            return;
        }

        const toList = this.toAddress.split(';').map(addr => addr.trim()).filter(addr => addr);
        const ccList = this.ccAddress ? this.ccAddress.split(';').map(addr => addr.trim()).filter(addr => addr) : [];

        const invalidTo = toList.find(addr => !this.isValidEmail(addr));
        const invalidCc = ccList.find(addr => !this.isValidEmail(addr));

        if (invalidTo || invalidCc) {
            this.showToast('Correo inválido', 'Introduce una dirección válida. ${invalidTo || invalidCc}`', 'error');
            return;
        }

        this.isLoading = true;

        sendCustomEmail({
            toAddresses: toList,
            ccAddresses: this.ccAddresses,
            subject: this.subject,
            body: this.body,
            whatId: this.recordId
        })
        .then(() => {
            this.showToast('Correo enviado', 'El correo ha sido enviado correctamente.', 'success');
            const runAsQuickAction = (this.isQuickAction !== undefined)
                ? this.isQuickAction
                : this.isInQuickActionContext();

            if (runAsQuickAction) {
                console.log('Cerrando Quick Action');
                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                console.log('Lanzando evento al padre para cerrar el LWC');
                this.dispatchEvent(new CustomEvent('closeemailpanel'));
            }
        })
        .catch(error => {
            console.error('ERROR AL ENVIAR EMAIL:', error);
            this.showToast('Error al enviar', error.body?.message || 'Error desconocido', 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
        
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    isInQuickActionContext() {
        try {
            new CloseActionScreenEvent();
            return true;
        } catch (e) {
            return false;
        }
    }
}