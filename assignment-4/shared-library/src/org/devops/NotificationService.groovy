package org.devops

/**
 * NotificationService – sends Slack and email notifications.
 * Usage:
 *   def notif = new NotificationService(this)
 *   notif.sendSlack('Build passed!', 'good')
 */
class NotificationService implements Serializable {

    def script
    String slackWebhookId

    NotificationService(def script, String slackWebhookId = 'slack-webhook') {
        this.script = script
        this.slackWebhookId = slackWebhookId
    }

    /**
     * Send a Slack notification via the webhook stored in Jenkins credentials.
     * @param message  The message text (supports Slack markdown)
     * @param color    'good' | 'warning' | 'danger'
     */
    void sendSlack(String message, String color = 'good') {
        script.withCredentials([script.string(credentialsId: slackWebhookId, variable: 'SLACK_URL')]) {
            def payload = groovy.json.JsonOutput.toJson([
                attachments: [[
                    color: color,
                    text : message
                ]]
            ])
            script.sh "curl -s -X POST -H 'Content-type: application/json' --data '${payload}' \"\${SLACK_URL}\""
        }
    }

    /**
     * Send an email notification via the Jenkins Mailer plugin.
     * @param to      Recipient email address
     * @param subject Email subject line
     * @param body    Email body (plain text)
     */
    void sendEmail(String to, String subject, String body) {
        script.mail(
            to     : to,
            subject: subject,
            body   : body
        )
    }
}
