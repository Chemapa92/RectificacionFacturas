/**
 * ╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
 * ║ @name        : CustomEmailController                                                                                                  ║
 * ║ @version     : 1.0                                                                                                                    ║
 * ║ @creation    : 21-05-2025                                                                                                             ║
 * ║ @author      : nikolay.romanyuk@horizon-cx.com                                                                                        ║
 * ╠═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
 * ║ @description :                                                                                                                        ║
 * ║   Controller class to manage email templates and attachments for Opportunity and Order__c records.                                    ║
 * ║                                                                                                                                       ║
 * ║   This class provides methods to:                                                                                                     ║
 * ║   - Load and parse Lightning email templates using data from related records.                                                         ║
 * ║   - Retrieve and present attached documents via ContentDocumentLink.                                                                  ║
 * ║   - Send emails with optional file attachments using the Messaging framework.                                                         ║
 * ║                                                                                                                                       ║
 * ║   It includes reusable utility methods for:                                                                                           ║
 * ║   - Fetching templates by developer name.                                                                                             ║
 * ║   - Obtaining the latest version of attached documents.                                                                               ║
 * ║   - Building email file attachments from ContentVersion data.                                                                         ║
 * ║                                                                                                                                       ║
 * ║   Designed for use in Lightning Web Components, this class supports modular and scalable                                              ║
 * ║   email handling with proper error management and reusable wrappers.                                                                  ║
 * ╠═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
 * ║ @changeLog   :                                                                                                                        ║
 * ║   21-05-2025 - Initial version                                                                                                        ║
 * ╚═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
 */
