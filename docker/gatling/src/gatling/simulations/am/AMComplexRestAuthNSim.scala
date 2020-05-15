/*
* Forgeops OpenAM callbacks REST Login AuthN simulation.
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
import frutil._
import com.fasterxml.jackson.databind.ObjectMapper
import ujson.Value

// Perform a callbacks based authentication against the /json/authenticate endpoint
class AMComplexRestAuthNSim extends Simulation {

    val config = new BenchConfig()
    val random = new util.Random
    
    val userFeeder: Iterator[Map[String, String]] = Iterator.continually(Map(
    """username""" -> (config.userPrefix + random.nextInt(config.userPoolSize).toString),
    """password""" -> config.userPassword)
    )

    val httpProtocol: HttpProtocolBuilder = http
        .baseUrl(config.amUrl)
        .inferHtmlResources()
        .contentTypeHeader("""application/json""")
        .header("Accept-API-Version", "resource=2.0, protocol=1.0")

    val loginScenario: ScenarioBuilder =
        scenario("Rest login")
        .during(config.duration) {
            exitBlockOnFail{
                exec(flushCookieJar)
                .exec(
                    http("get authId and callbacks")
                    .post(config.authnUrl)
                    .check(status.is(200))
                    .check(jsonPath("$.authId").find.saveAs("authId"))
                    .check(jsonPath("$").find.saveAs("callbacks"))
                )
                .feed(userFeeder)
                .exec(session => {
                    var data = ujson.read(session("callbacks").as[String])
                    data("callbacks")(0)("input")(0)("value") = session("username").as[String]
                    data("callbacks")(1)("input")(0)("value") = session("password").as[String]
                    session.set("callbacks", ujson.write(data))

                })
                .exec(http("submit credentials")
                    .post(config.authnUrl)
                    .disableUrlEncoding
                    .asJson
                    .header("Accept-API-Version", "resource=2.0, protocol=1.0")
                    .body(StringBody("${callbacks}")
                    )
                    .check(status.is(200))
                    .check(jsonPath("$.tokenId").find.saveAs("ssoToken"))
                )
            }
        }

    setUp(loginScenario.inject(rampUsers(config.concurrency) during config.warmup)).protocols(httpProtocol)

}
