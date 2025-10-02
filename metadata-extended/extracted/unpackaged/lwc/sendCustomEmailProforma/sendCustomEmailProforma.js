import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import loadTemplate from '@salesforce/apex/CustomEmailController.loadOpportunityTemplate';
import sendCustomEmail from '@salesforce/apex/CustomEmailController.sendCustomEmail';
import getAttachedDocuments from '@salesforce/apex/CustomEmailController.getAttachedDocuments';

export default class SendCustomEmailProforma extends NavigationMixin(LightningElement) {
    
    toAddress = '';
    subject = '';
    body = '';
    ccAddressesString = '';
    ccAddresses = [];
    attachmentIds = [];
    attachedFiles = [];
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

        Promise.all([
            loadTemplate({ opportunityId: this.recordId }),
            getAttachedDocuments({ opportunityId: this.recordId })
        ])
            .then(([template, files]) => {
                this.toAddress = template.toAddress;
                this.ccAddresses = template.ccAddresses || [];
                this.ccAddressesString = this.ccAddresses.join('; ');
                this.subject = template.subject;
                this.body = template.body;
                this.attachedFiles = files;
                this.attachmentIds = files.map(f => f.documentId);
            })
            .catch(error => {
                this.showToast('Error al cargar datos', error.body?.message || 'Error desconocido', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
        
    get pdfList() {
        return this.attachedFiles
            .filter(file => file.versionId)
            .map(file => ({
                title: file.title,
                versionId: file.versionId,
                documentId: file.documentId
            }));
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

    handleUploadFinished(event) {
        getAttachedDocuments({ opportunityId: this.recordId })
            .then(files => {
                this.attachedFiles = files;
                this.attachmentIds = files.map(f => f.documentId);
                this.showToast('Archivo subido', 'El archivo se ha subido correctamente.', 'success');
            })
            .catch(error => {
                console.error('Error al recargar archivos después del upload:', error);
                this.showToast('Error', 'No se pudieron cargar los archivos nuevos.', 'error');
            });
    }

    handlePreviewClick(event) {
        const documentId = event.currentTarget.dataset.documentId;

        if (!documentId) {
            this.showToast('Error de vista previa', 'No se puede mostrar el archivo. ID de documento no disponible.', 'error');
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: documentId
            }
        });
    }

    removeAttachment(event) {
        const versionIdToRemove = event.currentTarget.dataset.versionId;
        const fileToRemove = this.attachedFiles.find(file => file.versionId === versionIdToRemove);
        if (fileToRemove) {
            this.attachedFiles = this.attachedFiles.filter(file => file.versionId !== versionIdToRemove);
            this.attachmentIds = this.attachmentIds.filter(id => id !== fileToRemove.documentId);
            this.showToast('Archivo eliminado', `${fileToRemove.title} ha sido eliminado del correo.`, 'info');
        }
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    sendEmail() {
        if (!this.toAddress || !this.subject || !this.body || this.attachedFiles.length === 0) {
            this.showToast('Datos incompletos', 'Por favor, completa todos los datos obligatorios: Para, Asunto, Mensaje o Adjunto.', 'warning');
            return; // No continúa si hay errores
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
            whatId: this.recordId,
            attachmentIds: this.attachmentIds
        })
        .then(() => {
            this.showToast('Correo enviado', 'El correo ha sido enviado correctamente.', 'success');
            const runAsQuickAction = (this.isQuickAction !== undefined)
                ? this.isQuickAction
                : this.isInQuickActionContext(); // fallback dinámico

            if (runAsQuickAction) {
                console.log('Cerrando Quick Action');
                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                console.log('Lanzando evento al padre para cerrar el LWC');
                this.dispatchEvent(new CustomEvent('closeemailpanel'));
            }
        })
        .catch(error => {
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