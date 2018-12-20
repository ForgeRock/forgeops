/*
* Forgeops OpenIDM Read managed user test
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

class IDMReadManagedUsers extends Simulation{
    val concurrency: Integer = Integer.getInteger("concurrency", 10)
    val warmup: Integer = Integer.getInteger("warmup", 1)
    val idmHost: String = System.getProperty("idm_host", "openidm.example.forgeops.com")
    val idmPort: String = System.getProperty("idm_port", "443")
    val idmProtocol: String = System.getProperty("idm_protocol", "https")

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

    val httpProtocol: HttpProtocolBuilder = http
        .baseURLs(idmUrl)
        .inferHtmlResources()
        .contentTypeHeader("""application/json""")

    val readScenario: ScenarioBuilder = scenario("Read managed users").
        exec(session => session.set("resp_code", 200)).
        asLongAs( session => !(session("resp_code").as[Int] == 404) ) {
            feed(userFeeder)
                .exec(
                    http("Read managed user - GET")
                        .get(idmUrl + "/openidm/managed/user/testuser${id}")
                        .headers(getXIDMHeaders("openidm-admin", "openidm-admin"))
                        .check(status.in(200, 404).saveAs("resp_code"))
                )
        }

    setUp(readScenario.inject(atOnceUsers(concurrency))).protocols(httpProtocol)
}
