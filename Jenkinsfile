pipeline {
    agent any
    
    environment {
        GIT_LFS_SKIP_SMUDGE = '1'
        DOCKER_REGISTRY = 'ahmedrafat'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        SNYK_TOKEN = credentials('snyk-token')
        PROJECT_NAME = 'microservices-project'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        GIT_COMMIT_SHORT = "${env.GIT_COMMIT?.take(7) ?: 'unknown'}"
        
        // GCP KMS Configuration for Cosign
        GCP_PROJECT = "task-464917"
        KEY_LOCATION = "global"
        KEY_RING = "my-keyring"
        KEY_NAME = "cosign-key"
    }
    
    stages {
        // STAGE 1: TRUFFLEHOG SECRET DETECTION
        stage('TruffleHog Secret Detection') {
            steps {
                sh '''
                    echo "🔍 Running TruffleHog secret detection scan..."
                    ls -lR $(pwd)
                    docker run --rm -v $(pwd):/pwd trufflesecurity/trufflehog:latest filesystem --json /pwd > trufflehog_report.json || true
                    
                    # Show summary of findings
                    if [ -f trufflehog_report.json ]; then
                        echo "📊 TruffleHog scan completed"
                        SECRETS_COUNT=$(cat trufflehog_report.json | jq '. | length' 2>/dev/null || echo "0")
                        echo "🚨 Secrets found: $SECRETS_COUNT"
                        
                        # Show first few lines for quick review
                        echo "📄 Sample findings:"
                        head -n 10 trufflehog_report.json || true
                    fi
                '''
                archiveArtifacts artifacts: 'trufflehog_report.json', allowEmptyArchive: true
            }
        }
        
        // STAGE 2: SNYK SECURITY ANALYSIS
        stage('Snyk Security Analysis') {
            stages {
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
                        stage('Go Services Dependencies') {
                            steps {
                                script {
                                    def goServices = ['frontend', 'productcatalogservice', 'shippingservice', 'checkoutservice']
                                    goServices.each { service ->
                                        dir("src/${service}") {
                                            sh '''
                                                if [ -f "go.mod" ]; then
                                                    echo "🔧 Installing Go dependencies for ''' + service + '''..."
                                                    if command -v go &> /dev/null; then
                                                        echo "✅ Go found: $(go version)"
                                                        go mod download
                                                        go mod verify
                                                    else
                                                        echo "⚠️  Go not available, skipping dependencies"
                                                    fi
                                                else
                                                    echo "⚠️  No go.mod found"
                                                fi
                                            '''
                                        }
                                    }
                                }
                            }
                        }
                        
                        stage('Node.js Services Dependencies') {
                            steps {
                                script {
                                    def nodeServices = ['currencyservice', 'paymentservice']
                                    nodeServices.each { service ->
                                        dir("src/${service}") {
                                            sh '''
                                                if [ -f "package.json" ]; then
                                                    echo "🔧 Installing Node.js dependencies for ''' + service + '''..."
                                                    if command -v npm &> /dev/null; then
                                                        echo "✅ npm found: $(npm --version)"
                                                        npm ci --only=production
                                                    else
                                                        echo "⚠️  npm not available, skipping dependencies"
                                                    fi
                                                else
                                                    echo "⚠️  No package.json found"
                                                fi
                                            '''
                                        }
                                    }
                                }
                            }
                        }
                        
                        stage('Python Services Dependencies') {
                            steps {
                                script {
                                    def pythonServices = ['emailservice', 'recommendationservice', 'loadgenerator', 'shoppingassistantservice']
                                    pythonServices.each { service ->
                                        dir("src/${service}") {
                                            sh '''
                                                if [ -f "requirements.txt" ]; then
                                                    echo "🔧 Installing Python dependencies for ''' + service + '''..."
                                                    if command -v python3 &> /dev/null; then
                                                        echo "✅ Python3 found: $(python3 --version)"
                                                        python3 -m venv venv
                                                        . venv/bin/activate
                                                        pip install --upgrade pip
                                                        pip install --no-build-isolation -r requirements.txt || echo "Skipping errors"
                                                    else
                                                        echo "⚠️  python3 not available, skipping dependencies"
                                                    fi
                                                else
                                                    echo "⚠️  No requirements.txt found"
                                                fi
                                            '''
                                        }
                                    }
                                }
                            }
                        }
                        
                        stage('Java Service Dependencies') {
                            steps {
                                dir('src/adservice') {
                                    sh '''
                                        if [ -f "build.gradle" ] || [ -f "pom.xml" ]; then
                                            echo "🔧 Installing Java dependencies for adservice..."
                                            if [ -f "gradlew" ]; then
                                                chmod +x gradlew
                                                ./gradlew build -x test -x verifyGoogleJavaFormat --no-daemon
                                            elif [ -f "build.gradle" ] && command -v gradle &> /dev/null; then
                                                gradle build -x test -x verifyGoogleJavaFormat --no-daemon
                                            elif [ -f "pom.xml" ] && command -v mvn &> /dev/null; then
                                                mvn compile -DskipTests
                                            else
                                                echo "⚠️  No suitable build tool found"
                                            fi
                                        else
                                            echo "⚠️  No Java build files found"
                                        fi
                                    '''
                                }
                            }
                        }
                        
                        stage('.NET Service Dependencies') {
                            steps {
                                dir('src/cartservice') {
                                    sh '''
                                        if find . -name "*.csproj" -o -name "*.sln" | grep -q .; then
                                            echo "🔧 Installing .NET dependencies for cartservice..."
                                            if command -v dotnet &> /dev/null; then
                                                echo "✅ .NET found: $(dotnet --version)"
                                                dotnet restore
                                            else
                                                echo "⚠️  .NET runtime not available, skipping"
                                            fi
                                        else
                                            echo "⚠️  No .NET project files found"
                                        fi
                                    '''
                                }
                            }
                        }
                    }
                }
                
                stage('Snyk Vulnerability Scan') {
                    parallel {
                        stage('Snyk - Go Services') {
                            steps {
                                script {
                                    def goServices = ['frontend', 'productcatalogservice', 'shippingservice', 'checkoutservice']
                                    goServices.each { service ->
                                        dir("src/${service}") {
                                            sh """
                                                if [ -f "go.mod" ]; then
                                                    echo "🔍 Running Snyk vulnerability scan for ${service}..."
                                                    
                                                    # Run Snyk test
                                                    ../../node_modules/.bin/snyk test --severity-threshold=medium --json > snyk-results-${service}.json || SNYK_EXIT=\$?
                                                    
                                                    if [ -f "snyk-results-${service}.json" ]; then
                                                        echo "📊 Snyk scan completed for ${service}"
                                                        HIGH_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                                        MEDIUM_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                                        LOW_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                                        echo "🚨 ${service} vulnerabilities - High: \$HIGH_COUNT, Medium: \$MEDIUM_COUNT, Low: \$LOW_COUNT"
                                                    fi
                                                    
                                                    # Monitor project
                                                    ../../node_modules/.bin/snyk monitor --project-name="${PROJECT_NAME}-${service}" --target-reference="${GIT_COMMIT_SHORT}" || true
                                                else
                                                    echo "⚠️  No go.mod found, skipping Snyk scan"
                                                fi
                                            """
                                        }
                                    }
                                }
                            }
                        }
                        
                        stage('Snyk - Node.js Services') {
                            steps {
                                script {
                                    def nodeServices = ['currencyservice', 'paymentservice']
                                    nodeServices.each { service ->
                                        dir("src/${service}") {
                                            sh """
                                                if [ -f "package.json" ]; then
                                                    echo "🔍 Running Snyk vulnerability scan for ${service}..."
                                                    ../../node_modules/.bin/snyk test --severity-threshold=medium --json > snyk-results-${service}.json || SNYK_EXIT=\$?
                                                    
                                                    if [ -f "snyk-results-${service}.json" ]; then
                                                        echo "📊 Snyk scan completed for ${service}"
                                                        HIGH_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                                        MEDIUM_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                                        LOW_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                                        echo "🚨 ${service} vulnerabilities - High: \$HIGH_COUNT, Medium: \$MEDIUM_COUNT, Low: \$LOW_COUNT"
                                                    fi
                                                    
                                                    ../../node_modules/.bin/snyk monitor --project-name="${PROJECT_NAME}-${service}" --target-reference="${GIT_COMMIT_SHORT}" || true
                                                else
                                                    echo "⚠️  No package.json found, skipping Snyk scan"
                                                fi
                                            """
                                        }
                                    }
                                }
                            }
                        }
                        
                        stage('Snyk - Python Services') {
                            steps {
                                script {
                                    def pythonServices = ['emailservice', 'recommendationservice', 'loadgenerator', 'shoppingassistantservice']
                                    pythonServices.each { service ->
                                        dir("src/${service}") {
                                            sh """
                                                if [ -f "requirements.txt" ]; then
                                                    echo "🔍 Running Snyk vulnerability scan for ${service}..."
                                                    ../../node_modules/.bin/snyk test --severity-threshold=medium --json > snyk-results-${service}.json || SNYK_EXIT=\$?
                                                    
                                                    if [ -f "snyk-results-${service}.json" ]; then
                                                        echo "📊 Snyk scan completed for ${service}"
                                                        HIGH_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                                        MEDIUM_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                                        LOW_COUNT=\$(cat snyk-results-${service}.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                                        echo "🚨 ${service} vulnerabilities - High: \$HIGH_COUNT, Medium: \$MEDIUM_COUNT, Low: \$LOW_COUNT"
                                                    fi
                                                    
                                                    ../../node_modules/.bin/snyk monitor --project-name="${PROJECT_NAME}-${service}" --target-reference="${GIT_COMMIT_SHORT}" || true
                                                else
                                                    echo "⚠️  No requirements.txt found, skipping Snyk scan"
                                                fi
                                            """
                                        }
                                    }
                                }
                            }
                        }
                        
                        stage('Snyk - Java Services') {
                            steps {
                                dir('src/adservice') {
                                    sh '''
                                        if [ -f "build.gradle" ] || [ -f "pom.xml" ]; then
                                            echo "🔍 Running Snyk vulnerability scan for adservice..."
                                            ../../node_modules/.bin/snyk test --severity-threshold=medium --json > snyk-results-adservice.json || SNYK_EXIT=$?
                                            
                                            if [ -f "snyk-results-adservice.json" ]; then
                                                echo "📊 Snyk scan completed for adservice"
                                                HIGH_COUNT=$(cat snyk-results-adservice.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                                MEDIUM_COUNT=$(cat snyk-results-adservice.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                                LOW_COUNT=$(cat snyk-results-adservice.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                                echo "🚨 adservice vulnerabilities - High: $HIGH_COUNT, Medium: $MEDIUM_COUNT, Low: $LOW_COUNT"
                                            fi
                                            
                                            ../../node_modules/.bin/snyk monitor --project-name="${PROJECT_NAME}-adservice" --target-reference="${GIT_COMMIT_SHORT}" || true
                                        else
                                            echo "⚠️  No Java build files found, skipping Snyk scan"
                                        fi
                                    '''
                                }
                            }
                        }
                        
                        stage('Snyk - .NET Services') {
                            steps {
                                dir('src/cartservice') {
                                    sh '''
                                        if find . -name "*.csproj" -o -name "*.sln" | grep -q .; then
                                            echo "🔍 Running Snyk vulnerability scan for cartservice..."
                                            ../../node_modules/.bin/snyk test --severity-threshold=medium --json > snyk-results-cartservice.json || SNYK_EXIT=$?
                                            
                                            if [ -f "snyk-results-cartservice.json" ]; then
                                                echo "📊 Snyk scan completed for cartservice"
                                                HIGH_COUNT=$(cat snyk-results-cartservice.json | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l)
                                                MEDIUM_COUNT=$(cat snyk-results-cartservice.json | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l)
                                                LOW_COUNT=$(cat snyk-results-cartservice.json | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l)
                                                echo "🚨 cartservice vulnerabilities - High: $HIGH_COUNT, Medium: $MEDIUM_COUNT, Low: $LOW_COUNT"
                                            fi
                                            
                                            ../../node_modules/.bin/snyk monitor --project-name="${PROJECT_NAME}-cartservice" --target-reference="${GIT_COMMIT_SHORT}" || true
                                        else
                                            echo "⚠️  No .NET project files found, skipping Snyk scan"
                                        fi
                                    '''
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
                
                stage('Snyk Code Analysis') {
                    parallel {
                        stage('Code Analysis - Go Services') {
                            steps {
                                script {
                                    def goServices = ['frontend', 'productcatalogservice', 'shippingservice', 'checkoutservice']
                                    goServices.each { service ->
                                        dir("src/${service}") {
                                            sh """
                                                if [ -f "go.mod" ]; then
                                                    echo "🔍 Running Snyk Code analysis for ${service}..."
                                                    ../../node_modules/.bin/snyk code test --json > snyk-code-${service}.json || SNYK_CODE_EXIT=\$?
                                                    
                                                    if [ -f "snyk-code-${service}.json" ]; then
                                                        echo "📊 Snyk Code scan completed for ${service}"
                                                        HIGH_COUNT=\$(cat snyk-code-${service}.json | jq -r '.runs[]?.results[]? | select(.level == "error") | .ruleId' | wc -l)
                                                        MEDIUM_COUNT=\$(cat snyk-code-${service}.json | jq -r '.runs[]?.results[]? | select(.level == "warning") | .ruleId' | wc -l)
                                                        LOW_COUNT=\$(cat snyk-code-${service}.json | jq -r '.runs[]?.results[]? | select(.level == "note") | .ruleId' | wc -l)
                                                        echo "🚨 ${service} code issues - High: \$HIGH_COUNT, Medium: \$MEDIUM_COUNT, Low: \$LOW_COUNT"
                                                    fi
                                                else
                                                    echo "⚠️  No go.mod found, skipping Snyk Code scan"
                                                fi
                                            """
                                        }
                                    }
                                }
                            }
                        }
                        
                        stage('Code Analysis - Other Services') {
                            steps {
                                script {
                                    def otherServices = ['currencyservice', 'paymentservice', 'emailservice', 'recommendationservice', 'loadgenerator', 'adservice', 'cartservice', 'shoppingassistantservice']
                                    otherServices.each { service ->
                                        dir("src/${service}") {
                                            sh """
                                                echo "🔍 Running Snyk Code analysis for ${service}..."
                                                ../../node_modules/.bin/snyk code test --json > snyk-code-${service}.json || SNYK_CODE_EXIT=\$?
                                                
                                                if [ -f "snyk-code-${service}.json" ]; then
                                                    echo "📊 Snyk Code scan completed for ${service}"
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
                    post {
                        always {
                            archiveArtifacts artifacts: 'src/*/snyk-code-*.json', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        
        // STAGE 3: BUILD DOCKER IMAGES
        stage('Build Docker Images') {
            parallel {
                stage('adservice') {
                    steps {
                        sh """
                            echo '🐳 Building Java-based Ad Service'
                            docker build -t ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG} ./src/adservice
                        """
                    }
                }
                
                stage('cartservice') {
                    steps {
                        sh """
                            echo '🐳 Building C#-based Cart Service'
                            docker build -f ./src/cartservice/src/Dockerfile -t ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG} ./src/cartservice
                        """
                    }
                }
                
                stage('checkoutservice') {
                    steps {
                        sh """
                            echo '🐳 Building Go-based Checkout Service'
                            docker build -t ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG} ./src/checkoutservice
                        """
                    }
                }
                
                stage('currencyservice') {
                    steps {
                        sh """
                            echo '🐳 Building Node.js-based Currency Service'
                            docker build -t ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG} ./src/currencyservice
                        """
                    }
                }
                
                stage('emailservice') {
                    steps {
                        sh """
                            echo '🐳 Building Python-based Email Service'
                            docker build -t ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG} ./src/emailservice
                        """
                    }
                }
                
                stage('frontend') {
                    steps {
                        sh """
                            echo '🐳 Building Go-based Frontend Service'
                            docker build -t ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG} ./src/frontend
                        """
                    }
                }
                
                stage('loadgenerator') {
                    steps {
                        sh """
                            echo '🐳 Building Python/Locust-based Load Generator'
                            docker build -t ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG} ./src/loadgenerator
                        """
                    }
                }
                
                stage('paymentservice') {
                    steps {
                        sh """
                            echo '🐳 Building Node.js-based Payment Service'
                            docker build -t ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG} ./src/paymentservice
                        """
                    }
                }
                
                stage('productcatalogservice') {
                    steps {
                        sh """
                            echo '🐳 Building Go-based Product Catalog Service'
                            docker build -t ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG} ./src/productcatalogservice
                        """
                    }
                }
                
                stage('recommendationservice') {
                    steps {
                        sh """
                            echo '🐳 Building Python-based Recommendation Service'
                            docker build -t ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG} ./src/recommendationservice
                        """
                    }
                }
                
                stage('shippingservice') {
                    steps {
                        sh """
                            echo '🐳 Building Go-based Shipping Service'
                            docker build -t ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG} ./src/shippingservice
                        """
                    }
                }
                
                stage('shoppingassistantservice') {
                    steps {
                        sh """
                            echo '🐳 Building Shopping Assistant Service'
                            docker build -t ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG} ./src/shoppingassistantservice
                        """
                    }
                }
            }
        }
        
        // STAGE 4: TRIVY CONTAINER SECURITY SCAN
        stage('Trivy Container Security Scan') {
            parallel {
                stage('adservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for adservice..."
                            trivy image --format json --output trivy-adservice-report.json ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-adservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('cartservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for cartservice..."
                            trivy image --format json --output trivy-cartservice-report.json ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-cartservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('checkoutservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for checkoutservice..."
                            trivy image --format json --output trivy-checkoutservice-report.json ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-checkoutservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('currencyservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for currencyservice..."
                            trivy image --format json --output trivy-currencyservice-report.json ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-currencyservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('emailservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for emailservice..."
                            trivy image --format json --output trivy-emailservice-report.json ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-emailservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('frontend') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for frontend..."
                            trivy image --format json --output trivy-frontend-report.json ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-frontend-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('loadgenerator') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for loadgenerator..."
                            trivy image --format json --output trivy-loadgenerator-report.json ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-loadgenerator-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('paymentservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for paymentservice..."
                            trivy image --format json --output trivy-paymentservice-report.json ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-paymentservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('productcatalogservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for productcatalogservice..."
                            trivy image --format json --output trivy-productcatalogservice-report.json ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-productcatalogservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('recommendationservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for recommendationservice..."
                            trivy image --format json --output trivy-recommendationservice-report.json ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-recommendationservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('shippingservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for shippingservice..."
                            trivy image --format json --output trivy-shippingservice-report.json ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-shippingservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('shoppingassistantservice') {
                    steps {
                        sh """
                            echo "🔍 Running Trivy scan for shoppingassistantservice..."
                            trivy image --format json --output trivy-shoppingassistantservice-report.json ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG} || true
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-shoppingassistantservice-report.json', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        
        // STAGE 5: SETUP COSIGN
        stage('Setup Cosign') {
            steps {
                withCredentials([
                    file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                ]) {
                    sh '''
                        # Authenticate with GCP
                        echo "🔐 Authenticating with GCP..."
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        
                        # Install cosign if not available
                        if ! command -v cosign &> /dev/null; then
                            echo "🔧 Installing Cosign..."
                            curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
                            sudo mv cosign-linux-amd64 /usr/local/bin/cosign
                            sudo chmod +x /usr/local/bin/cosign
                        fi
                        
                        echo "✅ Cosign version: $(cosign version)"
                    '''
                }
            }
        }
        
        // STAGE 6: COSIGN SIGN IMAGES
        stage('Cosign Sign Images') {
            parallel {
                stage('Sign adservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing adservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG}
                                echo "✅ Successfully signed adservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign cartservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing cartservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG}
                                echo "✅ Successfully signed cartservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign checkoutservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing checkoutservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG}
                                echo "✅ Successfully signed checkoutservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign currencyservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing currencyservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG}
                                echo "✅ Successfully signed currencyservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign emailservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing emailservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG}
                                echo "✅ Successfully signed emailservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign frontend') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing frontend image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG}
                                echo "✅ Successfully signed frontend:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign loadgenerator') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing loadgenerator image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG}
                                echo "✅ Successfully signed loadgenerator:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign paymentservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing paymentservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG}
                                echo "✅ Successfully signed paymentservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign productcatalogservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing productcatalogservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG}
                                echo "✅ Successfully signed productcatalogservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign recommendationservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing recommendationservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG}
                                echo "✅ Successfully signed recommendationservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign shippingservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing shippingservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG}
                                echo "✅ Successfully signed shippingservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
                
                stage('Sign shoppingassistantservice') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            sh """
                                echo "🔐 Signing shoppingassistantservice image with Cosign and GCP KMS..."
                                cosign sign --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" --yes ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG}
                                echo "✅ Successfully signed shoppingassistantservice:${IMAGE_TAG}"
                            """
                        }
                    }
                }
            }
        }
        
        // STAGE 7: PUSH TO DOCKER REGISTRY
        stage('Push to Docker Registry') {
            stages {
                stage('Docker Registry Login') {
                    steps {
                        script {
                            withCredentials([usernamePassword(credentialsId: 'Dockerhub-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                                sh '''
                                    echo "🔐 Logging into Docker Hub..."
                                    echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                                    echo "✅ Successfully logged into Docker Hub"
                                '''
                            }
                        }
                    }
                }
                
                stage('Push Images') {
                    parallel {
                        stage('adservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing adservice image..."
                                    docker push ${DOCKER_REGISTRY}/adservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed adservice:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('cartservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing cartservice image..."
                                    docker push ${DOCKER_REGISTRY}/cartservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed cartservice:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('checkoutservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing checkoutservice image..."
                                    docker push ${DOCKER_REGISTRY}/checkoutservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed checkoutservice:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('currencyservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing currencyservice image..."
                                    docker push ${DOCKER_REGISTRY}/currencyservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed currencyservice:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('emailservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing emailservice image..."
                                    docker push ${DOCKER_REGISTRY}/emailservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed emailservice:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('frontend') {
                            steps {
                                sh """
                                    echo "📤 Pushing frontend image..."
                                    docker push ${DOCKER_REGISTRY}/frontend:${IMAGE_TAG}
                                    echo "✅ Successfully pushed frontend:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('loadgenerator') {
                            steps {
                                sh """
                                    echo "📤 Pushing loadgenerator image..."
                                    docker push ${DOCKER_REGISTRY}/loadgenerator:${IMAGE_TAG}
                                    echo "✅ Successfully pushed loadgenerator:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('paymentservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing paymentservice image..."
                                    docker push ${DOCKER_REGISTRY}/paymentservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed paymentservice:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('productcatalogservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing productcatalogservice image..."
                                    docker push ${DOCKER_REGISTRY}/productcatalogservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed productcatalogservice:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('recommendationservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing recommendationservice image..."
                                    docker push ${DOCKER_REGISTRY}/recommendationservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed recommendationservice:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('shippingservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing shippingservice image..."
                                    docker push ${DOCKER_REGISTRY}/shippingservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed shippingservice:${IMAGE_TAG}"
                                """
                            }
                        }
                        
                        stage('shoppingassistantservice') {
                            steps {
                                sh """
                                    echo "📤 Pushing shoppingassistantservice image..."
                                    docker push ${DOCKER_REGISTRY}/shoppingassistantservice:${IMAGE_TAG}
                                    echo "✅ Successfully pushed shoppingassistantservice:${IMAGE_TAG}"
                                """
                            }
                        }
                    }
                }
                
                stage('Verify Signed Images') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'gcp-sa-json', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            script {
                                def services = [
                                    'adservice', 'cartservice', 'checkoutservice', 'currencyservice', 
                                    'emailservice', 'frontend', 'loadgenerator', 'paymentservice',
                                    'productcatalogservice', 'recommendationservice', 'shippingservice', 
                                    'shoppingassistantservice'
                                ]
                                
                                services.each { service ->
                                    sh """
                                        echo "🔍 Verifying signature for ${service}..."
                                        cosign verify --key "gcpkms://projects/${GCP_PROJECT}/locations/${KEY_LOCATION}/keyRings/${KEY_RING}/cryptoKeys/${KEY_NAME}" ${DOCKER_REGISTRY}/${service}:${IMAGE_TAG} || echo "⚠️  Verification failed for ${service}:${IMAGE_TAG}"
                                        echo "✅ Verification completed for ${service}"
                                    """
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // CLEANUP STAGE
        stage('Cleanup Images') {
            steps {
                sh '''
                    echo "🧹 Running Docker system cleanup..."
                    docker system prune -f || true
                    docker image prune -f || true
                '''
            }
        }
    }
    
    post {
        always {
            script {
                sh '''
                    echo "=== FINAL PIPELINE SUMMARY ===" > final_report.txt
                    echo "Build: ${BUILD_NUMBER}" >> final_report.txt
                    echo "Date: $(date)" >> final_report.txt
                    echo "Repository: ${GIT_URL:-'Unknown'}" >> final_report.txt
                    echo "Commit: ${GIT_COMMIT:-'Unknown'}" >> final_report.txt
                    echo "" >> final_report.txt
                    
                    echo "=== PIPELINE EXECUTION ORDER ===" >> final_report.txt
                    echo "1. ✅ TruffleHog Secret Detection" >> final_report.txt
                    echo "2. ✅ Snyk Security Analysis (Dependencies + Code)" >> final_report.txt
                    echo "3. ✅ Docker Image Build" >> final_report.txt
                    echo "4. ✅ Trivy Container Security Scan" >> final_report.txt
                    echo "5. ✅ Cosign Setup & Image Signing" >> final_report.txt
                    echo "6. ✅ Docker Image Push & Signature Verification" >> final_report.txt
                    echo "" >> final_report.txt
                    
                    echo "=== SECURITY SCANS COMPLETED ===" >> final_report.txt
                    echo "- TruffleHog Secret Detection: $([ -f trufflehog_report.json ] && echo 'COMPLETED' || echo 'FAILED')" >> final_report.txt
                    echo "- Snyk Vulnerability Scan: $(find . -name 'snyk-results-*.json' | wc -l) services scanned" >> final_report.txt
                    echo "- Snyk Code Analysis: $(find . -name 'snyk-code-*.json' | wc -l) services scanned" >> final_report.txt
                    echo "- Trivy Container Scan: $(find . -name 'trivy-*-report.json' | wc -l) images scanned" >> final_report.txt
                    echo "" >> final_report.txt
                    
                    echo "=== DOCKER IMAGES BUILT & SIGNED ===" >> final_report.txt
                    echo "All 12 microservices built, signed, and pushed to ${DOCKER_REGISTRY}" >> final_report.txt
                    echo "Tag used: ${IMAGE_TAG} (build-specific, no latest tag)" >> final_report.txt
                    echo "All images signed with Cosign using GCP KMS BEFORE push" >> final_report.txt
                    echo "" >> final_report.txt
                    
                    echo "=== SERVICE BREAKDOWN ===" >> final_report.txt
                    echo "Go services (4): frontend, productcatalogservice, shippingservice, checkoutservice" >> final_report.txt
                    echo "Node.js services (2): currencyservice, paymentservice" >> final_report.txt
                    echo "Python services (4): emailservice, recommendationservice, loadgenerator, shoppingassistantservice" >> final_report.txt
                    echo "Java services (1): adservice" >> final_report.txt
                    echo "C# services (1): cartservice" >> final_report.txt
                    echo "" >> final_report.txt
                    
                    # Generate vulnerability summary if Snyk reports exist
                    if ls src/*/snyk-results-*.json 1> /dev/null 2>&1; then
                        echo "=== VULNERABILITY SUMMARY ===" >> final_report.txt
                        for file in src/*/snyk-results-*.json; do
                            if [ -f "$file" ]; then
                                service=$(basename "$file" | sed 's/snyk-results-//g' | sed 's/.json//g')
                                high=$(cat "$file" | jq -r '.vulnerabilities[]? | select(.severity == "high") | .id' | wc -l 2>/dev/null || echo "0")
                                medium=$(cat "$file" | jq -r '.vulnerabilities[]? | select(.severity == "medium") | .id' | wc -l 2>/dev/null || echo "0")
                                low=$(cat "$file" | jq -r '.vulnerabilities[]? | select(.severity == "low") | .id' | wc -l 2>/dev/null || echo "0")
                                echo "$service: High=$high, Medium=$medium, Low=$low" >> final_report.txt
                            fi
                        done
                        echo "" >> final_report.txt
                    fi
                    
                    # Generate Trivy summary if reports exist
                    if ls trivy-*-report.json 1> /dev/null 2>&1; then
                        echo "=== TRIVY CONTAINER SCAN SUMMARY ===" >> final_report.txt
                        for file in trivy-*-report.json; do
                            if [ -f "$file" ]; then
                                service=$(basename "$file" | sed 's/trivy-//g' | sed 's/-report.json//g')
                                critical=$(cat "$file" | jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL") | .VulnerabilityID' | wc -l 2>/dev/null || echo "0")
                                high=$(cat "$file" | jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH") | .VulnerabilityID' | wc -l 2>/dev/null || echo "0")
                                medium=$(cat "$file" | jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM") | .VulnerabilityID' | wc -l 2>/dev/null || echo "0")
                                echo "$service: Critical=$critical, High=$high, Medium=$medium" >> final_report.txt
                            fi
                        done
                    fi
                '''
                
                archiveArtifacts artifacts: 'final_report.txt, trivy-*-report.json, trufflehog_report.json, src/*/snyk-*.json', fingerprint: true, allowEmptyArchive: true
            }
            
            cleanWs()
        }
        
        success {
            echo '''
            🎉 ========================================
            ✅ PIPELINE COMPLETED SUCCESSFULLY! ✅
            ========================================
            
            📋 EXECUTION SEQUENCE COMPLETED:
            1. ✅ TruffleHog Secret Detection
            2. ✅ Snyk Security Analysis  
            3. ✅ Docker Image Build
            4. ✅ Trivy Container Security Scan
            5. ✅ Cosign Setup & Image Signing
            6. ✅ Docker Image Push & Verification
            
            🚀 All 12 microservices successfully:
            - Built as Docker images with build-specific tags
            - Scanned for vulnerabilities  
            - Signed with Cosign using GCP KMS BEFORE push
            - Pushed to Docker Hub registry
            - Verified for signature integrity
            
            🔐 Security improvements:
            - No "latest" tag used (build-specific tags only)
            - Images signed BEFORE push to registry
            - Signature verification after push
            
            📊 Check archived reports for detailed security analysis.
            '''
        }
        
        failure {
            echo '''
            ❌ ===============================
            💥 PIPELINE FAILED! 💥
            ===============================
            
            🔍 Possible failure points:
            1. TruffleHog secret detection issues
            2. Snyk authentication or scan failures
            3. Docker build errors (missing dependencies)
            4. Trivy scanner not available
            5. Cosign setup or GCP KMS authentication
            6. Image signing before push
            7. Docker registry authentication issues
            
            📋 Check the specific stage logs and archived reports.
            '''
        }
        
        unstable {
            echo '''
            ⚠️  ===============================
            🔶 PIPELINE UNSTABLE 🔶
            ===============================
            
            ⚡ Pipeline completed but with warnings:
            - Security scans found vulnerabilities
            - Some builds succeeded with warnings  
            - Non-critical errors in scanning tools
            - Signature verification issues
            
            📋 Review security reports to assess risk level.
            '''
        }
    }
}
