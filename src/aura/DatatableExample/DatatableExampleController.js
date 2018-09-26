({
    handleInit: function (component, event, helper) {
        const accounts = [];
        for (var i = 0; i < 100; i++) {
            accounts.push({
                Name: 'Test Account ' + i,

            });
        }
        component.set("v.accounts", accounts);
    },

    handleInputChange: function (component, event, helper) {
        let totalRevenue = 0;
        let totalEmployees = 0,
            accounts = component.get("v.accounts");

        for (let i = 0, j = accounts.length; i < j; i++) {
            if (accounts[i].AnnualRevenue) {
                totalRevenue += Number(accounts[i].AnnualRevenue);
            }
            if (accounts[i].NumberOfEmployees) {
                totalEmployees += Number(accounts[i].NumberOfEmployees);
            }
        }

        component.set("v.totalRevenue", totalRevenue);
        component.set("v.totalEmployees", totalEmployees);
    },

    handleAddNewAccount: function (component, event, helper) {

    },

    handleDeleteAccount: function (component, event, helper) {

    },

    handleUpdateAccount: function (component, event, helper) {

    },
})