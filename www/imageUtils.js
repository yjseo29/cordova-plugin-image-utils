var exec = require('cordova/exec');
const SERVICE = "ImageUtils";

function ImageUtils() { }

ImageUtils.prototype.compressImage = function(param, success, error){
	exec(success, error, SERVICE, 'compressImage', [param]);
};

ImageUtils.prototype.extractThumbnail = function(param, success, error){
	exec(success, error, SERVICE, 'extractThumbnail', [param]);
};

ImageUtils.prototype.getFileInfo = function(path, type, success, error){
	exec(success, error, SERVICE, 'getFileInfo', [path, type]);
};

ImageUtils.prototype.getExifForKey = function(path, tag, success, error){
	exec(success, error, SERVICE, 'getExifForKey', [path, tag]);
};

var imageUtils = new ImageUtils();
module.exports = imageUtils;