/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2024 Piotr Kożuchowski
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
 * /
 * *
 */

import {api, LightningElement} from "lwc";

const comparators = {
    equals   : (value, param) => value === param,
    notEquals: (value, param) => value !== param,
    isTruthy : (value) => !!value,
    isFalsy  : (value) => !value,
    isOneOf  : (value, param) => {
        if (Array.isArray(param)) {
            return param.indexOf(value) > -1;
        } else {
            return param.split(",").indexOf(value) > -1;
        }
    }
};

export default class If extends LightningElement {
    @api value;
    @api equals;
    @api notEquals;
    @api isTruthy;
    @api isFalsy;
    @api isOneOf;
    comparator = comparators.isTruthy;


    connectedCallback() {
        if (this.equals) {
            this.comparator = comparators.equals;
        } else if (this.notEquals) {
            this.comparator = comparators.notEquals;
        } else if (this.isTruthy) {
            this.comparator = comparators.isTruthy;
        } else if (this.isFalsy) {
            this.comparator = comparators.isFalsy;
        } else if (this.isOneOf) {
            this.comparator = comparators.isOneOf;
        }
    }

    get isTrue() {
        return this.comparator(this.value, this.equals || this.notEquals || this.isTruthy || this.isFalsy || this.isOneOf);
    }
}