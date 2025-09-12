const FormData = require('form-data');
const fs = require('fs');
const fetch = require('node-fetch');

async function testUpload() {
  try {
    // Crear un archivo de prueba
    const testFile = 'test.txt';
    fs.writeFileSync(testFile, 'Este es un archivo de prueba para testing');
    
    const form = new FormData();
    form.append('file', fs.createReadStream(testFile));
    form.append('id_caso', '2');
    form.append('id_seguimiento', '1');
    
    const response = await fetch('http://localhost:3000/api/adjuntos/upload', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZF91c3VhcmlvIjoyLCJpYXQiOjE3NTc2MDgyMzgsImV4cCI6MTc1NzYzNzAzOH0.D5QpWYPy0nh6tT0IXj2sd3-m7-Cg_G9Sd23bfGfWXDQ'
      },
      body: form
    });
    
    const result = await response.text();
    console.log('Status:', response.status);
    console.log('Response:', result);
    
    // Limpiar archivo de prueba
    fs.unlinkSync(testFile);
    
  } catch (error) {
    console.error('Error:', error);
  }
}

testUpload();
