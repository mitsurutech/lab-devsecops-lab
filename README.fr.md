# Labo de pipeline DevSecOps avec Docker Compose : Semgrep, Gitleaks, pip-audit, Trivy et une barrière de sécurité

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml)

Un labo prêt à l'emploi pour la classe, issu de la [plateforme d'apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning), où les écoles, lycées et universités donnent à chaque étudiant ses propres bases de données, conteneurs et terminal dans le navigateur. Il enseigne le DevSecOps en construisant un pipeline de sécurité autour d'une petite boutique en ligne dans laquelle des erreurs ont été laissées exprès : l'analyse statique avec Semgrep, la recherche de secrets dans les fichiers et l'historique Git avec Gitleaks, l'analyse des dépendances avec pip-audit, un scan dynamique de base de la boutique en fonctionnement, l'analyse de l'infrastructure as code avec Trivy, et une barrière de sécurité qui pose un statut de commit dans Gitea pour qu'une branche protégée refuse une fusion tant que la barrière n'est pas franchie. C'est le labo du module [DevSecOps pipelines](https://mitsurutech.co.uk/resources/university/devsecops-pipeline).

C'est un seul fichier `docker-compose`, `compose.yaml`, et il fonctionne de la même façon sur votre machine que sur la plateforme, où chaque étudiant reçoit une copie privée. **N'analysez et n'attaquez que votre propre copie.** Analyser le site ou le code de quelqu'un d'autre exige son autorisation écrite ; au Royaume-Uni, s'introduire dans un ordinateur sans autorisation est un délit au titre du Computer Misuse Act 1990.

## Ce qu'il contient

| Service | Ce que c'est |
|---|---|
| `gitea` | Gitea, un serveur Git, qui héberge `student/tuckshop` avec quatre commits créés au premier démarrage. Compte `student`, mot de passe `student`, tous deux inventés. Port 3000. |
| `shop` | La boutique de l'établissement, lancée directement depuis le dépôt : le port 8000 dans sa version d'origine, le port 8001 avec le même fichier lancé avec `--hardened`. |
| `ci` | L'exécuteur d'étapes du pipeline, Python 3.12 : `dast.py`, un petit scanner dynamique écrit pour ce labo dans l'esprit du scan de base d'OWASP ZAP, et `gate.py`, une barrière de sécurité. pip-audit y est installé depuis PyPI quand une leçon le demande. |
| `semgrep` | Semgrep 1.185.0, hors ligne, avec les règles propres au dépôt. |
| `gitleaks` | Gitleaks 8.30.1. Au démarrage, il clone le dépôt dans le volume partagé `/work`, où chaque scanner le lit. |
| `trivy` | Trivy 0.76.2, pour les mauvaises configurations du Dockerfile et du Terraform, hors ligne avec les contrôles qu'il embarque. |

Chaque image est épinglée par son digest. **Les erreurs de la boutique, son unique compte et la clé de paiement dans son historique Git (`tuck_live_...`) sont des données d'exercice prévues à cet effet**, inventées pour les exercices : la clé est justement ce que trouve la leçon sur la recherche de secrets, et rien de tout cela n'est un véritable identifiant. OWASP ZAP n'est pas dans le labo, car son image pèse plus d'un gigaoctet de Java et demande plus de mémoire qu'on n'en donne à un service de labo ; `dast.py` remplace donc son scan de base, et le dit.

## Essayer

Depuis le terminal à côté du labo, chaque outil se lance avec `docker exec` :

```bash
docker exec semgrep semgrep scan --config /work/tuckshop/.semgrep.yml --metrics=off /work/tuckshop
docker exec gitleaks gitleaks git /work/tuckshop --no-banner --redact -v
docker exec trivy trivy config -q /work/tuckshop
docker exec ci python3 dast.py http://shop:8000/ --active
docker exec ci python3 gate.py
```

La dernière commande lit les rapports JSON que les scanners ont écrits dans `/work/reports` : lancez donc d'abord les scanners avec leurs options JSON, comme le fait la leçon sur les barrières de sécurité avec un seul fichier de pipeline.

## Utilisation sur la plateforme

La plateforme donne à chaque étudiant sa propre copie d'un labo, dans le navigateur, avec un terminal à côté.

