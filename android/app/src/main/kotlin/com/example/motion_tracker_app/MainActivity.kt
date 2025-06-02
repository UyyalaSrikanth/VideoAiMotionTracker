package com.example.motion_tracker_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import org.opencv.android.OpenCVLoaderCallback
import org.opencv.android.LoaderCallbackInterface
import org.opencv.android.BaseLoaderCallback
import org.opencv.core.Mat
import org.opencv.core.Point
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc
import org.opencv.features2d.Features2d
import org.opencv.core.MatOfPoint2f
import org.opencv.core.MatOfByte
import org.opencv.video.Video
import org.opencv.android.Utils
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "motion_tracker/opencv"
    private var isOpenCVInitialized = false
    
    private val openCVLoaderCallback = object : BaseLoaderCallback(this) {
        override fun onManagerConnected(status: Int) {
            when (status) {
                LoaderCallbackInterface.SUCCESS -> {
                    isOpenCVInitialized = true
                    println("OpenCV loaded successfully")
                }
                else -> {
                    super.onManagerConnected(status)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeOpenCV" -> {
                    initializeOpenCV()
                    result.success(isOpenCVInitialized)
                }
                "detectFeatures" -> {
                    val imageData = call.argument<ByteArray>("imageData")
                    val width = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    val maxCorners = call.argument<Int>("maxCorners") ?: 100
                    val qualityLevel = call.argument<Double>("qualityLevel") ?: 0.01
                    val minDistance = call.argument<Double>("minDistance") ?: 10.0
                    
                    if (imageData != null && isOpenCVInitialized) {
                        try {
                            val features = detectGoodFeatures(imageData, width, height, maxCorners, qualityLevel, minDistance)
                            result.success(features)
                        } catch (e: Exception) {
                            result.error("DETECTION_ERROR", "Failed to detect features: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Invalid arguments or OpenCV not initialized", null)
                    }
                }
                "trackOpticalFlow" -> {
                    val prevFrame = call.argument<ByteArray>("prevFrame")
                    val currFrame = call.argument<ByteArray>("currFrame")
                    val prevPoints = call.argument<List<Map<String, Double>>>("prevPoints")
                    val width = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    
                    if (prevFrame != null && currFrame != null && prevPoints != null && isOpenCVInitialized) {
                        try {
                            val trackedPoints = trackOpticalFlowPyrLK(prevFrame, currFrame, prevPoints, width, height)
                            result.success(trackedPoints)
                        } catch (e: Exception) {
                            result.error("TRACKING_ERROR", "Failed to track optical flow: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Invalid arguments or OpenCV not initialized", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (!isOpenCVInitialized) {
            initializeOpenCV()
        }
    }

    private fun initializeOpenCV() {
        if (!org.opencv.android.OpenCVLoader.initDebug()) {
            org.opencv.android.OpenCVLoader.initAsync(org.opencv.android.OpenCVLoader.OPENCV_VERSION, this, openCVLoaderCallback)
        } else {
            openCVLoaderCallback.onManagerConnected(LoaderCallbackInterface.SUCCESS)
        }
    }

    private fun detectGoodFeatures(
        imageData: ByteArray,
        width: Int,
        height: Int,
        maxCorners: Int,
        qualityLevel: Double,
        minDistance: Double
    ): List<Map<String, Double>> {
        // Convert byte array to OpenCV Mat
        val bitmap = BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
        val mat = Mat()
        Utils.bitmapToMat(bitmap, mat)
        
        // Convert to grayscale
        val grayMat = Mat()
        Imgproc.cvtColor(mat, grayMat, Imgproc.COLOR_RGB2GRAY)
        
        // Detect good features to track
        val corners = MatOfPoint2f()
        Imgproc.goodFeaturesToTrack(
            grayMat,
            corners,
            maxCorners,
            qualityLevel,
            minDistance
        )
        
        // Convert to list of points
        val points = corners.toArray()
        val result = mutableListOf<Map<String, Double>>()
        
        for (point in points) {
            result.add(mapOf(
                "x" to point.x,
                "y" to point.y
            ))
        }
        
        return result
    }

    private fun trackOpticalFlowPyrLK(
        prevFrameData: ByteArray,
        currFrameData: ByteArray,
        prevPoints: List<Map<String, Double>>,
        width: Int,
        height: Int
    ): List<Map<String, Any?>> {
        // Convert byte arrays to OpenCV Mats
        val prevBitmap = BitmapFactory.decodeByteArray(prevFrameData, 0, prevFrameData.size)
        val currBitmap = BitmapFactory.decodeByteArray(currFrameData, 0, currFrameData.size)
        
        val prevMat = Mat()
        val currMat = Mat()
        Utils.bitmapToMat(prevBitmap, prevMat)
        Utils.bitmapToMat(currBitmap, currMat)
        
        // Convert to grayscale
        val prevGray = Mat()
        val currGray = Mat()
        Imgproc.cvtColor(prevMat, prevGray, Imgproc.COLOR_RGB2GRAY)
        Imgproc.cvtColor(currMat, currGray, Imgproc.COLOR_RGB2GRAY)
        
        // Convert previous points to OpenCV format
        val prevPointsArray = prevPoints.map { 
            Point(it["x"] ?: 0.0, it["y"] ?: 0.0) 
        }.toTypedArray()
        val prevPointsMat = MatOfPoint2f(*prevPointsArray)
        
        // Track points using optical flow
        val nextPointsMat = MatOfPoint2f()
        val status = MatOfByte()
        val error = Mat()
        
        Video.calcOpticalFlowPyrLK(
            prevGray,
            currGray,
            prevPointsMat,
            nextPointsMat,
            status,
            error
        )
        
        // Convert results back to list
        val nextPoints = nextPointsMat.toArray()
        val statusArray = status.toArray()
        val result = mutableListOf<Map<String, Any?>>()
        
        for (i in nextPoints.indices) {
            if (i < statusArray.size && statusArray[i][0] == 1.0.toByte()) {
                // Point was successfully tracked
                result.add(mapOf(
                    "x" to nextPoints[i].x,
                    "y" to nextPoints[i].y,
                    "tracked" to true
                ))
            } else {
                // Point was lost
                result.add(mapOf(
                    "x" to null,
                    "y" to null,
                    "tracked" to false
                ))
            }
        }
        
        return result
    }
}

