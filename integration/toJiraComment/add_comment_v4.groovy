@Grapes([
    @Grab(group='org.apache.httpcomponents', module='httpclient', version='4.5.14'),
    @Grab(group='com.squareup.okhttp3', module='okhttp', version='4.12.0'),
    @Grab(group='com.squareup.okhttp3', module='okhttp-urlconnection', version='4.12.0'),
    @Grab(group='info.picocli', module='picocli-groovy', version='4.7.6'),
])

import picocli.CommandLine
import static picocli.CommandLine.*
import org.apache.http.Header
import org.apache.http.HttpHeaders
import org.apache.http.message.BasicHeader
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.MediaType
import okhttp3.RequestBody
import okhttp3.Credentials
import groovy.json.JsonSlurper
import groovy.json.JsonOutput
import groovy.transform.Field
import java.util.stream.Collectors

@Command(
    name = 'AddCommentToJira',
    mixinStandardHelpOptions = true,
    version = '0.1',
    usageHelpAutoWidth = true,
    description = 'Contrast PS UAM(UnlicensedAppMerge) script merges whole unlicensed child applications onto <parent_id> that you set.\n' +
                  'Limitation: The script only aims to same language\'s unlicensed child applications, and it excludes already-merged applications.\n' +
                  'Preparation: Prepare four environment variables for your system. This script extracts the environment variables via the code below.\n\n' +
                  'Set variables properly, or change the code if necessary, at your own risk!\n' +
                  '  os.environ["CONTRAST_BASEURL"]\n' +
                  '  os.environ["CONTRAST_AUTHORIZATION"]\n' +
                  '  os.environ["CONTRAST_API_KEY"]\n' +
                  '  os.environ["CONTRAST_ORG_ID"]\n' +
                  '  os.environ["CONTRAST_JIRA_URL"]\n' +
                  '  os.environ["CONTRAST_JIRA_USER"]\n' +
                  '  os.environ["CONTRAST_JIRA_API_TOKEN"]\n'
)
@picocli.groovy.PicocliScript

@Option(names = ["-t", "--test"], description = "If you set this option, You can check a list of merge target applications without performing the merge process.")
@Field boolean test = false

@Option(names = ["-a", "--app"], required = true, description = "Specify the application name. e.g. PetClinic")
@Field String applicationName

@Option(names = ["-j", "--jira"], required = true, description = "Specify the Jira Ticket ID. e.g. FAKEBUG-12730")
@Field String jiraTicketId

class Config {
    static BASEURL        = System.getenv().CONTRAST_BASEURL
    static AUTHORIZATION  = System.getenv().CONTRAST_AUTHORIZATION
    static API_KEY        = System.getenv().CONTRAST_API_KEY
    static ORG_ID         = System.getenv().CONTRAST_ORG_ID
    static JIRA_URL       = System.getenv().CONTRAST_JIRA_URL
    static JIRA_USER      = System.getenv().CONTRAST_JIRA_USER
    static JIRA_API_TOKEN = System.getenv().CONTRAST_JIRA_API_TOKEN
}

if (Config.BASEURL == null || Config.AUTHORIZATION == null || Config.API_KEY == null || Config.ORG_ID == null || Config.JIRA_USER == null || Config.JIRA_API_TOKEN == null) {
    println "The required environment variable is not set."
    System.exit(1)
}

final LIMIT = 25

def authHeader = Config.AUTHORIZATION
def headers = []
headers.add(new BasicHeader(HttpHeaders.ACCEPT, "application/json"))
headers.add(new BasicHeader(HttpHeaders.CONTENT_TYPE, "application/json"))
headers.add(new BasicHeader("API-Key", Config.API_KEY))
headers.add(new BasicHeader(HttpHeaders.AUTHORIZATION, authHeader))

