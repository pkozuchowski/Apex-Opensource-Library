// SPDX-License-Identifier: MIT
// Copyright 2026 Piotr Kożuchowski

/**
 * Invocable and AuraEnabled Log actions
 */
public with sharing class LogActions {

    public class FlowLogRequest {
        @InvocableVariable(Label='Flow Name' Required=true)
        public String flowName;

        @InvocableVariable(Label='Message' Required=true)
        public String message;

        @InvocableVariable(Label='Severity' Required=true PlaceholderText='INFO/WARN/ERROR')
        public String severity;

        @InvocableVariable(Label='A Reference ID' Description='Id of record related to this log')
        public String referenceId;

        @InvocableVariable(Label='Input 1 Name') public String input1Name;
        @InvocableVariable(Label='Input 1 Value') public String input1Value;

        @InvocableVariable(Label='Input 2 Name') public String input2Name;
        @InvocableVariable(Label='Input 2 Value') public String input2Value;

        @InvocableVariable(Label='Input 3 Name') public String input3Name;
        @InvocableVariable(Label='Input 3 Value') public String input3Value;
    }

    @InvocableMethod(Label='Log' Description='Creates a persistent log entry in Log__c record.')
    public static void log(List<FlowLogRequest> requests) {
        for (FlowLogRequest req : requests) {
            Logger.log(
                LoggingLevel.valueOf(req.severity),
                new Log(req.message)
                    .withSource(req.flowName)
                    .withReferenceId(req.referenceId)
                    .withInput(req.input1Name, req.input1Value)
                    .withInput(req.input2Name, req.input2Value)
                    .withInput(req.input3Name, req.input3Value)
            );
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled(Cacheable=false)
    public static void log(String severity, String source, String message, String referenceId, Map<String, Object> inputs) {
        Logger.log(
            LoggingLevel.valueOf(severity),
            new Log(message)
                .withSource(source ?? 'LWC')
                .withReferenceId(referenceId)
                .withInputs(inputs)
        );
    }
}