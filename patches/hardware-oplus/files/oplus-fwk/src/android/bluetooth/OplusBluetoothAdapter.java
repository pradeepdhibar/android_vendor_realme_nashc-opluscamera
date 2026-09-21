package android.bluetooth;

public class OplusBluetoothAdapter {
    private static final OplusBluetoothAdapter INSTANCE =
            new OplusBluetoothAdapter();

    private OplusBluetoothAdapter() {
    }

    public static OplusBluetoothAdapter getOplusBluetoothAdapter() {
        return INSTANCE;
    }

    public boolean isBluetoothRecordConnected() {
        return false;
    }
}
