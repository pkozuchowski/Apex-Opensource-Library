import LightningRecordPicker from './lightningRecordPicker.html';
import {LightningInputExt} from "../input/lightningInput";

/**
 * For a polymorphic lookup, `fieldInfo.referenceToInfos` isn't guaranteed to come back
 * in a stable order, so picking [0] can resolve to a different object on every load.
 * Sorting by API name at least makes the un-overridden default deterministic.
 */
function getDefaultReferenceToApiName(fieldInfo) {
    return [...fieldInfo.referenceToInfos]
        .map(info => info.apiName)
        .sort()[0];
}

export class LightningReferenceExt extends LightningInputExt {
    objectApiName;

    renderExt() {
        return LightningRecordPicker;
    }

    connectFieldExt(data) {
        super.connectFieldExt(data);
        this.objectApiName = this.lookupObject || getDefaultReferenceToApiName(data.fieldInfo);
    }

    get attributes() {
        return {
            ...super.attributes,
            disabled: this.disabled || this.isReadOnly
        };
    }

    getEventValue(event) {
        return {[this.field]: event.detail.recordId};
    }

}