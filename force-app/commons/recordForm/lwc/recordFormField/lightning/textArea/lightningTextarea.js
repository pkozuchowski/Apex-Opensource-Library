import {LightningTextExt} from "../input/lightningInput";
import lightningTextarea from './lightningTextarea.html';
import lightningRichText from './lightningRichText.html';

export class LightningTextAreaExt extends LightningTextExt {
    get attributes() {
        return {
            ...super.attributes
        };
    }

    renderExt() {
        return lightningTextarea;
    }
}

export class LightningRichTextExt extends LightningTextExt {

    connectFieldExt() {
        this.formats = this.formats || ['font', 'size', 'bold', 'italic', 'underline', 'strike', 'list',
            'indent', 'align', 'link', 'image', 'clean', 'header', 'color'];
    }

    renderExt() {
        return lightningRichText;
    }

    get attributes() {
        return {
            ...super.attributes,
            formats          : this.formats,
            labelVisible     : true,
            shareWithEntityId: this.record?.Id
        };
    }
}