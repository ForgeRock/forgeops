/*
* Forgeops Backup to Google Cloud Storage Simulation
*
* Copyright (c) 2019-2024 Ping Identity Corporation. Use of this source code is subject to the
* Common Development and Distribution License (CDDL) that can be found in the LICENSE file
*/
package gsutil

import java.io.{File, FileInputStream}
import java.nio.file.Paths
import java.text.SimpleDateFormat
import java.util.Date

import com.google.auth.oauth2.GoogleCredentials
import com.google.cloud.storage.Storage.BlobListOption
import com.google.cloud.storage.{Blob, BlobInfo, Storage, StorageOptions}
import org.zeroturnaround.zip.ZipUtil

import scala.util.Random
import scala.util.Properties

trait GoogleStorageClient {
  val bucket: String = Properties.envOrElse("PERF_TEST_RESULTS_BUCKET_NAME", "forgeops-gatling")
  val fileNameSuffix: String = Properties.envOrElse("HOSTNAME", Random.alphanumeric.take(10).mkString(""))
  val downloadPath: String = Properties.envOrElse("PERF_TEST_LOG_DOWNLOAD_PATH", "build/reports/downloadedLogs")
  // The library assumes the env variable GOOGLE_APPLICATION_CREDENTIALS points to a
  // a service account json file.
  val storageClient: Storage = StorageOptions.getDefaultInstance.getService
}

trait fsUtils {

  def getListOfDirs(dir: String): List[File] = {
    val d = new File(dir)
    if (d.exists && d.isDirectory) {
      d.listFiles.filter(_.isDirectory).toList
    } else {
      List[File]()
    }
  }

}

object LogUploader extends GoogleStorageClient with fsUtils {

  @throws[Exception]
  def main(args: Array[String]): Unit = {

    val fileList = getListOfDirs("build/reports/gatling")
    val reportDir = fileList.head

    // deprecated - but works. The InputStream can only be consumed once - so retry is not possible
    // TODO: read input stream into byte[] array
    storageClient.create(
      BlobInfo.newBuilder(bucket, s"simulation-$fileNameSuffix.log").build(),
      new FileInputStream(s"$reportDir/simulation.log")
    )
  }

}

object LogDownloader extends GoogleStorageClient with fsUtils {

  @throws[Exception]
  def main(args: Array[String]): Unit = {

    val blobs = storageClient.list(bucket, BlobListOption.currentDirectory, BlobListOption.prefix(""))
    new File(downloadPath).mkdirs()

    blobs.iterateAll().forEach(blob => {
      if (blob.getName.endsWith(".log")) {
        println("Downloading log " + blob.getName)
        blob.downloadTo(Paths.get(downloadPath + "/" + blob.getName))
      }
    })
  }

}

object ReportUploader extends GoogleStorageClient with fsUtils {

  @throws[Exception]
  def main(args: Array[String]): Unit = {

    val reportDir = new File(downloadPath)

    val date: Date = new Date
    val dateFormat: SimpleDateFormat = new SimpleDateFormat("yyyyMMdd-HH-mm-ss")
    val filename: String = dateFormat.format(date)

    val zipFile = new File(s"build/reports/$filename.zip")
    ZipUtil.pack(reportDir, zipFile)

    storageClient.create(
      BlobInfo.newBuilder(bucket, "reports/" + zipFile.getName).build(),
      new FileInputStream(zipFile)
    )
    println("Uploaded report " + zipFile.getName)
  }

}

// Upload everything in the build/reports/gatling folder
object ResultsUploader extends  GoogleStorageClient with fsUtils {

  @throws[Exception]
  def main(args: Array[String]): Unit = {

    val reportDir = new File("build/reports/gatling")

    val date: Date = new Date
    val dateFormat: SimpleDateFormat = new SimpleDateFormat("yyyyMMdd-HH-mm-ss")
    val filename: String = dateFormat.format(date)

    val zipFile = new File(s"build/reports/$filename.zip")
    ZipUtil.pack(reportDir, zipFile)

    storageClient.create(
      BlobInfo.newBuilder(bucket, "reports/" + zipFile.getName).build(),
      new FileInputStream(zipFile)
    )
    println("Uploaded report " + zipFile.getName)
  }

}

object LogDeleter extends GoogleStorageClient with fsUtils {

  @throws[Exception]
  def main(args: Array[String]): Unit = {

    val blobs = storageClient.list(bucket, BlobListOption.currentDirectory, BlobListOption.prefix(""))

    blobs.iterateAll().forEach(blob => {
      if (blob.getName.endsWith(".log")) {
        println("Deleting logfile " + blob.getName)
        blob.delete()
      }
    })
  }

}
