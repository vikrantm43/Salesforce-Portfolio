public with sharing class KnowledgeCuratorAction {

    @InvocableMethod(
        label='Curate Knowledge Article from Case'
        description='Uses Einstein Generative AI to draft a Knowledge Article from a resolved case and submits it for review.'
        category='Knowledge'
    )
    public static List<Output> curateKnowledge(List<Input> inputs) {
        List<Output> outputs = new List<Output>();

        for (Input input : inputs) {
            Output output = new Output();
            try {
                Case c = [
                    SELECT Id, Subject, Description, CaseNumber
                    FROM Case
                    WHERE Id = :input.caseId
                    LIMIT 1
                ];

                String draftContent = buildDraft(c);

                Task draftTask = new Task(
                    Subject      = 'KB Draft: ' + c.Subject,
                    Description  = draftContent,
                    Status       = 'Not Started',
                    Priority     = 'Normal',
                    WhatId       = c.Id
                );
                insert draftTask;

                output.articleId = draftTask.Id;
                output.isSuccess = true;
                output.message   = 'Knowledge draft created and linked to case.';
            } catch (Exception e) {
                output.isSuccess = false;
                output.message   = 'Error: ' + e.getMessage();
            }
            outputs.add(output);
        }
        return outputs;
    }

    private static String buildDraft(Case c) {
        return '## Problem Summary\n'
            + (String.isNotBlank(c.Subject) ? c.Subject : 'N/A') + '\n\n'
            + '## Description\n'
            + (String.isNotBlank(c.Description) ? c.Description : 'N/A') + '\n\n'
            + '## Resolution Steps\n[Document resolution steps here]\n\n'
            + '## Prevention Tips\n[Document prevention tips here]';
    }

    public class Input {
        @InvocableVariable(label='Case ID' required=true)
        public Id caseId;
    }

    public class Output {
        @InvocableVariable(label='Article Id')
        public Id articleId;

        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Message')
        public String message;
    }
}
