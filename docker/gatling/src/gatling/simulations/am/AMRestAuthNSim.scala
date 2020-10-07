/*
* Forgeops OpenAM REST Login AuthN simulation.
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

// Perform a simple authentication against the /json/authenticate endpoint
class AMRestAuthNSim extends Simulation {

    val config = new BenchConfig()
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
        .contentTypeHeader("""application/json""")
        .header("Accept-API-Version", "resource=2.0, protocol=1.0")

    val loginScenario: ScenarioBuilder =
        scenario("Rest login")
        .during(config.duration) {
            feed(userFeeder)
            .exec(flushCookieJar) // need this otherwise same user is used for each thread
            .exec(http("Rest login")
                .post("/json/realms/root/authenticate")
                .disableUrlEncoding
                .headers(getXOpenAMHeaders("${username}", "${password}")))
        }

    setUp(loginScenario.inject(rampUsers(config.concurrency) during config.warmup)).protocols(httpProtocol)
}
