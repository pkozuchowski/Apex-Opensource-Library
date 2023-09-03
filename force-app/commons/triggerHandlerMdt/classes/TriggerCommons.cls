/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2023 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

public with sharing class TriggerCommons {

    /**
     * Sets default value on a field
     */
    public class DefaultField implements TriggerLogic {
        private String field, value;

        public void setParameters(String parameters) {
            List<String> fields = parameters.split(':');
            field = fields[0];
            value = fields[1];
        }

        public void execute(List<SObject> records, TriggerContext ctx) {
            for (SObject sobj : records) {
                if (sobj.get(field) == null) {
                    sobj.put(field, value);
                }
            }
        }
    }

    /**
     * Copies one field to another
     */
    public class CopyField implements TriggerLogic {
        private String source, target;

        public void setParameters(String parameters) {
            List<String> fields = parameters.split(':');
            source = fields[0];
            target = fields[1];
        }

        public void execute(List<SObject> records, TriggerContext ctx) {
            for (SObject sobj : records) {
                if (sobj.get(source) == null) {
                    sobj.put(target, sobj.get(source));
                }
            }
        }
    }

    /**
     * Executes Flow with given name and parameters
     */
    public class ExecuteFlow implements TriggerLogic {
        private String flowName, namespace;
        private Map<String, Object> params = new Map<String, Object>();

        public void execute(List<SObject> records, TriggerContext ctx) {
            for (SObject sobj : records) {
                params.put('record', sobj);
                params.put('old', ctx.getOld(sobj));

                Flow.Interview interview = Flow.Interview.createInterview(namespace, flowName, params);
                interview.start();

                SObject flowResult = (SObject) interview.getVariableValue('record');
                updateRecord(flowResult, sobj, ctx);
            }
        }

        public void setParameters(String parameters) {
            String[] lines = parameters.split('\n');
            setFlowName(lines);
            setFlowAdditionalParameters(lines);
        }

        private void setFlowName(String[] lines) {
            this.flowName = lines[0].trim();
            if (flowName.contains('__')) {
                String[] namespaceName = flowName.split('__');
                this.namespace = namespaceName[0];
                this.flowName = namespaceName[1];
            }
        }

        private void setFlowAdditionalParameters(String[] lines) {
            for (Integer i = 1; i < lines.size(); i++) {
                String[] param = lines[i].split(':');
                params.put(param[0], param[1]);
            }
        }

        @TestVisible
        private void updateRecord(SObject flowOutput, SObject sobj, TriggerContext ctx) {
            if (flowOutput != null) {
                switch on ctx.operationType {
                    when BEFORE_INSERT, BEFORE_UPDATE {
                        Map<String, Object> populatedFields = flowOutput.getPopulatedFieldsAsMap();

                        for (String field : populatedFields.keySet()) {
                            Object value = populatedFields.get(field);

                            if (sobj.get(field) != value) {
                                sobj.put(field, value);
                            }
                        }
                    }
                }
            }
        }
    }
}