const nodemailer = require("nodemailer");

async function sendEmail({ to, subject, text, html }) {
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  const mailOptions = {
    from: `"Sistema de Casos" <${process.env.SMTP_USER}>`,
    to,
    subject,
    text,
    html,
  };

  return transporter.sendMail(mailOptions);
}

module.exports = { sendEmail };
