const express = require('express');
const { HfInference } = require('@huggingface/inference');
const Document = require('../models/Document.js');
const auth = require('../middleware/auth.js');

const router = express.Router();

const hf = new HfInference(process.env.HF_TOKEN || 'your_huggingface_token');

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

    const summaryResult = await hf.summarization({
      model: 'facebook/bart-large-cnn',
      inputs: document.text,
      parameters: { max_length: 150, min_length: 30 }
    });

    // Hugging Face returns an array
    const summaryText = summaryResult[0]?.summary_text || '';

    res.json({ summary: summaryText });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
