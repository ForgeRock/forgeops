/*
* Forgeops IDM Self Service
# Copyright 2020 ForgeRock AS. All Rights Reserved
#
# Use of this code requires a commercial software license with ForgeRock AS.
# or with one of its affiliates. All use shall be exclusively subject
# to such license between the licensee and ForgeRock AS.
*/

package platform

import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder
import io.gatling.core.structure.ChainBuilder
import scala.concurrent.duration._
import frutil._
import com.fasterxml.jackson.databind.ObjectMapper
import ujson.Value


// User self registers

class Register extends Simulation {

    val config = new BenchConfig()

    val userFeeder: Array[Map[String,String]] =
        (0 to config.userPoolSize).toArray map ( x => { Map( 
            "username" ->  (config.userPrefix+x).toString, "password" ->  config.userPassword.toString)
        })

    val registrationUrl = config.amUrl + 
        "/json/realms/root/authenticate?authIndexType=service&authIndexValue=Registration"

    val httpProtocol: HttpProtocolBuilder = http
        .baseUrls(config.idmUrl)
        .inferHtmlResources()
        .contentTypeHeader("""application/json""")
        .header("Accept-API-Version", "resource=2.0, protocol=1.0")
        .disableCaching // without this nginx ingress starts returning 412

    def registrationTreeInitiate(requestName: String = "registrationInitiate"): ChainBuilder = {
      exec(
        http(requestName)
          .post(registrationUrl)
          .asJson
          .body(StringBody(""))
          .check(status.is(200))
          .check(jsonPath("$.authId").find.saveAs("authId"))
          .check(jsonPath("$").find.saveAs("callbacks"))
         )
    }

    def registrationCallback(requestName: String = "registationCallback"): ChainBuilder = {
      exec(http(requestName)
        .post(registrationUrl)
        .asJson
        .body(StringBody("${callbacks}"))
        .check(status.is(200))
        .check(jsonPath("$.tokenId").find.saveAs("tokenId"))) // Presence of the tokenId in the body indicates success
    }

    val scn: ScenarioBuilder = scenario("Managed User Registration")
      .during (config.duration) {
        feed(userFeeder)
          .exec(flushCookieJar)
          .exec(registrationTreeInitiate())
          .exec(session => {
            var data = ujson.read(session("callbacks").as[String])
            data("callbacks")(0)("input")(0)("value") = session("username").as[String]
            data("callbacks")(1)("input")(0)("value") = session("username").as[String]
            data("callbacks")(2)("input")(0)("value") = session("username").as[String]
            data("callbacks")(3)("input")(0)("value") = session("username").as[String] + "@forgerock.com"
            data("callbacks")(4)("input")(0)("value") = false
            data("callbacks")(5)("input")(0)("value") = false
            data("callbacks")(6)("input")(0)("value") = session("password").as[String]
            data("callbacks")(7)("input")(0)("value") = "What's your favorite color?"
            data("callbacks")(7)("input")(1)("value") = "red"
            data("callbacks")(8)("input")(0)("value") = "Who was your first employer?"
            data("callbacks")(8)("input")(1)("value") = "forgerock"
            data("callbacks")(9)("input")(0)("value") = true
            session.set("callbacks", ujson.write(data))
          })
          .exec(registrationCallback())
    }

    setUp(scn.inject(rampUsers(config.concurrency) during config.warmup)).protocols(httpProtocol)

}
