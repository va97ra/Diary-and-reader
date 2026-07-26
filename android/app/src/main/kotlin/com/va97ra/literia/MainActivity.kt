package com.va97ra.literia

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity
import java.io.File
import java.util.UUID

class MainActivity : AudioServiceActivity() {
    private var pendingFolderResult: MethodChannel.Result? = null
    private var pendingDownloadsAccessResult: MethodChannel.Result? = null
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "hasDownloadsAccess" -> result.success(hasDownloadsAccess())
                "requestDownloadsAccess" -> requestDownloadsAccess(result)
                "scanDownloads" -> runInBackground(result) { scanDownloads() }
                "chooseFolder" -> chooseFolder(result)
                "saveTextFile" -> {
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (fileName.isNullOrBlank() || bytes == null) {
                        result.error("invalid_file", "The backup data is missing.", null)
                    } else {
                        saveTextFile(
                            fileName = fileName,
                            mimeType = mimeType ?: "application/octet-stream",
                            bytes = bytes,
                            result = result,
                        )
                    }
                }
                "scanFolders" -> {
                    val uris = call.argument<List<String>>("uris").orEmpty()
                    runInBackground(result) { scanFolders(uris) }
                }
                "materialize" -> {
                    val uri = call.argument<String>("uri")
                    if (uri.isNullOrBlank()) {
                        result.error("invalid_uri", "The book URI is missing.", null)
                    } else {
                        runInBackground(result) { materialize(Uri.parse(uri)) }
                    }
                }
                "releaseFolder" -> {
                    val uri = call.argument<String>("uri")
                    if (!uri.isNullOrBlank()) releaseFolder(Uri.parse(uri))
                    result.success(null)
                }
                "availableBytes" -> result.success(StatFs(filesDir.path).availableBytes)
                else -> result.notImplemented()
            }
        }
    }

    private fun hasDownloadsAccess(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }

    private fun requestDownloadsAccess(result: MethodChannel.Result) {
        if (hasDownloadsAccess()) {
            result.success(true)
            return
        }
        if (pendingDownloadsAccessResult != null) {
            result.error("permission_busy", "The storage permission request is already open.", null)
            return
        }
        pendingDownloadsAccessResult = result
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val appSettings = Intent(
                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:$packageName"),
            )
            try {
                startActivityForResult(appSettings, REQUEST_DOWNLOADS_ACCESS)
            } catch (_: Exception) {
                startActivityForResult(
                    Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION),
                    REQUEST_DOWNLOADS_ACCESS,
                )
            }
        } else {
            requestPermissions(
                arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                REQUEST_DOWNLOADS_ACCESS,
            )
        }
    }

    private fun chooseFolder(result: MethodChannel.Result) {
        if (pendingFolderResult != null) {
            result.error("picker_busy", "The folder picker is already open.", null)
            return
        }
        pendingFolderResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(
                    DocumentsContract.EXTRA_INITIAL_URI,
                    Uri.parse(STORAGE_ROOT_URI),
                )
            }
        }
        startActivityForResult(intent, REQUEST_FOLDER)
    }

    private fun saveTextFile(
        fileName: String,
        mimeType: String,
        bytes: ByteArray,
        result: MethodChannel.Result,
    ) {
        if (pendingSaveResult != null) {
            result.error("picker_busy", "The save dialog is already open.", null)
            return
        }
        pendingSaveResult = result
        pendingSaveBytes = bytes
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, fileName)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(
                    DocumentsContract.EXTRA_INITIAL_URI,
                    Uri.parse(DOWNLOADS_URI),
                )
            }
        }
        try {
            startActivityForResult(intent, REQUEST_SAVE_FILE)
        } catch (error: Exception) {
            pendingSaveResult = null
            pendingSaveBytes = null
            result.error("save_unavailable", error.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_DOWNLOADS_ACCESS) {
            val result = pendingDownloadsAccessResult
            pendingDownloadsAccessResult = null
            result?.success(hasDownloadsAccess())
            return
        }
        if (requestCode == REQUEST_SAVE_FILE) {
            val result = pendingSaveResult
            val bytes = pendingSaveBytes
            pendingSaveResult = null
            pendingSaveBytes = null
            val uri = data?.data
            if (result == null) return
            if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) {
                result.success(false)
                return
            }
            runInBackground(result) {
                val output = contentResolver.openOutputStream(uri, "wt")
                    ?: throw IllegalStateException("The selected file cannot be written.")
                output.use {
                    it.write(bytes)
                    it.flush()
                }
                true
            }
            return
        }
        if (requestCode != REQUEST_FOLDER) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingFolderResult
        pendingFolderResult = null
        if (result == null) return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
            result.success(mapOf("uri" to uri.toString(), "name" to displayName(uri)))
        } catch (error: Exception) {
            result.error("folder_access", error.message, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (requestCode == REQUEST_DOWNLOADS_ACCESS) {
            val result = pendingDownloadsAccessResult
            pendingDownloadsAccessResult = null
            result?.success(hasDownloadsAccess())
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun scanDownloads(): Map<String, Any> {
        if (!hasDownloadsAccess()) {
            throw SecurityException("All files access is required to scan Downloads.")
        }
        val root = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!root.exists()) {
            return mapOf(
                "books" to emptyList<Map<String, Any>>(),
                "inaccessibleFolderUris" to listOf(root.absolutePath),
            )
        }
        val books = mutableListOf<Map<String, Any>>()
        var inspected = 0
        val iterator = root.walkTopDown().iterator()
        while (iterator.hasNext() && inspected < MAX_DOCUMENTS) {
            val file = iterator.next()
            inspected++
            if (!file.isFile || !isBookName(file.name)) continue
            books.add(
                mapOf(
                    "uri" to Uri.fromFile(file).toString(),
                    "name" to file.name,
                    "folderName" to root.name,
                    "size" to file.length().coerceAtLeast(0L),
                    "modified" to file.lastModified().coerceAtLeast(0L),
                ),
            )
        }
        return mapOf(
            "books" to books,
            "inaccessibleFolderUris" to emptyList<String>(),
        )
    }

    private fun scanFolders(uris: List<String>): Map<String, Any> {
        val books = mutableListOf<Map<String, Any>>()
        val inaccessible = mutableListOf<String>()
        for (rawUri in uris.distinct()) {
            try {
                val treeUri = Uri.parse(rawUri)
                val rootId = DocumentsContract.getTreeDocumentId(treeUri)
                val rootName = displayName(
                    DocumentsContract.buildDocumentUriUsingTree(treeUri, rootId),
                )
                scanDocumentTree(treeUri, rootId, rootName, books)
            } catch (_: Exception) {
                inaccessible.add(rawUri)
            }
        }
        return mapOf("books" to books, "inaccessibleFolderUris" to inaccessible)
    }

    private fun scanDocumentTree(
        treeUri: Uri,
        rootDocumentId: String,
        rootName: String,
        output: MutableList<Map<String, Any>>,
    ) {
        val queue = ArrayDeque<String>()
        val visited = mutableSetOf<String>()
        queue.add(rootDocumentId)
        var inspected = 0
        while (queue.isNotEmpty() && inspected < MAX_DOCUMENTS) {
            val parentId = queue.removeFirst()
            if (!visited.add(parentId)) continue
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                treeUri,
                parentId,
            )
            contentResolver.query(childrenUri, PROJECTION, null, null, null)?.use { cursor ->
                val idIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val nameIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val mimeIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)
                val sizeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
                val modifiedIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
                while (cursor.moveToNext() && inspected < MAX_DOCUMENTS) {
                    inspected++
                    val documentId = cursor.getString(idIndex)
                    val name = cursor.getString(nameIndex).orEmpty()
                    val mime = cursor.getString(mimeIndex).orEmpty()
                    if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                        queue.add(documentId)
                    } else if (isBookName(name)) {
                        val documentUri = DocumentsContract.buildDocumentUriUsingTree(
                            treeUri,
                            documentId,
                        )
                        output.add(
                            mapOf(
                                "uri" to documentUri.toString(),
                                "name" to name,
                                "folderName" to rootName,
                                "size" to cursor.longOrZero(sizeIndex),
                                "modified" to cursor.longOrZero(modifiedIndex),
                            ),
                        )
                    }
                }
            }
        }
    }

    private fun materialize(uri: Uri): Map<String, Any> {
        val sourceFile = if (uri.scheme.equals("file", ignoreCase = true)) {
            uri.path?.let(::File)
        } else {
            null
        }
        val name = (sourceFile?.name ?: displayName(uri)).ifBlank { "book" }
        val extension = when {
            name.lowercase().endsWith(".fb2.zip") -> ".fb2.zip"
            name.lowercase().endsWith(".epub") -> ".epub"
            name.lowercase().endsWith(".fb2") -> ".fb2"
            name.lowercase().endsWith(".txt") -> ".txt"
            name.lowercase().endsWith(".rtf") -> ".rtf"
            name.lowercase().endsWith(".docx") -> ".docx"
            name.lowercase().endsWith(".mobi") -> ".mobi"
            name.lowercase().endsWith(".doc") -> ".doc"
            name.lowercase().endsWith(".chm") -> ".chm"
            name.lowercase().endsWith(".zip") -> ".zip"
            else -> ".book"
        }
        val directory = File(cacheDir, "book-import").apply { mkdirs() }
        val target = File(directory, "${UUID.randomUUID()}$extension")
        try {
            val input = sourceFile?.inputStream()
                ?: contentResolver.openInputStream(uri)
                ?: throw IllegalStateException("The selected book cannot be opened.")
            input.use { source -> target.outputStream().use { source.copyTo(it) } }
            return mapOf(
                "path" to target.absolutePath,
                "name" to name,
                "size" to target.length(),
            )
        } catch (error: Exception) {
            target.delete()
            throw error
        }
    }

    private fun releaseFolder(uri: Uri) {
        try {
            contentResolver.releasePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // The grant may already have been revoked by Android settings.
        }
    }

    private fun displayName(uri: Uri): String {
        return contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) return@use null
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0) cursor.getString(index) else null
        } ?: uri.lastPathSegment.orEmpty()
    }

    private fun isBookName(name: String): Boolean {
        val lower = name.lowercase()
        return lower.endsWith(".epub") ||
            lower.endsWith(".fb2") ||
            lower.endsWith(".zip") ||
            lower.endsWith(".txt") ||
            lower.endsWith(".rtf") ||
            lower.endsWith(".docx") ||
            lower.endsWith(".mobi") ||
            lower.endsWith(".doc") ||
            lower.endsWith(".chm")
    }

    private fun Cursor.longOrZero(index: Int): Long =
        if (index >= 0 && !isNull(index)) getLong(index).coerceAtLeast(0L) else 0L

    private fun runInBackground(result: MethodChannel.Result, operation: () -> Any?) {
        Thread {
            try {
                val value = operation()
                runOnUiThread { result.success(value) }
            } catch (error: Exception) {
                runOnUiThread { result.error("book_files", error.message, null) }
            }
        }.start()
    }

    companion object {
        private const val CHANNEL = "literia/book_files"
        private const val REQUEST_FOLDER = 7012
        private const val REQUEST_DOWNLOADS_ACCESS = 7013
        private const val REQUEST_SAVE_FILE = 7014
        private const val MAX_DOCUMENTS = 10_000
        private const val STORAGE_ROOT_URI =
            "content://com.android.externalstorage.documents/root/primary"
        private const val DOWNLOADS_URI =
            "content://com.android.externalstorage.documents/document/primary%3ADownload"
        private val PROJECTION = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
    }
}
