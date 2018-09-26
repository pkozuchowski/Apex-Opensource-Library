/**
 * MIT License
 *
 * Copyright (c) 2018 Piotr Kożuchowski
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
({
    handleInit: function (component, event, helper) {
        const accounts = [];

        const accountGenerator = new helper.AccountGenerator(helper);
        for (var i = 0; i < 100; i++) {
            accounts.push(accountGenerator.generate());
        }
        component.set("v.accounts", accounts);

        /*Comparator*/
        component.set("v.comparators", {
            RecordType: function (thisAccount, otherAccounts) {
                return thisAccount.RecordType.Name.localeCompare(otherAccounts.RecordType.Name);
            }
        })
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
        const newAccounts = component.get("v.newAccounts").slice();
        newAccounts.push({});
        component.set("v.newAccounts", newAccounts);
    },

    handleDeleteAccount: function (component, event, helper) {
        const accountId = event.getSource().get("v.name");
        const accounts = component.get("v.accounts").slice();
        const accountIndex = accounts.findIndex(acc => acc.Id === accountId);

        accounts.splice(accountIndex, 1);
        component.set("v.accounts", accounts);
    },

    handleSaveNewAccounts: function (component, event, helper) {
        const accounts = [...component.get("v.accounts").slice(), ...component.get("v.newAccounts").slice()];
        component.set("v.accounts", accounts);
        component.set("v.newAccounts", []);
    },

    handleRemoveNewAccount: function (component, event, helper) {
        const index = event.getSource().get("v.name");
        const newAccounts = component.get("v.newAccounts").slice();

        newAccounts.splice(index, 1);
        component.set("v.newAccounts", newAccounts);
    }
})