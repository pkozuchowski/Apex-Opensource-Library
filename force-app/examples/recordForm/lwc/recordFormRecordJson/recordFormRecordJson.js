// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Piotr Kożuchowski
import RecordFormComponent from "c/recordFormComponent";
import {api} from "lwc";

export default class RecordFormRecordJson extends RecordFormComponent {
    static renderMode = "light";

    @api
    connectField({ fieldInfo, objectInfo }) {}

    get recordJson() {
        return JSON.stringify(this.record, null, 2);
    }
}
