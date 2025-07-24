pipeline {
  agent any
  environment {
    GIT_LFS_SKIP_SMUDGE = '1'
    DOCKER_REGISTRY = 'ahmedrafat'
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    SNYK_TOKEN = credentials('snyk-token')
    PROJECT_NAME = 'microservices-project'
    BUILD_NUMBER = "${env.BUILD_NUMBER}"

    // Uncomment these when ready to use
    //DOCKERHUB_USERNAME = credentials('dockerhub-username')
    //DOCKERHUB_PASSWORD = credentials('dockerhub-password')
    //COSIGN_PASSWORD = credentials('cosign-password')
    //COSIGN_KEY = credentials('cosign-key')
  }
  cd
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
    stage('Setup Snyk') {
            steps {
                sh '''
                    echo "🔧 Setting up Snyk CLI..."

                    npm install snyk

                    ./node_modules/.bin/snyk --version

                    echo "🔐 Authenticating with Snyk..."
                    ./node_modules/.bin/snyk auth $SNYK_TOKEN

                    echo "✅ Snyk setup completed"
                '''
            }
        }
        
    stage('Install Dependencies') {
        parallel {
            stage('Frontend (Go)') {
                steps {
                    dir('src/frontend') {
                        sh '''
                            if [ -f "go.mod" ]; then
                                echo "🔧 Installing Go dependencies for frontend..."
                                
                                # Check if Go is available
                                if command -v go &> /dev/null; then
                                    echo "✅ Go found: $(go version)"
                                    go mod download
                                    go mod verify
                                else
                                    echo "⚠️  Go not available, skipping Go dependencies for frontend"
                                fi
                            else
                                echo "⚠️  No go.mod found for frontend"
                            fi
                        '''
                    }
                }
            }
            
            stage('Product Catalog Service (Go)') {
                steps {
                    dir('src/productcatalogservice') {
                        sh '''
                            if [ -f "go.mod" ]; then
                                echo "🔧 Installing Go dependencies for productcatalogservice..."
                                
                                if command -v go &> /dev/null; then
                                    echo "✅ Go found: $(go version)"
                                    go mod download
                                    go mod verify
                                else
                                    echo "⚠️  Go not available, skipping Go dependencies for productcatalogservice"
                                fi
                            else
                                echo "⚠️  No go.mod found for productcatalogservice"
                            fi
                        '''
                    }
                }
            }
            
            stage('Shipping Service (Go)') {
                steps {
                    dir('src/shippingservice') {
                        sh '''
                            if [ -f "go.mod" ]; then
                                echo "🔧 Installing Go dependencies for shippingservice..."
                                
                                if command -v go &> /dev/null; then
                                    echo "✅ Go found: $(go version)"
                                    go mod download
                                    go mod verify
                                else
                                    echo "⚠️  Go not available, skipping Go dependencies for shippingservice"
                                fi
                            else
                                echo "⚠️  No go.mod found for shippingservice"
                            fi
                        '''
                    }
                }
            }
            
            stage('Checkout Service (Go)') {
                steps {
                    dir('src/checkoutservice') {
                        sh '''
                            if [ -f "go.mod" ]; then
                                echo "🔧 Installing Go dependencies for checkoutservice..."
                                
                                if command -v go &> /dev/null; then
                                    echo "✅ Go found: $(go version)"
                                    go mod download
                                    go mod verify
                                else
                                    echo "⚠️  Go not available, skipping Go dependencies for checkoutservice"
                                fi
                            else
                                echo "⚠️  No go.mod found for checkoutservice"
                            fi
                        '''
                    }
                }
            }
            
            stage('Cart Service (C#)') {
                steps {
                    dir('src/cartservice') {
                        sh '''
                            if [ -f "*.csproj" ] || [ -f "*.sln" ]; then
                                echo "Installing .NET dependencies for cartservice..."
                                if command -v dotnet &> /dev/null; then
                                    dotnet restore
                                else
                                    echo "Warning: .NET runtime not available, skipping cartservice"
                                fi
                            else
                                echo "No .NET project files found for cartservice"
                            fi
                        '''
                    }
                }
            }
            
            stage('Currency Service (Node.js)') {
                steps {
                    dir('src/currencyservice') {
                        sh '''
                            if [ -f "package.json" ]; then
                                echo "🔧 Installing Node.js dependencies for currencyservice..."
                                
                                if command -v npm &> /dev/null; then
                                    echo "✅ npm found: $(npm --version)"
                                    npm ci --only=production
                                else
                                    echo "⚠️  npm not available, skipping Node.js dependencies for currencyservice"
                                fi
                            else
                                echo "⚠️  No package.json found for currencyservice"
                            fi
                        '''
                    }
                }
            }
            
            stage('Payment Service (Node.js)') {
                steps {
                    dir('src/paymentservice') {
                        sh '''
                            if [ -f "package.json" ]; then
                                echo "🔧 Installing Node.js dependencies for paymentservice..."
                                
                                if command -v npm &> /dev/null; then
                                    echo "✅ npm found: $(npm --version)"
                                    npm ci --only=production
                                else
                                    echo "⚠️  npm not available, skipping Node.js dependencies for paymentservice"
                                fi
                            else
                                echo "⚠️  No package.json found for paymentservice"
                            fi
                        '''
                    }
                }
            }
            
            stage('Email Service (Python)') {
                steps {
                    dir('src/emailservice') {
                        sh '''
                            if [ -f "requirements.txt" ]; then
                                echo "Installing Python dependencies for emailservice..."
                                if command -v python3 &> /dev/null; then
                                    python3 -m venv venv
                                    . venv/bin/activate
                                    pip install --upgrade pip
                                    pip install --no-build-isolation -r requirements.txt || echo "Skipping errors"

                                else
                                    echo "Warning: python3 not available, skipping Python dependencies"
                                fi
                            else
                                echo "No requirements.txt found for emailservice"
                            fi


                        '''
                    }
                }
            }
            
            stage('Recommendation Service (Python)') {
                steps {
                    dir('src/recommendationservice') {
                        sh '''
                            if [ -f "requirements.txt" ]; then
                                echo "Installing Python dependencies for emailservice..."
                                if command -v python3 &> /dev/null; then
                                    python3 -m venv venv
                                    . venv/bin/activate
                                    pip install --no-build-isolation -r requirements.txt || echo "Skipping errors"

                                else
                                    echo "Warning: python3 not available, skipping Python dependencies"
                                fi
                            else
                                echo "No requirements.txt found for emailservice"
                            fi

                        '''
                    }
                }
            }
            stage('Shopping Assistant Service (Python)') {
                steps {
                    dir('src/shoppingassistantservice') {
                        sh '''
                            if [ -f "requirements.txt" ]; then
                                echo "Installing Python dependencies for shoppingassistantservice..."
                                if command -v python3 &> /dev/null; then
                                    rm -rf venv
                                    python3 -m venv venv
                                    venv/bin/pip install --upgrade pip
                                    venv/bin/pip install -r requirements.txt
                                else
                                    echo "Warning: python3 not available, skipping Python dependencies"
                                fi
                            else
                                echo "No requirements.txt found for shoppingassistantservice"
                            fi
                        '''
                    }
                }
            }

            stage('Load Generator (Python)') {
                steps {
                    dir('src/loadgenerator') {
                        sh '''
                            if [ -f "requirements.txt" ]; then
                                echo "Installing Python dependencies for emailservice..."
                                if command -v python3 &> /dev/null; then
                                    python3 -m venv venv
                                    . venv/bin/activate
                                    pip install --upgrade pip
                                    pip install -r requirements.txt
                                else
                                    echo "Warning: python3 not available, skipping Python dependencies"
                                fi
                            else
                                echo "No requirements.txt found for emailservice"
                            fi

                        '''
                    }
                }
            }
            
            stage('Ad Service (Java)') {
                steps {
                    dir('src/adservice') {
                        sh '''
                            if [ -f "build.gradle" ] || [ -f "pom.xml" ]; then
                                echo "Installing Java dependencies for adservice..."
                                if [ -f "gradlew" ]; then
                                    chmod +x gradlew
                                    ./gradlew build -x test -x verifyGoogleJavaFormat --no-daemon

                                elif [ -f "build.gradle" ] && command -v gradle &> /dev/null; then
                                    ./gradlew build -x test -x verifyGoogleJavaFormat --no-daemon
                                elif [ -f "pom.xml" ] && command -v mvn &> /dev/null; then
                                    mvn compile -DskipTests
                                else
                                    echo "Warning: No suitable build tool found for Java project"
                                fi
                            else
                                echo "No Java build files found for adservice"
                            fi
                        '''
                    }
                }
            }
        }
    }
    
    stage('Snyk Security Scan - Dependencies') {
        parallel {
            stage('Snyk Test - Go Services') {
                steps {
                    script {
                        def goServices = ['frontend', 'productcatalogservice', 'shippingservice', 'checkoutservice']
                        
                        goServices.each { service ->
                            dir("src/${service}") {
                                sh """
                                    if [ -f "go.mod" ]; then
                                        echo "🔍 Running Snyk security test for ${service}..."
                                        
                                        # Run Snyk test and capture results
                                        snyk test --severity-threshold=medium --json > snyk-results-${service}.json || SNYK_EXIT=\$?
                                        
                                        # Display summary
                                        if [ -f "snyk-results-${service}.json" ]; then
                                            echo "📊 Snyk scan completed for ${service}"
                                            
                                            # Extract vulnerability counts
                                            HIGH_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                            MEDIUM_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                            LOW_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                            
                                            echo "🚨 ${service} vulnerabilities - High: \$HIGH_COUNT, Medium: \$MEDIUM_COUNT, Low: \$LOW_COUNT"
                                        fi
                                        
                                        # Monitor the project for continuous monitoring
                                        snyk monitor --project-name="${PROJECT_NAME}-${service}" --target-reference="\$GIT_COMMIT_SHORT" || true
                                    else
                                        echo "⚠️  No go.mod found for ${service}, skipping Snyk scan"
                                    fi
                                """
                            }
                        }
                    }
                }
                post {
                    always {
                        archiveArtifacts artifacts: 'src/*/snyk-results-*.json', allowEmptyArchive: true
                    }
                }
            }
            
            stage('Snyk Test - Node.js Services') {
                steps {
                    script {
                        def nodeServices = ['currencyservice', 'paymentservice']
                        
                        nodeServices.each { service ->
                            dir("src/${service}") {
                                sh """
                                    if [ -f "package.json" ]; then
                                        echo "🔍 Running Snyk security test for ${service}..."
                                        
                                        # Run Snyk test and capture results
                                        snyk test --severity-threshold=medium --json > snyk-results-${service}.json || SNYK_EXIT=\$?
                                        
                                        # Display summary
                                        if [ -f "snyk-results-${service}.json" ]; then
                                            echo "📊 Snyk scan completed for ${service}"
                                            
                                            # Extract vulnerability counts
                                            HIGH_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                            MEDIUM_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                            LOW_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                            
                                            echo "🚨 ${service} vulnerabilities - High: \$HIGH_COUNT, Medium: \$MEDIUM_COUNT, Low: \$LOW_COUNT"
                                        fi
                                        
                                        # Monitor the project
                                        snyk monitor --project-name="${PROJECT_NAME}-${service}" --target-reference="\$GIT_COMMIT_SHORT" || true
                                    else
                                        echo "⚠️  No package.json found for ${service}, skipping Snyk scan"
                                    fi
                                """
                            }
                        }
                    }
                }
            }
            
            stage('Snyk Test - Python Services') {
                steps {
                    script {
                        def pythonServices = ['emailservice', 'recommendationservice', 'loadgenerator']
                        
                        pythonServices.each { service ->
                            dir("src/${service}") {
                                sh """
                                    if [ -f "requirements.txt" ]; then
                                        echo "🔍 Running Snyk security test for ${service}..."
                                        
                                        # Run Snyk test and capture results
                                        snyk test --severity-threshold=medium --json > snyk-results-${service}.json || SNYK_EXIT=\$?
                                        
                                        # Display summary
                                        if [ -f "snyk-results-${service}.json" ]; then
                                            echo "📊 Snyk scan completed for ${service}"
                                            
                                            # Extract vulnerability counts
                                            HIGH_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                            MEDIUM_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                            LOW_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                            
                                            echo "🚨 ${service} vulnerabilities - High: \$HIGH_COUNT, Medium: \$MEDIUM_COUNT, Low: \$LOW_COUNT"
                                        fi
                                        
                                        # Monitor the project
                                        snyk monitor --project-name="${PROJECT_NAME}-${service}" --target-reference="\$GIT_COMMIT_SHORT" || true
                                    else
                                        echo "⚠️  No requirements.txt found for ${service}, skipping Snyk scan"
                                    fi
                                """
                            }
                        }
                    }
                }
            }
            
            stage('Snyk Test - Java Service') {
                steps {
                    dir('src/adservice') {
                        sh '''
                            if [ -f "build.gradle" ] || [ -f "pom.xml" ]; then
                                echo "🔍 Running Snyk security test for adservice..."
                                
                                # Run Snyk test and capture results
                                snyk test --severity-threshold=medium --json > snyk-results-adservice.json || SNYK_EXIT=$?
                                
                                # Display summary
                                if [ -f "snyk-results-adservice.json" ]; then
                                    echo "📊 Snyk scan completed for adservice"
                                    
                                    # Extract vulnerability counts
                                    HIGH_COUNT=$(cat snyk-results-adservice.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                    MEDIUM_COUNT=$(cat snyk-results-adservice.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                    LOW_COUNT=$(cat snyk-results-adservice.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                    
                                    echo "🚨 adservice vulnerabilities - High: $HIGH_COUNT, Medium: $MEDIUM_COUNT, Low: $LOW_COUNT"
                                fi
                                
                                # Monitor the project
                                snyk monitor --project-name="${PROJECT_NAME}-adservice" --target-reference="$GIT_COMMIT_SHORT" || true
                            else
                                echo "⚠️  No Java build files found for adservice, skipping Snyk scan"
                            fi
                        '''
                    }
                }
            }
            
            stage('Snyk Test - .NET Service') {
                steps {
                    dir('src/cartservice') {
                        sh '''
                            if find . -name "*.csproj" -o -name "*.sln" | grep -q .; then
                                echo "🔍 Running Snyk security test for cartservice..."
                                
                                # Run Snyk test and capture results
                                snyk test --severity-threshold=medium --json > snyk-results-cartservice.json || SNYK_EXIT=$?
                                
                                # Display summary
                                if [ -f "snyk-results-cartservice.json" ]; then
                                    echo "📊 Snyk scan completed for cartservice"
                                    
                                    # Extract vulnerability counts
                                    HIGH_COUNT=$(cat snyk-results-cartservice.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                    MEDIUM_COUNT=$(cat snyk-results-cartservice.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                    LOW_COUNT=$(cat snyk-results-cartservice.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                    
                                    echo "🚨 cartservice vulnerabilities - High: $HIGH_COUNT, Medium: $MEDIUM_COUNT, Low: $LOW_COUNT"
                                fi
                                
                                # Monitor the project
                                snyk monitor --project-name="${PROJECT_NAME}-cartservice" --target-reference="$GIT_COMMIT_SHORT" || true
                            else
                                echo "⚠️  No .NET project files found for cartservice, skipping Snyk scan"
                            fi
                        '''
                    }
                }
            }
        }
    }
    
    stage('Snyk Code Analysis') {
        parallel {
            stage('Code Scan - Go Services') {
                steps {
                    script {
                        def goServices = ['frontend', 'productcatalogservice', 'shippingservice', 'checkoutservice']
                        
                        goServices.each { service ->
                            dir("src/${service}") {
                                sh """
                                    if [ -f "go.mod" ]; then
                                        echo "🔍 Running Snyk Code analysis for ${service}..."
                                        
                                        # Run Snyk Code scan
                                        snyk code test --json > snyk-code-${service}.json || SNYK_CODE_EXIT=\$?
                                        
                                        if [ -f "snyk-code-${service}.json" ]; then
                                            echo "📊 Snyk Code scan completed for ${service}"
                                            
                                            # Extract issue counts
                                            HIGH_COUNT=\$(cat snyk-code-${service}.json | jq -r '.runs[]?.results[]? | select(.level == "error") | .ruleId' | wc -l)
                                            MEDIUM_COUNT=\$(cat snyk-code-${service}.json | jq -r '.runs[]?.results[]? | select(.level == "warning") | .ruleId' | wc -l)
                                            LOW_COUNT=\$(cat snyk-code-${service}.json | jq -r '.runs[]?.results[]? | select(.level == "note") | .ruleId' | wc -l)
                                            
                                            echo "🚨 ${service} code issues - High: \$HIGH_COUNT, Medium: \$MEDIUM_COUNT, Low: \$LOW_COUNT"
                                        fi
                                    else
                                        echo "⚠️  No go.mod found for ${service}, skipping Snyk Code scan"
                                    fi
                                """
                            }
                        }
                    }
                }
                post {
                    always {
                        archiveArtifacts artifacts: 'src/*/snyk-code-*.json', allowEmptyArchive: true
                    }
                }
            }
            
            stage('Code Scan - Other Services') {
                steps {
                    script {
                        def otherServices = ['currencyservice', 'paymentservice', 'emailservice', 'recommendationservice', 'loadgenerator', 'adservice', 'cartservice']
                        
                        otherServices.each { service ->
                            dir("src/${service}") {
                                sh """
                                    echo "🔍 Running Snyk Code analysis for ${service}..."
                                    
                                    # Run Snyk Code scan
                                    snyk code test --json > snyk-code-${service}.json || SNYK_CODE_EXIT=\$?
                                    
                                    if [ -f "snyk-code-${service}.json" ]; then
                                        echo "📊 Snyk Code scan completed for ${service}"
                                        
                                        # Extract issue counts
                                        HIGH_COUNT=\$(cat snyk-code-${service}.json | jq -r '.runs[]?.results[]? | select(.level == "error") | .ruleId' | wc -l)
                                        MEDIUM_COUNT=\$(cat snyk-code-${service}.json | jq -r '.runs[]?.results[]? | select(.level == "warning") | .ruleId' | wc -l)
                                        LOW_COUNT=\$(cat snyk-code-${service}.json | jq -r '.runs[]?.results[]? | select(.level == "note") | .ruleId' | wc -l)
                                        
                                        echo "🚨 ${service} code issues - High: \$HIGH_COUNT, Medium: \$MEDIUM_COUNT, Low: \$LOW_COUNT"
                                    fi
                                """
                            }
                        }
                    }
                }
            }
        }
    }
    stage('Snyk Scan All Projects') {
        steps {
            // Set up python venvs and install requirements for Python projects
            sh '''
                for dir in src/emailservice src/loadgenerator src/recommendationservice src/shoppingassistantservice; do
                    if [ -f "$dir/requirements.txt" ]; then
                        python3 -m venv "$dir/venv"
                        . "$dir/venv/bin/activate"
                        pip install --upgrade pip setuptools wheel
                        pip install -r "$dir/requirements.txt" || echo "Skipping errors"
                        deactivate
                    fi
                done
            '''
    
            // Run Snyk test on all projects after dependencies are installed
            sh './node_modules/.bin/snyk test --all-projects'
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

pipeline {
    agent any
    environment {
        IMAGE_TAG = "${BUILD_NUMBER}"
        GCP_PROJECT = "task-464917"
        KEY_LOCATION = "global"
        KEY_RING = "my-keyring"
        KEY_NAME = "cosign-key"
    }
    stages {
        stage('Build, Push & Sign Images') {
            steps {
                withCredentials([
                    file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
                    usernamePassword(credentialsId: 'Dockerhub-cred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')
                ]) {
                    sh '''
                        # Authenticate gcloud
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        
                        # Login to Docker Hub
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        
                        # Install cosign if not installed
                        which cosign || (curl -sSL https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 -o /usr/local/bin/cosign && chmod +x /usr/local/bin/cosign)
                        
                        SERVICES="adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice shoppingassistantservice"
                        
                        for svc in $SERVICES; do
                            if [ "$svc" = "cartservice" ]; then
                                echo "🚀 Building cartservice with custom Dockerfile"
                                docker build -f ./src/cartservice/src/Dockerfile -t $DOCKER_USER/$svc:${IMAGE_TAG} ./src/cartservice
                            else
                                echo "🚀 Building $svc"
                                docker build -t $DOCKER_USER/$svc:${IMAGE_TAG} ./src/$svc
                            fi
                            
                            docker push $DOCKER_USER/$svc:${IMAGE_TAG}
                            
                            cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes $DOCKER_USER/$svc:${IMAGE_TAG}
                        done
                    '''
                }
            }
        }
    }
}
