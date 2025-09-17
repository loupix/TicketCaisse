## Roadmap TicketCaisse

### Phase 1 – Socle (fait/en cours)
- OCR multi‑moteurs (ML Kit, Tesseract, TFLite optionnel)
- Parsing robuste (totaux, TVA, sous‑total, remises, devise, date)
- Export CSV / PDF d’un ticket
- Persistance locale (JSON)
- Liste des tickets (consultation, suppression)
- Validation des tickets (édition de lignes, catégories) avec suggestions

### Phase 2 – Expérience et fiabilité
- Sauvegarde automatique après validation
- Edition des catégories côté utilisateur (CRUD catégories)
- Historique de versions d’un ticket (avant/après validation)
- Partage natif des fichiers exportés
- Ouverture des fichiers exportés depuis l’app
- Amélioration OCR: pré‑traitements image (rotation, contraste, crop)

### Phase 3 – Analytique
- Tableau de bord mensuel: dépenses par catégorie
- Graphiques (barres/anneau) par mois et cumul année
- Filtres: magasin, période, moteur OCR
- Export global mensuel (CSV/PDF)

### Phase 4 – Performances et qualité
- Cache des tickets, pagination sur la liste
- Tests unitaires pour parser et suggestion de catégories
- Tests widget pour écrans clés
- CI simple (format, analyse, tests)

### Phase 5 – Extensions (idées)
- Synchronisation cloud (ex: Drive, Dropbox) optionnelle
- Multi‑utilisateurs / profils
- Reconnaissance produits récurrents (apprentissage des corrections)
- Import par scan de PDF