**Pour l'essayer :** ouvrez la [page des conteneurs](https://mitsurutech.co.uk/fr/container), trouvez ce labo dans **Sample labs** et appuyez sur Start. Un compte gratuit est nécessaire.

**Pour le donner en travail à une classe :**

1. Dans votre module, créez une tâche de type **Lab** et choisissez **In a GitHub repository**.
2. Indiquez `https://github.com/mitsurutech/lab-devsecops-lab` avec la branche `main`. Le fichier compose est celui par défaut, `compose.yaml`. Faites d'abord un fork du dépôt si vous voulez le modifier.
3. Publiez. La copie de chaque étudiant part du commit que vous avez publié, donc une modification ultérieure ici ne change pas un labo déjà donné.

La [page de ce labo](https://mitsurutech.co.uk/help/lab-devsecops-lab) dans le manuel d'aide et son [guide des labos en conteneur](https://mitsurutech.co.uk/fr/help/labs) expliquent le reste. La leçon de base correspondante s'appelle **DevSecOps Basics**. Pas encore de compte d'établissement ? [La première année est gratuite](https://mitsurutech.co.uk/fr/pricing) jusqu'à 50 étudiants, et [l'inscription](https://mitsurutech.co.uk/fr/signup) ne demande qu'une adresse e-mail.

## L'exécuter sur votre propre machine

Il vous faut Docker avec le plugin Compose.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Gitea répond sur <http://127.0.0.1:3000> et la boutique sur <http://127.0.0.1:8000> et <http://127.0.0.1:8001>. `local.yaml` ne publie les ports que sur `127.0.0.1`. La boutique est volontairement vulnérable, alors ne la lancez pas là où d'autres personnes peuvent y accéder. Lancez les outils avec `docker compose exec`, par exemple `docker compose exec semgrep semgrep --version`. Supprimez le tout avec `docker compose -f compose.yaml -f local.yaml down -v`.

## Ce qui ne fonctionne pas dans un labo

Sur la plateforme, un labo n'atteint qu'une liste autorisée de sites de paquets : c'est ainsi que pip-audit vient de PyPI, et rien d'autre n'est téléchargé. Semgrep ne peut pas joindre son registre de règles ; il utilise donc les règles du dépôt et celles des étudiants, et Trivy utilise ses contrôles intégrés. Gitea n'a pas de runner Actions : les étudiants lancent eux-mêmes le fichier de pipeline, comme le ferait un runner. Le dépôt et `/work` sont conservés à l'arrêt du labo ; le pip-audit de l'exécuteur d'étapes ne l'est pas.

## Vérifier le labo

`test/check.sh` démarre le labo comme le runner de la plateforme démarre chaque service (toutes les capacités retirées, `no-new-privileges`, une limite de processus, une limite de mémoire et aucun accès à internet, sauf pour l'installation depuis PyPI de l'exécuteur d'étapes), puis exécute chaque commande citée dans les leçons et vérifie ce qu'elle affiche, depuis un terminal doté des mêmes outils que celui de la plateforme. Il faut Docker, et il tourne à chaque push : c'est le badge en haut de la page.

```bash
test/check.sh
```

## Licence

Cette œuvre est sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr). Vous pouvez la partager et l'adapter pour apprendre et enseigner, à condition de créditer Mitsuru Technologies Ltd, de ne pas en faire un usage commercial et de partager ce que vous en tirez sous la même licence. Le texte complet se trouve dans le fichier `LICENSE`. Gitea, Semgrep, Gitleaks, Trivy et Python tournent sans modification depuis leurs propres images publiques, chacun sous sa propre licence.

## À propos

Réalisé par [Mitsuru Technologies](https://mitsurutech.co.uk/fr) pour la [MitsuruTech Learning Platform](https://mitsurutech.co.uk/fr/learning) : Python, Java, Go, Node, SQL et Linux dans le navigateur pour les écoles et les établissements, avec des labos en conteneur, des applications web déployées depuis GitHub et des quiz qui se corrigent tout seuls. Essayez du code sans compte dans le [playground](https://mitsurutech.co.uk/fr/playground).

D'autres labos de sécurité du même endroit : [lab-graphql-lab](https://github.com/mitsurutech/lab-graphql-lab), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea).
