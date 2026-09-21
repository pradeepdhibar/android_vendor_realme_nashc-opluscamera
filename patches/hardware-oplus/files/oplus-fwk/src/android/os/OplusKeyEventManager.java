package android.os;

import android.content.Context;
import android.util.ArrayMap;
import android.view.KeyEvent;

public class OplusKeyEventManager {

    private static final OplusKeyEventManager sInstance =
            new OplusKeyEventManager();

    private OplusKeyEventManager() {
    }

    public static OplusKeyEventManager getInstance() {
        return sInstance;
    }

    public interface OnKeyEventObserver {
        void onKeyEvent(KeyEvent event);
    }

    public boolean registerKeyEventInterceptor(
            Context context,
            String interceptorKey,
            OnKeyEventObserver observer,
            ArrayMap configs) {
        // Compatibility shim: nashc has no Oplus key-event service on AOSP.
        return true;
    }

    public boolean unregisterKeyEventInterceptor(
            Context context,
            String interceptorKey,
            OnKeyEventObserver observer) {
        return true;
    }

    public boolean registerKeyEventObserver(
            Context context,
            OnKeyEventObserver observer,
            int listenFlag) {
        return true;
    }

    public boolean unregisterKeyEventObserver(
            Context context,
            OnKeyEventObserver observer) {
        return true;
    }

    public int getVersion() {
        return 1;
    }
}