def clientBuilder = new OkHttpClient.Builder()
def httpClient = clientBuilder.build()
def requestBuilder = new Request.Builder().url("${Config.BASEURL}/api/ng/${Config.ORG_ID}/applications").get()
for (Header header : headers) {
    requestBuilder.addHeader(header.getName(), header.getValue())
}
def request = requestBuilder.build()
def Response response = httpClient.newCall(request).execute()

def jsonParser = new JsonSlurper()
def resBody = response.body().string()
def appsJson = jsonParser.parseText(resBody)
if (response.code() != 200) {
    println "Failed to get the application list."
    println "${resBody}"
    System.exit(1)
}

def targetAppId = null

appsJson.applications.each{app ->
    if (app.name == applicationName) {
        targetAppId = app.app_id
    }
}

if (targetAppId == null) {
    println "Target application(ID) cannot be found."
    System.exit(2)
}

println "Target application ID is ${targetAppId}."

//if (test) {
//    println "Exit for test execution."
//    System.exit(0)
//}

def allTraces = []

def mediaTypeJson = MediaType.parse("application/json; charset=UTF-8")
def json = String.format("{\"modules\":[\"%s\"]}", targetAppId)
def body = RequestBody.create(json, mediaTypeJson)

requestBuilder = new Request.Builder().url("${Config.BASEURL}/api/ng/organizations/${Config.ORG_ID}/orgtraces/ui?expand=application&session_metadata&offset=${allTraces.size()}&limit=${LIMIT}&sort=-severity").post(body)
for (Header header : headers) {
    requestBuilder.addHeader(header.getName(), header.getValue())
}
request = requestBuilder.build()
response = httpClient.newCall(request).execute()
resBody = response.body().string()
def resJson = jsonParser.parseText(resBody)
if (response.code() != 200) {
    println "Failed to retrieve application vulnerabilities."
    println "${resBody}"
    System.exit(3)
}

def totalCnt = resJson['count']
resJson['items'].each { v ->
    println "${v['vulnerability']['severity']}, ${v['vulnerability']['ruleName']}"
    def appId = v['vulnerability']['application']['id']
    def traceLink = "${Config.BASEURL}/static/ng/index.html#/${Config.ORG_ID}/applications/${targetAppId}/vulns/${v['vulnerability']['uuid']}"
    allTraces.add([
        title: v['vulnerability']['title'],
        severity: v['vulnerability']['severity'],
        ruleName: v['vulnerability']['ruleName'],
        uuid: v['vulnerability']['uuid'],
        app_name: v['vulnerability']['application']['name'],
        link: traceLink
    ]) 
}

def traceIncompleteFlg = true
traceIncompleteFlg = totalCnt > allTraces.size()
while (traceIncompleteFlg) {
    requestBuilder = new Request.Builder().url("${Config.BASEURL}/api/ng/organizations/${Config.ORG_ID}/orgtraces/ui?expand=application&session_metadata&offset=${allTraces.size()}&limit=${LIMIT}&sort=-severity").post(body)
    for (Header header : headers) {
        requestBuilder.addHeader(header.getName(), header.getValue())
    }
    request = requestBuilder.build()
    response = httpClient.newCall(request).execute()
    resBody = response.body().string()
    resJson = jsonParser.parseText(resBody)
    if (response.code() != 200) {
        println "Failed to retrieve application vulnerabilities."
        println "${resBody}"
        System.exit(3)
    }
    resJson['items'].each { v ->
        println "${v['vulnerability']['severity']}, ${v['vulnerability']['ruleName']}"
        appId = v['vulnerability']['application']['id']
        traceLink = "${Config.BASEURL}/static/ng/index.html#/${Config.ORG_ID}/applications/${targetAppId}/vulns/${v['vulnerability']['uuid']}"
        allTraces.add([
            title: v['vulnerability']['title'],
            severity: v['vulnerability']['severity'],
            ruleName: v['vulnerability']['ruleName'],
            uuid: v['vulnerability']['uuid'],
            app_name: v['vulnerability']['application']['name'],
            link: traceLink
        ]) 
    }
    traceIncompleteFlg = totalCnt > allTraces.size()
}
println "Total(Trace): ${allTraces.size()}"

