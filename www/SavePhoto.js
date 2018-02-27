
var exec = require('cordova/exec');

exports.save = function (path, success, error, start, progress) {
    window.resolveLocalFileSystemURL(cordova.file.cacheDirectory, function (dirEntry) {
    	if (start)
	    	start();
        var fileTransfer = new FileTransfer();
        fileTransfer.onprogress = function (progressEvent) {
            if (progressEvent.lengthComputable && progress)
                progress(progressEvent);
        };
        var array = path.split('.'), suffix = array[array.length - 1], name = new Date().getTime().toString() + Math.round(Math.random() * 1000000) + '.' + suffix;
        fileTransfer.download(encodeURI(path), dirEntry.nativeURL + name, function (fileEntry) {
            exec(success, error, 'SavePhoto', 'save', [fileEntry.nativeURL]);
        }, function (response) {
            error(response);
        });
    });
};
