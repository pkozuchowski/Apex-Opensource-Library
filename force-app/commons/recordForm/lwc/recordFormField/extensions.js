import {
    LightningCheckboxExt,
    LightningDateExt,
    LightningDateTimeExt,
    LightningEmailExt,
    LightningNumberExt,
    LightningPhoneExt,
    LightningTextExt,
    LightningTimeExt, LightningUrlExt
} from "./lightning/input/lightningInputExt";
import LightningAddressExt from "./lightning/address/lightningAddressExt";
import {LightningMultiPicklistExt, LightningPicklistExt} from "./lightning/picklist/lightningPicklistExt";
import {LightningRichTextExt, LightningTextAreaExt} from "./lightning/textArea/lightningTextAreaInputExt";
import {LightningReferenceExt} from "./lightning/lookup/lightningRecordPickerExt";


const EXTENSIONS = {
    "lightning": {
        'String'       : LightningTextExt,
        'Boolean'      : LightningCheckboxExt,
        'Int'          : LightningNumberExt,
        'Double'       : LightningNumberExt,
        'Currency'     : LightningNumberExt,
        'Percent'      : LightningNumberExt,
        'Date'         : LightningDateExt,
        'DateTime'     : LightningDateTimeExt,
        'Time'         : LightningTimeExt,
        'Email'        : LightningEmailExt,
        'Phone'        : LightningPhoneExt,
        'Url'          : LightningUrlExt,
        'PlainTextArea': LightningTextAreaExt,
        'RichTextArea' : LightningRichTextExt,
        'Reference'    : LightningReferenceExt,
        'Picklist'     : LightningPicklistExt,
        'MultiPicklist': LightningMultiPicklistExt,
        'Address'      : LightningAddressExt,
    }
}

/**
 * Extends RecordFormField instance with custom methods and properties based on field type
 */
export function extendCtrl(cmp, {fieldInfo, formAttributes}) {
    try {
        const designSystem = formAttributes.designSystem ?? "lightning";
        let extensionName = fieldInfo.dataType;
        if (extensionName === 'TextArea') extensionName = fieldInfo.extraTypeInfo;

        const extension = EXTENSIONS[designSystem][extensionName];
        if (extension) {
            extendInstance(cmp, extension.prototype);
        }
    } catch (e) {
        console.error('extensions.js extendCtrl', e.message);
    }
}

/**
 * Apply extension class methods and properties onto RecordFormField instance
 */
function extendInstance(cmp, source) {
    // accept either a class/constructor or a prototype object
    const proto = (typeof source === 'function') ? source.prototype : source;
    if (!proto) return cmp;

    // collect prototype chain from root (excluding Object.prototype) to the provided prototype
    const protos = [];
    let p = proto;
    while (p && p !== Object.prototype) {
        protos.unshift(p);
        p = Object.getPrototypeOf(p);
    }

    // accumulate descriptors; later (subclass) descriptors overwrite earlier (superclass) ones
    const accumulated = {};
    for (const pr of protos) {
        const descs = Object.getOwnPropertyDescriptors(pr);
        delete descs.constructor; // don't copy the constructor
        const names = Object.getOwnPropertyNames(descs);
        const syms = Object.getOwnPropertySymbols(descs);
        for (const key of names.concat(syms)) {
            accumulated[key] = descs[key];
        }
    }

    // define all accumulated descriptors on the instance
    Object.defineProperties(cmp, accumulated);
    return cmp;
}