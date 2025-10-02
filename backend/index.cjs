const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db.js');
const app = express();
const port = process.env.PORT || 3000;

// Connect Database
connectDB();

const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 204,
};

app.use(cors(corsOptions)); // Enable CORS with options
app.use(express.json());

// Define routes
const authRoutes = require('./routes/auth.js');
const documentRoutes = require('./routes/documents.js');
const summarizeRoutes = require('./routes/summarize.js');
const flashcardRoutes = require('./routes/flashcards.js');
const quizRoutes = require('./routes/quizzes.js');
const progressRoutes = require('./routes/progress.js');
app.use('/api/auth', authRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/summarize', summarizeRoutes);
app.use('/api/flashcards', flashcardRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/progress', progressRoutes);

app.get('/', (req, res) => {
  res.send('AI Study Buddy Backend is running');
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
