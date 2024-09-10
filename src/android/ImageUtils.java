package org.apache.cordova;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.util.Base64;
import android.util.Log;

import androidx.exifinterface.media.ExifInterface;

import org.apache.cordova.camera.FileHelper;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.util.Objects;

public class ImageUtils extends CordovaPlugin {

    private static final String TAG = "ImageUtils";


    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        Log.d(TAG, "action : " + action);
        Log.d(TAG, "args : " + args.toString());

        if("compressImage".equals(action)){
            cordova.getThreadPool().execute(() -> compressImage(args, callbackContext));
            return true;
        }else if(action.equals("extractThumbnail")){
            cordova.getThreadPool().execute(() -> extractThumbnail(args, callbackContext));
            return true;
        }else if(action.equals("getFileInfo")){
            getFileInfo(args, callbackContext);
            return true;
        }else if(action.equals("getExifForKey")){
            getExifForKey(args.getString(0), args.getString(1), callbackContext);
            return true;
        }else{
            return false;
        }
    }

    public void compressImage(JSONArray args, CallbackContext callbackContext){
        try {
            JSONObject jsonObject = args.getJSONObject(0);
            String path = jsonObject.getString("path");
            int quality = jsonObject.getInt("quality");

            if(quality<100){
                ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                String compFileName = "compressImage_"+System.currentTimeMillis()+".jpg";
                File file = new File(cordova.getActivity().getExternalCacheDir(), compFileName);

                if(path.startsWith("content://")){
                    path = FileHelper.getRealPath(path, cordova);
                }
                rotatingImage(getBitmapRotate(path), BitmapFactory.decodeFile(path)).compress(Bitmap.CompressFormat.JPEG, quality, byteArrayOutputStream);

                try {
                    FileOutputStream fos = new FileOutputStream(file);
                    fos.write(byteArrayOutputStream.toByteArray());
                    fos.flush();
                    fos.close();
                } catch (Exception e) {
                    Log.e(TAG, "compressImage failed :", e);
                    callbackContext.error(e.getMessage());
                }

                jsonObject.put("path", file.getPath());
                jsonObject.put("uri", Uri.fromFile(file));
                jsonObject.put("size", file.length());
                jsonObject.put("name", file.getName());
                callbackContext.success(jsonObject);
            }else{
                callbackContext.success(jsonObject);
            }
        } catch (Exception e) {
            Log.e(TAG, "compressImage failed :", e);
            callbackContext.error(e.getMessage());
        }
    }

    public void extractThumbnail(JSONArray args, CallbackContext callbackContext){
        JSONObject jsonObject;
        if (args != null && args.length() > 0) {
            int thumbnailQuality;
            int thumbnailW;
            int thumbnailH;

            try {
                jsonObject = args.getJSONObject(0);

                thumbnailQuality = jsonObject.getInt("thumbnailQuality");
                thumbnailW = jsonObject.getInt("thumbnailW");
                thumbnailH = jsonObject.getInt("thumbnailH");

                String path = jsonObject.getString("path");
                jsonObject.put("exifRotate", getBitmapRotate(path));

                Bitmap thumbImage = ThumbnailUtils.extractThumbnail(BitmapFactory.decodeStream(FileHelper.getInputStreamFromUriString(path, cordova)), thumbnailW, thumbnailH);
                ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                thumbImage.compress(Bitmap.CompressFormat.JPEG, thumbnailQuality, byteArrayOutputStream);
                byte[] imageBytes = byteArrayOutputStream.toByteArray();
                byteArrayOutputStream.close();
                jsonObject.put("thumbnailBase64", Base64.encodeToString(imageBytes, Base64.NO_WRAP));

                callbackContext.success(jsonObject);
            } catch (Exception e) {
                Log.e(TAG, "extractThumbnail failed :", e);
                callbackContext.error(e.getMessage());
            }
        }
    }

    public int getBitmapRotate(String path){
        int degree = 0;
        try {
            ExifInterface exifInterface;

            if(path.startsWith("file:///android_asset/")){
                Uri uri = Uri.parse(path);
                exifInterface = new ExifInterface(cordova.getActivity().getAssets().open(Objects.requireNonNull(uri.getPath()).substring(15)));
            }else{
                if(path.startsWith("content://")){
                    path = FileHelper.getRealPath(path, cordova);
                }
                exifInterface = new ExifInterface(path);
            }

            int orientation = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION,ExifInterface.ORIENTATION_NORMAL);
            switch (orientation) {
                case ExifInterface.ORIENTATION_ROTATE_90:
                    degree = 90;
                    break;
                case ExifInterface.ORIENTATION_ROTATE_180:
                    degree = 180;
                    break;
                case ExifInterface.ORIENTATION_ROTATE_270:
                    degree = 270;
                    break;
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage(), e);
        }
        return degree;
    }

    public void getExifForKey(String path, String tag, CallbackContext callbackContext){
        try {
            ExifInterface exifInterface;

            if(path.startsWith("file:///android_asset/")){
                Uri uri = Uri.parse(path);
                exifInterface = new ExifInterface(cordova.getActivity().getAssets().open(Objects.requireNonNull(uri.getPath()).substring(15)));
            }else{
                if(path.startsWith("content://")){
                    path = FileHelper.getRealPath(path, cordova);
                }
                exifInterface = new ExifInterface(path);
            }

            String object = exifInterface.getAttribute(tag);
            callbackContext.success(object);
        } catch (Exception e) {
            Log.e(TAG, "getExifForKey failed :", e);
            callbackContext.error(e.getMessage());
        }
    }

    public void getFileInfo(JSONArray args, CallbackContext callbackContext){
        try {
            File file;
            String path = args.getString(0);

            if(path.startsWith("content://")){
                file = new File(FileHelper.getRealPath(path, cordova));
            }else{
                file = new File(path);
            }

            JSONObject jsonObject = new JSONObject();
            jsonObject.put("path", file.getPath());
            jsonObject.put("uri", Uri.fromFile(file));
            jsonObject.put("size", file.length());
            jsonObject.put("name", file.getName());
            String mimeType = FileHelper.getMimeType(jsonObject.getString("uri"), cordova);
            jsonObject.put("mediaType", mimeType.contains("video") ? "video" : "image");
            callbackContext.success(jsonObject);
        } catch (Exception e) {
            Log.e(TAG, "getFileInfo failed :", e);
            callbackContext.error(e.getMessage());
        }
    }

    private static Bitmap rotatingImage(int angle, Bitmap bitmap){
        Matrix matrix = new Matrix();
        matrix.postRotate(angle);

        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
    }
}
