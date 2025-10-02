const express = require('express');
const multer = require('multer');
const pdfParse = require('pdf-parse');
const fs = require('fs');
const Document = require('../models/Document.js');
const auth = require('../middleware/auth.js');

const router = express.Router();

const upload = multer({ dest: 'uploads/' });

// Upload document
router.post('/upload', auth, upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ msg: 'No file uploaded' });
    }

    let text = '';
    if (file.mimetype === 'application/pdf') {
      const dataBuffer = fs.readFileSync(file.path);
      const data = await pdfParse(dataBuffer);
      text = data.text;
    } else {
      // For text files
      text = fs.readFileSync(file.path, 'utf8');
    }

    const document = new Document({
      userId: req.user.id,
      filename: file.filename,
      originalName: file.originalname,
      text,
    });

    await document.save();
    res.json(document);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Get user's documents
router.get('/', auth, async (req, res) => {
  try {
    const documents = await Document.find({ userId: req.user.id });
    res.json(documents);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
