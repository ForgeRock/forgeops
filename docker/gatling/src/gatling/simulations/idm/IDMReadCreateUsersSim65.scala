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
class IDMReadCreateUsersSim65 extends Simulation {

    val config = new BenchConfig()
    val userFeeder = Iterator.from(0).map(i => Map("id" -> i))

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
                  "password": "Passw0rd"}
            """.format(userId, userId, userId, userId).stripMargin
        stringJson
    }

    val httpProtocol: HttpProtocolBuilder = http
        .baseUrls(config.idmUrl)
        .inferHtmlResources()
        .contentTypeHeader("""application/json""")
        .disableCaching // without this nginx ingress starts returning 412
        .header("Accept-API-Version", "resource=2.0, protocol=1.0")

    val createExec =
        during(config.duration) {
            feed(userFeeder)
            .exec(
              http("check for existing user")
                .get(config.idmUrl + "/managed/user")
                .queryParam("_queryFilter", "/userName eq \"testuser${id}\"")
                .headers(getXIDMHeaders(config.idmUser, config.idmPassword))
                .check(status.in(200, 404).saveAs("resp_code"))
                .check(jsonPath("$.result[0]._id").optional.saveAs("uid"))
            ) // if the uid does not exist, then create it..
            .doIf( "${uid.isUndefined()}") {
                exec(
                    http("Create managed user via POST")
                        .post(config.idmUrl + "/managed/user?_action=create")
                        .body(StringBody(getGeneratedUser("${id}"))).asJson
                        .headers(getXIDMHeaders(config.idmUser, config.idmPassword))
                )
            }
        }

    val chainedScenario = scenario("idm read create").exec(createExec);

    setUp(chainedScenario.inject(atOnceUsers(config.concurrency))).protocols(httpProtocol)
}
