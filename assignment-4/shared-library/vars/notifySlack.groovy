import org.devops.NotificationService

/**
 * notifySlack – global step to send Slack notifications.
 *
 * Usage in Jenkinsfile:
 *   @Library('devops-shared-lib') _
 *   notifySlack(message: 'Build passed!', color: 'good')
 *
 * Required keys:  message
 * Optional keys:  color (default: 'good'), credentialsId (default: 'slack-webhook')
 */
def call(Map params) {
    if (!params.containsKey('message') || !params.message) {
        error "notifySlack: 'message' parameter is required"
    }

    String color           = params.color           ?: 'good'
    String credentialsId   = params.credentialsId   ?: 'slack-webhook'

    def notificationService = new NotificationService(this, credentialsId)
    notificationService.sendSlack(params.message, color)
}
