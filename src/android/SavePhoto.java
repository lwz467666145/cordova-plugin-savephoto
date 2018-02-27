package com.chinact.mobile.plugin.savephoto;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PermissionHelper;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

public class SavePhoto extends CordovaPlugin {

    private static Activity cordovaActivity;
    public static final int SAVE_TO_ALBUM_SEC = 1;
    public CallbackContext callback;
    private String floderName;
    private String fileOldPath;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        cordovaActivity = cordova.getActivity();
    }

    @Override
    public boolean execute(final String action, final JSONArray data, final CallbackContext callbackContext) throws JSONException {
        floderName = "SavePhoto";
        callback = callbackContext;
        try {
            ApplicationInfo appInfo = cordovaActivity.getPackageManager().getApplicationInfo(cordovaActivity.getPackageName(), PackageManager.GET_META_DATA);
            floderName = appInfo.metaData.getString("com.chinact.mobile.plugin.savephoto.FLODER_NAME");
        } catch (Exception e) {
            e.printStackTrace();
        }
        if ("save".equals(action)) {
            String path = data.getString(0);
            fileOldPath = cordovaActivity.getApplicationContext().getCacheDir() + path.substring(path.indexOf("/cache/") + 6);
            File oldFile = new File(fileOldPath);
            if (oldFile.exists())
                checkPermission();
        }
        return true;
    }

    private void checkPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            boolean savePermission = PermissionHelper.hasPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE);
            if (savePermission)
                copyFile();
            else
                PermissionHelper.requestPermission(this, SAVE_TO_ALBUM_SEC, Manifest.permission.WRITE_EXTERNAL_STORAGE);
        } else
            copyFile();
    }

    private void copyFile() {
        try {
            String[] list = fileOldPath.split("/");
            File file = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM).getAbsolutePath() + "/" + floderName);
            if (!file.exists())
                file.mkdirs();
            String fileNewPath = file.getAbsolutePath() + "/" + list[list.length - 1];
            FileInputStream fis = new FileInputStream(fileOldPath);
            FileOutputStream fos = new FileOutputStream(fileNewPath);
            int byteread = 0;
            byte[] buffer = new byte[1024];
            while ((byteread = fis.read(buffer)) != -1) {
                fos.write(buffer, 0, byteread);
            }
            fis.close();
            fos.close();
            Intent intent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
            Uri uri = Uri.fromFile(new File(fileNewPath));
            intent.setData(uri);
            cordovaActivity.sendBroadcast(intent);
            callback.success();
        } catch (Exception e) {
            callback.error("Authorized Failed");
            e.printStackTrace();
        }
    }

    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
        for (int r : grantResults) {
            if (r == PackageManager.PERMISSION_DENIED) {
                callback.error("Authorized Failed");
                return;
            }
        }
        switch (requestCode) {
            case SAVE_TO_ALBUM_SEC:
                copyFile();
                break;
        }
    }
    
}