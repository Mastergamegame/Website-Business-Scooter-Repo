const siteConfig = {
  companyName: "ScootRetur Stockholm",
  privacyUrl: "#",
  formEndpoint: "/api/lead",
};

const MAX_IMAGE_DIMENSION = 1600;
const MAX_IMAGE_BYTES = 900 * 1024;
const INITIAL_IMAGE_QUALITY = 0.82;
const MIN_IMAGE_QUALITY = 0.56;

const translations = {
  sv: {
    page_title: "Trött på långsam support? Sälj din elscooter istället.",
    page_description:
      "En enkel sida för personer i Stockholm som vill sälja en felaktig eller oönskad elscooter istället för att vänta på långsam support eller sega återbetalningar.",
    hero_eyebrow: "Stockholm - Vi köper elscootrar direkt från kunder",
    hero_title: "Trött på långsam support? Sälj din elscooter istället.",
    hero_subtitle:
      "Vi köper felaktiga eller problematiska elscootrar direkt från kunder i Stockholm. Enkelt, lokalt och utan onödigt krångel.",
    hero_cta_primary: "Få ett erbjudande",
    hero_cta_secondary: "Hur det fungerar",
    hero_note: "Vi köper scootrar direkt från kunder. Detta är ingen verkstad, butik eller officiell support.",
    hero_chip_1: "Direktköp från kund",
    hero_chip_2: "Enklare än att vänta",
    hero_chip_3: "Betalning på plats",
    hero_side_kicker: "Ett enklare alternativ",
    hero_side_title: "Vi köper scootern så att du kan gå vidare snabbare.",
    hero_side_body:
      "Om supporten tar för lång tid eller problemet drar ut på tiden kan det vara enklare att sälja scootern direkt.",
    hero_info_area_label: "Område",
    hero_info_area_value: "Stockholm",
    hero_info_focus_label: "Fokus",
    hero_info_focus_value: "Felaktiga eller använda elscootrar",
    hero_info_handoff_label: "Överlämning",
    hero_info_handoff_value: "Enkel lokal överlämning",
    hero_legal: "Oberoende tjänst. Inte officiell support och inte kopplad till Xiaomi eller Mi Store.",
    steps_eyebrow: "Hur det fungerar",
    steps_title: "Fyra enkla steg",
    steps_subtitle: "Ett enkelt alternativ för dig som inte vill vänta på support eller långa processer.",
    step_1_title: "Skicka modell och problem",
    step_1_body: "Berätta vilken scooter du har och vad problemet verkar vara.",
    step_2_title: "Vi bedömer scootern",
    step_2_body: "Vi går igenom uppgifterna och ser om scootern passar oss.",
    step_3_title: "Du får ett erbjudande",
    step_3_body: "Om vi är intresserade kontaktar vi dig med ett enkelt erbjudande.",
    step_4_title: "Vi möts och betalar på plats",
    step_4_body: "Om vi kommer överens möts vi i Stockholm och betalning sker vid köp.",
    contact_eyebrow: "Få ett erbjudande",
    contact_title: "Berätta kort om din scooter",
    contact_body: "Fyll i några enkla uppgifter så återkommer vi om scootern är av intresse.",
    contact_soft_1_label: "Första steg",
    contact_soft_1_value: "Kort och enkelt",
    contact_soft_2_label: "Överlämning",
    contact_soft_2_value: "Lokalt i Stockholm",
    contact_soft_3_label: "Kontakt",
    contact_soft_3_value: "Bara om scootern verkar relevant",
    form_name: "Namn",
    form_contact: "E-post eller telefon",
    form_contact_placeholder: "Din e-post eller ditt telefonnummer",
    form_model: "Scootermodell",
    form_model_placeholder: "Exempel: Xiaomi Pro 2",
    form_problem: "Beskriv problemet",
    form_problem_placeholder: "Kort beskrivning av felet",
    form_scooter_photo: "Bild på scootern",
    form_scooter_photo_note: "Ladda upp en tydlig bild på hela scootern.",
    form_damage_photo: "Bild på fel eller skada",
    form_damage_photo_note: "Ladda upp en bild som visar problemet tydligt.",
    form_followup_note: "Skicka med en bild på scootern och en bild på felet så att vi kan göra en snabbare bedömning.",
    form_submit: "Skicka",
    form_trust_note: "Vi kontaktar dig bara om scootern verkar relevant för oss.",
    footer_privacy: "Integritet / Privacy policy",
    form_status_idle: "Skicka din förfrågan så återkommer vi om scootern verkar relevant.",
    form_status_invalid: "Fyll i de obligatoriska fälten och ladda upp båda bilderna innan du skickar.",
    form_status_missing_endpoint: "Formuläret är inte konfigurerat än.",
    form_status_preparing: "Bearbetar bilder...",
    form_status_sending: "Skickar förfrågan...",
    form_status_success: "Tack. Din förfrågan är skickad.",
    form_status_preview: "Förfrågan togs emot lokalt. Gmail är inte konfigurerat än.",
    form_status_payload_too_large: "Bilderna är för stora. Välj mindre eller tydligare beskurna bilder och försök igen.",
    form_status_error: "Det gick inte att skicka förfrågan just nu.",
    success_dialog_label: "Skickat",
    success_dialog_title: "Din förfrågan är skickad",
    success_dialog_body: "Vi har tagit emot dina uppgifter och återkommer om scootern är relevant för oss.",
    success_dialog_button: "Stäng",
  },
  en: {
    page_title: "Tired of slow support? Sell your e-scooter instead.",
    page_description:
      "A simple Stockholm page for people who want to sell a faulty or unwanted e-scooter instead of waiting on slow support or refund delays.",
    hero_eyebrow: "Stockholm - We buy e-scooters directly from customers",
    hero_title: "Tired of slow support? Sell your e-scooter instead.",
    hero_subtitle:
      "We buy faulty or problematic e-scooters directly from customers in Stockholm. Simple, local, and easier than waiting.",
    hero_cta_primary: "Get an offer",
    hero_cta_secondary: "How it works",
    hero_note: "We buy scooters directly from customers. This is not a repair shop, store, or official support page.",
    hero_chip_1: "Direct customer buyback",
    hero_chip_2: "Simpler than waiting",
    hero_chip_3: "Payment on site",
    hero_side_kicker: "A simpler option",
    hero_side_title: "We buy the scooter so you can move on faster.",
    hero_side_body:
      "If support is taking too long or the scooter issue keeps dragging on, selling it can be the easier option.",
    hero_info_area_label: "Area",
    hero_info_area_value: "Stockholm",
    hero_info_focus_label: "Focus",
    hero_info_focus_value: "Used or faulty e-scooters",
    hero_info_handoff_label: "Handoff",
    hero_info_handoff_value: "Simple local handoff",
    hero_legal: "Independent service. Not official support and not affiliated with Xiaomi or Mi Store.",
    steps_eyebrow: "How it works",
    steps_title: "Four simple steps",
    steps_subtitle: "A simple alternative for people who do not want to wait for support or long processes.",
    step_1_title: "Send model and issue",
    step_1_body: "Tell us what scooter you have and what the issue seems to be.",
    step_2_title: "We review the details",
    step_2_body: "We go through the information and see if the scooter is a fit for us.",
    step_3_title: "You get an offer",
    step_3_body: "If we are interested, we contact you with a simple offer.",
    step_4_title: "We meet and pay on site",
    step_4_body: "If we agree, we meet in Stockholm and payment is made on purchase.",
    contact_eyebrow: "Get an offer",
    contact_title: "Tell us about your scooter",
    contact_body: "Fill in a few simple details and we will get back to you if the scooter is of interest.",
    contact_soft_1_label: "First step",
    contact_soft_1_value: "Short and easy",
    contact_soft_2_label: "Handoff",
    contact_soft_2_value: "Local in Stockholm",
    contact_soft_3_label: "Contact",
    contact_soft_3_value: "Only if the scooter seems relevant",
    form_name: "Name",
    form_contact: "Email or phone",
    form_contact_placeholder: "Your email or phone number",
    form_model: "Scooter model",
    form_model_placeholder: "Example: Xiaomi Pro 2",
    form_problem: "Describe the problem",
    form_problem_placeholder: "Short description of the issue",
    form_scooter_photo: "Photo of the scooter",
    form_scooter_photo_note: "Upload a clear photo of the full scooter.",
    form_damage_photo: "Photo of the issue or damage",
    form_damage_photo_note: "Upload a photo that clearly shows the problem.",
    form_followup_note: "Please include one photo of the scooter and one photo of the issue so we can review it faster.",
    form_submit: "Send",
    form_trust_note: "We only contact you if the scooter seems relevant for us.",
    footer_privacy: "Privacy policy",
    form_status_idle: "Send your request and we will review it.",
    form_status_invalid: "Please complete the required fields and upload both images before sending the request.",
    form_status_missing_endpoint: "The form endpoint is not configured yet.",
    form_status_preparing: "Optimizing images...",
    form_status_sending: "Sending request...",
    form_status_success: "Thanks. Your inquiry was sent.",
    form_status_preview: "The inquiry was captured locally. Gmail is not configured yet.",
    form_status_payload_too_large: "The images are too large. Please choose smaller or more tightly cropped images and try again.",
    form_status_error: "Could not send the inquiry right now.",
    success_dialog_label: "Sent",
    success_dialog_title: "Your inquiry was sent",
    success_dialog_body: "We received your details and will get back to you if the scooter is relevant for us.",
    success_dialog_button: "Close",
  },
};

