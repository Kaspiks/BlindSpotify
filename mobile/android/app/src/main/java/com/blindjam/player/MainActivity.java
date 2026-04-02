package com.blindjam.player;

import android.os.Bundle;
import android.view.View;
import android.webkit.WebSettings;
import android.webkit.WebView;

import com.getcapacitor.BridgeActivity;

/**
 * Capacitor entry with WebView performance tuning.
 * <p>
 * "on a destroyed WebView" in Logcat usually means async work (live reload, plugin callback, or
 * activity recreate) touched the bridge after teardown — avoid {@code cap run -l} when profiling;
 * use {@code chrome://inspect} for JS errors.
 */
public class MainActivity extends BridgeActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Capacitor's bridge creates the WebView; grab it and tune settings.
        WebView webView = getBridge().getWebView();
        if (webView != null) {
            webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);

            WebSettings ws = webView.getSettings();
            ws.setDomStorageEnabled(true);
            ws.setCacheMode(WebSettings.LOAD_DEFAULT);
            ws.setDatabaseEnabled(true);
            // Render immediately, don't wait for full page load.
            ws.setRenderPriority(WebSettings.RenderPriority.HIGH);
            ws.setBlockNetworkImage(false);
        }
    }
}
