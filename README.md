# cordova-plugin-savephoto
Save Photo To System Album

# Install
cordova plugin add https://github.com/lwz467666145/cordova-plugin-savephoto.git --variable FLODER_NAME=FloderName

# User
// path - 图片网络地址
navigator.savePhoto.save(path, function () {
  // 保存成功回调方法
}, function () {
  // 保存失败回调方法
}, function () {
  // 开始保存回调方法，配合进度回调方法
}, function () {
  // 进度回调方法，配合开始保存回调方法，用以显示下载图片进度
});
