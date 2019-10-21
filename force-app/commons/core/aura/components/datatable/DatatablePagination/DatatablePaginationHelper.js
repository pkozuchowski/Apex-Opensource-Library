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
    getLastPage: function (component) {
        //var isSearched = component.get("v.isSearched");
        var pageSize = component.get("v.pageSize");
        var itemsLength = component.get("v.itemsLength");

        return Math.ceil(itemsLength / pageSize) - 1;
    },

    getPaginationItems: function (component) {
        var currentPage = component.get("v.page"),
            paginationItems = [],
            lastPage = this.getLastPage(component),

            min = Math.max(currentPage - 2, 0),
            max = Math.min(currentPage + 2, lastPage);

        if (min != 0) {
            paginationItems.push({label: '...', value: min - 1});
        }

        for (; min <= max; min++) {
            paginationItems.push({label: min + 1, value: min});
        }

        if (max != lastPage) {
            paginationItems.push({label: '...', value: max + 1});
        }
        component.set("v.paginationItems", paginationItems);
    },

    firePaginationEvent: function (component) {
        const event = component.getEvent("pagination");

        event.setParams({
            paginationPage: component.get("v.page"),
            paginationPageSize: component.get("v.pageSize")
        });

        event.fire();
    }
})