package ig
  
import io.gatling.core.Predef._
import io.gatling.core.scenario.Simulation
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder

class IGReverseProxyWebSim extends Simulation {

    val userPoolSize: Integer = Integer.getInteger("users", 3)
    val concurrency: Integer = Integer.getInteger("concurrency", 25)
    val duration: Integer = Integer.getInteger("duration", 30)
    val warmup: Integer = Integer.getInteger("warmup", 3)
    val igHost: String = System.getProperty("ig_host", "openig.prod.perf.forgerock-qa.com")
    val igPort: String = System.getProperty("ig_port", "443")
    val igProtocol: String = System.getProperty("ig_protocol", "https")
    
    val igUrl: String = igProtocol + "://" + igHost + ":" + igPort
    val random = new util.Random
    
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
            //.headers(getXOpenAMHeaders("${username}", "${password}")))
        }
        
    setUp(request.inject(rampUsers(concurrency) over warmup)).protocols(httpProtocol)
}