# Kôji - Devis de Rénovation

Application Flutter pour la création de devis de rénovation immobilière.

## Configuration

### Variables d'environnement

L'application utilise `dart-define` pour la configuration sécurisée de Supabase :

```bash
# Développement (avec clé par défaut)
flutter run

# Production (avec votre clé Supabase)
flutter run --dart-define=SUPABASE_ANON_KEY=votre_clé_anon_supabase
```

### Configuration Supabase

1. Créez un projet sur [Supabase](https://supabase.com)
2. Obtenez votre clé anon depuis les paramètres du projet
3. Utilisez la commande avec `--dart-define` pour spécifier la clé

## Développement

### Prérequis

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0

### Installation

```bash
flutter pub get
flutter run
```

## Fonctionnalités

- Création de profils d'entreprise
- Estimation de devis par pièces
- Calcul automatique des ratios MO/Matériaux
- Export PDF des devis
