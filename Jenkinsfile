pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKER_REPO = 'jesusramirezgamarra/frontend-react-k8'
        KUBE_DEPLOYMENT_NAME = 'mi-web-front-jesusramirez'
        DEPLOYMENT_FILE_NAME = 'deployment-frontend.yaml'
        SERVICE_NAME = 'mi-web-service-jesusramirez'
    }

    options {
        skipStagesAfterUnstable()
    }

    stages {
        stage('Verificar rama') {
            steps {
                script {
                    if (env.BRANCH_NAME != 'develop') {
                        error("🚫 Este pipeline solo se ejecuta en la rama 'develop'. Rama actual: ${env.BRANCH_NAME}")
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

        stage('Instalar dependencias') {
            agent {
                docker { image 'node:18-alpine' }
            }
            steps {
                echo "📦 Verificando dependencias en node_modules..."
                sh '''
                if [ ! -d "node_modules/.bin" ]; then
                    echo "⚡ No hay dependencias instaladas. Ejecutando npm ci..."
                    npm ci
                else
                    echo "✅ Dependencias ya instaladas, omitiendo instalación."
                fi
                '''
            }
        }

        stage('Construir proyecto') {
            agent {
                docker { image 'node:18-alpine' }
            }
            steps {
                echo "⚙️ Compilando frontend..."
                sh 'npm run build'
            }
        }

        stage('Construir y subir imagen a DockerHub') {
            agent {
                docker { image 'docker:latest' }
            }
            steps {
                script {
                    echo "🔐 Autenticando en DockerHub..."
                    withDockerRegistry([credentialsId: 'dockerhub-credentials']) {
                        sh '''
                        docker build --cache-from $DOCKER_REPO:latest -t $DOCKER_REPO:latest .
                        docker push $DOCKER_REPO:latest
                        '''
                    }
                }
            }
        }

        stage('Desplegar en Minikube') {
            agent {
                docker { image 'bitnami/kubectl:latest' }
            }
            steps {
                withKubeConfig([credentialsId: 'minikube-kubeconfig']) {
                    script {
                        echo "🔍 Verificando si el deployment existe..."
                        def deploymentExists = sh(script: "kubectl get deployment $KUBE_DEPLOYMENT_NAME --ignore-not-found", returnStdout: true).trim()

                        if (deploymentExists == '') {
                            echo "✅ Creando Deployment..."
                            sh "kubectl apply -f $DEPLOYMENT_FILE_NAME"
                        } else {
                            echo "🔄 Deployment ya existe, actualizando imagen..."
                            sh "kubectl set image deployment/$KUBE_DEPLOYMENT_NAME mi-web-front-jesusramirez=$DOCKER_REPO:latest"
                        }
                    }
                }
            }
        }

        stage('Obtener IP del LoadBalancer') {
            agent {
                docker { image 'bitnami/kubectl:latest' }
            }
            steps {
                withKubeConfig([credentialsId: 'minikube-kubeconfig']) {
                    script {
                        echo "🌍 Obteniendo IP del LoadBalancer..."
                        def lbIp = sh(script: "kubectl get svc $SERVICE_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
                        env.LB_IP = lbIp ?: "No asignada aún"
                        echo "🌐 IP del LoadBalancer: ${env.LB_IP}"
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
