({
    handleInit: function (component, event, helper) {
        component.set("v.page", 0);
        helper.getPaginationItems(component);
    },

    handlePageChange: function (component, event, helper) {
        helper.getPaginationItems(component);
    },

    handlePageSizeChange: function (component, event, helper) {
        const value = event.getParam("value");
        const oldValue = event.getParam("oldValue");

        if (!oldValue || value.length != oldValue.length) {
            component.set("v.page", 0);
            helper.getPaginationItems(component);
        }
    },

    goToFirst: function (component) {
        component.set("v.page", 0);
    },

    goToPrevious: function (component) {
        var currentPage = component.get("v.page");

        if (currentPage > 0) {
            component.set("v.page", currentPage - 1);
        }
    },

    goToNext: function (component, event, helper) {
        var currentPage = component.get("v.page"),
            lastPage = helper.getLastPage(component);

        if (currentPage < lastPage) {
            component.set("v.page", currentPage + 1);
        }
    },

    goToLast: function (component, event, helper) {
        component.set("v.page", helper.getLastPage(component));
    },

    goToPage: function (component, event) {
        var page = event.getSource().get("v.name");
        component.set("v.page", parseInt(page));
    }
})