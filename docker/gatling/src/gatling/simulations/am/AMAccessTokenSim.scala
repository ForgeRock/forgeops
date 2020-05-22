/*
* Forgeops OpenAM OAuth2 simulation.
*
* Copyright ForgeRock AS.
*/

package am

import io.gatling.core.Predef._
import io.gatling.core.scenario.Simulation
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder
import frutil._

// Get an access token using the auth code flow
class AMAccessTokenSim extends Simulation {

    val config = new BenchConfig()

    val oauth2ClientId: String = System.getProperty("oauth2_client_id", "oauth2")
    val oauth2ClientPassword: String = System.getProperty("oauth2_client_pw", "password")
    val oauth2RedirectUri: String = System.getProperty("oauth2_redirect_uri", "https://fake.com")
    val getTokenInfo: String = System.getProperty("get_token_info", "False")
    val scope: String = System.getProperty("am_oauth2_scope","profile")
    val realm: String = System.getProperty("realm", "/")
    val state = 1234

    val tokenVarName = "token"
    val codeVarName = "authcode"
    var accessTokenVarName = "access_token"

    val random = new util.Random

    val userFeeder: Iterator[Map[String, String]] = Iterator.continually(Map(
        """username""" -> (config.userPrefix + random.nextInt(config.userPoolSize).toString),
        """password""" -> config.userPassword)
    )

    def getXOpenAMHeaders(username: String, password: String): scala.collection.immutable.Map[String, String] = {
        scala.collection.immutable.Map(
            "X-OpenAM-Username" -> username,
            "X-OpenAM-Password" -> password)
    }

    val httpProtocol: HttpProtocolBuilder = http
        .baseUrl(config.amUrl)
        .inferHtmlResources()
        .header("Accept-API-Version", "resource=2.0, protocol=1.0")

    val accessTokenScenario: ScenarioBuilder = scenario("OAuth2 Auth code flow")
        .during(config.duration) {
            feed(userFeeder)
            .exec(flushCookieJar)
            .exec(
                http("Rest login stage")
                    .post("/json/authenticate")
                    .disableUrlEncoding
                    .header("Content-Type", "application/json")
                    .headers(getXOpenAMHeaders("${username}", "${password}"))
                    .check(jsonPath("$.tokenId").find.saveAs(tokenVarName))
            ).exec(
                addCookie(Cookie("iPlanetDirectoryPro", _(tokenVarName).as[String]))
            ).exec(
                http("Authorize stage")
                    .post("/oauth2/authorize")
                    .queryParam("client_id", oauth2ClientId)
                    .queryParam("scope", scope)
                    .queryParam("state", state)
                    .queryParam("redirect_uri", oauth2RedirectUri)
                    .queryParam("response_type", "code")
                    .formParam("decision", "Allow")
                    .formParam("csrf", "${%s}".format(tokenVarName))
                    .disableFollowRedirect
                    .check(headerRegex("Location", """(?<=code=)(.+?)(?=&)""")
                        .saveAs(codeVarName))
                    .check(status.is(302))

            ).exec(
                http("AccessToken stage")
                  .post("/oauth2/access_token")
                  .queryParam("realm", realm)
                  .formParam("grant_type", "authorization_code")
                  .formParam("code", _(codeVarName).as[String])
                  .formParam("redirect_uri", oauth2RedirectUri)
                  .basicAuth(oauth2ClientId, oauth2ClientPassword)
                  .check(jsonPath("$.access_token").find.saveAs(accessTokenVarName))
            ).doIf(getTokenInfo.toLowerCase.equals("true")) {
                exec(
                    http("IdTokenInfo stage")
                    .get("/oauth2/tokeninfo")
                    .queryParam("access_token", _(accessTokenVarName).as[String])
                    .check(jsonPath("$.access_token").exists)
                )
            }

        }

    setUp(accessTokenScenario.inject(rampUsers(config.concurrency) during config.warmup)).protocols(httpProtocol)
}
