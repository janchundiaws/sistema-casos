import express from "express";
import jwt from "jsonwebtoken";
import sql from "mssql";
import ldap from "ldapjs";
import { sqlConfig } from "../db.js";

const router = express.Router();

// Configuración de Active Directory
const AD_CONFIG = {
  url: "ldap://mi-servidor-ad:389",
  baseDN: "dc=miempresa,dc=local",
};

router.post("/ad-login", async (req, res) => {
  const { usuario, password } = req.body;

  if (!usuario || !password) {
    return res.status(400).json({ error: "Usuario y contraseña son requeridos" });
  }

  // Crear cliente LDAP
  const client = ldap.createClient({ url: AD_CONFIG.url });

  // Intentar bind con las credenciales
  client.bind(`${usuario}@miempresa.local`, password, async (err) => {
    if (err) {
      console.error("Error autenticando en AD:", err.message);
      return res.status(401).json({ error: "Credenciales inválidas en Active Directory" });
    }

    try {
      // Verificar si está en la BD de usuarios
      const pool = await sql.connect(sqlConfig);
      const result = await pool
        .request()
        .input("usuario", sql.VarChar, usuario)
        .query("SELECT id_usuario, nombre, email FROM Usuario WHERE usuario = @usuario");

      if (result.recordset.length === 0) {
        return res.status(403).json({ error: "Usuario no autorizado en el sistema" });
      }

      const user = result.recordset[0];

      // Generar token JWT
      const token = jwt.sign(
        { id: user.id_usuario, usuario: user.nombre, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: "8h" }
      );

      res.json({ message: "Login exitoso", token, user });
    } catch (dbErr) {
      console.error("Error en BD:", dbErr.message);
      res.status(500).json({ error: "Error interno en la validación de usuario" });
    } finally {
      client.unbind();
    }
  });
});

export default router;
