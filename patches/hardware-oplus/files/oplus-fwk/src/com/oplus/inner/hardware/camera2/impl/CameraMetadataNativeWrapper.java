package com.oplus.inner.hardware.camera2.impl;

import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.CaptureResult;
import android.util.Log;

import java.lang.reflect.Field;

public class CameraMetadataNativeWrapper {
    private static final String TAG = "CameraMetadataNativeWrapper";

    public CameraMetadataNativeWrapper() {
    }

    public static long getMetadataPtr(Object obj) {
        if (obj == null) {
            return 0L;
        }

        try {
            final Object nativeMeta;

            if (obj instanceof CameraCharacteristics) {
                Field f = CameraCharacteristics.class.getDeclaredField("mProperties");
                f.setAccessible(true);
                nativeMeta = f.get(obj);
            } else if (obj instanceof CaptureRequest) {
                Field f = CaptureRequest.class.getDeclaredField("mLogicalCameraSettings");
                f.setAccessible(true);
                nativeMeta = f.get(obj);
            } else if (obj instanceof CaptureResult) {
                Field f = CaptureResult.class.getDeclaredField("mResults");
                f.setAccessible(true);
                nativeMeta = f.get(obj);
            } else {
                nativeMeta = obj;
            }

            if (nativeMeta == null) {
                Log.e(TAG, "Unwrapped metadata is null!");
                return 0L;
            }

            Field ptrField =
                    nativeMeta.getClass().getDeclaredField("mMetadataPtr");
            ptrField.setAccessible(true);

            return ptrField.getLong(nativeMeta);
        } catch (Exception e) {
            Log.e(TAG, "Failed to get ptr from "
                    + obj.getClass().getName(), e);
            return 0L;
        }
    }
}
