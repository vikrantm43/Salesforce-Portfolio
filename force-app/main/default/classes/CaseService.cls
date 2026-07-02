public with sharing class CaseService {

    public static void setDefaultPriority(List<Case> cases) {
        for (Case c : cases) {
            if (String.isBlank(c.Priority)) {
                c.Priority = 'Medium';
            }
        }
    }

    public static void createFollowUpTask(List<Case> cases) {
        List<Task> tasks = new List<Task>();
        for (Case c : cases) {
            tasks.add(new Task(
                Subject     = 'Follow up: ' + c.Subject,
                WhatId      = c.Id,
                OwnerId     = c.OwnerId,
                Status      = 'Not Started',
                Priority    = 'Normal',
                ActivityDate = Date.today().addDays(3)
            ));
        }
        if (!tasks.isEmpty()) insert tasks;
    }

    public static void sendClosureNotification(List<Case> cases) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Case c : cases) {
            if (c.ContactId == null) continue;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(c.ContactId);
            mail.setWhatId(c.Id);
            mail.setSaveAsActivity(true);
            mail.setSubject('Your Case ' + c.CaseNumber + ' Has Been Closed');
            mail.setPlainTextBody(
                'Hi,\n\nYour support case "' + c.Subject + '" has been resolved and closed.\n\n'
                + 'If you need further assistance, please reply to reopen the case.\n\nThank you.'
            );
            emails.add(mail);
        }
        if (!emails.isEmpty()) Messaging.sendEmail(emails, false);
    }
}
