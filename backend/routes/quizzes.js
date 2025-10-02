const express = require('express');
const { HfInference } = require('@huggingface/inference');
const Document = require('../models/Document.js');
const Quiz = require('../models/Quiz.js');
const auth = require('../middleware/auth.js');

const router = express.Router();

const hf = new HfInference(process.env.HF_TOKEN || 'your_huggingface_token');

// Generate quizzes
router.post('/generate/:id', auth, async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);
    if (!document || document.userId.toString() !== req.user.id) {
      return res.status(404).json({ msg: 'Document not found' });
    }

    const prompt = `Generate 5 multiple-choice questions with 4 options each from the following text:\n\n${document.text}\n\nFormat: Q1: Question\nA1: Option1\nB1: Option2\nC1: Option3\nD1: Option4\nCorrect1: A\n...`;

    const response = await hf.textGeneration({
      model: 'gpt2',
      inputs: prompt,
      parameters: { max_length: 1000 }
    });

    const generatedText = response.generated_text;
    // Parse the response
    const lines = generatedText.split('\n');
    const quizzes = [];
    let currentQ = null;
    let options = [];
    for (let line of lines) {
      if (line.startsWith('Q')) {
        if (currentQ) {
          // Save previous
          const quiz = new Quiz({
            userId: req.user.id,
            documentId: req.params.id,
            question: currentQ,
            options,
            correctAnswer: 'A', // Assume A for simplicity
          });
          await quiz.save();
          quizzes.push(quiz);
        }
        currentQ = line.substring(3);
        options = [];
      } else if (line.startsWith('A') || line.startsWith('B') || line.startsWith('C') || line.startsWith('D')) {
        options.push(line.substring(3));
      }
    }
    // Last one
    if (currentQ) {
      const quiz = new Quiz({
        userId: req.user.id,
        documentId: req.params.id,
        question: currentQ,
        options,
        correctAnswer: 'A',
      });
      await quiz.save();
      quizzes.push(quiz);
    }

    res.json(quizzes);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Get quizzes for document
router.get('/:id', auth, async (req, res) => {
  try {
    const quizzes = await Quiz.find({ documentId: req.params.id, userId: req.user.id });
    res.json(quizzes);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
