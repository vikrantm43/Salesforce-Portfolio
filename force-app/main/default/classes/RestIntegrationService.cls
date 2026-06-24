public class RestIntegrationService implements Queueable, Database.AllowsCallouts {

    private static final Integer MAX_RETRIES = 3;
    private static final Integer TIMEOUT_MS  = 10000;

    private String namedCredential;
    private String endpoint;
    private String method;
    private String requestBody;
    private Integer retryCount;
    private Id relatedRecordId;

    public RestIntegrationService(String namedCredential, String endpoint, String method,
                                   String requestBody, Id relatedRecordId) {
        this.namedCredential = namedCredential;
        this.endpoint        = endpoint;
        this.method          = method;
        this.requestBody     = requestBody;
        this.relatedRecordId = relatedRecordId;
        this.retryCount      = 0;
    }

    public void execute(QueueableContext ctx) {
        IntegrationResponse response = makeCallout();

        if (!response.isSuccess && retryCount < MAX_RETRIES) {
            retryCount++;
            System.enqueueJob(this);
        } else {
            logResponse(response);
        }
    }

    private IntegrationResponse makeCallout() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + namedCredential + endpoint);
        req.setMethod(method);
        req.setTimeout(TIMEOUT_MS);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');

        if (String.isNotBlank(requestBody)) {
            req.setBody(requestBody);
        }

        IntegrationResponse result = new IntegrationResponse();

        try {
            HttpResponse res = new Http().send(req);
            result.statusCode = res.getStatusCode();
            result.responseBody = res.getBody();
            result.isSuccess = (res.getStatusCode() >= 200 && res.getStatusCode() < 300);
        } catch (CalloutException e) {
            result.isSuccess = false;
            result.errorMessage = e.getMessage();
        }

        return result;
    }

    private void logResponse(IntegrationResponse response) {
        Integration_Log__c log = new Integration_Log__c(
            Related_Record_Id__c = relatedRecordId,
            Endpoint__c          = endpoint,
            Status_Code__c       = response.statusCode,
            Response_Body__c     = response.responseBody?.abbreviate(131072),
            Is_Success__c        = response.isSuccess,
            Error_Message__c     = response.errorMessage,
            Retry_Count__c       = retryCount
        );
        insert log;
    }

    public class IntegrationResponse {
        public Boolean isSuccess    = false;
        public Integer statusCode;
        public String responseBody;
        public String errorMessage;
    }
}
