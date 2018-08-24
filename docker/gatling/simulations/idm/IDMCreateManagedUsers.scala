/*
* Forgeops OpenIDM Create managed user test
*
* Copyright (c) 2018 ForgeRock AS. Use of this source code is subject to the
* Common Development and Distribution License (CDDL) that can be found in the LICENSE file
*/
package idm

import io.gatling.commons.util.LongCounter
import io.gatling.core.Predef._
import io.gatling.core.scenario.Simulation
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder

class IDMCreateManagedUsers extends Simulation {
    val concurrency: Integer = Integer.getInteger("concurrency", 10)
    val warmup: Integer = Integer.getInteger("warmup", 10)
    val idmHost: String = System.getProperty("idm_host", "openidm.example.forgeops.com")
    val idmPort: String = System.getProperty("idm_port", "80")
    val idmProtocol: String = System.getProperty("idm_protocol", "http")
    val duration: Integer = Integer.getInteger("duration", 60).toInt

    val idmUrl: String = idmProtocol + "://" + idmHost + ":" + idmPort
    val random = new util.Random
    val counter = new LongCounter
    def t: Integer = 0

    val userFeeder: Iterator[Map[String, String]] = Iterator.continually(Map(
        """id""" -> counter.incrementAndGet().toString
    ))

    def getXIDMHeaders(username: String, password: String): scala.collection.immutable.Map[String, String] = {
        scala.collection.immutable.Map(
            "X-OpenIDM-Username" -> username,
            "X-OpenIDM-Password" -> password)
    }

    def getGeneratedUser(userId: String) : String = {
        val stringJson: String =
            """  {"userName": "testuser%s",
                  "givenName": "givenname%s",
                  "sn": "tester%s",
                  "mail": "testuser%s@forgerock.com",
                  "password": "Th3Password"}
            """.format(userId, userId, userId, userId).stripMargin
        stringJson
    }

    val httpProtocol: HttpProtocolBuilder = http
        .baseURLs(idmUrl)
        .inferHtmlResources()
        .contentTypeHeader("""application/json""")
        .disableCaching // without this nginx ingress starts returning 412

    val createScenario: ScenarioBuilder = scenario("Create managed users").
        during(duration) {
            feed(userFeeder)
                .exec(
                    http("Create managed user via POST")
                        .post(idmUrl + "/openidm/managed/user?_action=create")
                        .body(StringBody(getGeneratedUser("${id}"))).asJSON
                        .headers(getXIDMHeaders("openidm-admin", "openidm-admin"))
                )
        }

    setUp(createScenario.inject(atOnceUsers(concurrency))).protocols(httpProtocol)
}