const applyText = (selector, value) => {
  document.querySelectorAll(selector).forEach((node) => {
    node.textContent = value;
  });
};

const applyHref = (selector, value) => {
  document.querySelectorAll(selector).forEach((node) => {
    node.setAttribute("href", value);
  });
};

const setStatus = (message) => {
  const status = document.querySelector(".form-status");
  if (status) {
    status.textContent = message;
  }
};

const readFileAsDataUrl = (file) =>
  new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () => reject(new Error("FILE_READ_FAILED"));

    reader.readAsDataURL(file);
  });

const loadImageElement = (source) =>
  new Promise((resolve, reject) => {
    const image = new Image();

    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error("IMAGE_LOAD_FAILED"));
    image.src = source;
  });

const estimateDataUrlBytes = (value) => {
  const base64 = String(value || "").split(",")[1] || "";
  const padding = base64.endsWith("==") ? 2 : base64.endsWith("=") ? 1 : 0;
  return Math.max(0, Math.floor((base64.length * 3) / 4) - padding);
};

const buildUploadName = (filename) => {
  const safeName = String(filename || "image")
    .replace(/\.[^.]+$/, "")
    .replace(/[^a-z0-9_-]+/gi, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");

  return (safeName || "image") + ".jpg";
};

const prepareUploadImage = async (file) => {
  const source = await readFileAsDataUrl(file);
  const image = await loadImageElement(source);
  const maxSide = Math.max(image.naturalWidth || image.width || 1, image.naturalHeight || image.height || 1);
  const scale = Math.min(1, MAX_IMAGE_DIMENSION / maxSide);
  const width = Math.max(1, Math.round((image.naturalWidth || image.width || 1) * scale));
  const height = Math.max(1, Math.round((image.naturalHeight || image.height || 1) * scale));
  const canvas = document.createElement("canvas");
  const context = canvas.getContext("2d");

  if (!context) {
    throw new Error("IMAGE_PROCESSING_FAILED");
  }

  canvas.width = width;
  canvas.height = height;
  context.drawImage(image, 0, 0, width, height);

  let quality = INITIAL_IMAGE_QUALITY;
  let dataUrl = canvas.toDataURL("image/jpeg", quality);

  while (estimateDataUrlBytes(dataUrl) > MAX_IMAGE_BYTES && quality > MIN_IMAGE_QUALITY) {
    quality = Math.max(MIN_IMAGE_QUALITY, quality - 0.08);
    dataUrl = canvas.toDataURL("image/jpeg", quality);
  }

  if (estimateDataUrlBytes(dataUrl) > MAX_IMAGE_BYTES) {
    throw new Error("IMAGE_TOO_LARGE");
  }

  return {
    dataUrl,
    filename: buildUploadName(file.name),
  };
};

const successModal = document.querySelector("#success-modal");
const successCloseButtons = document.querySelectorAll("[data-close-success]");
let lastFocusedElement = null;

const hideSuccessModal = () => {
  if (!successModal) {
    return;
  }

  successModal.hidden = true;
  successModal.setAttribute("aria-hidden", "true");
  document.body.classList.remove("modal-open");
  lastFocusedElement?.focus?.();
};

const showSuccessModal = () => {
  if (!successModal) {
    return;
  }

  lastFocusedElement = document.activeElement;
  successModal.hidden = false;
  successModal.setAttribute("aria-hidden", "false");
  document.body.classList.add("modal-open");
  successModal.querySelector("button[data-close-success]")?.focus();
};

const renderLanguage = (lang) => {
  const copy = translations[lang] || translations.sv;
  document.documentElement.lang = lang;
  document.title = copy.page_title;

  const metaDescription = document.querySelector('meta[name="description"]');
  if (metaDescription) {
    metaDescription.setAttribute("content", copy.page_description);
  }

  document.querySelectorAll("[data-i18n]").forEach((node) => {
    const key = node.getAttribute("data-i18n");
    if (key && copy[key]) {
      node.textContent = copy[key];
    }
  });

  document.querySelectorAll("[data-i18n-placeholder]").forEach((node) => {
    const key = node.getAttribute("data-i18n-placeholder");
    if (key && copy[key]) {
      node.setAttribute("placeholder", copy[key]);
    }
  });

  document.querySelectorAll("[data-switch-lang]").forEach((button) => {
    const isActive = button.getAttribute("data-switch-lang") === lang;
    button.classList.toggle("is-active", isActive);
    button.setAttribute("aria-pressed", String(isActive));
  });

  localStorage.setItem("scooter-site-language", lang);
  setStatus(copy.form_status_idle);
};

applyText(".company-name", siteConfig.companyName);
applyHref(".privacy-link", siteConfig.privacyUrl);

document.querySelectorAll("[data-switch-lang]").forEach((button) => {
  button.addEventListener("click", () => {
    renderLanguage(button.getAttribute("data-switch-lang") || "sv");
  });
});

const preferredLanguage = (() => {
  const saved = localStorage.getItem("scooter-site-language");
  if (saved === "sv" || saved === "en") {
    return saved;
  }

  return navigator.language.toLowerCase().startsWith("en") ? "en" : "sv";
})();

renderLanguage(preferredLanguage);

successCloseButtons.forEach((button) => {
  button.addEventListener("click", hideSuccessModal);
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && successModal && !successModal.hidden) {
    hideSuccessModal();
  }
});

