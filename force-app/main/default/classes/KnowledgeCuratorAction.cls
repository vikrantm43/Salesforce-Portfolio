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
                    SELECT Id, Subject, Description, Resolution__c, Product__c
                    FROM Case
                    WHERE Id = :input.caseId
                    LIMIT 1
                ];

                String prompt = buildPrompt(c);
                String draftContent = callEinsteinGenAI(prompt);

                Knowledge__kav article = new Knowledge__kav(
                    Title      = 'KB: ' + c.Subject,
                    Summary__c = draftContent.abbreviate(255),
                    Answer__c  = draftContent,
                    Language   = 'en_US',
                    VersionData = Blob.valueOf(draftContent)
                );
                insert article;

                output.articleId = article.Id;
                output.isSuccess = true;
                output.message   = 'Knowledge article drafted and submitted for review.';
            } catch (Exception e) {
                output.isSuccess = false;
                output.message   = 'Error: ' + e.getMessage();
            }
            outputs.add(output);
        }
        return outputs;
    }

    private static String buildPrompt(Case c) {
        return 'You are a Salesforce knowledge base author. '
            + 'Based on the following resolved support case, write a concise, helpful Knowledge Article '
            + 'that can assist other customers facing the same issue.\n\n'
            + 'Subject: ' + c.Subject + '\n'
            + 'Description: ' + c.Description + '\n'
            + 'Resolution: ' + c.Resolution__c + '\n\n'
            + 'Format: Problem Summary, Root Cause, Resolution Steps, Prevention Tips.';
    }

    private static String callEinsteinGenAI(String prompt) {
        ConnectApi.EinsteinLLMGenerationsInput input = new ConnectApi.EinsteinLLMGenerationsInput();
        input.promptTextorId = prompt;
        ConnectApi.EinsteinLLMGenerationsOutput output =
            ConnectApi.EinsteinAI.generateMessages('sfdc_ai__DefaultGPT4Omni', input);
        return output.generations[0].text;
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
