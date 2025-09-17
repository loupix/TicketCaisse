# TicketCaisse

Application Flutter pour scanner des tickets de caisse, valider les lignes, catégoriser les achats et les enregistrer pour le suivi financier.

## Fonctionnalités

- OCR multi‑moteurs: Google ML Kit, Tesseract, (optionnel) TensorFlow Lite
- Parsing des tickets: totaux, TVA, sous‑total, remises, devise, date
- Validation: édition des lignes (nom, quantité, prix) et affectation de catégories
- Catégorisation: suggestions automatiques, liste de catégories éditables dans le code
- Persistance locale: sauvegarde des tickets au format JSON dans le stockage applicatif
- Liste des tickets: consultation, suppression, détails
- Export: CSV et PDF d’un ticket depuis l’écran de détails

## Démarrage

Prérequis:
- Flutter SDK >= 3.9.2
- Android/iOS/Desktop configuré pour le dev Flutter

Installation:
1. Installer les dépendances
   - `flutter pub get`
2. Lancer l’application
   - `flutter run`

Permissions:
- Caméra et accès aux photos (sélection et prise de vue)

## Utilisation

1. Depuis l’accueil, choisir un moteur OCR puis sélectionner une image (Galerie) ou prendre une photo (Caméra)
2. Vérifier les résultats; option Voir détails pour un affichage complet
3. Bouton Valider pour corriger les lignes et affecter des catégories
4. Enregistrer le ticket, lister les tickets via l’icône Dossier dans l’appbar
5. Exporter un ticket en CSV/PDF depuis l’écran de détails (menu en haut à droite)

## Architecture rapide

- `lib/services/ocr_manager.dart`: orchestration des moteurs OCR
- `lib/services/ticket_parser.dart`: parsing du texte OCR → `TicketData`
- `lib/providers/ocr_provider.dart`: état OCR (Riverpod)
- `lib/services/ticket_repository.dart`: stockage JSON local
- `lib/providers/saved_tickets_provider.dart`: état des tickets sauvegardés
- `lib/services/export_service.dart`: export CSV/PDF
- `lib/services/category_suggestion_service.dart`: suggestions de catégories
- `lib/screens/*`: UI (accueil, détails, validation, liste)
- `lib/models/*`: modèles (`TicketData`, `TicketItem`, `CategoryDefinitions`)

## Roadmap

La feuille de route se trouve dans `docs/ROADMAP.md`.

## Licence

Projet privé (usage personnel/équipe). Adapter selon vos besoins.
