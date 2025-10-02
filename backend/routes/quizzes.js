const express = require('express');
const { HfInference } = require('@huggingface/inference');
const Document = require('../models/Document.js');
const Quiz = require('../models/Quiz.js');
const auth = require('../middleware/auth.js');

const router = express.Router();

const hf = new HfInference(process.env.HF_TOKEN);

// Generate quizzes
router.post('/generate/:id', auth, async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);
    if (!document || document.userId.toString() !== req.user.id) {
      return res.status(404).json({ msg: 'Document not found' });
    }

    if (!document.text || document.text.trim() === '') {
      return res.status(400).json({ msg: 'Document has no text to generate quizzes' });
    }

    const MAX_CHARS = 500; // safe cutoff for gpt2
    const inputText = document.text.slice(0, MAX_CHARS);

    const prompt = `Generate 5 multiple-choice questions from the following text. Each question should have 4 options (A, B, C, D) and indicate the correct answer. Format as JSON: {"question": "Question text", "options": ["A. Option1", "B. Option2", "C. Option3", "D. Option4"], "correctAnswer": "A"}\n\nText:\n${inputText}\n\nOutput as a JSON array of objects.`;

    const response = await hf.textGeneration({
      model: 'gpt2',
      inputs: prompt,
      parameters: { max_length: 1500 }
    });

    const generatedText = response.generated_text;
    console.log('Generated quizzes text:', generatedText);

    // Try to parse as JSON
    let quizzesData = [];
    try {
      const jsonMatch = generatedText.match(/\[.*\]/s);
      if (jsonMatch) {
        quizzesData = JSON.parse(jsonMatch[0]);
      } else {
        // Fallback parsing
        const parts = generatedText.split(/Q\d*:/).slice(1);
        for (let part of parts) {
          const lines = part.split('\n');
          let question = '';
          let options = [];
          let correctAnswer = 'A';
          for (let line of lines) {
            if (line.trim()) {
              if (!question) {
                question = line.trim();
              } else if (line.match(/^[A-D]\d*:/)) {
                options.push(line.trim());
              } else if (line.startsWith('Correct')) {
                correctAnswer = line.split(':')[1].trim();
              }
            }
          }
          if (question && options.length >= 4) {
            quizzesData.push({ question, options: options.slice(0, 4), correctAnswer });
          }
        }
      }
    } catch (parseErr) {
      console.error('Parsing error:', parseErr);
      // Simple fallback
      quizzesData = [
        { question: 'Sample Question 1', options: ['A. Option1', 'B. Option2', 'C. Option3', 'D. Option4'], correctAnswer: 'A' },
        { question: 'Sample Question 2', options: ['A. Option1', 'B. Option2', 'C. Option3', 'D. Option4'], correctAnswer: 'B' },
      ];
    }

    const quizzes = [];
    for (let item of quizzesData.slice(0, 5)) { // Limit to 5
      const quiz = new Quiz({
        userId: req.user.id,
        documentId: req.params.id,
        question: item.question || 'Question',
        options: item.options || ['A. Option1', 'B. Option2', 'C. Option3', 'D. Option4'],
        correctAnswer: item.correctAnswer || 'A',
      });
      await quiz.save();
      quizzes.push(quiz);
    }

    res.json(quizzes);
  } catch (err) {
    console.error('Quizzes generate error:', err);
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
