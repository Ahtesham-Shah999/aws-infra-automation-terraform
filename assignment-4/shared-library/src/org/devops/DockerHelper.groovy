package org.devops

/**
 * DockerHelper – wraps docker build and push operations.
 * Usage:
 *   def docker = new DockerHelper(this)
 *   docker.buildImage('myapp', 'abc1234')
 *   docker.pushImage('myapp', 'abc1234', '123456789.dkr.ecr.us-east-1.amazonaws.com')
 */
class DockerHelper implements Serializable {

    def script

    DockerHelper(def script) {
        this.script = script
    }

    /**
     * Build a Docker image with two tags: SHA and branch name.
     * @param name        Image name (e.g. devops-a4-app)
     * @param sha         Short Git commit SHA
     * @param branchName  Branch name (slashes replaced with dashes)
     * @param context     Docker build context path (default '.')
     */
    void buildImage(String name, String sha, String branchName, String context = '.') {
        script.sh """
            docker build \
              -t ${name}:${sha} \
              -t ${name}:${branchName} \
              ${context}
        """
    }

    /**
     * Push both SHA and branch tags to ECR.
     * @param name        Image name
     * @param sha         Short Git commit SHA
     * @param branchName  Branch name tag
     * @param registry    Full ECR registry URL
     */
    void pushImage(String name, String sha, String branchName, String registry) {
        script.sh """
            docker tag ${name}:${sha}         ${registry}/${name}:${sha}
            docker tag ${name}:${branchName}  ${registry}/${name}:${branchName}
            docker push ${registry}/${name}:${sha}
            docker push ${registry}/${name}:${branchName}
        """
    }
}
