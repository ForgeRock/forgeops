package ig

import io.gatling.core.Predef._
import io.gatling.core.scenario.Simulation
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder

class IGReverseProxyWebSim extends Simulation {

    val userPoolSize: Integer = Integer.getInteger("users", 3)
    val concurrency: Integer = Integer.getInteger("concurrency", 200)
    val duration: Integer = Integer.getInteger("duration", 60)
    val warmup: Integer = Integer.getInteger("warmup", 3)
    val igHost: String = System.getProperty("ig_host", "openig.example.forgeops.com")
    val igPort: String = System.getProperty("ig_port", "80")
    val igProtocol: String = System.getProperty("ig_protocol", "http")

    val igUrl: String = "http://" + igHost + ":" + igPort

    val httpProtocol: HttpProtocolBuilder = http
        .baseURLs(igUrl)
        .inferHtmlResources()
        .contentTypeHeader("""application/json""")
        .header("Accept-API-Version", "resource=2.0, protocol=1.0")

    val request: ScenarioBuilder = scenario("ReverseProxy")
        .during(duration) {
            exec(http("Rest")
              .get("/")
              .disableUrlEncoding)
        }

    setUp(request.inject(rampUsers(concurrency) over warmup)).protocols(httpProtocol)
}