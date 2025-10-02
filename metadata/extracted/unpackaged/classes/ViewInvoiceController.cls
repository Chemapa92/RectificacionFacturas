public with sharing class ViewInvoiceController {
    @AuraEnabled
    public static String getInvoiceName(String recordId){
        String invoiceName = 'Factura';
        List<Invoice__c> lInvoice = [SELECT Id, Name FROM Invoice__c WHERE id = :recordId];
        if(lInvoice != null && !lInvoice.isEmpty()){
            invoiceName += ' ' + lInvoice.get(0).Name;
        }
        invoiceName += ' ' + Date.today().day() + '/' + Date.today().month() + '/' + Date.today().year(); 
        return invoiceName;
    }
}