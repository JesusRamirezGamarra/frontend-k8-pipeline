pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_REPO = 'jesusramirezgamarra/frontend-react-k8'
        KUBE_DEPLOYMENT_NAME='mi-web-front-jesusramirez'
        DEPLOYMENT_FILE_NAME='deployment-frontend.yaml'
    }

    stages {
        stage ('Instalar dependencias...') {
            agent {
                docker { image 'node:18-alpine'}
            }
            steps {
                echo "Remover dependencias antiguas o referencias por el json.lock"
                sh 'rm -rf node_modules package-lock.json'
                sh 'npm install'
            }
        }

        stage ('Construir proyecto con archivos estaticos...') {
            agent {
                docker { image 'node:18-alpine'}
            }
            steps {
                sh 'npm run build'
            }
        }

        stage('Construir y pushear imagen a dockerhub') {
            agent {
                docker {
                    image 'docker:latest'
                }
            }
            steps {
                sh '''
                echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                docker build -t $DOCKER_REPO:latest .
                docker push $DOCKER_REPO:latest
                '''
            }
        }

        stage('Despliegue inicial en minikube...') {
            agent {
                docker { 
                    image 'bitnami/kubectl:latest'
                    args '--entrypoint=""'
                }
            }
            steps {
                withKubeConfig([credentialsId: 'minikube-kubeconfig']) {
                    script {
                        def deploymentExists = sh(script: "kubectl get deployment $KUBE_DEPLOYMENT_NAME --ignore-not-found", returnStdout: true).trim()
                        if (deploymentExists) {
                            echo "El deployment ya existe, proceder a la actualizacion de la imagen..."
                        } else {
                            echo "Deployment no existe proceder a aplicarlo..."
                            sh "kubectl apply -f $DEPLOYMENT_FILE_NAME"
                        }
                    }
                }
            }
        }

        stage('Actualizacion de imagen en minikube...') {
            agent {
                docker { 
                    image 'bitnami/kubectl:latest'
                    args '--entrypoint=""'
                }
            }
            steps {
                withKubeConfig([credentialsId: 'minikube-kubeconfig']) {
                    sh "kubectl set image deployment/$KUBE_DEPLOYMENT_NAME mi-web-front-jesusramirez=$DOCKER_REPO:latest"
                }
            }
        }

    }
}