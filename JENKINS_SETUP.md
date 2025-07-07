# Guide de Configuration Jenkins Pipeline - Paycare ETL

## 📋 Vue d'ensemble

Ce pipeline Jenkins automatise entièrement le processus ETL (Extract, Transform, Load) de Paycare avec les étapes suivantes :

1. **Clone Repository** - Récupération du code source
2. **Run Tests** - Exécution des tests unitaires avec couverture
3. **Build Docker Image** - Construction de l'image conteneurisée
4. **Run Container** - Exécution du pipeline ETL
5. **Publish Test Results** - Publication des rapports et artefacts

## 🚀 Configuration Initiale

### Prérequis Jenkins

Assurez-vous que votre instance Jenkins dispose de :

- **Jenkins 2.401+** avec Pipeline plugin
- **Docker** installé sur l'agent Jenkins
- **Python 3.9+** disponible
- **Git** configuré

### Plugins Jenkins Requis

Installez ces plugins depuis **Manage Jenkins > Manage Plugins** :

```bash
- Pipeline
- Docker Pipeline
- HTML Publisher
- JUnit
- Git
- Workspace Cleanup
- Build Timeout
- Timestamper
```

### Configuration des Credentials

Dans **Manage Jenkins > Manage Credentials**, créez :

1. **docker-registry-credentials** (optionnel)
   - Type: Username with password
   - ID: `docker-registry-credentials`
   - Pour push vers un registre Docker

2. **git-credentials** (si dépôt privé)
   - Type: Username with password ou SSH Username with private key
   - ID: `git-credentials`

## 🔧 Configuration du Job Jenkins

### Création du Pipeline Job

1. **New Item** → **Pipeline** → Nommez votre job (ex: `paycare-etl-pipeline`)

2. **Configuration du job** :
   ```groovy
   Pipeline script from SCM:
   - SCM: Git
   - Repository URL: [votre-repo-url]
   - Credentials: [git-credentials si nécessaire]
   - Branch: */main
   - Script Path: Jenkinsfile
   ```

3. **Build Triggers** (optionnel) :
   - ☑️ Poll SCM: `H/5 * * * *` (vérifie toutes les 5 minutes)
   - ☑️ GitHub hook trigger (si GitHub)

### Variables d'Environnement

Modifiez les variables dans le `Jenkinsfile` selon vos besoins :

```groovy
environment {
    DOCKER_IMAGE_NAME = 'paycare-etl'           // Nom de votre image
    DOCKER_REGISTRY = 'your-registry.com'       // Votre registre Docker
    PYTHON_VERSION = '3.9'                      // Version Python
}
```

## 📊 Rapports et Artefacts Générés

Le pipeline génère automatiquement :

### 📈 Rapports de Tests
- **Test Results** : Résultats JUnit XML
- **Test Report** : Rapport HTML détaillé
- **Coverage Report** : Couverture de code HTML

### 📦 Artefacts
- **output_data.csv** : Données transformées par l'ETL
- **pipeline-summary.txt** : Résumé du build
- **Docker Image** : Image conteneurisée taguée

### 📍 Localisation des Rapports

Dans l'interface Jenkins du build :
- **Test Results** → Onglet dédié
- **Test Report** → Lien dans la sidebar
- **Coverage Report** → Lien dans la sidebar
- **Artifacts** → Section "Build Artifacts"

## 🔍 Structure du Pipeline

### Stage 1: Clone Repository
```bash
✅ Nettoie le workspace
✅ Clone le repository
✅ Affiche les informations du commit
```

### Stage 2: Run Tests
```bash
✅ Installe les dépendances Python
✅ Exécute pytest avec couverture
✅ Génère les rapports XML/HTML
✅ Publie les résultats dans Jenkins
```

### Stage 3: Build Docker Image
```bash
✅ Construit l'image Docker
✅ Tagge avec le numéro de build
✅ Affiche les informations de l'image
```

### Stage 4: Run Container
```bash
✅ Prépare les répertoires de sortie
✅ Exécute le conteneur ETL
✅ Monte les volumes data/ et output/
✅ Vérifie les résultats
✅ Archive les artefacts
```

### Stage 5: Publish Test Results
```bash
✅ Génère un rapport de synthèse
✅ Nettoie les anciennes images Docker
✅ Archive tous les artefacts
✅ Envoie les notifications (optionnel)
```

## 🚨 Gestion des Erreurs

### Échecs Courants et Solutions

**1. Échec des tests**
```bash
Solution: Vérifiez les logs de test dans Jenkins
Action: Corrigez les tests défaillants et recommitez
```

**2. Échec de build Docker**
```bash
Solution: Vérifiez que Docker est disponible sur l'agent
Action: Testez manuellement: docker build -t test .
```

**3. Échec d'exécution du conteneur**
```bash
Solution: Vérifiez les permissions des volumes montés
Action: Assurez-vous que data/ contient input_data.csv
```

**4. Problèmes de credentials**
```bash
Solution: Vérifiez la configuration des credentials Jenkins
Action: Testez l'accès au repository/registre manuellement
```

## 📧 Notifications (Optionnel)

Pour activer les notifications email, décommentez dans le `Jenkinsfile` :

```groovy
// Dans les sections success/failure
emailext (
    subject: "✅ Paycare ETL Pipeline - Build #${BUILD_NUMBER} SUCCESS",
    body: readFile('pipeline-summary.txt'),
    to: "team@paycare.com"
)
```

Configuration requise :
1. **Manage Jenkins > Configure System**
2. **E-mail Notification** → Configurez SMTP
3. **Extended E-mail Notification** → Configurez les templates

## 🔄 Maintenance

### Nettoyage Automatique

Le pipeline inclut un nettoyage automatique :
- **Workspace** : Nettoyé après chaque build
- **Docker Images** : Garde les 5 dernières versions
- **Build History** : Garde les 10 derniers builds

### Monitoring

Surveillez ces métriques dans Jenkins :
- **Build Success Rate** : Devrait être > 95%
- **Build Duration** : Devrait être < 10 minutes
- **Test Coverage** : Devrait être > 80%

## 🚀 Utilisation Avancée

### Exécution Manuelle avec Paramètres

Pour paramétrer le pipeline, ajoutez au début du `Jenkinsfile` :

```groovy
parameters {
    choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
    booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip test execution')
    string(name: 'DOCKER_TAG', defaultValue: 'latest', description: 'Docker image tag')
}
```

### Déploiement Multi-Environnements

Ajoutez des stages conditionnels :

```groovy
stage('Deploy to Staging') {
    when { 
        branch 'develop' 
    }
    steps {
        // Logique de déploiement staging
    }
}
```

## 🛠️ Dépannage

### Debug Mode

Pour activer plus de logs, ajoutez dans le `Jenkinsfile` :

```groovy
options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timeout(time: 30, unit: 'MINUTES')
    timestamps()
    ansiColor('xterm')  // Ajouter cette ligne
}
```

### Test Local du Pipeline

Testez les composants individuellement :

```bash
# Test des tests unitaires
python -m pytest test_etl.py -v

# Test du build Docker
docker build -t paycare-etl-test .

# Test d'exécution
docker run --rm -v $(pwd)/data:/app/data -v $(pwd)/output:/app/output paycare-etl-test
```

## 📞 Support

En cas de problème :
1. Consultez les logs Jenkins détaillés
2. Vérifiez la configuration des agents
3. Testez les composants individuellement
4. Contactez l'équipe DevOps

---

**Version du Guide** : 1.0  
**Dernière Mise à Jour** : $(date)  
**Auteur** : Équipe DevOps Paycare 