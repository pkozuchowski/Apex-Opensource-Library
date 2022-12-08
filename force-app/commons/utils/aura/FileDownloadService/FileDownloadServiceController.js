({

    handleDownload: function (cmp, event, helper) {
        const params = event.getParam('arguments');
        const data = params.data;
        const fileName = params.fileName;


        const fileReader = new FileReader();
        fileReader.onload = function (e) {
            const link = document.createElement("a");
            link.href = e.target.result;
            link.download = fileName;
            document.body.appendChild(link);
            link.click();
            link.remove();
        };
        fileReader.readAsDataURL(data);
    }
});