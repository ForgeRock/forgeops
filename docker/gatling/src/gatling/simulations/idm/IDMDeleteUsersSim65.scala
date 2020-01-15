/*
* Forgeops OpenIDM Create managed user test
*
* Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
* Common Development and Distribution License (CDDL) that can be found in the LICENSE file
*/
package idm

import io.gatling.core.Predef._
import io.gatling.core.structure._
import io.gatling.core.scenario.Simulation
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder
import scala.concurrent.duration._
import frutil._

// An IDM simulation for 6.5 - creates users via REST API
class IDMDeleteUsersSim65 extends Simulation {

    val config = new BenchConfig()
    val userFeeder = Iterator.from(0).map(i => Map("id" -> i))

    def getXIDMHeaders(username: String, password: String): scala.collection.immutable.Map[String, String] = {
        scala.collection.immutable.Map(
            "X-OpenIDM-Username" -> username,
            "X-OpenIDM-Password" -> password)
    }

    val httpProtocol: HttpProtocolBuilder = http
        .baseUrls(config.idmUrl)
        .inferHtmlResources()
        .contentTypeHeader("""application/json""")
        .disableCaching // without this nginx ingress starts returning 412

    // Scenario to check that a user exists then deletes them. This prevents measuring user deletion on 404s.
    val deleteScenario = scenario("idm delete").exec(
            during(config.duration) {
                feed(userFeeder)
                .exec(http("query for existing user")
                    .get(config.idmUrl + "/managed/user")
                    .queryParam("_queryFilter", "/userName eq \"testuser${id}\"")
                    .headers(getXIDMHeaders(config.idmUser, config.idmPassword))
                    .check(status.in(200, 404))
                    .check(jsonPath("$.result[0]._id").optional.saveAs("uid"))
                )
                .doIf( "${uid.exists()}") {
                    exec(http("Deleting user")
                        .delete(config.idmUrl + "/managed/user/${uid}")
                        .headers(getXIDMHeaders(config.idmUser, config.idmPassword))
                        .header("if-match", "*")
                        .check(status.in(200, 404))
                    )
                }        
            }
    )

    setUp(deleteScenario.inject(atOnceUsers(config.concurrency))).protocols(httpProtocol)
}
