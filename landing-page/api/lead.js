import nodemailer from "nodemailer";

const RECIPIENT_EMAIL = process.env.LEAD_RECIPIENT_EMAIL || "jonasatchan@gmail.com";
const GMAIL_USER = process.env.GMAIL_SMTP_USER || "";
const GMAIL_APP_PASSWORD = process.env.GMAIL_SMTP_APP_PASSWORD || "";

const isEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || "").trim());

const escapeHtml = (value) =>
  String(value || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");

const readJsonBody = async (req) => {
  if (req.body && typeof req.body === "object") {
    return req.body;
  }

  if (typeof req.body === "string" && req.body.length > 0) {
    return JSON.parse(req.body);
  }

  const chunks = [];
  for await (const chunk of req) {
    chunks.push(typeof chunk === "string" ? Buffer.from(chunk) : chunk);
  }

  const raw = Buffer.concat(chunks).toString("utf8");
  return raw ? JSON.parse(raw) : {};
};

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

export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.status(405).json({ ok: false, message: "Method not allowed." });
    return;
  }

  if (!GMAIL_USER || !GMAIL_APP_PASSWORD) {
    res.status(500).json({ ok: false, message: "Server email is not configured." });
    return;
  }

  try {
    const body = await readJsonBody(req);
    const lead = {
      name: String(body.name || "").trim(),
      contact: String(body.contact || "").trim(),
      model: String(body.model || "").trim(),
      problem: String(body.problem || "").trim(),
      scooterPhoto: body.scooterPhoto,
      scooterPhotoName: String(body.scooterPhotoName || "scooter-photo.jpg"),
      damagePhoto: body.damagePhoto,
      damagePhotoName: String(body.damagePhotoName || "damage-photo.jpg"),
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
      res.status(400).json({ ok: false, message: "Missing required fields." });
      return;
    }

    const attachments = [
      decodeDataUrl(lead.scooterPhoto, lead.scooterPhotoName),
      decodeDataUrl(lead.damagePhoto, lead.damagePhotoName),
    ];

    const transport = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: GMAIL_USER,
        pass: GMAIL_APP_PASSWORD,
      },
    });

    const mailOptions = {
      from: GMAIL_USER,
      to: RECIPIENT_EMAIL,
      subject: "New scooter lead: " + lead.model + " from " + lead.name,
      text: [
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
      ].join("\n"),
      html: [
        "<h2>New scooter inquiry</h2>",
        "<p><strong>Name:</strong> " + escapeHtml(lead.name) + "</p>",
        "<p><strong>Contact:</strong> " + escapeHtml(lead.contact) + "</p>",
        "<p><strong>Scooter model:</strong> " + escapeHtml(lead.model) + "</p>",
        "<p><strong>Issue:</strong><br />" + escapeHtml(lead.problem).replace(/\n/g, "<br />") + "</p>",
        "<p><strong>Submitted:</strong> " + escapeHtml(lead.submittedAt) + "</p>",
      ].join(""),
      attachments,
    };

    if (isEmail(lead.contact)) {
      mailOptions.replyTo = lead.contact;
    }

    await transport.sendMail(mailOptions);

    res.status(200).json({ ok: true, mode: "gmail", message: "Inquiry sent successfully." });
  } catch (error) {
    console.error("Lead delivery failed", error);
    res.status(500).json({ ok: false, message: "Could not send the inquiry email." });
  }
}
