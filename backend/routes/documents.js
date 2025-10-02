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
    console.log('Upload request received');
    console.log('req.user:', req.user ? req.user.id : 'No user');
    console.log('req.file:', req.file ? 'File present' : 'No file');
    console.log('req.body:', req.body);

    const file = req.file;
    if (!file) {
      console.log('No file uploaded - returning 400');
      return res.status(400).json({ msg: 'No file uploaded' });
    }

    console.log('File uploaded:', file.originalname, 'Mimetype:', file.mimetype, 'Path:', file.path);

    let text = '';
    if (file.mimetype === 'application/pdf') {
      console.log('Processing PDF file');
      try {
        const dataBuffer = fs.readFileSync(file.path);
        const data = await pdfParse(dataBuffer);
        text = data.text;
        console.log('PDF text extracted, length:', text.length);
      } catch (pdfErr) {
        console.error('Error parsing PDF:', pdfErr.message);
        return res.status(400).json({ msg: 'Invalid PDF file' });
      }
    } else if (file.mimetype.startsWith('text/')) {
      console.log('Processing text file');
      try {
        text = fs.readFileSync(file.path, 'utf8');
        console.log('Text file read, length:', text.length);
      } catch (textErr) {
        console.error('Error reading text file:', textErr.message);
        return res.status(400).json({ msg: 'Invalid text file' });
      }
    } else {
      console.log('Unsupported file type:', file.mimetype);
      return res.status(400).json({ msg: 'Unsupported file type. Only PDF and text files are allowed.' });
    }

    if (!text || text.trim().length === 0) {
      console.log('No text extracted from file');
      return res.status(400).json({ msg: 'No readable text found in the file' });
    }

    const document = new Document({
      userId: req.user.id,
      filename: file.filename,
      originalName: file.originalname,
      text,
    });

    console.log('Saving document to DB');
    await document.save();
    console.log('Document saved successfully');
    res.json(document);
  } catch (err) {
    console.error('Error in upload:', err.message);
    console.error('Stack:', err.stack);
    res.status(500).json({ msg: 'Server error', error: err.message });
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
