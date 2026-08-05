# 🪶 flutter_quill_delta_from_html_robust

Un **fork renforcé, prêt pour la production** de [`flutter_quill_delta_from_html`](https://github.com/CatHood0/flutter_quill_delta_from_html) pour l'écosystème [`flutter_quill`](https://pub.dev/packages/flutter_quill).

Un package **Dart** qui convertit du contenu **HTML** en format Quill **Delta**, utilisé par le package [Quill Js](https://quilljs.com/).

**Ce package** prend en charge la conversion d'un large éventail de balises et attributs **HTML** en opérations **Delta** correspondantes, garantissant que votre contenu **HTML** est fidèlement représenté dans l'**éditeur Quill**.

> **⚠️ Changement majeur** : le paramètre optionnel `attributes` de `Delta.insert` / `Delta.retain` / `Operation.insert` / `Operation.retain` devient **nommé**. Voir le [README dart_quill_delta_robust](https://github.com/Sebastien-VZN/dart_quill_delta_robust).

## Pourquoi ce fork ?

Ce fork fait partie de la famille **robust**, qui partage la même rigueur sur tous les projets :

- **API durcie** : dépend de [`dart_quill_delta_robust`](https://github.com/Sebastien-VZN/dart_quill_delta_robust) qui utilise une signature explicite `attributes:` **nommée**.
- **Analyse stricte** : imposée via [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) avec personnalisation Axomind (`strict-casts`, `strict-inference`, `strict-raw-types`).
- **Corrections** : `continue` labelisé dans les boucles de blocs personnalisés (corrige la double insertion), `pullquote` retourne les attributs au lieu d'une liste vide, `Operation.insert` nommé pour les images.
- **Identité du fork** : repository, homepage et issue tracker pointent vers ce fork ; `publish_to: none`.

## Balises prises en charge

```html
    <!--Formatage du texte-->
        <b>, <strong>: Texte en gras 
        <i>, <em>: Texte en italique
        <u>, <ins>: Texte souligné
        <s>, <del>: Texte barré
        <sup>: Exposant
        <sub>: Indice

    <!--Titres-->
        <h1> à <h6>: Titres de différents niveaux

    <!--Listes et listes imbriquées-->
        <ul>: Listes non ordonnées
        <ol>: Listes ordonnées
        <li>: Éléments de liste
        <li data-checked="true">: Checklists 
        <input type="checkbox">: Alternative aux checklists

    <!--Liens-->
        <a>: Hyperliens avec prise en charge de l'attribut href

    <!--Images-->
        <img>: Images avec prise en charge de src, align et styles

    <!--div-->
        <div>: Conteneurs HTML
        
    <!--Tableaux-->
        <table>: Balise HTML pour tableaux (prise en charge basique) 
        
    <!--Vidéos -->
        <video>: Vidéos avec prise en charge de src

    <!--Citations-->
        <blockquote>: Citations en bloc

    <!--Blocs de code-->
        <pre>, <code>: Blocs de code

    <!--Alignement du texte, alignement inline et direction-->
        <p style="text-align:left|center|right|justify">: Alignement par style
        <p align="left|center|right|justify">: Alignement par paragraphe
        <p dir="rtl">: Direction du paragraphe 

    <!--Attributs de texte-->
        <p style="padding: 10px;line-height: 1.0px;font-size: 12px;font-family: Times New Roman;color:#ffffff">: Attributs inline
    
    <!--Blocs personnalisés-->
        <pullquote data-author="john">: HTML personnalisé
```

## Démarrage

Ajoutez la dépendance à votre `pubspec.yaml` :

```yaml
dependencies:
  flutter_quill_delta_from_html:
    git:
      url: https://github.com/Sebastien-VZN/flutter_quill_delta_from_html_robust.git
```

Puis lancez `flutter pub get` et importez le package :

```dart
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

void main() {
  final htmlContent = '<p style="line-height: 2.0">Hello, <b>world</b>!</p>';
  final delta = HtmlToDelta().convert(htmlContent, transformTableAsEmbed: false);
/*
   { "insert": "hello, " },
   { "insert": "world", "attributes": {"bold": true} },
   { "insert": "!" },
   { "insert": "\n", { 'line-height': 2.0 } }
*/
}
```

Pour les fonctionnalités avancées (`CustomHtmlPart`, `HtmlOperations`), voir la version anglaise.

---

[English](./README.md)
