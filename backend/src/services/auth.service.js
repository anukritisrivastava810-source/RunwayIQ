import { UserRepository } from '../repositories/user.repository.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { ApiError } from '../utils/ApiError.js';

const userRepository = new UserRepository();

export class AuthService {
  async registerFounder(data) {
    const existingUser = await userRepository.findByEmail(data.email);
    if (existingUser) throw new ApiError(400, 'User already exists');

    const passwordHash = await bcrypt.hash(data.password, 10);
    const user = await userRepository.create({
      companyId: data.companyId,
      email: data.email,
      passwordHash,
      firstName: data.firstName,
      lastName: data.lastName,
      role: 'FOUNDER',
    });
    
    const { passwordHash: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  async login(email, password) {
    const user = await userRepository.findByEmail(email);
    if (!user) throw new ApiError(401, 'Invalid credentials');

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) throw new ApiError(401, 'Invalid credentials');

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role, companyId: user.companyId },
      process.env.JWT_SECRET || 'supersecret',
      { expiresIn: '1d' }
    );

    const { passwordHash: _, ...userWithoutPassword } = user;
    return { user: userWithoutPassword, token };
  }
}
