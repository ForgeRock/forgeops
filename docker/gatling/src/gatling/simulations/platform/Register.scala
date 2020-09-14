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


//Test flow
// User self registers

class Register extends Simulation {

    val config = new BenchConfig()
    val amAuth = new AMAuth(config)

    var userFeeder: Array[Map[String,String]] =
      (1 to config.userPoolSize).toArray map ( x => { Map( "username" ->  x.toString) })

    val registrationUrl = config.amUrl + 
            "/json/realms/root/authenticate?service=Registration&authIndexType=service&authIndexValue=Registration"

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
         )
    }

    def registrationCallback(authId: String, username: String, password: String,
                           requestName: String = "registationCallback"): ChainBuilder = {
      exec(http(requestName)
        .post(registrationUrl)
        .asJson
        .body(StringBody(
          """{"authId":"%s",""".format(authId) +
            """"callbacks":[{"type":"ValidatedCreateUsernameCallback","output":[{"name":"policies","value":[{"policyId":"unique"},""" +
            """{"policyId":"no-internal-user-conflict"},{"policyId":"cannot-contain-characters","params":{"forbiddenChars":["/"]}}]},""" +
            """{"name":"failedPolicies","value":[]},{"name":"validateOnly","value":false},{"name":"prompt","value":"Username"}],""" +
            """"input":[{"name":"IDToken1","value":"%s"},{"name":"IDToken1validateOnly","value":false}],"_id":0},""".format(username) +
            """{"type":"StringAttributeInputCallback","output":[{"name":"name","value":"givenName"},""" +
            """{"name":"prompt","value":"First Name"},{"name":"required","value":true},{"name":"policies","value":[]},""" +
            """{"name":"failedPolicies","value":[]},{"name":"validateOnly","value":false},{"name":"value","value":""}],""" +
            """"input":[{"name":"IDToken2","value":"%s"},{"name":"IDToken2validateOnly","value":false}],"_id":1},""".format(username) +
            """{"type":"StringAttributeInputCallback","output":[{"name":"name","value":"sn"},{"name":"prompt","value":"Last Name"},""" +
            """{"name":"required","value":true},{"name":"policies","value":[]},{"name":"failedPolicies","value":[]},""" +
            """{"name":"validateOnly","value":false},{"name":"value","value":""}],"input":[{"name":"IDToken3","value":"%s"},""".format(username) +
            """{"name":"IDToken3validateOnly","value":false}],"_id":2},{"type":"StringAttributeInputCallback",""" +
            """"output":[{"name":"name","value":"mail"},{"name":"prompt","value":"Email Address"},{"name":"required","value":true},""" +
            """{"name":"policies","value":[{"policyId":"valid-email-address-format"}]},{"name":"failedPolicies","value":[]},""" +
            """{"name":"validateOnly","value":false},{"name":"value","value":""}],"input":[{"name":"IDToken4","value":"%s@gmail.com"},""".format(username) +
            """{"name":"IDToken4validateOnly","value":false}],"_id":3},{"type":"BooleanAttributeInputCallback",""" +
            """"output":[{"name":"name","value":"preferences/marketing"},{"name":"prompt","value":"Send me special offers and services"},""" +
            """{"name":"required","value":true},{"name":"policies","value":[]},{"name":"failedPolicies","value":[]},""" +
            """{"name":"validateOnly","value":false},{"name":"value","value":false}],"input":[{"name":"IDToken5","value":false},""" +
            """{"name":"IDToken5validateOnly","value":false}],"_id":4},{"type":"BooleanAttributeInputCallback",""" +
            """"output":[{"name":"name","value":"preferences/updates"},{"name":"prompt","value":"Send me news and updates"},""" +
            """{"name":"required","value":true},{"name":"policies","value":[]},{"name":"failedPolicies","value":[]},""" +
            """{"name":"validateOnly","value":false},{"name":"value","value":false}],"input":[{"name":"IDToken6","value":false},""" +
            """{"name":"IDToken6validateOnly","value":false}],"_id":5},{"type":"ValidatedCreatePasswordCallback",""" +
            """"output":[{"name":"echoOn","value":false},{"name":"policies","value":[{"policyId":"at-least-X-capitals",""" +
            """"params":{"numCaps":1}},{"policyId":"at-least-X-numbers","params":{"numNums":1}},""" +
            """{"policyId":"cannot-contain-others","params":{"disallowedFields":["userName","givenName","sn"]}}]},""" +
            """{"name":"failedPolicies","value":[]},{"name":"validateOnly","value":false},{"name":"prompt","value":"Password"}],""" +
            """"input":[{"name":"IDToken7","value":"%s"},{"name":"IDToken7validateOnly","value":false}],"_id":6},""" .format(password) +
            """{"type":"KbaCreateCallback","output":[{"name":"prompt","value":"Select a security question"},""" +
            """{"name":"predefinedQuestions","value":["What's your favorite color?","Who was your first employer?"]}],""" +
            """"input":[{"name":"IDToken8question","value":"What's your favorite color?"},{"name":"IDToken8answer","value":"red"}],"_id":7},""" +
            """{"type":"KbaCreateCallback","output":[{"name":"prompt","value":"Select a security question"},""" +
            """{"name":"predefinedQuestions","value":["What's your favorite color?","Who was your first employer?"]}],""" +
            """"input":[{"name":"IDToken9question","value":"Who was your first employer?"},{"name":"IDToken9answer","value":"forgerock"}],"_id":8},""" +
            """{"type":"TermsAndConditionsCallback","output":[{"name":"version","value":"0.0"},""" +
            """{"name":"terms","value":"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."},{"name":"createDate","value":"2019-10-28T04:20:11.320Z"}],""" +
            """"input":[{"name":"IDToken10","value":true}],"_id":9}],""" +
            """"header":"Sign Up","description":"Signing up is fast and easy.<br>Already have an account? <a href='#/service/Login'>Sign In</a>"}"""
        ) )
        .check(status.is(200))
        .check(jsonPath("$.tokenId").find.saveAs("tokenId"))
      )
        .exec(addCookie(Cookie(config.loginCookie, "${tokenId}")))
    }

    val scn: ScenarioBuilder = scenario("Managed User Self Service")
      .during (config.duration) {
        feed(userFeeder)
          .exec(flushCookieJar)
          .exec(registrationTreeInitiate())
          .exec(registrationCallback(authId = "${authId}", config.userPrefix+"${username}", config.userPassword))
    }

    setUp(scn.inject(rampUsers(config.concurrency) during config.warmup)).protocols(httpProtocol)

}



