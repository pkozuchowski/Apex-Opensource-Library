/**
 * MIT License
 *
 * Copyright (c) 2020 Piotr Kożuchowski
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

import apexGetCustomLabels from '@salesforce/apex/Localization.getCustomLabels';
import apexGetFieldLabels from '@salesforce/apex/Localization.getFieldLabels';
import apexGetPicklistLabels from '@salesforce/apex/Localization.getPicklistsLabels';

/**
 * @param labelNames API names of the labels to retrieve ex. ['Site.login','ClickHere']
 * @param locale Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)
 *
 * @return Promise<Object> Translated custom labels by API names
 */
export function getCustomLabels(labelNames, locale) {
    return apexGetCustomLabels({labelNames, locale})
        .catch(handleError);
}

/**
 * @param fields API names of the sobject and field ex. ["Account.Name"]
 * @param locale Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)
 *
 * @return Promise<Object> Translated field labels by API names
 */
export function getFieldLabels(fields, locale) {
    return apexGetFieldLabels({fields, locale})
        .catch(handleError);
}

/**
 * @param fields API names of the sobject and field ex. ["Account.Name"]
 * @param locale Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)
 *
 * @return Promise<Object> Translated picklist labels by API Names for each SObjectType
 */
export function getPicklistLabels(fields, locale) {
    return apexGetPicklistLabels({fields, locale})
        .catch(handleError);
}

function handleError(err) {
    throw err.body.message;
}