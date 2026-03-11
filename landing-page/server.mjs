import express from "express";
import nodemailer from "nodemailer";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = Number(process.env.LANDING_PAGE_PORT || 4173);
const RECIPIENT_EMAIL = process.env.LEAD_RECIPIENT_EMAIL || "jonasatchan@gmail.com";
const GMAIL_USER = process.env.GMAIL_SMTP_USER || "";
const GMAIL_APP_PASSWORD = process.env.GMAIL_SMTP_APP_PASSWORD || "";
const PREVIEW_DIR = path.join(__dirname, ".tmp-mail");

const app = express();

app.use(express.json({ limit: "20mb" }));
app.use(express.static(__dirname));

const escapeHtml = (value) =>
  String(value || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");

const isEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || "").trim());

const decodeDataUrl = (value, fallbackName) => {
  const match = String(value || "").match(/^data:([^;]+);base64,(.+)$/);

  if (!match) {
    throw new Error("Invalid image payload.");
  }

  return {
    filename: fallbackName,
    content: Buffer.from(match[2], "base64"),
    contentType: match[1],
  };
};

const validateLead = (body) => {
  const lead = {
    name: String(body.name || "").trim(),
    contact: String(body.contact || "").trim(),
    model: String(body.model || "").trim(),
    problem: String(body.problem || "").trim(),
    scooterPhoto: body.scooterPhoto,
    scooterPhotoName: String(body.scooterPhotoName || "scooter-photo"),
    damagePhoto: body.damagePhoto,
    damagePhotoName: String(body.damagePhotoName || "damage-photo"),
    submittedAt: new Date().toISOString(),
  };

  if (
    !lead.name ||
    !lead.contact ||
    !lead.model ||
    !lead.problem ||
    !lead.scooterPhoto ||
    !lead.damagePhoto
  ) {
    return { error: "Missing required fields." };
  }

  try {
    return {
      value: {
        ...lead,
        attachments: [
          decodeDataUrl(lead.scooterPhoto, lead.scooterPhotoName),
          decodeDataUrl(lead.damagePhoto, lead.damagePhotoName),
        ],
      },
    };
  } catch (error) {
    return { error: error.message || "Invalid image payload." };
  }
};

const buildMessage = (lead) => {
  const subject = "New scooter lead: " + lead.model + " from " + lead.name;
  const text = [
    "New scooter inquiry",
    "",
    "Name: " + lead.name,
    "Contact: " + lead.contact,
    "Scooter model: " + lead.model,
    "",
    "Issue:",
    lead.problem,
    "",
    "Submitted: " + lead.submittedAt,
  ].join("\n");

  const html = [
    "<h2>New scooter inquiry</h2>",
    "<p><strong>Name:</strong> " + escapeHtml(lead.name) + "</p>",
    "<p><strong>Contact:</strong> " + escapeHtml(lead.contact) + "</p>",
    "<p><strong>Scooter model:</strong> " + escapeHtml(lead.model) + "</p>",
    "<p><strong>Issue:</strong><br />" + escapeHtml(lead.problem).replace(/\n/g, "<br />") + "</p>",
    "<p><strong>Submitted:</strong> " + escapeHtml(lead.submittedAt) + "</p>",
    "<p><strong>Attachments:</strong> scooter photo and issue photo included.</p>",
  ].join("");

  return { subject, text, html };
};

const createTransport = () => {
  if (GMAIL_USER && GMAIL_APP_PASSWORD) {
    return {
      mode: "gmail",
      transport: nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: GMAIL_USER,
          pass: GMAIL_APP_PASSWORD,
        },
      }),
    };
  }

  return {
    mode: "preview",
    transport: nodemailer.createTransport({
      streamTransport: true,
      newline: "unix",
      buffer: true,
    }),
  };
};

const savePreview = async (buffer) => {
  await fs.mkdir(PREVIEW_DIR, { recursive: true });
  const filename = "lead-" + Date.now() + ".eml";
  const previewPath = path.join(PREVIEW_DIR, filename);
  await fs.writeFile(previewPath, buffer);
  return previewPath;
};

app.post("/api/lead", async (req, res) => {
  const result = validateLead(req.body);

  if (result.error) {
    res.status(400).json({ ok: false, message: result.error });
    return;
  }

  const lead = result.value;
  const { subject, text, html } = buildMessage(lead);
  const { mode, transport } = createTransport();
  const mailOptions = {
    from: mode === "gmail" ? GMAIL_USER : "ScootRetur Stockholm <no-reply@local.test>",
    to: RECIPIENT_EMAIL,
    subject,
    text,
    html,
    attachments: lead.attachments,
  };

  if (isEmail(lead.contact)) {
    mailOptions.replyTo = lead.contact;
  }

  try {
    const info = await transport.sendMail(mailOptions);

    if (mode === "preview") {
      const previewPath = await savePreview(info.message);
      res.json({
        ok: true,
        mode,
        message: "Lead saved locally. Gmail delivery is not configured yet.",
        previewPath,
      });
      return;
    }

    res.json({
      ok: true,
      mode,
      message: "Inquiry sent successfully.",
      messageId: info.messageId,
    });
  } catch (error) {
    console.error("Lead delivery failed", error);
    res.status(500).json({ ok: false, message: "Could not send the inquiry email." });
  }
});

app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

app.listen(PORT, () => {
  console.log("Landing page server running on http://127.0.0.1:" + PORT);
  if (!GMAIL_USER || !GMAIL_APP_PASSWORD) {
    console.log("Gmail SMTP is not configured. Lead emails will be saved locally in preview mode.");
  }
});
