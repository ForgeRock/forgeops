package ig

import java.io.{File, FileOutputStream, PrintWriter}

import io.gatling.core.Predef._
import io.gatling.core.scenario.Simulation
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder

class IGGenerateTokensSim extends Simulation {

  val userPoolSize: Integer = Integer.getInteger("users", 10)
  val amHost: String = System.getProperty("am_host", "default.iam.forgeops.com")
  val amPort: String = System.getProperty("am_port", "443")

  val amProtocol: String = System.getProperty("am_protocol", "https")

  val oauth2ClientId: String = System.getProperty("oauth2_client_id", "oauth2")
  val oauth2ClientPassword: String = System.getProperty("oauth2_client_pw", "password")

  val realm: String = System.getProperty("realm", "/")
  val scope: String = System.getProperty("scope", "mail")
  val tokenVarName = "token"
  var accessTokenVarName = "access_token"

  val amUrl: String = amProtocol + "://" + amHost + ":" + amPort + "/am"
  val random = new util.Random

  val header = "tokens"
  val csvFile: String = System.getProperty("csv_file_path", "/tmp/tokens.csv")
  val userSeq: Range = 0 until userPoolSize


  def getXOpenAMHeaders(username: String, password: String): scala.collection.immutable.Map[String, String] = {
    scala.collection.immutable.Map(
      "X-OpenAM-Username" -> username,
      "X-OpenAM-Password" -> password)
  }

  def createCSVFile() = {
    val s1 = new File(csvFile)
    if (s1.exists) {
      s1.delete()
    }
    val writer = new PrintWriter(new FileOutputStream(new File(csvFile)))
    writer.println(header)
    writer.close()
  }

  val httpProtocol: HttpProtocolBuilder = http
    .baseUrl(amUrl)
    .inferHtmlResources()
    .header("Accept-API-Version", "resource=2.0, protocol=1.0")

  val generateTokenScenario: ScenarioBuilder = scenario("OAuth2 Auth code flow").
    foreach(userSeq, "user") {
        exec(
          http("Request Token stage")
            .post("/oauth2/access_token")
//             .queryParam("realm", realm)
            .formParam("grant_type", "password")
            .formParam("scope", scope)
            .formParam("username", "testuser${user}")
            .formParam("password", "Passw0rd")
            .basicAuth(oauth2ClientId, oauth2ClientPassword)
            .check(jsonPath("$.access_token").find.saveAs(accessTokenVarName))
        ).exec (
        session => {
          val writer = new PrintWriter(new FileOutputStream(new File(csvFile), true))
          writer.write(session(accessTokenVarName).as[String])
          writer.write("\n")
          writer.close()
          session
        }
      )
    }

  createCSVFile()
  setUp(generateTokenScenario.inject(atOnceUsers(1))).protocols(httpProtocol)
}

