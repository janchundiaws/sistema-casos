const express6 = require('express');
const { sendEmail } = require("../services/emailService");

const routerEmail = express6.Router();

/**
 * @swagger
 * /api/email/send:
 *   post:
 *     summary: Enviar un correo electrónico
 *     tags: [Email]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               to:
 *                 type: string
 *                 example: destinatario@empresa.com
 *               subject:
 *                 type: string
 *                 example: Seguimiento de Caso
 *               text:
 *                 type: string
 *                 example: Texto plano del mensaje
 *               html:
 *                 type: string
 *                 example: "<b>Este es un correo en HTML</b>"
 *     responses:
 *       200:
 *         description: Correo enviado correctamente
 *       500:
 *         description: Error al enviar el correo
 */
routerEmail.post("/send", async (req, res) => {
  const { to, subject, text, html } = req.body;

  try {
    const result = await sendEmail({ to, subject, text, html });
    res.json({ message: "Correo enviado correctamente", result });
  } catch (error) {
    console.error("Error enviando correo:", error.message);
    res.status(500).json({ error: "Error enviando correo", details: error.message });
  }
});

module.exports = routerEmail;
