/*
* Forgeops OpenAM OAuth2 simulation.
*
* Copyright (c) 2018 ForgeRock AS. Use of this source code is subject to the
* Common Development and Distribution License (CDDL) that can be found in the LICENSE file
*/

package am

import io.gatling.core.Predef._
import io.gatling.core.scenario.Simulation
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder

class AMAccessTokenSim extends Simulation {

    val userPoolSize: Integer = Integer.getInteger("users", 3)
    val concurrency: Integer = Integer.getInteger("concurrency", 10)
    val duration: Integer = Integer.getInteger("duration", 60)
    val warmup: Integer = Integer.getInteger("warmup", 1)
    val amHost: String = System.getProperty("am_host", "openam.example.forgeops.com")
    val amPort: String = System.getProperty("am_port", "443")
    val amProtocol: String = System.getProperty("am_protocol", "https")

    val oauth2ClientId: String = System.getProperty("oauth2_client_id", "oauth2")
    val oauth2ClientPassword: String = System.getProperty("oauth2_client_pw", "password")
    val oauth2RedirectUri: String = System.getProperty("oauth2_redirect_uri", "http://fake.com")
    val getTokenInfo: String = System.getProperty("get_token_info", "False")

    val realm: String = System.getProperty("realm", "/")
    val state = 1234
    val scope = "cn"
    val tokenVarName = "token"
    val codeVarName = "authcode"
    var accessTokenVarName = "access_token"

    val amUrl: String = amProtocol + "://" + amHost + ":" + amPort
    val random = new util.Random

    val userFeeder: Iterator[Map[String, String]] = Iterator.continually(Map(
        """username""" -> ("""user.""" + random.nextInt(userPoolSize).toString),
        """password""" -> "password")
    )

    def getXOpenAMHeaders(username: String, password: String): scala.collection.immutable.Map[String, String] = {
        scala.collection.immutable.Map(
            "X-OpenAM-Username" -> username,
            "X-OpenAM-Password" -> password)
    }

    val httpProtocol: HttpProtocolBuilder = http
        .baseURLs(amUrl)
        .inferHtmlResources()
        .header("Accept-API-Version", "resource=2.0, protocol=1.0")

    val accessTokenScenario: ScenarioBuilder = scenario("OAuth2 Auth code flow")
        .during(duration) {
            feed(userFeeder)
            .exec(
                http("Rest login stage")
                    .post("/openam/json/authenticate")
                    .disableUrlEncoding
                    .header("Content-Type", "application/json")
                    .headers(getXOpenAMHeaders("${username}", "${password}"))
                    .check(jsonPath("$.tokenId").find.saveAs(tokenVarName))
            ).exec(
                addCookie(Cookie("iPlanetDirectoryPro", _.get(tokenVarName).as[String]))
            ).exec(
                http("Authorize stage")
                    .post("/openam/oauth2/authorize")
                    .queryParam("client_id", oauth2ClientId)
                    .queryParam("scope", scope)
                    .queryParam("state", state)
                    .queryParam("redirect_uri", oauth2RedirectUri)
                    .queryParam("response_type", "code")
                    .queryParam("realm", realm)
                    .formParam("decision", "Allow")
                    .formParam("csrf", "${%s}".format(tokenVarName))
                    .disableFollowRedirect
                    .check(headerRegex("Location", """code=([^&\s]*)&?""")
                        .saveAs(codeVarName))
                    .check(status.is(302))

            ).exec(
                http("AccessToken stage")
                  .post("/openam/oauth2/access_token")
                  .queryParam("realm", realm)
                  .formParam("grant_type", "authorization_code")
                  .formParam("code", _.get(codeVarName).as[String])
                  .formParam("redirect_uri", oauth2RedirectUri)
                  .basicAuth(oauth2ClientId, oauth2ClientPassword)
                  .check(jsonPath("$.access_token").find.saveAs(accessTokenVarName))
            ).doIf(getTokenInfo.toLowerCase.equals("true")) {
                exec(
                    http("IdTokenInfo stage")
                    .get("/openam/oauth2/tokeninfo")
                    .queryParam("access_token", _.get(accessTokenVarName).as[String])
                    .check(jsonPath("$.access_token").exists)
                )
            }

        }

    setUp(accessTokenScenario.inject(rampUsers(concurrency) over warmup)).protocols(httpProtocol)
}
