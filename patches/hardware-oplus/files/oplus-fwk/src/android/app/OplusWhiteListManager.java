package android.app;

import android.content.Context;

import java.util.ArrayList;

public class OplusWhiteListManager {

    public OplusWhiteListManager(Context context) {
    }

    public ArrayList<String> getStageProtectListFromPkg(String callerPkg, int type) {
        return new ArrayList<>();
    }

    @Deprecated
    public void addStageProtectInfo(String pkg, long timeout) {
        // No-op on AOSP/crDroid.
    }

    public void removeStageProtectInfo(String pkg) {
        // No-op on AOSP/crDroid.
    }
}
