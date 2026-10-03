# Servicold Peru — Clon estático (demo)

Clon estático de la página de inicio de [servicoldperu.com](https://servicoldperu.com/) para fines de presentación.

Sitio de demostración: **https://arnix64.github.io/servicold/**

## Contenido

- `index.html` — página clonada con todas las rutas reescritas a rutas relativas locales.
- `assets/` — CSS, JavaScript, imágenes y fuentes descargados del sitio original.
- `.nojekyll` — evita el procesamiento de GitHub Pages (Jekyll).
- `source-original.html` — HTML original de respaldo.
- `mirror.ps1` — script de PowerShell usado para generar el espejo local.

## Ver en local

Abre `index.html` en el navegador, o sirve la carpeta:

```powershell
python -m http.server 8080
# luego abre http://localhost:8080
```

## Aviso

- Es un espejo con fines de demostración/portafolio. Todos los derechos del diseño y contenido pertenecen a Servicold Peru.
- El formulario de contacto está deshabilitado; algunas funciones dinámicas (WhatsApp/estadísticas) apuntan al servidor original y no operan en esta demo.
