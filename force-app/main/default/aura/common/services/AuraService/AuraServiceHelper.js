({
    cssClass: function (fn, element, styleClass) {
        fn(element, styleClass);
        $A.util.addClass(cmp.find(auraId), "slds-hide");
    },

    setTimeout: function (callback, timeout) {
        window.setTimeout($A.getCallback(callback), timeout);
    },

    callApex: function (config) {
        return new Promise($A.getCallback(function (resolve, reject) {
            const action = config.component.get(config.method);
            action.setParams(config.params || {});
            if (config.background) {
                action.setBackground();
            }
            action.setCallback(config.scope || {}, function (response) {
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
            return obj;
        }
    },

    download: function (config) {
        const blob = new Blob([config.data], {type: config.type});
        const fileReader = new FileReader();

        fileReader.onload = function (e) {
            const link = document.createElement("a");
            link.href = e.target.result;
            link.download = config.fileName;
            document.body.appendChild(link);
            link.click();
            link.remove();
        };
        fileReader.readAsDataURL(blob);
    }
})
