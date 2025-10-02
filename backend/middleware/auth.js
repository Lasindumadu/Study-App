const jwt = require('jsonwebtoken');

const jwtSecret = process.env.JWT_SECRET || 'your_jwt_secret';

function auth(req, res, next) {
  let token = req.header('x-auth-token');

  if (!token) {
    // Try to get token from Authorization header
    const authHeader = req.header('Authorization') || req.header('authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
      token = authHeader.substring(7, authHeader.length);
    }
  }

  if (!token) {
    return res.status(401).json({ msg: 'No token, authorization denied' });
  }

  try {
    const decoded = jwt.verify(token, jwtSecret);
    req.user = decoded.user;
    next();
  } catch (err) {
    res.status(401).json({ msg: 'Token is not valid' });
  }
}

module.exports = auth;
