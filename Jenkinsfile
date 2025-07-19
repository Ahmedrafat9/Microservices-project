pipeline {
  agent any
  environment {
    GIT_LFS_SKIP_SMUDGE = '1'
    DOCKER_REGISTRY = 'ahmedrafat' // update this
    IMAGE_TAG = "${env.BUILD_NUMBER}"  // Jenkins build number as tag
    SNYK_TOKEN = credentials('snyk-token')
    //DOCKERHUB_USERNAME = credentials('dockerhub-username')
    //DOCKERHUB_PASSWORD = credentials('dockerhub-password')
    //COSIGN_PASSWORD = credentials('cosign-password')
    //COSIGN_KEY = credentials('cosign-key') // this is a file; might use secret file credential
    }
  
  stages {
    stage('Setup Protocol Buffers') {
      steps {
        script {
          // Install protoc if not available
          sh '''
            if ! command -v protoc &> /dev/null; then
              echo "Installing Protocol Buffers compiler..."
              sudo apt-get update && apt-get install -y protobuf-compiler
            fi
            protoc --version
          '''
        }
      }
    }
    
    stage('Compile Protocol Buffers') {
      parallel {
        stage('Go Services Proto') {
          steps {
            sh '''
              # Compile proto files for Go services (frontend, productcatalogservice, shippingservice, checkoutservice)
              mkdir -p ./frontend/genproto
              mkdir -p ./productcatalogservice/genproto
              mkdir -p ./shippingservice/genproto
              mkdir -p ./checkoutservice/genproto
              
              protoc --go_out=./frontend/genproto --go-grpc_out=./frontend/genproto ./protos/*.proto
              protoc --go_out=./productcatalogservice/genproto --go-grpc_out=./productcatalogservice/genproto ./protos/*.proto
              protoc --go_out=./shippingservice/genproto --go-grpc_out=./shippingservice/genproto ./protos/*.proto
              protoc --go_out=./checkoutservice/genproto --go-grpc_out=./checkoutservice/genproto ./protos/*.proto
            '''
          }
        }
        stage('C# Services Proto') {
          steps {
            sh '''
              # Compile proto files for C# services (cartservice)
              mkdir -p ./cartservice/genproto
              protoc --csharp_out=./cartservice/genproto --grpc_out=./cartservice/genproto --plugin=protoc-gen-grpc=grpc_csharp_plugin ./protos/*.proto
            '''
          }
        }
        stage('Node.js Services Proto') {
          steps {
            sh '''
              # Compile proto files for Node.js services (currencyservice, paymentservice)
              mkdir -p ./currencyservice/genproto
              mkdir -p ./paymentservice/genproto
              
              protoc --js_out=import_style=commonjs,binary:./currencyservice/genproto --grpc_out=./currencyservice/genproto --plugin=protoc-gen-grpc=grpc_node_plugin ./protos/*.proto
              protoc --js_out=import_style=commonjs,binary:./paymentservice/genproto --grpc_out=./paymentservice/genproto --plugin=protoc-gen-grpc=grpc_node_plugin ./protos/*.proto
            '''
          }
        }
        stage('Python Services Proto') {
          steps {
            sh '''
              # Compile proto files for Python services (emailservice, recommendationservice, loadgenerator)
              mkdir -p ./emailservice/genproto
              mkdir -p ./recommendationservice/genproto
              mkdir -p ./loadgenerator/genproto
              
              python -m grpc_tools.protoc --python_out=./emailservice/genproto --grpc_python_out=./emailservice/genproto --proto_path=./protos ./protos/*.proto
              python -m grpc_tools.protoc --python_out=./recommendationservice/genproto --grpc_python_out=./recommendationservice/genproto --proto_path=./protos ./protos/*.proto
              python -m grpc_tools.protoc --python_out=./loadgenerator/genproto --grpc_python_out=./loadgenerator/genproto --proto_path=./protos ./protos/*.proto
            '''
          }
        }
        stage('Java Services Proto') {
          steps {
            sh '''
              # Compile proto files for Java services (adservice)
              mkdir -p ./adservice/src/main/java/genproto
              protoc --java_out=./adservice/src/main/java/genproto --grpc_java_out=./adservice/src/main/java/genproto --plugin=protoc-gen-grpc-java=protoc-gen-grpc-java ./protos/*.proto
            '''
          }
        }
      }
    }
    
    stage('TruffleHog Scan') {
      parallel {
        stage('adservice') { steps { sh 'trufflehog --json ./adservice' } }
        stage('cartservice') { steps { sh 'trufflehog --json ./cartservice' } }
        stage('checkoutservice') { steps { sh 'trufflehog --json ./checkoutservice' } }
        stage('currencyservice') { steps { sh 'trufflehog --json ./currencyservice' } }
        stage('emailservice') { steps { sh 'trufflehog --json ./emailservice' } }
        stage('frontend') { steps { sh 'trufflehog --json ./frontend' } }
        stage('loadgenerator') { steps { sh 'trufflehog --json ./loadgenerator' } }
        stage('paymentservice') { steps { sh 'trufflehog --json ./paymentservice' } }
        stage('productcatalogservice') { steps { sh 'trufflehog --json ./productcatalogservice' } }
        stage('recommendationservice') { steps { sh 'trufflehog --json ./recommendationservice' } }
        stage('shippingservice') { steps { sh 'trufflehog --json ./shippingservice' } }
        stage('shoppingassistantservice') { steps { sh 'trufflehog --json ./shoppingassistantservice' } }
      }
    }
    
    stage('Snyk Scan') {
      parallel {
        stage('adservice') { steps { sh "snyk test --file=adservice/pom.xml || true" } }
        stage('cartservice') { steps { sh "snyk test --file=cartservice/src/cartservice.csproj || true" } }
        stage('checkoutservice') { steps { sh "snyk test --file=checkoutservice/go.mod || true" } }
        stage('currencyservice') { steps { sh "snyk test --file=currencyservice/package.json || true" } }
        stage('emailservice') { steps { sh "snyk test --file=emailservice/requirements.txt || true" } }
        stage('frontend') { steps { sh "snyk test --file=frontend/go.mod || true" } }
        stage('loadgenerator') { steps { sh "snyk test --file=loadgenerator/requirements.txt || true" } }
        stage('paymentservice') { steps { sh "snyk test --file=paymentservice/package.json || true" } }
        stage('productcatalogservice') { steps { sh "snyk test --file=productcatalogservice/go.mod || true" } }
        stage('recommendationservice') { steps { sh "snyk test --file=recommendationservice/requirements.txt || true" } }
        stage('shippingservice') { steps { sh "snyk test --file=shippingservice/go.mod || true" } }
        stage('shoppingassistantservice') { steps { sh "snyk test --file=shoppingassistantservice/requirements.txt || true" } }
      }
    }
    
    stage('Build Docker Images') {
      parallel {
        stage('adservice') { 
          steps { 
            sh """
              echo 'Building Java-based Ad Service'
              docker build -t ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG} ./adservice
            """ 
          } 
        }
        stage('cartservice') { 
          steps { 
            sh """
              echo 'Building C#-based Cart Service'
              docker build -t ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG} ./cartservice
            """ 
          } 
        }
        stage('checkoutservice') { 
          steps { 
            sh """
              echo 'Building Go-based Checkout Service'
              docker build -t ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG} ./checkoutservice
            """ 
          } 
        }
        stage('currencyservice') { 
          steps { 
            sh """
              echo 'Building Node.js-based Currency Service'
              docker build -t ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG} ./currencyservice
            """ 
          } 
        }
        stage('emailservice') { 
          steps { 
            sh """
              echo 'Building Python-based Email Service'
              docker build -t ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG} ./emailservice
            """ 
          } 
        }
        stage('frontend') { 
          steps { 
            sh """
              echo 'Building Go-based Frontend Service'
              docker build -t ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG} ./frontend
            """ 
          } 
        }
        stage('loadgenerator') { 
          steps { 
            sh """
              echo 'Building Python/Locust-based Load Generator'
              docker build -t ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG} ./loadgenerator
            """ 
          } 
        }
        stage('paymentservice') { 
          steps { 
            sh """
              echo 'Building Node.js-based Payment Service'
              docker build -t ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG} ./paymentservice
            """ 
          } 
        }
        stage('productcatalogservice') { 
          steps { 
            sh """
              echo 'Building Go-based Product Catalog Service'
              docker build -t ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG} ./productcatalogservice
            """ 
          } 
        }
        stage('recommendationservice') { 
          steps { 
            sh """
              echo 'Building Python-based Recommendation Service'
              docker build -t ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG} ./recommendationservice
            """ 
          } 
        }
        stage('shippingservice') { 
          steps { 
            sh """
              echo 'Building Go-based Shipping Service'
              docker build -t ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG} ./shippingservice
            """ 
          } 
        }
        stage('shoppingassistantservice') { 
          steps { 
            sh """
              echo 'Building Shopping Assistant Service'
              docker build -t ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG} ./shoppingassistantservice
            """ 
          } 
        }
      }
    }
    
    stage('Trivy Scan') {
      parallel {
        stage('adservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG}" } }
        stage('cartservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG}" } }
        stage('checkoutservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG}" } }
        stage('currencyservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG}" } }
        stage('emailservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG}" } }
        stage('frontend') { steps { sh "trivy image ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG}" } }
        stage('loadgenerator') { steps { sh "trivy image ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG}" } }
        stage('paymentservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG}" } }
        stage('productcatalogservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG}" } }
        stage('recommendationservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG}" } }
        stage('shippingservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG}" } }
        stage('shoppingassistantservice') { steps { sh "trivy image ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG}" } }
      }
    }
     stage('GCP Auth') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS --project=task-464917'
        }
      }
    }
    stage('Cosign Sign') {
      parallel {
        stage('adservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG}" } }
        stage('cartservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG}" } }
        stage('checkoutservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG}" } }
        stage('currencyservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG}" } }
        stage('emailservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG}" } }
        stage('frontend') { steps { sh "cosign sign ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG}" } }
        stage('loadgenerator') { steps { sh "cosign sign ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG}" } }
        stage('paymentservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG}" } }
        stage('productcatalogservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG}" } }
        stage('recommendationservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG}" } }
        stage('shippingservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG}" } }
        stage('shoppingassistantservice') { steps { sh "cosign sign ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG}" } }
      }
    }
    
    stage('Dockerhub Auth') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS --project=task-464917'
        }
      }
    }
    stage('Push to Docker Registry') {
        
      parallel {
        stage('adservice') { steps { sh "docker push ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG}" } }
        stage('cartservice') { steps { sh "docker push ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG}" } }
        stage('checkoutservice') { steps { sh "docker push ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG}" } }
        stage('currencyservice') { steps { sh "docker push ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG}" } }
        stage('emailservice') { steps { sh "docker push ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG}" } }
        stage('frontend') { steps { sh "docker push ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG}" } }
        stage('loadgenerator') { steps { sh "docker push ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG}" } }
        stage('paymentservice') { steps { sh "docker push ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG}" } }
        stage('productcatalogservice') { steps { sh "docker push ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG}" } }
        stage('recommendationservice') { steps { sh "docker push ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG}" } }
        stage('shippingservice') { steps { sh "docker push ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG}" } }
        stage('shoppingassistantservice') { steps { sh "docker push ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG}" } }
      }
    }
  }
  
  post {
    always {
      // Clean up workspace
      cleanWs()
    }
    success {
      echo 'Pipeline completed successfully!'
    }
    failure {
      echo 'Pipeline failed!'
    }
  }
}