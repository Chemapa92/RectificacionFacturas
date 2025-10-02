public with sharing class OrderHandler {

	public static void handleAfterUpdate(Map<Id, Order__c> newOrders, Map<Id, Order__c> oldOrders){
        List<Order__c> lOrderWithFreight = new List<Order__c>();
        Set<Id> sAccount = new Set<Id>();
        Set<Id> sUser = new Set<Id>();
        for(Id orderID : newOrders.keySet()){
            if(oldOrders.get(orderID).FreightOder__c == null && newOrders.get(orderID).FreightOder__c != oldOrders.get(orderID).FreightOder__c){
                lOrderWithFreight.add(newOrders.get(orderID));
                sAccount.add(newOrders.get(orderID).Account__c);
                sUser.add(newOrders.get(orderID).OwnerId);
            }
        }

        // if(!lOrderWithFreight.isEmpty()){
        //     sendFreightOderEmail(lOrderWithFreight, sAccount, sUser);
        // }
	}

	private static void sendFreightOderEmail(List<Order__c> lOrderWithFreight, Set<Id> sAccount, Set<Id> sUser){

        Map<Id, Account> mAccount = new Map<Id, Account>([SELECT ID, Email__c FROM Account WHERE id IN :sAccount]);
        Map<Id, User> mUser = new Map<Id, User>([SELECT ID, Email FROM User WHERE id IN :sUser]);
        EmailTemplate template = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'FreightOderTemplate' LIMIT 1];
        OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Hafesa' LIMIT 1];

        Integer splitter = 0;
        Integer counter = 0;
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        while (splitter < lOrderWithFreight.size()) {
            Integer i = 0;
            while(i < 200 && (splitter + i) < lOrderWithFreight.size()){
                Order__c order = lOrderWithFreight.get(splitter+i);
                if(mAccount.containsKey(order.Account__c) && mAccount.get(order.Account__c).Email__c != null && mAccount.get(order.Account__c).Email__c != ''){

                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] {mAccount.get(order.Account__c).Email__c});
                    email.setccAddresses(new String[] {mUser.get(order.OwnerId).Email});
                    email.setTemplateId(template.Id);
                    email.setOrgWideEmailAddressId(owea.Id);
                    email.setTargetObjectId(UserInfo.getUserId());
                    email.setWhatId(order.id);
                    email.setSaveAsActivity(false);
                    
                    mails.add(email);
                }
                counter++;
                i++;
            }

            System.debug('mails: ' + mails);
            if(!mails.isEmpty()){
                if(!Test.isRunningTest()){
                    List<Messaging.SendEmailResult> results = Messaging.sendEmail(mails);
                    if (results[0].success) {
                        System.debug('The email was sent successfully.');
                    } else {
                        System.debug('The email failed to send:  ' +  results[0].errors[0].message);
                    }
                }
            }
            splitter = counter;
        }
	}
}