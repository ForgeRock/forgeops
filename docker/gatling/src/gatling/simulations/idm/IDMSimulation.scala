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

// An IDM simulation - creates users via REST API
class IDMSimulation extends Simulation {

    val config = new BenchConfig()
    val amAuth = new AMAuth(config)
    val userFeeder = Iterator.from(0).map(i => Map("id" -> i))


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

    // See
    // https://stackoverflow.com/questions/48975160/gatling-performance-testhow-to-perform-task-in-background-every-x-minutes
    // For example on how to refresh a token

    val deleteExec =
        exec(amAuth.authenticate)
        .during(config.duration) {
            feed(userFeeder)
            .exec(amAuth.refreshAccessToken)
            .exec(
                http("Query for existing user")
                .get(config.idmUrl + "/managed/user")
                .queryParam("_queryFilter", "/userName eq \"testuser${id}\"")
                .header("Authorization", "Bearer ${accessToken}")
                .check(jsonPath("$.result[0]._id").optional.saveAs("uid"))
            )
            .doIf( "${uid.exists()}") {
                exec(http("Deleting existing user")
                    .delete(config.idmUrl + "/managed/user/${uid}")
                    .header("Authorization", "Bearer ${accessToken}")
                    .header("if-match", "*")
                )
            }
        }

    // The create test checks to ensure the id does not exist
    // this is slower - but is more realistic
    val createExec =
        exec(amAuth.authenticate)
        .during(config.duration) {
            feed(userFeeder)
            .exec(amAuth.refreshAccessToken)
          .exec(
              http("Query for existing user")
                .get(config.idmUrl + "/managed/user")
                .queryParam("_queryFilter", "/userName eq \"testuser${id}\"")
                .header("Authorization", "Bearer ${accessToken}")
                .check(jsonPath("$.result[0]._id").optional.saveAs("uid"))
          ) // if the uid does not exist, then create it..
              .doIf( "${uid.isUndefined()}") {
                exec(http("Create managed user via POST")
                      .post(config.idmUrl + "/managed/user?_action=create")
                      .body(StringBody(getGeneratedUser("${id}"))).asJson
                      .header("Authorization", "Bearer ${accessToken}")
                )
            }
        }
    // If DELETE_USERS is true, then run the delete simulation first
    val chainedScenario = if (config.deleteUsers)
            scenario("IDM Delete then Create").exec(deleteExec).exec(createExec);
        else
            scenario("IDM Create").exec(createExec);

    setUp(chainedScenario.inject(atOnceUsers(config.concurrency))).protocols(httpProtocol)
}