def basePayload = JsonOutput.toJson([
    body: [
        version: 1,
        type: "doc",
        content: [
            [
                type: "table",
                attrs: [
                    isNumberColumnEnabled: false,
                    layout: "center",
                    width: 600,
                    displayMode: "default"
                ],
                content: [
                    // Insert table block here.
                ]
            ]
        ]
    ]
])

def baseDict = new JsonSlurper().parseText(basePayload)
def rowDictList = []
// Table Header
def rowDictForHeader = [:]
rowDictForHeader['type'] = 'tableRow'
def cellContentsForHeader = []
cellContentsForHeader.add([type: 'tableHeader', attrs: [:], content: [[type: 'paragraph', content: [[type: 'text', text: 'Risk']]]]])
cellContentsForHeader.add([type: 'tableHeader', attrs: [:], content: [[type: 'paragraph', content: [[type: 'text', text: 'Issue Type']]]]])
cellContentsForHeader.add([type: 'tableHeader', attrs: [:], content: [[type: 'paragraph', content: [[type: 'text', text: 'Affected Path/Class']]]]])
cellContentsForHeader.add([type: 'tableHeader', attrs: [:], content: [[type: 'paragraph', content: [[type: 'text', text: 'Details']]]]])
rowDictForHeader['content'] = cellContentsForHeader
rowDictList.add(rowDictForHeader)

// Table Cell
def pattern = ~/ from | on | at | in | : |：/
def pattern2 = /^.+?( from | on | at | in | : |：)(.+)$/
allTraces.each { t ->
    def rowDict = [:]
    rowDict.type = 'tableRow'
    def cellContents = []
    cellContents.add([type: 'tableCell', attrs: [:], content: [[type: 'paragraph', content: [[type: 'text', text: t.severity]]]]])
    cellContents.add([type: 'tableCell', attrs: [:], content: [[type: 'paragraph', content: [[type: 'text', text: t.ruleName]]]]])
    def title = t.title
    if (title =~ pattern) {
      def m = title =~ pattern2
      if (m) {
        title = m[0][2] 
      }
    }
    cellContents.add([type: 'tableCell', attrs: [:], content: [[type: 'paragraph', content: [[type: 'text', text: title]]]]])
    cellContents.add([
        type: 'tableCell', 
        attrs: [:], 
        content: [
            [
                type: 'paragraph', 
                content: [
                    [
                        type: 'text', 
                        text: t.uuid, 
                        marks: [
                            [
                                type: 'link', 
                                attrs: [href: t.link, title: 'to TeamServer']
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ])
    rowDict.content = cellContents
    rowDictList.add(rowDict)
}
baseDict.body.content[0].content = rowDictList
def payload = JsonOutput.toJson(baseDict)
body = RequestBody.create(payload, mediaTypeJson)
requestBuilder = new Request.Builder().url("${Config.JIRA_URL}/rest/api/3/issue/${jiraTicketId}/comment").post(body)

String credential = Credentials.basic(Config.JIRA_USER, Config.JIRA_API_TOKEN)
headers = []
headers.add(new BasicHeader(HttpHeaders.ACCEPT, "application/json"))
headers.add(new BasicHeader(HttpHeaders.CONTENT_TYPE, "application/json"))
headers.add(new BasicHeader(HttpHeaders.AUTHORIZATION, credential))
for (Header header : headers) {
    requestBuilder.addHeader(header.getName(), header.getValue())
}

println "${Config.JIRA_USER}, ${Config.JIRA_API_TOKEN}"
println Credentials.basic(Config.JIRA_USER, Config.JIRA_API_TOKEN)
request = requestBuilder.build()
response = httpClient.newCall(request).execute()
resBody = response.body().string()
resJson = jsonParser.parseText(resBody)
if (response.code() != 200) {
    println "Failed to add a comment to Jira."
    println "${resBody}"
    System.exit(1)
}

System.exit(0)


