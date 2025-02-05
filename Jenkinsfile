pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_REPO = 'jesusramirezgamarra/frontend-react-k8'
        KUBE_DEPLOYMENT_NAME='mi-web-front-jesusramirez'
        DEPLOYMENT_FILE_NAME='deployment-frontend.yaml'
        SERVICE_NAME='mi-web-service-jesusramirez'  // 🔹 Reemplaza con el nombre real de tu servicio LoadBalancer
    }

    options {
        skipStagesAfterUnstable()
    }

    stages {
        stage('Verificar rama') {
            steps {
                script {
                    if (env.BRANCH_NAME != 'develop') {
                        error("Este pipeline solo se ejecuta en la rama 'develop'. Rama actual: ${env.BRANCH_NAME}")
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "${env.BRANCH_NAME}"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/JesusRamirezGamarra/frontend-k8-pipeline.git',
                        credentialsId: 'dockerhub-credentials'
                    ]],
                    extensions: [
                        [$class: 'CloneOption', depth: 1, noTags: true]
                    ]
                ])
            }
        }

        stage ('Instalar dependencias...') {
            agent {
                docker { image 'node:18-alpine' }
            }
            steps {
                echo "Remover dependencias antiguas o referencias por el json.lock"
                sh 'rm -rf node_modules package-lock.json'
                sh 'npm install'
            }
        }

        stage ('Construir proyecto con archivos estáticos...') {
            agent {
                docker { image 'node:18-alpine' }
            }
            steps {
                sh 'npm run build'
            }
        }

        stage('Construir y pushear imagen a DockerHub') {
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

        stage('Despliegue inicial en Minikube...') {
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
                            echo "El deployment ya existe, proceder a la actualización de la imagen..."
                        } else {
                            echo "Deployment no existe, proceder a aplicarlo..."
                            sh "kubectl apply -f $DEPLOYMENT_FILE_NAME"
                        }
                    }
                }
            }
        }

        stage('Actualización de imagen en Minikube...') {
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

        stage('Obtener IP del LoadBalancer') {
            agent {
                docker { 
                    image 'bitnami/kubectl:latest'
                    args '--entrypoint=""'
                }
            }
            steps {
                withKubeConfig([credentialsId: 'minikube-kubeconfig']) {
                    script {
                        def lbIp = sh(script: "kubectl get svc $SERVICE_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
                        if (!lbIp) {
                            lbIp = "No asignada aún"
                        }
                        env.LB_IP = lbIp
                        echo "IP del LoadBalancer: ${env.LB_IP}"
                    }
                }
            }
        }
    }

    post {
        success {
            mail to: 'luciojesusramirezgamarra@gmail.com',
                subject: "✅ Pipeline ${env.JOB_NAME} ejecutado correctamente",
                body: """
                Hola,

                El pipeline '${env.JOB_NAME}' (Build #${env.BUILD_NUMBER}) ha finalizado correctamente.

                📌 Puedes ver los detalles aquí:
                ${env.BUILD_URL}

                🌍 IP del LoadBalancer: ${env.LB_IP}

                Saludos,
                Jenkins Server
                """
        }
    }
}
