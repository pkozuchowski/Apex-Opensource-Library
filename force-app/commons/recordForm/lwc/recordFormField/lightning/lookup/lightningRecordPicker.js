import LightningRecordPicker from './lightningRecordPicker.html';
import {LightningInputExt} from "../input/lightningInput";

export class LightningReferenceExt extends LightningInputExt {
    objectApiName;

    renderExt() {
        return LightningRecordPicker;
    }

    connectFieldExt({fieldInfo}) {
        super.connectFieldExt(arguments[0]);
        this.objectApiName = fieldInfo.referenceToInfos[0].apiName;
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