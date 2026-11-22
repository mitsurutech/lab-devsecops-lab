# Laboratorio de pipeline DevSecOps con Docker Compose: Semgrep, Gitleaks, pip-audit, Trivy y una puerta de seguridad

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml)

Un laboratorio listo para clase, de la [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning), donde colegios, institutos y universidades dan a cada estudiante sus propias bases de datos, contenedores y terminal en el navegador. Enseña DevSecOps construyendo un pipeline de seguridad alrededor de una pequeña tienda web que tiene errores dejados a propósito: análisis estático con Semgrep, búsqueda de secretos en los archivos y en el historial de Git con Gitleaks, análisis de dependencias con pip-audit, un escaneo dinámico básico de la tienda en marcha, análisis de infraestructura como código con Trivy, y una puerta de seguridad que pone un estado de commit en Gitea para que una rama protegida rechace una fusión hasta que la puerta se supere. Es el laboratorio del módulo [DevSecOps pipelines](https://mitsurutech.co.uk/resources/university/devsecops-pipeline).

Es un solo archivo `docker-compose`, `compose.yaml`, y funciona igual en tu ordenador que en la plataforma, donde cada estudiante recibe una copia privada. **Escanea y ataca solo tu propia copia.** Escanear la web o el código de otra persona exige su permiso por escrito; en el Reino Unido, entrar en un ordenador sin permiso es un delito según la Computer Misuse Act 1990.

## Qué contiene

| Servicio | Qué es |
|---|---|
| `gitea` | Gitea, un servidor Git, con `student/tuckshop` y cuatro commits creados en el primer arranque. Cuenta `student`, contraseña `student`, ambas inventadas. Puerto 3000. |
| `shop` | La tienda del centro, ejecutada directamente desde el repositorio: el puerto 8000 tal como se escribió al principio, el puerto 8001 con el mismo archivo ejecutado con `--hardened`. |
| `ci` | El ejecutor de pasos del pipeline, Python 3.12: `dast.py`, un pequeño escáner dinámico escrito para este laboratorio al estilo del escaneo básico de OWASP ZAP, y `gate.py`, una puerta de seguridad. pip-audit se instala aquí desde PyPI cuando una lección lo pide. |
| `semgrep` | Semgrep 1.185.0, sin conexión, con las reglas propias del repositorio. |
| `gitleaks` | Gitleaks 8.30.1. Al arrancar clona el repositorio en el volumen compartido `/work`, donde lo lee cada escáner. |
| `trivy` | Trivy 0.76.2, para configuraciones incorrectas en el Dockerfile y en Terraform, sin conexión con las comprobaciones que trae incorporadas. |

Cada imagen está fijada por su digest. **Los errores de la tienda, su única cuenta y la clave de pagos de su historial de Git (`tuck_live_...`) son datos de ejercicio preparados a propósito**, inventados para los ejercicios: la clave es justo lo que encuentra la lección de búsqueda de secretos, y nada de ello es una credencial real. OWASP ZAP no está en el laboratorio porque su imagen ocupa más de un gigabyte de Java y necesita más memoria de la que se da a un servicio del laboratorio, así que `dast.py` sustituye a su escaneo básico, y lo dice.

## Pruébalo

Desde la terminal junto al laboratorio, cada herramienta se ejecuta con `docker exec`:

```bash
docker exec semgrep semgrep scan --config /work/tuckshop/.semgrep.yml --metrics=off /work/tuckshop
docker exec gitleaks gitleaks git /work/tuckshop --no-banner --redact -v
docker exec trivy trivy config -q /work/tuckshop
docker exec ci python3 dast.py http://shop:8000/ --active
docker exec ci python3 gate.py
```

El último lee los informes JSON que los escáneres escribieron en `/work/reports`, así que ejecuta antes los escáneres con sus opciones JSON, como hace la lección de puertas de seguridad con un solo archivo de pipeline.

## Uso en la plataforma

La plataforma da a cada estudiante su propia copia de un laboratorio, en el navegador, con una terminal al lado.

**Para probarlo:** abre la [página de contenedores](https://mitsurutech.co.uk/es/container), busca este laboratorio en **Sample labs** y pulsa Start. Necesitas una cuenta gratuita.

**Para ponerlo como tarea a una clase:**

1. En tu módulo, crea una tarea de tipo **Lab** y elige **In a GitHub repository**.
2. Indica `https://github.com/mitsurutech/lab-devsecops-lab` con la rama `main`. El archivo compose es el predeterminado, `compose.yaml`. Haz antes un fork del repositorio si quieres cambiarlo.
3. Publica. La copia de cada estudiante parte del commit que publicaste, así que un cambio posterior aquí no altera un laboratorio ya asignado.

La [página de este laboratorio](https://mitsurutech.co.uk/help/lab-devsecops-lab) en el manual de ayuda y su [guía de laboratorios de contenedores](https://mitsurutech.co.uk/es/help/labs) explican el resto. La lección básica que lo acompaña es **DevSecOps Basics**. ¿Aún no tienes cuenta de centro? [El primer año es gratis](https://mitsurutech.co.uk/es/pricing) para hasta 50 estudiantes, y para [registrarte](https://mitsurutech.co.uk/es/signup) basta un correo electrónico.

## Ejecutarlo en tu propio ordenador

Necesitas Docker con el plugin Compose.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Gitea responde en <http://127.0.0.1:3000> y la tienda en <http://127.0.0.1:8000> y <http://127.0.0.1:8001>. `local.yaml` solo publica los puertos en `127.0.0.1`. La tienda es insegura a propósito, así que no la ejecutes donde otras personas puedan llegar a ella. Ejecuta las herramientas con `docker compose exec`, por ejemplo `docker compose exec semgrep semgrep --version`. Elimínalo todo con `docker compose -f compose.yaml -f local.yaml down -v`.

## Qué no funciona en un laboratorio

En la plataforma, un laboratorio solo llega a una lista permitida de sitios de paquetes: pip-audit viene de PyPI por esa vía, y no se descarga nada más. Semgrep no puede llegar a su registro de reglas, así que usa las reglas del repositorio y las de los estudiantes, y Trivy usa sus comprobaciones incorporadas. Gitea no tiene runner de Actions, así que los estudiantes ejecutan ellos mismos el archivo de pipeline, como haría un runner. El repositorio y `/work` se conservan al parar el laboratorio; el pip-audit del ejecutor de pasos no.

## Comprobar el laboratorio

`test/check.sh` arranca el laboratorio como el runner de la plataforma arranca cada servicio (todas las capacidades eliminadas, `no-new-privileges`, un límite de procesos, un límite de memoria y sin salida a internet salvo para la instalación desde PyPI del ejecutor de pasos) y luego ejecuta cada comando que citan las lecciones y comprueba lo que imprime, desde una terminal con las herramientas que tiene la de la plataforma. Necesita Docker y se ejecuta en cada push: es la insignia de arriba.

```bash
test/check.sh
```

## Licencia

Esta obra está bajo la licencia [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es). Puedes compartirla y adaptarla para aprender y enseñar, siempre que cites a Mitsuru Technologies Ltd, no la uses con fines comerciales y compartas lo que crees a partir de ella con la misma licencia. El texto completo está en el archivo `LICENSE`. Gitea, Semgrep, Gitleaks, Trivy y Python se ejecutan sin cambios desde sus propias imágenes públicas, cada uno con su propia licencia.

## Acerca de

Creado por [Mitsuru Technologies](https://mitsurutech.co.uk/es) para la [MitsuruTech Learning Platform](https://mitsurutech.co.uk/es/learning): Python, Java, Go, Node, SQL y Linux en el navegador para colegios, institutos y centros de formación, con laboratorios de contenedores, aplicaciones web desplegadas desde GitHub y cuestionarios que se corrigen solos. Prueba código sin cuenta en el [playground](https://mitsurutech.co.uk/es/playground).

Más laboratorios de seguridad del mismo sitio: [lab-graphql-lab](https://github.com/mitsurutech/lab-graphql-lab), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea).
