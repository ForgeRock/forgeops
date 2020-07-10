package frutil

import io.gatling.core.Predef._
import io.gatling.core.structure._
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder
import scala.concurrent.duration._
import scala.util._


// Holds the benchmark config for hostname, etc.
class BenchConfig {
    val host: String   = Properties.envOrElse("TARGET_HOST", "prod.iam.example.com")
    val port: String =  Properties.envOrElse("PORT", "443")
    val protocol: String =  Properties.envOrElse("protocol", "https")
    val scope: String =  Properties.envOrElse("SCOPE", "openid")
    val client_id: String = Properties.envOrElse("CLIENT_ID", "idm-provisioning")
    val client_password: String = Properties.envOrElse("CLIENT_PASSWORD", "password")
    val idmUser: String = Properties.envOrElse("IDM_USER", "openidm-admin")
    val idmPassword: String = Properties.envOrElse("IDM_PASSWORD", "openidm-admin")
    val userPassword: String = Properties.envOrElse("USER_PASSWORD", "password")
    val duration:Integer =  Properties.envOrElse("DURATION", "60").toInt
    val userPoolSize: Integer = Properties.envOrElse("USER_POOL", "1000000").toInt
    // template for test users.
    val userPrefix:String = Properties.envOrElse("USER_PREFIX", "user.");
    // Run the IDM delete users before running the create user simulation
    val deleteUsers: Boolean = Properties.envOrElse("DELETE_USERS", "false").toBoolean

    val concurrency: Integer = Properties.envOrElse("CONCURRENCY", "30").toInt
    val warmup: Integer = Integer.getInteger("warmup", 1)

    val idmUrl: String = protocol + "://" + host + ":" + port + "/openidm"
    val amUrl: String = protocol + "://" + host + ":" + port + "/am"
    val authnUrl: String = Properties.envOrElse("AUTHN_URL", "/json/realms/root/authenticate?authIndexType=service&authIndexValue=UserNamePassword")
}

// Utility for OIDC client auth, refreshing access tokens, etc.
class AMAuth (val config: BenchConfig) {
    val authTimeout = 30 minutes
    val safetyMargin = 2 minutes

    // sample curl:
    // curl -u idm-provisioning:password --data 'grant_type=client_credentials&scope=openid'
    // -X POST https://smoke.iam.forgeops.com/am/oauth2/access_token
    // add this to a chain to get an access token.
    // tood: Do paramterize the client, grant, etc.
    val authenticate: ChainBuilder =
        exec(
            http("get access token")
                .post(config.amUrl + "/oauth2/access_token")
                .formParam("grant_type","client_credentials")
                .formParam("scope", config.scope)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .basicAuth(config.client_id,config.client_password)
                .check(jsonPath("$.access_token").find.saveAs("accessToken"))
        )
        .exec( session => session.set("timeout", authTimeout.fromNow))

    // add this to a simulation to refresh the access token. Required for simulations that run
    // longer than the access token lifetime.
    val refreshAccessToken: ChainBuilder =
        doIf(session => { session("timeout").as[Deadline].timeLeft <= safetyMargin }) {
            exec(
                http("get access token")
                .post(config.amUrl + "/oauth2/access_token")
                .formParam("grant_type","client_credentials")
                .formParam("scope", config.scope)
                .header("Content-Type", "application/x-www-form-urlencoded")
                .basicAuth(config.client_id,config.client_password)
                .check(jsonPath("$.access_token").find.saveAs("accessToken"))
            )
            .exec( session => session.set("timeout", authTimeout.fromNow))
        }
}
