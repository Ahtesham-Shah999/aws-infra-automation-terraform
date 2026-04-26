import org.devops.DockerHelper

/**
 * buildAndPushImage – global step to build and push a Docker image to ECR.
 *
 * Usage:
 *   buildAndPushImage(
 *     name      : 'devops-a4-app',
 *     sha       : env.GIT_SHA,
 *     branch    : env.BRANCH_NAME_CLEAN,
 *     registry  : env.ECR_REGISTRY,
 *     awsCredsId: 'aws-access-key',
 *     region    : 'us-east-1',
 *     context   : 'assignment-4/app'
 *   )
 *
 * Required keys: name, sha, branch, registry, awsCredsId
 */
def call(Map params) {
    ['name', 'sha', 'branch', 'registry', 'awsCredsId'].each { key ->
        if (!params.containsKey(key) || !params[key]) {
            error "buildAndPushImage: '${key}' parameter is required"
        }
    }

    String context = params.context ?: '.'
    String region  = params.region  ?: 'us-east-1'

    def docker = new DockerHelper(this)

    // Build
    docker.buildImage(params.name, params.sha, params.branch, context)

    // Authenticate to ECR then push
    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                      credentialsId: params.awsCredsId]]) {
        sh """
            aws ecr get-login-password --region ${region} | \
              docker login --username AWS --password-stdin ${params.registry}
        """
        docker.pushImage(params.name, params.sha, params.branch, params.registry)
    }
}
