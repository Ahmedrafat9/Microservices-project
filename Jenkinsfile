pipeline {
  agent any
  environment {
    GIT_LFS_SKIP_SMUDGE = '1'
    DOCKER_REGISTRY = 'ahmedrafat'
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    // Uncomment these when ready to use
    //DOCKERHUB_USERNAME = credentials('dockerhub-username')
    //DOCKERHUB_PASSWORD = credentials('dockerhub-password')
    //COSIGN_PASSWORD = credentials('cosign-password')
    //COSIGN_KEY = credentials('cosign-key')
  }
  
  stages {
    stage('TruffleHog Scan') {
      steps {
        sh '''
           echo "Running TruffleHog secret detection scan..."
           ls -lR $(pwd)
           docker run --rm -v $(pwd):/pwd trufflesecurity/trufflehog:latest filesystem --json /pwd > trufflehog_report.json || true
        '''
        archiveArtifacts artifacts: 'trufflehog_report.json', allowEmptyArchive: true
      }
    }
    
    stage('Build Docker Images') {
      parallel {
        stage('adservice') {
          steps {
            sh """
              echo 'Building C#-based Ad Service'
              docker build -t ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG} ./src/adservice
            """
          }
        }  
        stage('cartservice') {
          steps {
            sh """
              echo 'Building C#-based Cart Service'
              ls -la ./src/cartservice/src/
              docker build -f ./src/cartservice/src/Dockerfile -t ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG} ./src/cartservice
            """
          }
        }
        stage('checkoutservice') {
          steps {
            sh """
              echo 'Building Go-based Checkout Service'
              docker build -t ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG} ./src/checkoutservice
            """
          }
        }
        stage('currencyservice') {
          steps {
            sh """
              echo 'Building Node.js-based Currency Service'
              docker build -t ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG} ./src/currencyservice
            """
          }
        }
        stage('emailservice') {
          steps {
            sh """
              echo 'Building Python-based Email Service'
              docker build -t ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG} ./src/emailservice
            """
          }
        }
        stage('frontend') {
          steps {
            sh """
              echo 'Building Go-based Frontend Service'
              docker build -t ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG} ./src/frontend
            """
          }
        }
        stage('loadgenerator') {
          steps {
            sh """
              echo 'Building Python/Locust-based Load Generator'
              docker build -t ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG} ./src/loadgenerator
            """
          }
        }
        stage('paymentservice') {
          steps {
            sh """
              echo 'Building Node.js-based Payment Service'
              docker build -t ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG} ./src/paymentservice
            """
          }
        }
        stage('productcatalogservice') {
          steps {
            sh """
              echo 'Building Go-based Product Catalog Service'
              docker build -t ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG} ./src/productcatalogservice
            """
          }
        }
        stage('recommendationservice') {
          steps {
            sh """
              echo 'Building Python-based Recommendation Service'
              docker build -t ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG} ./src/recommendationservice
            """
          }
        }
        stage('shippingservice') {
          steps {
            sh """
              echo 'Building Go-based Shipping Service'
              docker build -t ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG} ./src/shippingservice
            """
          }
        }
        stage('shoppingassistantservice') {
          steps {
            sh """
              echo 'Building Shopping Assistant Service'
              docker build -t ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG} ./src/shoppingassistantservice
            """
          }
        }
      }
    }
    
    stage('Trivy Container Security Scan') {
      parallel {
        stage('adservice') {
          steps {
            sh "trivy image --format json --output trivy-adservice-report.json ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-adservice-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('cartservice') {
          steps {
            sh "trivy image --format json --output trivy-cartservice-report.json ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-cartservice-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('checkoutservice') {
          steps {
            sh "trivy image --format json --output trivy-checkoutservice-report.json ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-checkoutservice-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('currencyservice') {
          steps {
            sh "trivy image --format json --output trivy-currencyservice-report.json ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-currencyservice-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('emailservice') {
          steps {
            sh "trivy image --format json --output trivy-emailservice-report.json ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-emailservice-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('frontend') {
          steps {
            sh "trivy image --format json --output trivy-frontend-report.json ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-frontend-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('loadgenerator') {
          steps {
            sh "trivy image --format json --output trivy-loadgenerator-report.json ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-loadgenerator-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('paymentservice') {
          steps {
            sh "trivy image --format json --output trivy-paymentservice-report.json ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-paymentservice-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('productcatalogservice') {
          steps {
            sh "trivy image --format json --output trivy-productcatalogservice-report.json ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-productcatalogservice-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('recommendationservice') {
          steps {
            sh "trivy image --format json --output trivy-recommendationservice-report.json ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-recommendationservice-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('shippingservice') {
          steps {
            sh "trivy image --format json --output trivy-shippingservice-report.json ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-shippingservice-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('shoppingassistantservice') {
          steps {
            sh "trivy image --format json --output trivy-shoppingassistantservice-report.json ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG} || true"
          }
          post {
            always {
              archiveArtifacts artifacts: 'trivy-shoppingassistantservice-report.json', allowEmptyArchive: true
            }
          }
        }
      }
    }
    
    stage('Docker Registry Login') {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'Dockerhub-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
            sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
          }
        }
      }
    }
    
    stage('Push to Docker Registry') {
      parallel {
        stage('adservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG}"
          }
        }
        stage('cartservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG}"
          }
        }
        stage('checkoutservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG}"
          }
        }
        stage('currencyservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG}"
          }
        }
        stage('emailservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG}"
          }
        }
        stage('frontend') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG}"
          }
        }
        stage('loadgenerator') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG}"
          }
        }
        stage('paymentservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG}"
          }
        }
        stage('productcatalogservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG}"
          }
        }
        stage('recommendationservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG}"
          }
        }
        stage('shippingservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG}"
          }
        }
        stage('shoppingassistantservice') {
          steps {
            sh "docker push ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG}"
          }
        }
      }
    }
    
    /*
    // Uncomment this stage when ready to use Cosign
    stage('Cosign Sign Images') {
      parallel {
        stage('adservice') {
          steps {
            withCredentials([
              file(credentialsId: 'cosign-key', variable: 'COSIGN_KEY'),
              string(credentialsId: 'cosign-password', variable: 'COSIGN_PASSWORD')
            ]) {
              sh """
                cosign sign --key \${COSIGN_KEY} ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG}
              """
            }
          }
        }
        // Add other services here following the same pattern
      }
    }
    */
  }
  
  post {
    always {
      script {
        sh '''
          echo "=== FINAL PIPELINE SUMMARY ===" > final_report.txt
          echo "Build: ${BUILD_NUMBER}" >> final_report.txt
          echo "Date: $(date)" >> final_report.txt
          echo "Repository: ${GIT_URL}" >> final_report.txt
          echo "Commit: ${GIT_COMMIT}" >> final_report.txt
          echo "" >> final_report.txt
          
          echo "=== SECURITY SCANS COMPLETED ===" >> final_report.txt
          echo "- TruffleHog Secret Detection: $([ -f trufflehog_report.json ] && echo 'COMPLETED' || echo 'FAILED')" >> final_report.txt
          echo "- Trivy Container Scan: $(find . -name 'trivy-*-report.json' | wc -l) images scanned" >> final_report.txt
          echo "" >> final_report.txt
          
          echo "=== DOCKER IMAGES BUILT ===" >> final_report.txt
          docker images | grep ${DOCKER_REGISTRY} | grep ${IMAGE_TAG} >> final_report.txt || echo "No images found" >> final_report.txt
        '''
        
        archiveArtifacts artifacts: 'final_report.txt, trivy-*-report.json', fingerprint: true, allowEmptyArchive: true
      }
      
      // Clean up Docker images to save space
      sh """
        docker system prune -f || true
      """
      
      cleanWs()
    }
    
    success {
      echo 'Comprehensive security pipeline completed successfully!'
    }
    
    failure {
      echo 'Pipeline failed! Check logs for details.'
    }
  }
}
