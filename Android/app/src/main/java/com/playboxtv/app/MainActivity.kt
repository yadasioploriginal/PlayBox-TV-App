package com.playboxtv.app

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView
    
    private val primaryURL = "https://stare.playboxtv.pl.eu.org/app"
    private val fallbackURLs = listOf(
        "https://tv.yadasiopl.pl.eu.org/app",
        "https://pbtv.netlify.app/app"
    )
    private var currentFallbackIndex = -1

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        webView = WebView(this)
        setContentView(webView)

        val settings: WebSettings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.mediaPlaybackRequiresUserGesture = false
        settings.allowFileAccess = true

        webView.webChromeClient = WebChromeClient()
        webView.webViewClient = object : WebViewClient() {
            override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                super.onReceivedError(view, request, error)
                if (request?.isForMainFrame == true) {
                    tryNextFallback()
                }
            }
        }

        loadCurrentURL()
    }

    private fun loadCurrentURL() {
        val url = if (currentFallbackIndex < 0) {
            primaryURL
        } else if (currentFallbackIndex < fallbackURLs.size) {
            fallbackURLs[currentFallbackIndex]
        } else {
            ""
        }

        if (url.isNotEmpty()) {
            webView.loadUrl(url)
        } else {
            Toast.makeText(this, "Nie udało się połączyć z żadnym serwerem", Toast.LENGTH_LONG).show()
        }
    }

    private fun tryNextFallback() {
        currentFallbackIndex++
        loadCurrentURL()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}
