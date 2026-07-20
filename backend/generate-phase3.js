import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const SRC_DIR = path.join(__dirname, 'src');

const filesToCreate = [];

// 1. Create directories
['controllers', 'routes', 'middleware', 'services', 'repositories'].forEach(dir => {
  const dirPath = path.join(SRC_DIR, dir);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
});

// 2. Auth & User Repository/Service (since they were not in phase 2 but are needed now)
filesToCreate.push({
  path: 'repositories/user.repository.js',
  content: "import prisma from '../config/prisma.js';\n\nexport class UserRepository {\n  async create(data) {\n    return await prisma.user.create({ data });\n  }\n\n  async findByEmail(email) {\n    return await prisma.user.findUnique({ where: { email } });\n  }\n\n  async findById(id) {\n    return await prisma.user.findUnique({ where: { id } });\n  }\n}\n"
});

filesToCreate.push({
  path: 'services/auth.service.js',
  content: "import { UserRepository } from '../repositories/user.repository.js';\nimport bcrypt from 'bcryptjs';\nimport jwt from 'jsonwebtoken';\nimport { ApiError } from '../utils/ApiError.js';\n\nconst userRepository = new UserRepository();\n\nexport class AuthService {\n  async registerFounder(data) {\n    const existingUser = await userRepository.findByEmail(data.email);\n    if (existingUser) throw new ApiError(400, 'User already exists');\n\n    const passwordHash = await bcrypt.hash(data.password, 10);\n    const user = await userRepository.create({\n      companyId: data.companyId,\n      email: data.email,\n      passwordHash,\n      firstName: data.firstName,\n      lastName: data.lastName,\n      role: 'FOUNDER',\n    });\n    \n    const { passwordHash: _, ...userWithoutPassword } = user;\n    return userWithoutPassword;\n  }\n\n  async login(email, password) {\n    const user = await userRepository.findByEmail(email);\n    if (!user) throw new ApiError(401, 'Invalid credentials');\n\n    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);\n    if (!isPasswordValid) throw new ApiError(401, 'Invalid credentials');\n\n    const token = jwt.sign(\n      { id: user.id, email: user.email, role: user.role, companyId: user.companyId },\n      process.env.JWT_SECRET || 'supersecret',\n      { expiresIn: '1d' }\n    );\n\n    const { passwordHash: _, ...userWithoutPassword } = user;\n    return { user: userWithoutPassword, token };\n  }\n}\n"
});


// 3. Middleware
filesToCreate.push({
  path: 'middleware/auth.middleware.js',
  content: "import jwt from 'jsonwebtoken';\nimport { ApiError } from '../utils/ApiError.js';\nimport { asyncHandler } from './asyncHandler.js';\n\nexport const authenticateUser = asyncHandler(async (req, res, next) => {\n  let token;\n  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {\n    token = req.headers.authorization.split(' ')[1];\n  }\n\n  if (!token) {\n    return next(new ApiError(401, 'Not authorized to access this route'));\n  }\n\n  try {\n    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'supersecret');\n    req.user = decoded;\n    next();\n  } catch (err) {\n    return next(new ApiError(401, 'Not authorized to access this route'));\n  }\n});\n"
});

filesToCreate.push({
  path: 'middleware/role.middleware.js',
  content: "import { ApiError } from '../utils/ApiError.js';\n\nexport const authorizeRoles = (...roles) => {\n  return (req, res, next) => {\n    if (!req.user || !roles.includes(req.user.role)) {\n      return next(new ApiError(403, 'User role is not authorized to access this route'));\n    }\n    next();\n  };\n};\n"
});

// 4. Auth Controller & Routes
filesToCreate.push({
  path: 'controllers/auth.controller.js',
  content: "import { AuthService } from '../services/auth.service.js';\nimport { ApiResponse } from '../utils/ApiResponse.js';\nimport { asyncHandler } from '../middleware/asyncHandler.js';\n\nconst authService = new AuthService();\n\nexport const login = asyncHandler(async (req, res) => {\n  const { email, password } = req.body;\n  const data = await authService.login(email, password);\n  res.status(200).json(new ApiResponse(200, data, 'Login successful'));\n});\n\nexport const registerFounder = asyncHandler(async (req, res) => {\n  const data = await authService.registerFounder(req.body);\n  res.status(201).json(new ApiResponse(201, data, 'Founder registered successfully'));\n});\n\nexport const logout = asyncHandler(async (req, res) => {\n  res.status(200).json(new ApiResponse(200, null, 'Logout successful'));\n});\n"
});

filesToCreate.push({
  path: 'routes/auth.routes.js',
  content: "import { Router } from 'express';\nimport { login, registerFounder, logout } from '../controllers/auth.controller.js';\n\nconst router = Router();\n\nrouter.post('/login', login);\nrouter.post('/register', registerFounder);\nrouter.post('/logout', logout);\n\nexport default router;\n"
});

