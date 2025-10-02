public without sharing class QueueCallA3Service implements Queueable,Database.AllowsCallouts {

    private Id recordId;
    private String method;
    private String serviceText;
    private sObject obj;
    private Integer timeOut;
  
    public QueueCallA3Service(Id recordId, String method, String serviceText, sObject obj, Integer timeOut) {
        this.recordId = recordId;
        this.method = method;
        this.serviceText = serviceText;
        this.obj = obj;
        this.timeOut = timeOut;
    }

    public void execute(QueueableContext qc) {
        if(serviceText == 'Client'){
            clientService();
        }else if(serviceText == 'Order'){
            orderService();
        }
    }

    private void clientService() {
        List<ShippingAddress__c> listShipp = [SELECT Id, Candidato__c FROM ShippingAddress__c WHERE Candidato__c = :recordId];
        try{
            String response = A3IntegrationService.getRequestWithBody(method, serviceText, obj, timeOut);
            
            Boolean error = false;
            if(response.contains('ERROR INSERT') || response.contains('ERROR AUTH:')){
                error = true;
            }

            A3IntegrationService.sendEmail(error, recordId);
            if(listShipp != null && !listShipp.isEmpty()){
                delete listShipp;
            }

        }catch(Exception e){

            A3IntegrationService.sendEmail(true, recordId);
            if(listShipp != null && !listShipp.isEmpty()){
                delete listShipp;
            }
            System.debug('Error on CLIENT QueueCallA3Service: ' + e.getMessage() + ' on ' + e.getLineNumber());
        }
    }

    private void orderService() {
        try{           
            system.debug('Entra en order service');
		    //Vuelve a llamar al servicio si el order es nulo o ERROR, si es el código de a3 no vuelve a mandarlo
		    if(obj.get('OrderNumber__c') == null || obj.get('OrderNumber__c') == 'ERROR'){

                String response = A3IntegrationService.getRequestWithBody(method, serviceText, obj, timeOut);
                system.debug('response '+response);
                String orderNumber;
                if(response.contains('ERROR INSERT') || response.contains('ERROR AUTH:')){
                    orderNumber = 'ERROR';
                    system.debug('1 ');
                    Portal_Configuration__mdt metadata = Portal_Configuration__mdt.getInstance('Default');
                    if(metadata.Send_Notifications__c){
                        notifyUsers(obj, response);
                    }
                    if(metadata.Post_Chatter__c){
                        postFeed(obj, response);
                    }
                }else{
                    system.debug('2 ');
                    orderNumber = response.split(':').get(response.split(':').size()-1);
                    Portal_Configuration__mdt metadata = Portal_Configuration__mdt.getInstance('Default');
                    if(metadata.Send_Notifications__c){
                        notifyUsers(obj, null);
                    }
                }
                update new Order__c(id=recordId,OrderNumber__c=orderNumber);
            }

        }catch(Exception e){

            update new Order__c(id=recordId,OrderNumber__c='ERROR');
            Portal_Configuration__mdt metadata = Portal_Configuration__mdt.getInstance('Default');
            if(metadata.Send_Notifications__c){
                notifyUsers(obj, 'ERROR ON A3 INSERT');
            }
            if(metadata.Post_Chatter__c){
                postFeed(obj, 'ERROR ON A3 INSERT');
            }
            System.debug('Error on ORDER QueueCallA3Service: ' + e.getMessage() + ' on ' + e.getLineNumber());
        }
    }
    
    private static void postFeed(sObject obj, String errorBody) {

        if(errorBody.contains('<!DOCTYPE ')){
            errorBody = errorBody.split('<!DOCTYPE ').get(0);
        }

        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();

        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = String.valueOf(obj.get('OwnerId'));
        messageBodyInput.messageSegments.add(mentionSegment);

        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = ' Se ha producido un error en la carga del pedido en A3, acceda a este registro ';
        messageBodyInput.messageSegments.add(textSegment);

        ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputInv = new ConnectApi.EntityLinkSegmentInput();
        entityLinkSegmentInputInv.entityId = String.valueOf(obj.get('id'));
        messageBodyInput.messageSegments.add(entityLinkSegmentInputInv);  

        textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = ' y reenvíelo de nuevo. Si el problema persiste póngase en contacto con su administrador. (' + errorBody + ')';
        messageBodyInput.messageSegments.add(textSegment);

        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        feedItemInput.body = messageBodyInput;
        feedItemInput.subjectId = String.valueOf(obj.get('OwnerId'));
        
        ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
        batchInputs.add(batchInput);

        
        if(!Test.isRunningTest()){
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchinputs);
        }
	}

    private static void notifyUsers(sObject obj, String errorBody) {

        if(errorBody != null && errorBody.contains('<!DOCTYPE ')){
            errorBody = errorBody.split('<!DOCTYPE ').get(0);
        }

        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Notify_Error'];


        String bodyText = errorBody==null?'Se ha cargado correctamente el pedido ' + String.valueOf(obj.get('Name')) + ' en A3':'Se ha producido un error en la carga del pedido en A3, acceda a este registro ' + String.valueOf(obj.get('Name')) + ' y reenvíelo de nuevo. Si el problema persiste póngase en contacto con su administrador. (' + errorBody + ')';
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle(errorBody==null?'Pedido cargado en A3':'Error en el envío del pedido a A3');
        notification.setBody(bodyText);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(String.valueOf(obj.get('id')));
        
        // Actually send the notification
        try {
            Set<String> sUser = new Set<String>();
            sUser.add(String.valueOf(UserInfo.getUserId()));
            if(!Test.isRunningTest()){
                notification.send(sUser);
            }
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
}