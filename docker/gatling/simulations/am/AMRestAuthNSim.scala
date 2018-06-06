/*
* Forgeops OpenAM REST Login AuthN simulation.
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

class AMRestAuthNSim extends Simulation {

    val userPoolSize: Integer = Integer.getInteger("users", 3)
    val concurrency: Integer = Integer.getInteger("concurrency", 10)
    val duration: Integer = Integer.getInteger("duration", 60)
    val warmup: Integer = Integer.getInteger("warmup", 1)
    val amHost: String = System.getProperty("am_host", "openam.example.forgeops.com")
    val amPort: String = System.getProperty("am_port", "80")
    val amProtocol: String = System.getProperty("am_protocol", "http")

    val amUrl: String = "http://" + amHost + ":" + amPort
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
        .contentTypeHeader("""application/json""")
        .header("Accept-API-Version", "resource=2.0, protocol=1.0")

    val loginScenario: ScenarioBuilder = scenario("Rest login")
        .during(duration) {
            feed(userFeeder)
            .exec(http("Rest login")
                .post("/openam/json/authenticate")
                .disableUrlEncoding
                .headers(getXOpenAMHeaders("${username}", "${password}")))
        }

    setUp(loginScenario.inject(rampUsers(concurrency) over warmup)).protocols(httpProtocol)
}
