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