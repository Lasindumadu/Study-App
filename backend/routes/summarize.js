const express = require('express');
const { HfInference } = require('@huggingface/inference');
const Document = require('../models/Document.js');
const auth = require('../middleware/auth.js');
const multer = require('multer');
const pdfParse = require('pdf-parse');
const fs = require('fs');

const router = express.Router();
const hf = new HfInference(process.env.HF_TOKEN);
const upload = multer({ dest: 'uploads/' });

// Helper: split text into chunks
function chunkText(text, chunkSize = 3000) {
  const chunks = [];
  let start = 0;
  while (start < text.length) {
    chunks.push(text.slice(start, start + chunkSize));
    start += chunkSize;
  }
  return chunks;
}

// Summarize document
router.post('/:id', auth, async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);
    if (!document || document.userId.toString() !== req.user.id) {
      return res.status(404).json({ msg: 'Document not found' });
    }
    if (!document.text || document.text.trim() === '') {
      return res.status(400).json({ msg: 'Document has no text to summarize' });
    }

    const textChunks = chunkText(document.text, 1000);
    let combinedSummary = '';

    for (const chunk of textChunks) {
      try {
        const messages = [{ role: 'user', content: `Summarize the following text concisely:\n\n${chunk}\n\nSummary:` }];

        const result = await hf.chatCompletion({
          model: 'mistralai/Mixtral-8x7B-Instruct-v0.1',
          messages,
          max_tokens: 200,
          temperature: 0.1
        });

        combinedSummary += (result.choices[0].message.content || '') + '\n';
      } catch (chunkErr) {
        console.error('Error summarizing chunk:', chunkErr);
        combinedSummary += '[Error summarizing this chunk]\n';
      }
    }

    res.json({ summary: combinedSummary.trim() });
  } catch (err) {
    console.error('Summarize error:', err.stack);
    res.status(500).json({ msg: 'Failed to summarize document', error: err.message });
  }
});

// Summarize PDF directly
router.post('/pdf', auth, upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ msg: 'No file uploaded' });
    }

    if (file.mimetype !== 'application/pdf') {
      return res.status(400).json({ msg: 'Only PDF files are supported' });
    }

    // Extract text from PDF
    const dataBuffer = fs.readFileSync(file.path);
    const data = await pdfParse(dataBuffer);
    const pdfText = data.text;

    if (!pdfText || pdfText.trim().length === 0) {
      return res.status(400).json({ msg: 'No readable text found in the PDF' });
    }

    // Clean up uploaded file
    fs.unlinkSync(file.path);

    // Chunk and summarize
    const textChunks = chunkText(pdfText, 1000);
    let combinedSummary = '';

    for (const chunk of textChunks) {
      try {
        const messages = [{ role: 'user', content: `Summarize the following text concisely:\n\n${chunk}\n\nSummary:` }];

        const result = await hf.chatCompletion({
          model: 'mistralai/Mixtral-8x7B-Instruct-v0.1',
          messages,
          max_tokens: 200,
          temperature: 0.1
        });

        combinedSummary += (result.choices[0].message.content || '') + '\n';
      } catch (chunkErr) {
        console.error('Error summarizing PDF chunk:', chunkErr);
        combinedSummary += '[Error summarizing this chunk]\n';
      }
    }

    res.json({ summary: combinedSummary.trim() });
  } catch (err) {
    console.error('Summarize PDF error:', err.stack);
    res.status(500).json({ msg: 'Failed to summarize PDF', error: err.message });
  }
});

module.exports = router;