const form = document.querySelector("#lead-form");

form?.addEventListener("submit", async (event) => {
  event.preventDefault();

  const currentLanguage = document.documentElement.lang === "en" ? "en" : "sv";
  const copy = translations[currentLanguage];
  const scooterPhotoInput = form.elements.scooterPhoto;
  const damagePhotoInput = form.elements.damagePhoto;

  if (!form.reportValidity()) {
    setStatus(copy.form_status_invalid);
    return;
  }

  if (!siteConfig.formEndpoint) {
    setStatus(copy.form_status_missing_endpoint);
    return;
  }

  const scooterPhotoFile = scooterPhotoInput?.files?.[0];
  const damagePhotoFile = damagePhotoInput?.files?.[0];

  if (!scooterPhotoFile || !damagePhotoFile) {
    setStatus(copy.form_status_invalid);
    return;
  }

  const submitButton = form.querySelector('button[type="submit"]');

  submitButton?.setAttribute("disabled", "disabled");
  setStatus(copy.form_status_preparing);

  try {
    const [scooterPhoto, damagePhoto] = await Promise.all([
      prepareUploadImage(scooterPhotoFile),
      prepareUploadImage(damagePhotoFile),
    ]);

    setStatus(copy.form_status_sending);

    const payload = {
      name: String(form.elements.name.value || "").trim(),
      contact: String(form.elements.contact.value || "").trim(),
      model: String(form.elements.model.value || "").trim(),
      problem: String(form.elements.problem.value || "").trim(),
      scooterPhoto: scooterPhoto.dataUrl,
      scooterPhotoName: scooterPhoto.filename,
      damagePhoto: damagePhoto.dataUrl,
      damagePhotoName: damagePhoto.filename,
    };

    const response = await fetch(siteConfig.formEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const resJson = await response.json().catch(() => null);

    if (!response.ok || !resJson?.ok) {
      if (response.status === 413) {
        setStatus(copy.form_status_payload_too_large);
        return;
      }

      setStatus(resJson?.message || copy.form_status_error);
      return;
    }

    if (resJson.mode === "preview") {
      setStatus(copy.form_status_preview);
    } else {
      setStatus(copy.form_status_success);
    }

    form.reset();
    showSuccessModal();
    return;
  } catch (error) {
    if (error instanceof Error && error.message === "IMAGE_TOO_LARGE") {
      setStatus(copy.form_status_payload_too_large);
      return;
    }

    setStatus(copy.form_status_error);
  } finally {
    submitButton?.removeAttribute("disabled");
  }
});
