pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sarthakt86/logicworks-devops-project.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t demo-app:1.0 .'
            }
        }

        stage('Docker Run') {
            steps {
                sh 'docker rm -f demo-app || true'
                sh 'docker run -d -p 8081:8080 --name demo-app demo-app:1.0'
            }
        }
    }

    post {
        success {
            echo 'Application deployed successfully 🚀'
        }
        failure {
            echo 'Deployment failed ❌'
        }
    }
}
