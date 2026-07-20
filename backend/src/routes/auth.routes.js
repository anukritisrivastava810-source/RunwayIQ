import { Router } from 'express';
import { login, registerFounder, logout } from '../controllers/auth.controller.js';

const router = Router();

router.post('/login', login);
router.post('/register', registerFounder);
router.post('/logout', logout);

export default router;
