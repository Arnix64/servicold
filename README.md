# Servicold Perú — Sitio estático (demo)

Sitio de presentación de **Servicold Perú**, especialistas en aire acondicionado y refrigeración en Lima.

Demo: **https://arnix64.github.io/servicold/**

## Contenido

- `index.html` — página con rutas relativas locales y SEO (metadatos, Open Graph).
- `custom.css` — capa de diseño moderno (tipografía, botones, tarjetas, formulario).
- `custom.js` — WhatsApp, navegación con anclas y envío del formulario (Formspree).
- `assets/` — CSS, JS, imágenes y fuentes optimizadas (sin formatos de fuente obsoletos).
- `assets/img/` — logo transparente (`servicold-logo.png`) y fotos de trabajos (`proyecto-1..6.jpg`).
- `robots.txt` y `sitemap.xml` — para buscadores.
- `.nojekyll` — evita el procesamiento de GitHub Pages (Jekyll).
- `source-original.html` — HTML original de respaldo.
- `mirror.ps1` — script usado para generar el espejo local.

## Ver en local

Abre `index.html` en el navegador, o sirve la carpeta:

```powershell
python -m http.server 8080
# luego abre http://localhost:8080
```

## Configurar el formulario

El formulario usa **Formspree**. En `custom.js`, reemplaza:

```js
var FORMSPREE_ENDPOINT = "https://formspree.io/f/TU_ID_FORMSPREE";
```

por tu endpoint real (por ejemplo `https://formspree.io/f/abcdwxyz`). Mientras no lo
cambies, el formulario mostrará un aviso y no enviará datos.

## Aviso

- Proyecto con fines de demostración/portafolio. El diseño y el contenido pertenecen a Servicold Perú.
- El botón de WhatsApp abre el chat con el número configurado; el contador de clics del sitio original no aplica en esta demo.
