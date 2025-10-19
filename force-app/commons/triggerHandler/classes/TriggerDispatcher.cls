// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

/**
 * Dispatcher class responsible for executing trigger handlers in the proper context.
 * This class acts as a central point for trigger execution, ensuring that logic is executed in the correct order.
 *
 * @example
 * trigger AccountTrigger on Account (before insert, after insert, before update, after update) {
 *   TriggerDispatcher.run(new AccountTriggerHandler());
 * }
 */
public inherited sharing class TriggerDispatcher {
    @TestVisible static List<ApexTypeImplementor> mockedExceptionHandlers;

    /**
     * Runs instance of concrete Trigger Handler implementation
     */
    public static void run(TriggerHandler triggerHandler) {
        run(triggerHandler, TriggerContext.getInstance());
    }

    @TestVisible
    private static void run(TriggerHandler triggerHandler, TriggerContext ctx) {
        try {
            if (shouldRun(ctx, triggerHandler)) {
                List<SObject> records = ctx.getRecords();
                triggerHandler.initialize(ctx.getRecords(), ctx);

                for (TriggerAction action : getActions(triggerHandler, ctx)) {
                    if (TriggerSettings.isActionEnabled(action)) {
                        System.debug('action enabled');
                        action.execute(records, ctx);
                    } else {
                        System.debug('action not enabled');

                    }
                }

                triggerHandler.finalize(records, ctx);
            }
        } catch (Exception ex) {
            triggerHandler.onException(ex, ctx);
            handleException(ex, ctx);
            throw ex;
        }
    }

    /**
    * @return True when:
    * - is in trigger context (can be mocked in unit tests)
    * - if it's not disabled in Bypass Triggers settings
    * - if it's not manually disabled in code via  disableTrigger();
    */
    private static Boolean shouldRun(TriggerContext triggerContext, TriggerHandler th) {
        return triggerContext.isExecuting && TriggerSettings.isSObjectTriggerEnabled(triggerContext.sObjectType);
    }

    /** Returns list of Trigger Actions to be executed for given Trigger Context */
    private static List<TriggerAction> getActions(TriggerHandler triggerHandler, TriggerContext ctx) {
        List<SObject> records = ctx.getRecords();

        switch on ctx.operationType {
            when BEFORE_INSERT {
                return triggerHandler.beforeInsert(records, ctx);
            }
            when BEFORE_UPDATE {
                return triggerHandler.beforeUpdate(records, ctx);
            }
            when BEFORE_DELETE {
                return triggerHandler.beforeDelete(records, ctx);
            }
            when AFTER_INSERT {
                return triggerHandler.afterInsert(records, ctx);
            }
            when AFTER_UPDATE {
                return triggerHandler.afterUpdate(records, ctx);
            }
            when AFTER_DELETE {
                return triggerHandler.afterDelete(records, ctx);
            }
            when AFTER_UNDELETE {
                return triggerHandler.afterUndelete(records, ctx);
            }
        }
        return new List<TriggerAction>();
    }

    /** Invokes all registered Trigger Exception Handlers */
    private static void handleException(Exception ex, TriggerContext ctx) {
        List<ApexTypeImplementor> handlers = mockedExceptionHandlers ?? [
            SELECT ClassName
            FROM ApexTypeImplementor
            WHERE InterfaceName = 'TriggerExceptionHandler'
            AND IsConcrete = TRUE
            WITH SYSTEM_MODE
        ];

        for (ApexTypeImplementor implementor : handlers) {
            Type handlerType = Type.forName(implementor.ClassName);
            TriggerExceptionHandler handler = (TriggerExceptionHandler) handlerType?.newInstance();
            handler?.onException(ex, ctx);
        }
    }

    private TriggerDispatcher() {}
}