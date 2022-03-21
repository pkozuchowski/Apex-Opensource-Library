({
    callApex: function (component, method, params, background) {
        return new Promise($A.getCallback(function (resolve, reject) {
            const action = component.get(method);
            action.setParams(params || {});

            if (background) action.setBackground();

            action.setCallback({}, function (response) {
                const state = response.getState();

                if (state === "SUCCESS") {
                    resolve(response.getReturnValue());
                } else if (state === "ERROR") {
                    reject(response.getError()[0]);
                }
            });

            $A.enqueueAction(action);
        }));
    },

    copy: function (obj) {
        if (obj) {
            return JSON.parse(JSON.stringify(obj));
        } else {
            throw new Error('Object to copy is not defined.');
        }
    }
})
