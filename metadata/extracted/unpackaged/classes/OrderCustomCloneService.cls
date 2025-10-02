public with sharing class OrderCustomCloneService {
    // ===== CONFIG - ajusta a tu org si hace falta =====
    private static final String ORDER_OBJ              = 'Order__c';
    private static final String ORDER_STATUS_FIELD     = 'Status__c';
    private static final String ORDER_EFFECTIVE_FIELD  = 'EffectiveDate__c'; // si no existe, se ignora
    private static final String ORDER_ACCOUNT_FIELD    = 'Account__c';       // si no existe, se ignora
    private static final String ORDER_CONTRACT_FIELD   = 'Contract__c';      // si no existe, se ignora
    private static final String ORDER_PRICEBOOK_FIELD  = 'Pricebook2__c';    // si no existe, se ignora
    private static final String ORDERITEM_OBJ          = 'OrderItem__c';
    private static final String OI_PARENT_FIELD        = 'Pedido__c';        // lookup a Order__c
    // Campos de línea habituales (se copian si existen en la org y en el registro origen)
    private static final List<String> OI_FIELDS_TO_COPY = new List<String>{
        'Product__c','ProductDescription__c','Quantity__c','UnitPrice__c','Discount__c','Description__c',
        'PricebookEntry__c'
    };

    @AuraEnabled
    public static Id cloneOrder(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('Id de pedido obligatorio.');
        }
        try {
            // ====== Construir SELECT dinámico para la cabecera ======
            List<String> headerFields = new List<String>{};
            for (String f : new List<String>{
                ORDER_ACCOUNT_FIELD, ORDER_CONTRACT_FIELD, ORDER_PRICEBOOK_FIELD,
                ORDER_EFFECTIVE_FIELD, ORDER_STATUS_FIELD, 'CurrencyIsoCode'
            }) {
                if (hasField(ORDER_OBJ, f)) headerFields.add(f);
            }
            String soql = 'SELECT Id' + (headerFields.isEmpty() ? '' : ',' + String.join(headerFields, ',')) +
                          ' FROM ' + ORDER_OBJ + ' WHERE Id = :recordId LIMIT 1';
            SObject src = Database.query(soql);

            // ====== Crear cabecera destino ======
            SObject dst = (SObject) Type.forName('Schema', ORDER_OBJ).newInstance();
            // Copiar algunos campos si existen
            copyIfNotNull(src, dst, ORDER_ACCOUNT_FIELD);
            copyIfNotNull(src, dst, ORDER_CONTRACT_FIELD);
            copyIfNotNull(src, dst, ORDER_PRICEBOOK_FIELD);
            // Estado = "Nuevo"
            putIfExists(dst, ORDER_STATUS_FIELD, 'Nuevo');
            // Fecha efectiva hoy (si existe el campo)
            if (hasField(ORDER_OBJ, ORDER_EFFECTIVE_FIELD)) {
                dst.put(ORDER_EFFECTIVE_FIELD, Date.today());
            }
            // Divisa si hay MC
            if (hasField(ORDER_OBJ, 'CurrencyIsoCode') && src.get('CurrencyIsoCode') != null) {
                dst.put('CurrencyIsoCode', src.get('CurrencyIsoCode'));
            }
            insert dst;
            Id newOrderId = (Id) dst.get('Id');

            // ====== Query de líneas origen ======
            List<String> lineFieldsSel = new List<String>();
            for (String f : OI_FIELDS_TO_COPY) if (hasField(ORDERITEM_OBJ, f)) lineFieldsSel.add(f);
            String soqlLines = 'SELECT ' + (lineFieldsSel.isEmpty() ? 'Id' : String.join(lineFieldsSel, ',')) +
                               ' FROM ' + ORDERITEM_OBJ + ' WHERE ' + OI_PARENT_FIELD + ' = :recordId';
            List<SObject> srcLines = Database.query(soqlLines);

            if (!srcLines.isEmpty()) {
                List<SObject> toInsert = new List<SObject>();
                for (SObject oi : srcLines) {
                    SObject ni = (SObject) Type.forName('Schema', ORDERITEM_OBJ).newInstance();
                    ni.put(OI_PARENT_FIELD, newOrderId);
                    // Copia campos de línea si existen y tienen valor
                    for (String f : OI_FIELDS_TO_COPY) {
                        if (hasField(ORDERITEM_OBJ, f)) {
                            Object v = oi.get(f);
                            if (v != null) ni.put(f, v);
                        }
                    }
                    // Divisa si aplica
                    if (hasField(ORDERITEM_OBJ, 'CurrencyIsoCode') && oi.get('CurrencyIsoCode') != null) {
                        ni.put('CurrencyIsoCode', oi.get('CurrencyIsoCode'));
                    }
                    toInsert.add(ni);
                }
                insert toInsert;
            }
            return newOrderId;
        } catch (Exception e) {
            throw new AuraHandledException('No se pudo clonar el pedido: ' + e.getMessage());
        }
    }

    // ===== Helpers =====
    private static Boolean hasField(String objApi, String fieldApi) {
        if (String.isBlank(fieldApi)) return false;
        Schema.SObjectType t = Schema.getGlobalDescribe().get(objApi);
        if (t == null) return false;
        return t.getDescribe().fields.getMap().containsKey(fieldApi);
    }
    private static void copyIfNotNull(SObject src, SObject dst, String fieldApi) {
        if (hasField(dst.getSObjectType().getDescribe().getName(), fieldApi)) {
            Object v = src.get(fieldApi);
            if (v != null) dst.put(fieldApi, v);
        }
    }
    private static void putIfExists(SObject s, String f, Object v) {
        if (hasField(s.getSObjectType().getDescribe().getName(), f)) s.put(f, v);
    }
}