public with sharing class CustomEmailController {
    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : loadOpportunityTemplate                                                                                             ║
    * ║ @description : Loads and parses a Lightning email template for an Opportunity record.                                              ║
    * ║                 Replaces placeholders with Opportunity data and returns parsed subject, body and recipient address.                ║
    * ║ @param         opportunityId (Id) → Id of the Opportunity to be used in the template                                               ║
    * ║ @return      : EmailTemplateWrapper containing subject, body, and toAddress                                                        ║
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    @AuraEnabled
    public static EmailTemplateWrapper loadOpportunityTemplate(Id opportunityId) {
        EmailTemplate template = loadTemplateByDeveloperName(Label.EmailTemplate_Proforma);
        Opportunity opp = getOpportunity(opportunityId);

        String parsedSubject = template.Subject
            .replace('{{{Opportunity.OpportunityNumber__c}}}', opp.OpportunityNumber__c != null ? opp.OpportunityNumber__c : '');

        String parsedBody = template.HtmlValue
            .replace('{{{Opportunity.OpportunityNumber__c}}}', opp.OpportunityNumber__c != null ? opp.OpportunityNumber__c : '')
            .replace('{{{Opportunity.OwnerName__c}}}', opp.Owner.Name)
            .replace('{!Account.Name}', opp.Account != null ? opp.Account.Name : '');

        String toAddress = opp.Account != null
            ? (opp.Account.Parent != null && opp.Account.Parent.Email__c != null
                ? opp.Account.Parent.Email__c
                : opp.Account.Email__c)
            : null;

        // String ccAddress = opp.CreatedBy != null ? opp.CreatedBy.Email : null;
        // List<String> ccAddresses = new List<String>{
        //     opp.CreatedBy != null && String.isNotBlank(opp.CreatedBy.Email) ? opp.CreatedBy.Email : null
        // };
        // ccAddresses.removeAll(new List<String>{null});

        List<String> ccAddresses = new List<String>(); 

        if (opp.CreatedBy != null && String.isNotBlank(opp.CreatedBy.Email)) {
            ccAddresses.add(opp.CreatedBy.Email);
        }


        return new EmailTemplateWrapper(parsedSubject, parsedBody, toAddress, ccAddresses);
    }

    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : loadOrderTemplate                                                                                                   ║
    * ║ @description : Loads and parses a Lightning email template for an Order__c record.                                                 ║
    * ║                 Replaces placeholders with Order__c, Account, Carrier, and OrderItem data.                                         ║
    * ║ @param         orderId (Id) → Id of the Order__c record to be used in the template                                                 ║
    * ║ @return      : EmailTemplateWrapper containing subject, body, and toAddress                                                        ║
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    @AuraEnabled
    public static EmailTemplateWrapper loadOrderTemplate(Id orderId) {
        EmailTemplate template = loadTemplateByDeveloperName(Label.EmailTemplate_OrdenCargaCustom);
        Order__c order = getOrder(orderId);

        String productRows = '';
        Integer totalRows = order.Lineas_de_pedido__r.size();
        Integer currentIndex = 0;
        for (OrderItem__c linea : order.Lineas_de_pedido__r) {
            currentIndex++;
            Boolean isLast = currentIndex == totalRows;
            String borderStyle = 'border:1px solid #432c6c; text-align: center; font-size: 10px;';
            if (isLast) {
                borderStyle += ' border-bottom-left-radius: 10px; border-bottom-right-radius: 10px;';
            }
            productRows += '<tr>';
            productRows += '<td style="' + borderStyle + '">' + linea.ProductDescription__r.Name + '</td>';
            productRows += '<td style="' + borderStyle + '">' + String.valueOf(linea.Quantity__c) + ' L.</td>';
            productRows += '</tr>';
        }
        
        String parsedSubject = template.Subject
            .replace('{{FREIGHT_ORDER}}', String.valueOf(order.FreightOder__c) != null ? order.FreightOder__c : '')
            .replace('{{STORE}}', String.valueOf(order.Store__c));
        
        String parsedBody = template.HtmlValue
            .replace('{{ACCOUNT_NAME}}', order.Account__r != null ? order.Account__r.Name : 'Cliente')
            .replace('{{CARRIER}}', order.Carrier__c != null ? order.Carrier__r.Name : '')
            .replace('{{SHIPPING_ADDRESS}}', order.Account__r?.ShippingStreet != null ? order.Account__r.ShippingStreet : '')
            .replace('{{SHIPPING_CITY}}', order.Account__r?.ShippingCity != null ? order.Account__r.ShippingCity : '')
            .replace('{{STORE}}', String.valueOf(order.Store__c))
            .replace('{{FREIGHT_ORDER}}', order.FreightOder__c != null ? String.valueOf(order.FreightOder__c) : '')
            .replace('{{OWNER_EMAIL}}', order.Owner.Email != null ? String.valueOf(order.Owner.Email) : '')
            .replace('{{PRODUCT_ROWS}}', productRows);

        String toAddress = order.Carrier__r != null ? order.Carrier__r.Email__c : null;

        // String ccAddress = order.CreatedBy != null ? order.CreatedBy.Email : null;

        // List<String> ccAddresses = new List<String>{
        //     order.CreatedBy != null && String.isNotBlank(order.CreatedBy.Email) ? order.CreatedBy.Email : null,
        //     (order.Account__r != null && order.Account__r.ParentId != null && String.isNotBlank(order.Account__r.Parent.Email__c)) ? order.Account__r.Parent.Email__c : null
        // };
        // ccAddresses.removeAll(new List<String>{null});

        List<String> ccAddresses = new List<String>();

        if (order.CreatedBy != null && String.isNotBlank(order.CreatedBy.Email)) {
            ccAddresses.add(order.CreatedBy.Email);
        }

        if (order.Account__r != null && 
            order.Account__r.Parent != null && 
            String.isNotBlank(order.Account__r.Parent.Email__c)) {
            ccAddresses.add(order.Account__r.Parent.Email__c);
        }

        return new EmailTemplateWrapper(parsedSubject, parsedBody, toAddress, ccAddresses);
    }

    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : sendCustomEmail                                                                                                     ║
    * ║ @description : Sends an email with the given subject, body, and attachments from a Lightning component.                            ║
    * ║                 Links the email to a record via WhatId and supports file attachments from ContentDocument.                         ║
    * ║ @param         toAddress → recipient email address                                                                                 ║ 
    * ║ @param         subject → subject of the email                                                                                      ║     
    * ║ @param         body → HTML body content of the email                                                                               ║    
    * ║ @param         whatId → record Id to relate the email to (e.g. Opportunity, Order__c)                                              ║   
    * ║ @param         attachmentIds → ContentDocument Ids to be attached                                                                  ║                                                            
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    @AuraEnabled
    public static void sendCustomEmail(List<String> toAddresses, List<String> ccAddresses, String subject, String body, Id whatId, List<Id> attachmentIds) {
        if (toAddresses.isEmpty() || String.isBlank(subject) || String.isBlank(body) || whatId == null) {
            throw new AuraHandledException('Faltan campos obligatorios para enviar el correo.');
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setCcAddresses(ccAddresses);
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setWhatId(whatId);
        email.setOrgWideEmailAddressId(Label.OrgWideEmailNoreplyId);

        if (attachmentIds != null && !attachmentIds.isEmpty()) {
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            for (Id contentDocumentId : attachmentIds) {
                ContentVersion cv = getLatestVersion(contentDocumentId);
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(cv.Title);
                efa.setBody(cv.VersionData);
                efa.setContentType(getMimeType(cv.FileType));
                attachments.add(efa);
            }
            email.setFileAttachments(attachments);
        }

        Messaging.sendEmail(new List<Messaging.Email>{ email });
    }

    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : getAttachedDocuments                                                                                                ║
    * ║ @description : Retrieves the latest ContentDocument attached to a given Opportunity via ContentDocumentLink.                       ║
    * ║ @param         opportunityId (Id) → Id of the Opportunity                                                                          ║
    * ║ @return      : List<ContentDocumentWrapper> with document ID, title, and latest version Id (max 1 result)                          ║
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    @AuraEnabled
    public static List<ContentDocumentWrapper> getAttachedDocuments(Id opportunityId) {
        if (!hasRequiredPermissions()) {
            return new List<ContentDocumentWrapper>();
        }
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :opportunityId
            ORDER BY ContentDocument.CreatedDate DESC
            LIMIT 1];
        List<ContentDocumentWrapper> result = new List<ContentDocumentWrapper>();
        for (ContentDocumentLink cdl : links) {
            result.add(new ContentDocumentWrapper(
                cdl.ContentDocumentId, 
                cdl.ContentDocument.Title, 
                cdl.ContentDocument.LatestPublishedVersionId
            ));
        }
        return result;
    }

    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : loadTemplateByDeveloperName                                                                                         ║
    * ║ @description : Retrieves a Lightning EmailTemplate by its DeveloperName, verifying access and existence.                           ║
    * ║ @param         developerName (String) → DeveloperName of the EmailTemplate                                                         ║
    * ║ @return      : EmailTemplate                                                                                                       ║
    * ║ @throws        AuraHandledException if template is not found or access is denied                                                   ║
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    private static EmailTemplate loadTemplateByDeveloperName(String developerName) {
        if (!hasRequiredPermissions()) {
            throw new AuraHandledException('Permisos insuficientes para acceder a las plantillas de correo.');
        }
        List<EmailTemplate> templates = [
            SELECT Subject, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
        if (templates.isEmpty()) {
            throw new AuraHandledException('Plantilla de correo no encontrada.');
        }
        return templates[0];
    }

    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : getOpportunity                                                                                                      ║
    * ║ @description : Retrieves Opportunity data used to fill in placeholders in the email template.                                      ║
    * ║ @param         opportunityId (Id) → Id of the Opportunity                                                                          ║
    * ║ @return      : Opportunity record with related Account and Owner                                                                   ║
    * ║ @throws        AuraHandledException if access is denied                                                                            ║
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    private static Opportunity getOpportunity(Id opportunityId) {
        if (!hasRequiredPermissions()) {
            throw new AuraHandledException('Permisos insuficientes para acceder a la oportunidad.');
        }
        Opportunity opportunity = [
            SELECT Id, Name, OpportunityNumber__c, Owner.Name, Account.Name, Account.Email__c, Account.Parent.Email__c, CreatedBy.Email
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        return opportunity;
    }

    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : getOrder                                                                                                            ║
    * ║ @description : Retrieves Order__c data used to fill in placeholders in the email template.                                         ║
    * ║ @param         orderId (Id) → Id of the Order__c                                                                                   ║
    * ║ @return      : Order__c record with Account, Carrier, Owner, and OrderItem__c data                                                 ║
    * ║ @throws        AuraHandledException if access is denied                                                                            ║
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    private static Order__c getOrder(Id orderId) {
        if (!hasRequiredPermissions()) {
            throw new AuraHandledException('Permisos insuficientes para acceder al pedido.');
        }
        Order__c order = [
            SELECT Id, Name, Owner.Name, Owner.Email,
                   Account__r.Name, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.Email__c, Carrier__r.Email__c,
                   Account__r.Parent.Email__c, toLabel(Store__c), FreightOder__c, Carrier__r.Name, CreatedBy.Email,
                   (SELECT ProductDescription__r.Name, TotalAmount__c, Quantity__c FROM Lineas_de_pedido__r)
            FROM Order__c
            WHERE Id = :orderId
            LIMIT 1
        ];
        return order;
    }

    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : getLatestVersion                                                                                                    ║
    * ║ @description : Retrieves the latest ContentVersion from a given ContentDocumentId.                                                 ║
    * ║ @param         contentDocumentId (Id) → Id of the ContentDocument                                                                  ║
    * ║ @return      : ContentVersion with file data                                                                                       ║
    * ║ @throws        AuraHandledException if access is denied                                                                            ║
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    private static ContentVersion getLatestVersion(Id contentDocumentId) {
        if (!hasRequiredPermissions()) {
            throw new AuraHandledException('Permisos insuficientes para acceder a archivos adjuntos.');
        }
        Id latestId = [
            SELECT ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
            LIMIT 1
        ].ContentDocument.LatestPublishedVersionId;

        ContentVersion latestVersion = [
            SELECT Id, VersionData, Title, FileType
            FROM ContentVersion
            WHERE Id = :latestId
            LIMIT 1
        ];
        return latestVersion;
    }

    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : getMimeType                                                                                                         ║
    * ║ @description : Maps file extensions to their corresponding MIME types used in email attachments.                                   ║
    * ║ @param         fileType (String) → file extension (e.g., 'PDF', 'PNG', 'DOCX')                                                     ║
    * ║ @return      : Corresponding MIME type string                                                                                      ║
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    private static String getMimeType(String fileType) {
        Map<String, String> mimeTypes = new Map<String, String>{
            'PDF' => 'application/pdf',
            'PNG' => 'image/png',
            'JPG' => 'image/jpeg',
            'JPEG' => 'image/jpeg',
            'TXT' => 'text/plain',
            'DOCX' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'XLSX' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        };
        return mimeTypes.get(fileType != null ? fileType.toUpperCase() : 'TXT');
    }

    /**
    * ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : hasRequiredPermissions                                                                                              ║
    * ║ @description : Checks if the running user has access to the required objects used in this controller.                              ║
    * ║ @return      : true if access to all sObjects is granted; false otherwise                                                          ║
    * ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
    */
    @TestVisible
    private static Boolean hasRequiredPermissions() {
        return Schema.sObjectType.EmailTemplate.isAccessible() &&
               Schema.sObjectType.ContentVersion.isAccessible() &&
               Schema.sObjectType.ContentDocumentLink.isAccessible() &&
               Schema.sObjectType.Opportunity.isAccessible() &&
               Schema.sObjectType.Order__c.isAccessible() &&
               Schema.sObjectType.OrderItem__c.isAccessible() &&
               Schema.sObjectType.Account.isAccessible();
    }

    /**
    * ╔══════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : EmailTemplateWrapper                                                      ║
    * ║ @description : Data wrapper to encapsulate parsed email template content.                ║
    * ║                                                                                          ║
    * ║ Contains the subject, HTML body, and recipient email address to be used                  ║
    * ║ when displaying or sending a custom email from an LWC component.                         ║
    * ║                                                                                          ║
    * ║ Used as a return type for email template loading methods.                                ║
    * ╚══════════════════════════════════════════════════════════════════════════════════════════╝
    */
    public class EmailTemplateWrapper {
        @AuraEnabled public String subject;
        @AuraEnabled public String body;
        @AuraEnabled public String toAddress;
        @AuraEnabled public List<String> ccAddresses;

        public EmailTemplateWrapper(String subject, String body, String toAddress, List<String> ccAddresses) {
            this.subject = subject;
            this.body = body;
            this.toAddress = toAddress;
            this.ccAddresses = ccAddresses;
        }
    }

    /**
    * ╔══════════════════════════════════════════════════════════════════════════════════════════╗
    * ║ @name        : ContentDocumentWrapper                                                    ║
    * ║ @description : Lightweight wrapper for attached documents linked to a record.            ║
    * ║                                                                                          ║
    * ║ Holds the document ID, title, and latest published version ID.                           ║
    * ║ Used to display attached files in the UI and to track selected attachments for emails.   ║
    * ║                                                                                          ║
    * ║ Typically returned by getAttachedDocuments() and consumed by Lightning components.       ║
    * ╚══════════════════════════════════════════════════════════════════════════════════════════╝
    */
    public class ContentDocumentWrapper {
        @AuraEnabled public String documentId;
        @AuraEnabled public String title;
        @AuraEnabled public String versionId;

        public ContentDocumentWrapper(String documentId, String title, String versionId) {
            this.documentId = documentId;
            this.title = title;
            this.versionId = versionId;
        }
    }
}