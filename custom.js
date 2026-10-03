/* ==========================================================================
   Servicold Perú — custom.js
   Mejoras funcionales: contacto por WhatsApp, navegación, formulario
   (Formspree) y pequeños detalles de presentación.
   ========================================================================== */

(function () {
  "use strict";

  /* -------------------- Configuración -------------------- */
  var WHATSAPP_NUMBER = "51994324387"; // número con código de país, sin +
  var WHATSAPP_MESSAGE =
    "Hola Servicold, me gustaría solicitar una cotización de aire acondicionado / refrigeración.";
  var PHONE_DISPLAY = "994 324 387";
  var PHONE_LINK = "tel:+51994324387";
  var EMAIL = "ventas@servicoldperu.com";

  /* Endpoint de Formspree. Reemplaza TU_ID_FORMSPREE por tu ID real:
     https://formspree.io/f/xxxxxxxx  */
  var FORMSPREE_ENDPOINT = "https://formspree.io/f/TU_ID_FORMSPREE";

  var WA_URL =
    "https://wa.me/" + WHATSAPP_NUMBER + "?text=" + encodeURIComponent(WHATSAPP_MESSAGE);

  /* -------------------- Asignar anclas a secciones -------------------- */
  var SECTIONS = {
    "39288382": "nosotros",
    "3dd46ae7": "servicios",
    "5eef1697": "porque",
    "a556264": "proyectos",
    "62a6235e": "cobertura",
    "87d4da9": "contacto",
    "31803545": "cta"
  };

  function assignSectionIds() {
    Object.keys(SECTIONS).forEach(function (dataId) {
      var el = document.querySelector('.elementor-element-' + dataId);
      if (el && !el.id) {
        el.id = SECTIONS[dataId];
      }
    });
  }

  /* -------------------- Tarjetas modernas -------------------- */
  var CARD_IDS = [
    "3f140f6c", "679ac38c", "23efbc9e", "153d9923", "3cef2abd", "3d693bc6", // servicios
    "3b0094f2", "594e6148", "5802458f", "228a2e6b",                         // proyectos
    "221f5aed", "5204e60", "3dca7b28",                                      // por qué elegirnos
    "3b89fd07", "74dbe781"                                                  // nosotros
  ];

  function markCards() {
    CARD_IDS.forEach(function (id) {
      var el = document.querySelector(".elementor-element-" + id);
      if (el) { el.classList.add("svc-card"); }
    });
  }

  /* -------------------- WhatsApp -------------------- */
  var WA_TEXT = /escr[ií]benos|cont[aá]ctanos|solicitar presupuesto/i;

  function wireWhatsApp() {
    document.querySelectorAll("a.elementor-button, a.elementor-icon").forEach(function (a) {
      var text = (a.textContent || "").trim();
      if (WA_TEXT.test(text)) {
        a.setAttribute("href", WA_URL);
        a.setAttribute("target", "_blank");
        a.setAttribute("rel", "noopener");
      } else if (/^contacto$/i.test(text)) {
        a.setAttribute("href", "#contacto");
      } else if (/ver todo/i.test(text)) {
        a.setAttribute("href", "#proyectos");
      }
    });
  }

  /* -------------------- Enlaces de navegación -------------------- */
  var NAV_MAP = {
    "inicio": "#inicio",
    "nosotros": "#nosotros",
    "servicios": "#servicios",
    "proyectos": "#proyectos",
    "contacto": "#contacto",
    "cobertura": "#cobertura",
    "galería": "#galeria",
    "galeria": "#galeria"
  };

  function wireNav() {
    document.querySelectorAll("a").forEach(function (a) {
      var text = (a.textContent || "").trim().toLowerCase();
      if (NAV_MAP[text] && (a.getAttribute("href") === "#" || a.getAttribute("href") === "./" || !a.getAttribute("href"))) {
        a.setAttribute("href", NAV_MAP[text]);
      }
    });
  }

  /* -------------------- Teléfono y correo clicables -------------------- */
  function makeContactClickable() {
    document.querySelectorAll(".elementskit-section-subtitle, .ekit-heading--subtitle").forEach(function (el) {
      var text = (el.textContent || "").trim();
      if (text.indexOf(PHONE_DISPLAY) !== -1 && !el.querySelector("a")) {
        el.innerHTML = '<a href="' + PHONE_LINK + '" style="color:inherit">' + text + "</a>";
      } else if (text.indexOf(EMAIL) !== -1 && !el.querySelector("a")) {
        el.innerHTML = '<a href="mailto:' + EMAIL + '" style="color:inherit">' + text + "</a>";
      }
    });
  }

  /* -------------------- Formulario (Formspree) -------------------- */
  function setupForm() {
    var form = document.querySelector("form.elementor-form");
    if (!form) { return; }

    form.setAttribute("action", FORMSPREE_ENDPOINT);
    form.setAttribute("method", "POST");

    var status = document.createElement("div");
    status.className = "svc-form-status";
    form.appendChild(status);

    function show(type, message) {
      status.className = "svc-form-status is-active is-" + type;
      status.textContent = message;
    }

    form.addEventListener("submit", function (e) {
      e.preventDefault();
      e.stopImmediatePropagation();

      var emailField = form.querySelector('input[type="email"]');
      if (emailField && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailField.value)) {
        show("error", "Por favor, ingresa un correo electrónico válido.");
        emailField.focus();
        return;
      }

      if (FORMSPREE_ENDPOINT.indexOf("TU_ID_FORMSPREE") !== -1) {
        show("error", "Demo: falta configurar el endpoint de Formspree en custom.js (FORMSPREE_ENDPOINT).");
        return;
      }

      show("loading", "Enviando mensaje...");
      var button = form.querySelector('button[type="submit"]');
      if (button) { button.disabled = true; }

      fetch(FORMSPREE_ENDPOINT, {
        method: "POST",
        body: new FormData(form),
        headers: { Accept: "application/json" }
      })
        .then(function (response) {
          if (response.ok) {
            form.reset();
            show("success", "¡Gracias! Hemos recibido tu mensaje y te contactaremos muy pronto.");
          } else {
            return response.json().then(function (data) {
              var msg = data && data.errors
                ? data.errors.map(function (x) { return x.message; }).join(" ")
                : "No se pudo enviar el mensaje.";
              throw new Error(msg);
            });
          }
        })
        .catch(function () {
          show("error", "No se pudo enviar. Escríbenos directamente por WhatsApp.");
        })
        .finally(function () {
          if (button) { button.disabled = false; }
        });
    }, true);
  }

  /* -------------------- Galería (lightbox) -------------------- */
  function setupGallery() {
    var items = document.querySelectorAll(".svc-gallery-item");
    if (!items.length) { return; }

    var box = document.createElement("div");
    box.className = "svc-lightbox";
    box.innerHTML = '<button class="svc-lightbox-close" aria-label="Cerrar">\u00d7</button><img alt="" />';
    document.body.appendChild(box);

    var img = box.querySelector("img");

    function close() { box.classList.remove("is-open"); }
    function open(src, alt) {
      img.setAttribute("src", src);
      img.setAttribute("alt", alt || "");
      box.classList.add("is-open");
    }

    box.addEventListener("click", function (e) {
      if (e.target === box || e.target.classList.contains("svc-lightbox-close")) { close(); }
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") { close(); }
    });

    items.forEach(function (a) {
      a.addEventListener("click", function (e) {
        e.preventDefault();
        var inner = a.querySelector("img");
        open(a.getAttribute("href"), inner ? inner.getAttribute("alt") : "");
      });
    });
  }

  /* -------------------- Cabecera (sticky + menú móvil) -------------------- */
  function setupHeader() {
    var header = document.getElementById("svcHeader");
    if (!header) { return; }
    var toggle = document.getElementById("svcHeaderToggle");
    var nav = document.getElementById("svcHeaderNav");

    function onScroll() {
      header.classList.toggle("is-scrolled", window.scrollY > 20);
    }
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });

    if (toggle) {
      toggle.addEventListener("click", function () {
        var open = header.classList.toggle("is-open");
        toggle.setAttribute("aria-expanded", open ? "true" : "false");
      });
    }
    if (nav) {
      nav.querySelectorAll("a").forEach(function (a) {
        a.addEventListener("click", function () {
          header.classList.remove("is-open");
          if (toggle) { toggle.setAttribute("aria-expanded", "false"); }
        });
      });
    }
    var cta = header.querySelector(".svc-header-cta");
    if (cta) {
      cta.setAttribute("href", WA_URL);
      cta.setAttribute("target", "_blank");
      cta.setAttribute("rel", "noopener");
    }
  }

  /* -------------------- Init -------------------- */
  function init() {
    assignSectionIds();
    markCards();
    wireWhatsApp();
    wireNav();
    makeContactClickable();
    setupForm();
    setupGallery();
    setupHeader();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
