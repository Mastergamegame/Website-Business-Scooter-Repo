import nodemailer from 'nodemailer';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Method Not Allowed' });
  }

  const {
    name,
    contact,
    model,
    problem,
    scooterPhoto,
    scooterPhotoName,
    damagePhoto,
    damagePhotoName,
  } = req.body || {};

  // Validate basic fields
  if (!name || !contact || !model || !problem) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const leadRecipient = process.env.LEAD_RECIPIENT_EMAIL || 'jonasatchan@gmail.com';
  const smtpUser = process.env.GMAIL_SMTP_USER;
  const smtpPass = process.env.GMAIL_SMTP_APP_PASSWORD;

  if (!smtpUser || !smtpPass) {
    return res.status(500).json({ message: 'Email configuration missing' });
  }

  const attachments = [];

  // Helper to push attachment if Data URL exists
  function addAttachment(dataUrl, filenameFallback) {
    if (!dataUrl) return;
    let base64String = dataUrl;
    // If it has a data URL prefix, remove it
    const parts = dataUrl.split(',');
    if (parts.length === 2) {
      base64String = parts[1];
    }
    attachments.push({
      filename: filenameFallback,
      content: Buffer.from(base64String, 'base64'),
    });
  }

  addAttachment(scooterPhoto, scooterPhotoName || 'scooter-photo');
  addAttachment(damagePhoto, damagePhotoName || 'damage-photo');

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: smtpUser,
      pass: smtpPass,
    },
  });

  const textBody = `
Name: ${name}
Contact: ${contact}
Model: ${model}
Problem: ${problem}
  `.trim();

  const mailOptions = {
    from: smtpUser,
    to: leadRecipient,
    subject: 'New Scooter Lead',
    text: textBody,
    attachments,
  };

  try {
    await transporter.sendMail(mailOptions);
    return res.status(200).json({ message: 'success' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Failed to send email' });
  }
}
