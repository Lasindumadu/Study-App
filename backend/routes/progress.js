const express = require('express');
const Progress = require('../models/Progress.js');
const auth = require('../middleware/auth.js');

const router = express.Router();

// Save quiz progress
router.post('/', auth, async (req, res) => {
  const { quizId, score, totalQuestions } = req.body;
  try {
    const progress = new Progress({
      userId: req.user.id,
      quizId,
      score,
      totalQuestions,
    });
    await progress.save();
    res.json(progress);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// Get user's progress
router.get('/', auth, async (req, res) => {
  try {
    const progress = await Progress.find({ userId: req.user.id }).populate('quizId');
    res.json(progress);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