// 5. CRUD Controllers & Routes
const entities = [
  'company', 'employee', 'department', 'expense',
  'investor', 'funding', 'treasury', 'scenario'
];

entities.forEach(entity => {
  const modelName = entity.charAt(0).toUpperCase() + entity.slice(1);
  const serviceName = modelName + 'Service';
  const instanceName = entity + 'Service';
  
  filesToCreate.push({
    path: `controllers/${entity}.controller.js`,
    content: `import { ${serviceName} } from '../services/${entity}.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const ${instanceName} = new ${serviceName}();

export const get${modelName}s = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10 } = req.query;
  const data = await ${instanceName}.getAll${modelName}s(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, '${modelName}s retrieved successfully'));
});

export const get${modelName}ById = asyncHandler(async (req, res) => {
  const data = await ${instanceName}.get${modelName}ById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, '${modelName} retrieved successfully'));
});

export const create${modelName} = asyncHandler(async (req, res) => {
  const data = await ${instanceName}.create${modelName}(req.body);
  res.status(201).json(new ApiResponse(201, data, '${modelName} created successfully'));
});

export const update${modelName} = asyncHandler(async (req, res) => {
  const data = await ${instanceName}.update${modelName}(req.params.id, req.body);
  res.status(200).json(new ApiResponse(200, data, '${modelName} updated successfully'));
});

export const delete${modelName} = asyncHandler(async (req, res) => {
  await ${instanceName}.delete${modelName}(req.params.id);
  res.status(200).json(new ApiResponse(200, null, '${modelName} deleted successfully'));
});
`
  });

  filesToCreate.push({
    path: `routes/${entity}.routes.js`,
    content: `import { Router } from 'express';
import { get${modelName}s, get${modelName}ById, create${modelName}, update${modelName}, delete${modelName} } from '../controllers/${entity}.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authenticateUser);

router.get('/', get${modelName}s);
router.get('/:id', get${modelName}ById);
router.post('/', create${modelName});
router.put('/:id', update${modelName});
router.delete('/:id', delete${modelName});

export default router;
`
  });
});

// 6. Dashboard Controller & Routes
filesToCreate.push({
  path: 'controllers/dashboard.controller.js',
  content: `import { DashboardService } from '../services/dashboard.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const dashboardService = new DashboardService();

export const getDashboard = asyncHandler(async (req, res) => {
  const data = await dashboardService.getDashboard(req.user.companyId);
  res.status(200).json(new ApiResponse(200, data, 'Dashboard retrieved successfully'));
});

export const getSummary = asyncHandler(async (req, res) => {
  const data = await dashboardService.getFundingSummary(req.user.companyId);
  res.status(200).json(new ApiResponse(200, data, 'Summary retrieved successfully'));
});

export const getRunway = asyncHandler(async (req, res) => {
  const data = await dashboardService.getRunway(req.user.companyId);
  res.status(200).json(new ApiResponse(200, { runway: data }, 'Runway retrieved successfully'));
});

export const getBurnRate = asyncHandler(async (req, res) => {
  const data = await dashboardService.getBurnRate(req.user.companyId);
  res.status(200).json(new ApiResponse(200, { burnRate: data }, 'Burn rate retrieved successfully'));
});

export const getPayroll = asyncHandler(async (req, res) => {
  res.status(200).json(new ApiResponse(200, {}, 'Payroll retrieved successfully'));
});
`
});

filesToCreate.push({
  path: 'routes/dashboard.routes.js',
  content: `import { Router } from 'express';
import { getDashboard, getSummary, getRunway, getBurnRate, getPayroll } from '../controllers/dashboard.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authenticateUser);

router.get('/', getDashboard);
router.get('/summary', getSummary);
router.get('/runway', getRunway);
router.get('/burn-rate', getBurnRate);
router.get('/payroll', getPayroll);

export default router;
`
});

// 7. Index Routes
filesToCreate.push({
  path: 'routes/index.js',
  content: `import { Router } from 'express';
import authRoutes from './auth.routes.js';
import companyRoutes from './company.routes.js';
import dashboardRoutes from './dashboard.routes.js';
import employeeRoutes from './employee.routes.js';
import departmentRoutes from './department.routes.js';
import expenseRoutes from './expense.routes.js';
import investorRoutes from './investor.routes.js';
import fundingRoutes from './funding.routes.js';
import treasuryRoutes from './treasury.routes.js';
import scenarioRoutes from './scenario.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/companies', companyRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/employees', employeeRoutes);
router.use('/departments', departmentRoutes);
router.use('/expenses', expenseRoutes);
router.use('/investors', investorRoutes);
router.use('/funding', fundingRoutes);
router.use('/treasury', treasuryRoutes);
router.use('/scenarios', scenarioRoutes);

export default router;
`
});

// Write all generated files
filesToCreate.forEach(file => {
  const fullPath = path.join(SRC_DIR, file.path);
  const dir = path.dirname(fullPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(fullPath, file.content, 'utf-8');
});

console.log('Successfully generated Phase 3 files.');
