pipeline {
    agent any
    
    environment {
        // Define environment variables
        DOCKER_IMAGE_NAME = 'paycare-etl'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        PYTHON_VERSION = '3.9'
        
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }
    
    stages {
        stage('1. Clone Repository') {
            steps {
                script {
                    echo "🔄 Checking repository status..."
                    try {
                        // Check if we're in an SCM context
                        def isSCMContext = binding.hasVariable('scm') && scm != null
                        
                        if (isSCMContext) {
                            echo "📥 SCM context detected - cloning repository..."
                            // Nettoyage du workspace
                            cleanWs()
                            
                            // Clone du repository
                            checkout scm
                            
                            // Affichage des informations du commit
                            sh '''
                                echo "📋 Repository Information:"
                                echo "Branch: ${GIT_BRANCH}"
                                echo "Commit: ${GIT_COMMIT}"
                                echo "Author: $(git log -1 --pretty=format:'%an <%ae>')"
                                echo "Message: $(git log -1 --pretty=format:'%s')"
                                echo "Files changed in this commit:"
                                git diff-tree --no-commit-id --name-only -r ${GIT_COMMIT} || echo "No files changed"
                            '''
                        } else {
                            echo "📁 Non-SCM context detected - using workspace files..."
                            // Vérifier que les fichiers nécessaires sont présents
                            sh '''
                                echo "📋 Workspace Information:"
                                echo "Current directory: $(pwd)"
                                echo "Files present:"
                                ls -la
                                
                                # Vérifier les fichiers essentiels
                                if [ ! -f "etl.py" ]; then
                                    echo "❌ etl.py not found in workspace"
                                    exit 1
                                fi
                                if [ ! -f "test_etl.py" ]; then
                                    echo "❌ test_etl.py not found in workspace"
                                    exit 1
                                fi
                                if [ ! -f "requirements.txt" ]; then
                                    echo "❌ requirements.txt not found in workspace"
                                    exit 1
                                fi
                                if [ ! -f "Dockerfile" ]; then
                                    echo "❌ Dockerfile not found in workspace"
                                    exit 1
                                fi
                                
                                echo "✅ All required files are present"
                            '''
                        }
                        
                        echo "✅ Repository/workspace ready"
                    } catch (Exception e) {
                        echo "❌ Failed to prepare repository: ${e.getMessage()}"
                        error("Repository preparation failed")
                    }
                }
            }
        }
        
        stage('2. Run Tests') {
            steps {
                script {
                    echo "🧪 Running unit tests..."
                    try {
                        // Installation des dépendances Python
                        sh '''
                            echo "📦 Installing Python dependencies..."
                            python3 -m pip install --upgrade pip
                            python3 -m pip install -r requirements.txt
                            echo "Dependencies installed successfully"
                        '''
                        
                        // Exécution des tests avec rapports
                        sh '''
                            echo "🔍 Running tests with coverage..."
                            python3 -m pytest test_etl.py \
                                --verbose \
                                --junitxml=test-results.xml \
                                --html=test-report.html \
                                --self-contained-html \
                                --cov=etl \
                                --cov-report=xml:coverage.xml \
                                --cov-report=html:htmlcov \
                                --cov-report=term-missing
                        '''
                        
                        echo "✅ All tests passed successfully"
                    } catch (Exception e) {
                        echo "❌ Tests failed: ${e.getMessage()}"
                        // Publier les résultats même en cas d'échec
                        publishTestResults testResultsPattern: 'test-results.xml', allowEmptyResults: true
                        error("Tests failed")
                    }
                }
            }
            post {
                always {
                    // Publication des résultats de tests
                    publishTestResults testResultsPattern: 'test-results.xml', allowEmptyResults: true
                    
                    // Publication du rapport HTML
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'test-report.html',
                        reportName: 'Test Report'
                    ])
                    
                    // Publication de la couverture de code
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        
        stage('3. Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image..."
                    try {
                        // Construction de l'image Docker
                        sh '''
                            echo "Building Docker image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                            docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                            docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest
                            echo "Docker image built successfully"
                        '''
                        
                        // Inspection de l'image
                        sh '''
                            echo "📋 Docker Image Information:"
                            docker images ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                            echo "Image size: $(docker inspect ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} --format='{{.Size}}' | numfmt --to=iec-i --suffix=B)"
                        '''
                        
                        echo "✅ Docker image built successfully"
                    } catch (Exception e) {
                        echo "❌ Docker build failed: ${e.getMessage()}"
                        error("Docker build failed")
                    }
                }
            }
        }
        
        stage('4. Run Container') {
            steps {
                script {
                    echo "🚀 Running containerized ETL pipeline..."
                    try {
                        // Préparation des répertoires de sortie
                        sh '''
                            echo "📁 Preparing output directories..."
                            mkdir -p output
                            rm -f output/output_data.csv
                        '''
                        
                        // Exécution du conteneur ETL
                        sh '''
                            echo "🔄 Running ETL container..."
                            docker run --rm \
                                -v $(pwd)/data:/app/data \
                                -v $(pwd)/output:/app/output \
                                ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                                python etl.py
                        '''
                        
                        // Vérification des résultats
                        sh '''
                            echo "📊 Verifying ETL results..."
                            if [ -f "output/output_data.csv" ]; then
                                echo "✅ Output file created successfully"
                                echo "Output file size: $(stat -c%s output/output_data.csv) bytes"
                                echo "Number of rows: $(tail -n +2 output/output_data.csv | wc -l)"
                                echo "First 5 lines of output:"
                                head -n 5 output/output_data.csv
                            else
                                echo "❌ Output file not found"
                                exit 1
                            fi
                        '''
                        
                        echo "✅ ETL pipeline executed successfully"
                    } catch (Exception e) {
                        echo "❌ Container execution failed: ${e.getMessage()}"
                        error("Container execution failed")
                    }
                }
            }
            post {
                always {
                    // Archiver les fichiers de sortie
                    archiveArtifacts artifacts: 'output/*.csv', allowEmptyArchive: true, fingerprint: true
                }
            }
        }
        
        stage('5. Publish Test Results') {
            steps {
                script {
                    echo "📊 Publishing final results and reports..."
                    try {
                        // Génération d'un rapport de synthèse
                        sh '''
                            echo "📈 Generating pipeline summary..."
                            cat > pipeline-summary.txt << EOF
PAYCARE ETL PIPELINE - BUILD SUMMARY
====================================
Build Number: ${BUILD_NUMBER}
Git Branch: ${GIT_BRANCH}
Git Commit: ${GIT_COMMIT}
Build Date: $(date)
Build Duration: ${BUILD_DURATION:-"In Progress"}

COMPONENTS TESTED:
- Extract Data Function: ✅ Passed
- Transform Data Function: ✅ Passed  
- Load Data Function: ✅ Passed
- End-to-End ETL Process: ✅ Passed

DOCKER IMAGE:
- Image Name: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
- Image Status: ✅ Built Successfully

ETL EXECUTION:
- Input File: data/input_data.csv
- Output File: output/output_data.csv
- Status: ✅ Completed Successfully

ARTIFACTS:
- Test Results: test-results.xml
- Test Report: test-report.html
- Coverage Report: htmlcov/index.html
- Output Data: output/output_data.csv
EOF
                            cat pipeline-summary.txt
                        '''
                        
                        // Nettoyage des images Docker anciennes (garder les 5 dernières)
                        sh '''
                            echo "🧹 Cleaning up old Docker images..."
                            docker images ${DOCKER_IMAGE_NAME} --format "table {{.Tag}}\\t{{.CreatedAt}}" | grep -v TAG | sort -k2 -r | tail -n +6 | awk '{print $1}' | xargs -r docker rmi ${DOCKER_IMAGE_NAME}: || true
                        '''
                        
                        echo "✅ Pipeline completed successfully"
                    } catch (Exception e) {
                        echo "⚠️ Warning in final stage: ${e.getMessage()}"
                        // Ne pas faire échouer le build pour les erreurs de nettoyage
                    }
                }
            }
            post {
                always {
                    // Archiver le rapport de synthèse
                    archiveArtifacts artifacts: 'pipeline-summary.txt', allowEmptyArchive: true
                    
                    // Publication des métriques finales
                    echo "📊 Final Pipeline Metrics:"
                    echo "Build Status: ${currentBuild.currentResult}"
                    echo "Build Duration: ${currentBuild.durationString}"
                }
                success {
                    echo "🎉 Pipeline completed successfully!"
                    // Notification de succès (email, Slack, etc.)
                    // emailext (
                    //     subject: "✅ Paycare ETL Pipeline - Build #${BUILD_NUMBER} SUCCESS",
                    //     body: readFile('pipeline-summary.txt'),
                    //     to: "${env.CHANGE_AUTHOR_EMAIL ?: 'team@paycare.com'}"
                    // )
                }
                failure {
                    echo "💥 Pipeline failed!"
                    // Notification d'échec
                    // emailext (
                    //     subject: "❌ Paycare ETL Pipeline - Build #${BUILD_NUMBER} FAILED",
                    //     body: "The ETL pipeline has failed. Please check the Jenkins logs for details.\n\nBuild URL: ${BUILD_URL}",
                    //     to: "${env.CHANGE_AUTHOR_EMAIL ?: 'team@paycare.com'}"
                    // )
                }
                unstable {
                    echo "⚠️ Pipeline is unstable!"
                }
            }
        }
    }
    
    post {
        always {
            // Nettoyage final du workspace
            script {
                try {
                    // Nettoyage des conteneurs en cours d'exécution
                    sh 'docker ps -q --filter ancestor=${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} | xargs -r docker stop || true'
                    sh 'docker ps -aq --filter ancestor=${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} | xargs -r docker rm || true'
                } catch (Exception e) {
                    echo "Warning: Failed to cleanup containers: ${e.getMessage()}"
                }
            }
        }
        cleanup {
            // Nettoyage final du workspace
            cleanWs()
        }
    }
} 