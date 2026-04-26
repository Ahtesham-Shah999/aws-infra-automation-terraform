/**
 * runSonarScan – global step to run SonarQube analysis.
 *
 * Usage:
 *   runSonarScan(
 *     projectKey    : 'devops-a4-app',
 *     sources       : 'src',
 *     tests         : 'tests',
 *     coverageReport: 'coverage/lcov.info',
 *     serverName    : 'sonarqube'
 *   )
 *
 * Required keys: projectKey
 */
def call(Map params) {
    if (!params.containsKey('projectKey') || !params.projectKey) {
        error "runSonarScan: 'projectKey' parameter is required"
    }

    String sources        = params.sources        ?: 'src'
    String tests          = params.tests          ?: 'tests'
    String coverageReport = params.coverageReport ?: 'coverage/lcov.info'
    String serverName     = params.serverName     ?: 'sonarqube'

    withSonarQubeEnv(serverName) {
        sh """
            npx sonar-scanner \
              -Dsonar.projectKey=${params.projectKey} \
              -Dsonar.sources=${sources} \
              -Dsonar.tests=${tests} \
              -Dsonar.javascript.lcov.reportPaths=${coverageReport}
        """
    }

    timeout(time: 5, unit: 'MINUTES') {
        waitForQualityGate abortPipeline: true
    }
}
