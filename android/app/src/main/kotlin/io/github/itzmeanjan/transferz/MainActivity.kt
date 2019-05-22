package io.github.itzmeanjan.transferz

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.*
import android.provider.MediaStore
import android.view.Gravity
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File

class MainActivity : FlutterActivity() {
    private val methodChannelName = "io.github.itzmeanjan.transferz"
    private val multiCastLockTag = "io.github.itzmeanjan.transferz"
    private lateinit var wifiMultiCastLock: WifiManager.MulticastLock
    private lateinit var methodChannel: MethodChannel
    private lateinit var permissionResultHandler: PermissionResultHandler
    private lateinit var fileChooserCallBack: FileChooserCallBack
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        methodChannel = MethodChannel(flutterView, methodChannelName)
        methodChannel.setMethodCallHandler { methodCall, result ->
            when (methodCall.method) {
                "isPermissionAvailable" -> {
                    result.success(isPermissionAvailable())
                }
                "requestPermission" -> {
                    permissionResultHandler = object : PermissionResultHandler {
                        override fun granted() {
                            result.success(true)
                        }

                        override fun denied() {
                            result.success(false)
                        }

                    }
                    requestPermission()
                }
                "getHomeDir" -> {
                    result.success(getHomeDir(methodCall.argument<String>("dirName")!!))
                }
                "initFileChooser" -> {
                    fileChooserCallBack = object : FileChooserCallBack {
                        override fun send(filePaths: List<String>) {
                            result.success(filePaths)
                        }
                    }
                    initFileChooser()
                }
                "showToast" -> {
                    Toast.makeText(this, methodCall.argument<String>("message"), if (methodCall.argument<String>("duration") == "long") Toast.LENGTH_LONG else Toast.LENGTH_SHORT).apply {
                        setGravity(Gravity.CENTER, 0, 0)
                        show()
                    }
                }
                "vibrateDevice" -> {
                    vibrateDevice(methodCall.argument<String>("type")!!)
                }
                "isConnected" -> {
                    result.success(isConnected())
                }
                "acquireWifiMultiCastLock" -> {
                    (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).createMulticastLock(multiCastLockTag).also {
                        wifiMultiCastLock = it
                        it.acquire()
                    }
                }
                "releaseWifiMultiCastLock" -> {
                    if(wifiMultiCastLock.isHeld) wifiMultiCastLock.release()
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            999 -> {
                if (permissions.isNotEmpty() && grantResults.isNotEmpty()) {
                    if (permissions[0] == android.Manifest.permission.WRITE_EXTERNAL_STORAGE && grantResults[0] == PackageManager.PERMISSION_GRANTED)
                        permissionResultHandler.granted()
                    else
                        permissionResultHandler.denied()
                } else
                    permissionResultHandler.denied()
            }
            else -> {
                // doing nothing useful
            }
        }
    }

    private fun isPermissionAvailable(): Boolean {
        return ContextCompat.checkSelfPermission(applicationContext, android.Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermission() {
        ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE), 999)
    }

    private fun getHomeDir(dirName: String): String {
        return File(Environment.getExternalStorageDirectory(), dirName).absolutePath
    }

    private fun initFileChooser() {
        val intent = Intent()
        intent.action = Intent.ACTION_GET_CONTENT
        intent.type = "*/*"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2)
            intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true) // choosing multiple files is allowed if and only if API level is greater than 17
        startActivityForResult(intent, 998)
    }

    private fun vibrateDevice(type: String) {
        (getSystemService(Context.VIBRATOR_SERVICE) as Vibrator).apply {
            if (Build.VERSION.SDK_INT > Build.VERSION_CODES.N_MR1)
                vibrate(VibrationEffect.createOneShot(if (type == "default") 300 else 100, if (type == "default") VibrationEffect.DEFAULT_AMPLITUDE else 2))
            else
                vibrate(500)
        }
    }

    private fun isConnected(): Boolean =
            (getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager).activeNetworkInfo?.isConnected
                    ?: false

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            998 -> {
                if (resultCode == Activity.RESULT_OK) {
                    val filePaths = mutableListOf<String>()
                    if (data?.clipData != null) {
                        var i = 0
                        while (i < data.clipData?.itemCount!!) {
                            filePaths.add(uriToFilePath(data.clipData?.getItemAt(i)?.uri!!))
                            i++
                        }
                    } else
                        filePaths.add(uriToFilePath(data?.data!!))
                    fileChooserCallBack.send(filePaths)
                } else
                    fileChooserCallBack.send(listOf())
            }
            else -> {
                // doing nothing useful
            }
        }
    }

    private fun uriToFilePath(uri: Uri): String {
        val cursor = applicationContext.contentResolver.query(uri, arrayOf(MediaStore.MediaColumns.DATA), null, null, null)
        cursor?.moveToFirst()
        val tmp = cursor?.getString(0)
        cursor?.close()
        return tmp!!
    }
}

interface PermissionResultHandler {
    fun granted()
    fun denied()
}

interface FileChooserCallBack {
    fun send(filePaths: List<String>)
}