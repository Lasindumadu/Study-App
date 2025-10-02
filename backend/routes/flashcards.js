const express = require('express');
const { HfInference } = require('@huggingface/inference');
const Document = require('../models/Document.js');
const Flashcard = require('../models/Flashcard.js');
const auth = require('../middleware/auth.js');

const router = express.Router();

const hf = new HfInference(process.env.HF_TOKEN || 'your_huggingface_token');

// Generate flashcards
router.post('/generate/:id', auth, async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);
    if (!document || document.userId.toString() !== req.user.id) {
      return res.status(404).json({ msg: 'Document not found' });
    }

    const prompt = `Generate 5 question-answer flashcards from the following text:\n\n${document.text}\n\nFormat: Q1: Question\nA1: Answer\nQ2: Question\nA2: Answer\n...`;

    const response = await hf.textGeneration({
      model: 'gpt2', // Or better model if available
      inputs: prompt,
      parameters: { max_length: 500 }
    });

    const generatedText = response.generated_text;
    // Parse the response to extract Q&A
    const lines = generatedText.split('\n');
    const flashcards = [];
    for (let i = 0; i < lines.length; i += 2) {
      if (lines[i].startsWith('Q') && lines[i+1] && lines[i+1].startsWith('A')) {
        const question = lines[i].substring(3);
        const answer = lines[i+1].substring(3);
        const flashcard = new Flashcard({
          userId: req.user.id,
          documentId: req.params.id,
          question,
          answer,
        });
        await flashcard.save();
        flashcards.push(flashcard);
      }
    }

    res.json(flashcards);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Get flashcards for document
router.get('/:id', auth, async (req, res) => {
  try {
    const flashcards = await Flashcard.find({ documentId: req.params.id, userId: req.user.id });
    res.json(flashcards);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
