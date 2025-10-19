// SPDX-License-Identifier: MIT
// Copyright 2023 Piotr Kożuchowski

public with sharing class TriggerCommons {

    /**
     * Utility trigger logic that evaluates a formula and assigns the computed value
     * to a specified field on processed SObjects. Intended for use in BEFORE triggers
     * to populate or override a field value based on a formula evaluated per record.
     *
     * Parameters (provided via metadata):
     * - {@code field} : API name of the target field to populate.
     * - {@code formula} : formula text to be evaluated in the context of each record.
     * - {@code replaceIfSet} : optional boolean controlling whether existing values
     *   should be replaced (defaults to false).
     */
    public class FieldSetter implements TriggerAction {
        private String field;
        private String formula;
        private Boolean replaceIfSet = true;
        private FormulaEval.FormulaInstance formulaInstance;

        /**
         * Evaluates the configured formula for each record in {@code records} and
         * assigns the result to {@code field} when the existing value is null or
         * {@code replaceIfSet} is true.
         *
         * @param records list of SObjects processed by the trigger
         * @param ctx trigger context helper providing {@code sObjectType} and access
         *            to old values where applicable
         */
        public void execute(List<SObject> records, TriggerContext ctx) {
            initFormulaInstance(ctx);

            for (SObject record : records) {
                Object currentValue = record.get(field);

                if (currentValue == null || replaceIfSet == true) {
                    Object computed = evaluateFormula(record);
                    record.put(field, computed);
                }
            }
        }

        /**
         * Lazily builds the {@link FormulaEval.FormulaInstance} from the configured
         * {@link #formula} using the provided trigger context type. No-op if the
         * instance is already built or if {@code formula} is null.
         *
         * @param ctx trigger context providing the {@code sObjectType} required by the builder
         */
        private void initFormulaInstance(TriggerContext ctx) {
            if (formulaInstance == null) {
                FormulaEval.FormulaReturnType formulaReturnType = getReturnType(ctx.sObjectType, field);
                formulaInstance = System.Formula.builder()
                    .withType(ctx.sObjectType)
                    .withFormula(formula)
                    .withReturnType(formulaReturnType)
                    .parseAsTemplate(formulaReturnType == FormulaEval.FormulaReturnType.STRING)
                    .build();
            }
        }

        /**
         * Determines the appropriate {@link FormulaEval.FormulaReturnType} for the
         * target field on the given SObject type.
         *
         * @param sobjType SObjectType of the records being processed
         * @param field API name of the target field
         * @return corresponding FormulaReturnType
         */
        private FormulaEval.FormulaReturnType getReturnType(SObjectType sobjType, String field) {
            Schema.DescribeFieldResult dfr = sobjType.getDescribe().fields.getMap().get(field).getDescribe();
            Schema.DisplayType dt = dfr.getType();

            return new Map<DisplayType, FormulaEval.FormulaReturnType>{
                DisplayType.BOOLEAN => FormulaEval.FormulaReturnType.BOOLEAN,
                DisplayType.DATE => FormulaEval.FormulaReturnType.DATE,
                DisplayType.DATETIME => FormulaEval.FormulaReturnType.DATETIME,
                DisplayType.TIME => FormulaEval.FormulaReturnType.TIME,
                DisplayType.ID => FormulaEval.FormulaReturnType.ID,
                DisplayType.REFERENCE => FormulaEval.FormulaReturnType.ID,
                DisplayType.CURRENCY => FormulaEval.FormulaReturnType.DECIMAL,
                DisplayType.PERCENT => FormulaEval.FormulaReturnType.DECIMAL,
                DisplayType.DOUBLE => FormulaEval.FormulaReturnType.DOUBLE,
                DisplayType.INTEGER => FormulaEval.FormulaReturnType.INTEGER,
                DisplayType.LONG => FormulaEval.FormulaReturnType.LONG
            }.get(dt) ?? FormulaEval.FormulaReturnType.STRING;
        }


        /**
         * Evaluates the prepared formula instance against the given record.
         *
         * @param contextRecord SObject used as the evaluation context for the formula
         * @return computed value or {@code null} when no formula instance is available
         */
        private Object evaluateFormula(SObject contextRecord) {
            if (formulaInstance == null) {
                return null;
            }
            // Assumes FormulaInstance.evaluate(SObject) exists and returns computed value
            return formulaInstance.evaluate(contextRecord);
        }
    }
}