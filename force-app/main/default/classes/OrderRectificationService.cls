public class OrderRectificationService implements Queueable, Database.AllowsCallouts {

    public Id invoiceId;

    public OrderRectificationService(Id invoiceId) {
        this.invoiceId = invoiceId;
    }

    public void execute(QueueableContext qc) {
        // 1) Traer la invoice con el pedido original
        Invoice__c inv = [
            SELECT Id, Name, Order__c
            FROM Invoice__c
            WHERE Id = :invoiceId
            LIMIT 1
        ];
        if (inv.Order__c == null) {
            throw new AuraHandledException('La factura no tiene un pedido relacionado.');
        }

        // 2) Traer el pedido original y sus líneas
        Order__c original = [
            SELECT Id, Name, RecordTypeId, Status__c, Account__c, EffectiveDate__c, /* añade tus campos */
                   (SELECT Id, Product__c, Quantity__c, UnitPrice__c /* añade más campos si aplica */
                    FROM OrderItems__r)
            FROM Order__c
            WHERE Id = :inv.Order__c
            LIMIT 1
        ];

        // 3) Obtener RecordType "Rectificativo"
        Id rectiRtId = getRecordTypeId('Order__c', 'Rectificativo');

        // 4) Clonar cabecera (ajusta campos según tu modelo)
        Order__c recti = new Order__c();
        recti.RecordTypeId = rectiRtId;
        recti.Account__c   = original.Account__c;
        recti.EffectiveDate__c = original.EffectiveDate__c;
        recti.Original_Order__c = original.Id;
        recti.Status__c = 'Draft'; // o el que aplique en tu modelo
        // Copia aquí cualquier otro campo necesario…

        insert recti;

        // 5) Clonar líneas con cantidad negativa
        List<OrderItem__c> newLines = new List<OrderItem__c>();
        for (OrderItem__c line : original.OrderItems__r) {
            OrderItem__c nl = new OrderItem__c();
            nl.Order__c   = recti.Id;
            nl.Product__c = line.Product__c;
            nl.UnitPrice__c = line.UnitPrice__c;
            nl.Quantity__c  = (line.Quantity__c == null) ? null : -1 * line.Quantity__c;
            // Copia otros campos necesarios…
            newLines.add(nl);
        }
        if (!newLines.isEmpty()) {
            insert newLines;
        }
    }

    private static Id getRecordTypeId(String sObjectApiName, String developerName) {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.getGlobalDescribe()
            .get(sObjectApiName)
            .getDescribe()
            .getRecordTypeInfosByDeveloperName();
        if (rtInfos.containsKey(developerName)) {
            return rtInfos.get(developerName).getRecordTypeId();
        }
        // Fallback query si hace falta (organizaciones antiguas)
        RecordType rt = [
            SELECT Id FROM RecordType WHERE SobjectType = :sObjectApiName AND DeveloperName = :developerName LIMIT 1
        ];
        return rt.Id;
    }
}
