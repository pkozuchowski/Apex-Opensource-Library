import LightningRecordPicker from './lightningRecordPicker.html';
import {LightningInputExt} from "../input/lightningInput";

export class LightningReferenceExt extends LightningInputExt {
    objectApiName;

    renderExt() {
        return LightningRecordPicker;
    }

    connectFieldExt(data) {
        super.connectFieldExt(data);
        this.objectApiName = data.fieldInfo.referenceToInfos[0].apiName;
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