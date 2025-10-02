const express = require('express');
const { HfInference } = require('@huggingface/inference');
const Document = require('../models/Document.js');
const Flashcard = require('../models/Flashcard.js');
const auth = require('../middleware/auth.js');

const router = express.Router();

const hf = new HfInference(process.env.HF_TOKEN);

// Generate flashcards
router.post('/generate/:id', auth, async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);
    if (!document || document.userId.toString() !== req.user.id) {
      return res.status(404).json({ msg: 'Document not found' });
    }

    if (!document.text || document.text.trim() === '') {
      return res.status(400).json({ msg: 'Document has no text to generate flashcards' });
    }

    const MAX_CHARS = 500; // safe cutoff for gpt2
    const inputText = document.text.slice(0, MAX_CHARS);

    const prompt = `Generate 5 question-answer flashcards from the following text. Format each as JSON: {"question": "Question text", "answer": "Answer text"}\n\nText:\n${inputText}\n\nOutput as a JSON array of objects.`;

    const response = await hf.textGeneration({
      model: 'gpt2',
      inputs: prompt,
      parameters: { max_length: 1000 }
    });

    const generatedText = response.generated_text;
    console.log('Generated text:', generatedText);

    // Try to parse as JSON
    let flashcardsData = [];
    try {
      // Extract JSON array from the text
      const jsonMatch = generatedText.match(/\[.*\]/s);
      if (jsonMatch) {
        flashcardsData = JSON.parse(jsonMatch[0]);
      } else {
        // Fallback: simple parsing
        const lines = generatedText.split('\n');
        for (let i = 0; i < lines.length; i += 2) {
          if (lines[i] && lines[i+1]) {
            const question = lines[i].replace(/^Q\d*:\s*/, '');
            const answer = lines[i+1].replace(/^A\d*:\s*/, '');
            if (question && answer) {
              flashcardsData.push({ question, answer });
            }
          }
        }
      }
    } catch (parseErr) {
      console.error('Parsing error:', parseErr);
      // Fallback to simple split
      const parts = generatedText.split(/Q\d*:/).slice(1);
      for (let part of parts) {
        const qa = part.split(/A\d*:/);
        if (qa.length >= 2) {
          flashcardsData.push({ question: qa[0].trim(), answer: qa[1].trim() });
        }
      }
    }

    const flashcards = [];
    for (let item of flashcardsData.slice(0, 5)) { // Limit to 5
      const flashcard = new Flashcard({
        userId: req.user.id,
        documentId: req.params.id,
        question: item.question || 'Question',
        answer: item.answer || 'Answer',
      });
      await flashcard.save();
      flashcards.push(flashcard);
    }

    res.json(flashcards);
  } catch (err) {
    console.error('Flashcards generate error:', err);
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
