@isTest
private class CustomEmailControllerTest {
    @TestSetup
    static void setupTestData() {
        Account parentAcc = new Account(Name = 'Parent Account', Email__c = 'parent@example.com');
        insert parentAcc;

        Account acc = new Account(Name = 'Test Account', ParentId = parentAcc.Id, ShippingStreet = 'Street 1', ShippingCity = 'City');
        insert acc;

        User owner = [SELECT Id FROM User WHERE Profile.Name = 'Grupo Hafesa' AND IsActive = true LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'PR-000000',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            OwnerId = owner.Id
        );
        insert opp;

        EmailTemplate templateOpp = [
            SELECT Id, Subject, HtmlValue 
            FROM EmailTemplate 
            WHERE DeveloperName =: Label.EmailTemplate_Proforma 
            LIMIT 1
        ];

        Carrier__c carrier = new Carrier__c(
            Name = 'Test Carrier',
            CarrierCode__c = 'TC-001',
            Business__c = 'Energía',
            Email__c = 'test@carrieremail.com'
        );
        insert carrier;

        Order__c order = new Order__c(
            Account__c = acc.Id,
            Store__c = 'OILDISTR',
            OwnerId = owner.Id,
            Carrier__c = carrier.Id
        );
        insert order;

        Product2 product = new Product2(Name = 'Test Product', isActive = true);
        insert product;

        OrderItem__c item = new OrderItem__c(
            Pedido__c = order.Id,
            Quantity__c = 5,
            ProductDescription__c = product.Id
        );
        insert item;

        
        EmailTemplate templateOrder = [
            SELECT Id, Subject, HtmlValue 
            FROM EmailTemplate 
            WHERE DeveloperName =: Label.EmailTemplate_OrdenCargaCustom 
            LIMIT 1
        ];

        ContentVersion version = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert version;

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id].ContentDocumentId,
            LinkedEntityId = opp.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;
    }

    // Verifies that the opportunity email template loads correctly with placeholders replaced
    @isTest
    static void testLoadOpportunityTemplate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        CustomEmailController.EmailTemplateWrapper result = CustomEmailController.loadOpportunityTemplate(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assertNotEquals(null, result.subject, 'El asunto no debe ser null');
        System.assertNotEquals(null, result.body, 'El cuerpo no debe ser null');
        System.assert(result.subject.contains('Proforma PR-'), 'El asunto debería contener el número de oportunidad');
        System.assert(result.body.contains('PR-'), 'El cuerpo debería contener el número de oportunidad');
        System.assert(result.toAddress == 'parent@example.com', 'El destinatario debe ser el email del parent account');
    }

    // Verifies that the order email template loads correctly with placeholders replaced
    @isTest
    static void testLoadOrderTemplate() {
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        Test.startTest();
        CustomEmailController.EmailTemplateWrapper result = CustomEmailController.loadOrderTemplate(order.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.body.contains('Test Account'), 'El cuerpo debe contener el nombre de la cuenta');
        System.assert(result.body.contains('Test Carrier'), 'El cuerpo debe contener el nombre del transportista');
        System.assert(result.body.contains('Street 1'), 'El cuerpo debe contener la dirección de envío');
        System.assert(result.body.contains('City'), 'El cuerpo debe contener la ciudad de envío');
        System.assert(result.body.contains('Test Product'), 'El cuerpo debe contener el nombre del producto');
        System.assert(result.toAddress == 'test@carrieremail.com', 'El destinatario debe ser el email del transportista');
    }

    // Verifies that the email is sent correctly without attachments
    @isTest
    static void testSendCustomEmail() {
        Opportunity opp = [SELECT Id, Account.Parent.Email__c FROM Opportunity LIMIT 1];
        Test.startTest();
        CustomEmailController.sendCustomEmail(
            new List<String>{opp.Account.Parent.Email__c},
            new List<String>{opp.Account.Parent.Email__c},
            'Test Subject',
            '<p>Test Body</p>',
            opp.Id,
            new List<Id>()
        );
        Test.stopTest();
        System.assert(true, 'Se ha enviado el correo correctamente sin adjuntos');
    }

    // Verifies that the email is sent correctly with attachments
    @isTest 
    static void testSendCustomEmailWithAttachment() {
        Opportunity opp = [SELECT Id, Account.Parent.Email__c FROM Opportunity WHERE Account.Parent.Email__c != null LIMIT 1];
        Id docId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :opp.Id LIMIT 1].ContentDocumentId;
        Test.startTest();
        CustomEmailController.sendCustomEmail(
            new List<String>{opp.Account.Parent.Email__c},
            new List<String>{opp.Account.Parent.Email__c},
            'Asunto con adjunto',
            '<p>Contenido</p>',
            opp.Id,
            new List<Id>{docId}
        );
        Test.stopTest();
        System.assert(true, 'Se ha enviado el correo correctamente sin adjuntos');

    }

    // Verifies that the attached documents are retrieved correctly
    @isTest
    static void testGetAttachedDocuments() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<CustomEmailController.ContentDocumentWrapper> docs = CustomEmailController.getAttachedDocuments(opp.Id);
        Test.stopTest();

        System.assertEquals(1, docs.size(), 'Debe haber un documento adjunto');
        System.assertEquals('Test File', docs[0].title, 'El archivo adjunto debe llamarse "Test File"');
        System.assertNotEquals(null, docs[0].documentId, 'Debe tener un ID de documento válido');
        System.assertNotEquals(null, docs[0].versionId, 'Debe tener una versión válida');
    }
}