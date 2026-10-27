import 'dotenv/config';
import request from 'supertest';
import app from '../src/app.js';
import prisma from '../src/config/prisma.js';

let passedCount = 0;
let failedCount = 0;
const testResults = [];

function assert(condition, message) {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

async function runTest(testName, fn) {
  process.stdout.write(`  • ${testName}... `);
  try {
    await fn();
    passedCount++;
    testResults.push({ name: testName, status: 'PASSED' });
    console.log('✅ PASS');
  } catch (error) {
    failedCount++;
    testResults.push({ name: testName, status: 'FAILED', error: error.message });
    console.log(`❌ FAIL\n    Error: ${error.message}`);
  }
}

async function main() {
  console.log('\n======================================================');
  console.log('🧪 RUNNING EMPLOYEE BACKEND CRUD INTEGRATION TEST SUITE');
  console.log('======================================================\n');

  // Setup: Find or create a test company and department
  const existingCompany = await prisma.company.findFirst();
  assert(existingCompany, 'A company must exist in the database for testing');
  const companyId = existingCompany.id;

  let testDept = await prisma.department.findFirst({ where: { companyId } });
  if (!testDept) {
    testDept = await prisma.department.create({
      data: { companyId, name: `Dept_Test_${Date.now()}` }
    });
  }
  const departmentId = testDept.id;

  console.log(`📌 Test Company: "${existingCompany.name}" (${companyId})`);
  console.log(`📌 Test Department: "${testDept.name}" (${departmentId})\n`);

  let createdEmployeeId = null;
  let secondEmployeeId = null;
  const uniqueTimestamp = Date.now();
  const testEmail1 = `emp1_${uniqueTimestamp}@runwayiq.test`;
  const testEmail2 = `emp2_${uniqueTimestamp}@runwayiq.test`;

  console.log('--- 1. POST /api/v1/employee (Create Employee) ---');

  await runTest('Create employee with valid data and explicit departmentId', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        companyId,
        departmentId,
        firstName: 'Alex',
        lastName: 'Morgan',
        email: testEmail1,
        role: 'Staff Engineer',
        annualSalary: 155000,
        currency: 'USD',
        status: 'ACTIVE',
        joinedAt: '2026-02-01T00:00:00.000Z'
      });

    assert(res.status === 201, `Expected status 201, got ${res.status}: ${JSON.stringify(res.body)}`);
    assert(res.body.id, 'Expected response to have employee ID');
    assert(res.body.firstName === 'Alex', 'Expected firstName to match');
    assert(res.body.lastName === 'Morgan', 'Expected lastName to match');
    assert(res.body.email === testEmail1, 'Expected email to match');
    assert(res.body.role === 'Staff Engineer', 'Expected role to match');
    assert(Number(res.body.annualSalary) === 155000, 'Expected annualSalary to match');
    assert(res.body.department && res.body.department.id === departmentId, 'Expected department relation to be populated');

    createdEmployeeId = res.body.id;

    // Verify in PostgreSQL via Prisma
    const dbRecord = await prisma.employee.findUnique({
      where: { id: createdEmployeeId },
      include: { department: true, company: true }
    });
    assert(dbRecord !== null, 'Employee record must exist in PostgreSQL');
    assert(dbRecord.companyId === companyId, 'PostgreSQL record companyId mismatch');
    assert(dbRecord.company.id === companyId, 'Company relationship mismatch');
    assert(dbRecord.departmentId === departmentId, 'PostgreSQL record departmentId mismatch');
    assert(dbRecord.department.id === departmentId, 'Department relationship mismatch');
  });

  await runTest('Create employee with dual route (/api/v1/employees) and auto-department resolution', async () => {
    const res = await request(app)
      .post('/api/v1/employees')
      .send({
        companyId,
        // departmentId omitted -> must auto-assign or find department
        firstName: 'Jordan',
        lastName: 'Taylor',
        email: testEmail2,
        role: 'Product Designer',
        annualSalary: 110000,
        currency: 'USD',
        status: 'ACTIVE',
        joinedAt: '2026-03-01T00:00:00.000Z'
      });

    assert(res.status === 201, `Expected 201, got ${res.status}: ${JSON.stringify(res.body)}`);
    assert(res.body.id, 'Expected employee ID');
    assert(res.body.departmentId, 'Expected departmentId to be auto-assigned');
    assert(res.body.department, 'Expected department relation');

    secondEmployeeId = res.body.id;

    // Verify in PostgreSQL
    const dbRecord = await prisma.employee.findUnique({
      where: { id: secondEmployeeId }
    });
    assert(dbRecord !== null, 'Employee must exist in PostgreSQL');
    assert(dbRecord.companyId === companyId, 'companyId must match');
  });

  console.log('\n--- 2. GET /api/v1/employee/:id (Get Employee by ID) ---');

  await runTest('Retrieve employee by ID returns correct record and 200 status', async () => {
    const res = await request(app).get(`/api/v1/employee/${createdEmployeeId}`);
    assert(res.status === 200, `Expected 200, got ${res.status}`);
    assert(res.body.id === createdEmployeeId, 'Expected matching ID');
    assert(res.body.email === testEmail1, 'Expected matching email');
    assert(res.body.department !== undefined, 'Expected department included');
  });

  await runTest('Retrieve employee by ID via dual route (/api/v1/employees/:id)', async () => {
    const res = await request(app).get(`/api/v1/employees/${createdEmployeeId}`);
    assert(res.status === 200, `Expected 200, got ${res.status}`);
    assert(res.body.id === createdEmployeeId, 'Expected matching ID');
  });

  console.log('\n--- 3. GET /api/v1/employee/company/:companyId (Get Employees by Company) ---');

  await runTest('Retrieve employees by companyId ensures route precedence and filters correctly', async () => {
    const res = await request(app).get(`/api/v1/employee/company/${companyId}`);
    assert(res.status === 200, `Expected 200, got ${res.status}`);
    assert(Array.isArray(res.body), 'Expected array response');
    const hasEmployee1 = res.body.some(e => e.id === createdEmployeeId);
    const hasEmployee2 = res.body.some(e => e.id === secondEmployeeId);
    assert(hasEmployee1 && hasEmployee2, 'Expected both created employees in list');
    // Verify each has matching companyId
    assert(res.body.every(e => e.companyId === companyId), 'All returned employees must belong to companyId');
  });

  await runTest('Retrieve employees by companyId via dual route (/api/v1/employees/company/:companyId)', async () => {
    const res = await request(app).get(`/api/v1/employees/company/${companyId}`);
    assert(res.status === 200, `Expected 200, got ${res.status}`);
    assert(Array.isArray(res.body), 'Expected array response');
    assert(res.body.some(e => e.id === createdEmployeeId), 'Expected employee present');
  });

  console.log('\n--- 4. GET /api/v1/employee (Get All Employees) ---');

  await runTest('Retrieve all employees returns array containing created employees', async () => {
    const res = await request(app).get('/api/v1/employee');
    assert(res.status === 200, `Expected 200, got ${res.status}`);
    assert(Array.isArray(res.body), 'Expected array');
    assert(res.body.some(e => e.id === createdEmployeeId), 'Employee must be present in all employees list');
  });

  await runTest('Retrieve all employees with companyId query filter', async () => {
    const res = await request(app).get(`/api/v1/employee?companyId=${companyId}`);
    assert(res.status === 200, `Expected 200, got ${res.status}`);
    assert(Array.isArray(res.body), 'Expected array');
    assert(res.body.every(e => e.companyId === companyId), 'Query filter must only return company employees');
  });

  console.log('\n--- 5. PUT /api/v1/employee/:id (Update Employee) ---');

  await runTest('Update employee role and salary persists in PostgreSQL', async () => {
    const updatePayload = {
      role: 'Principal Engineer',
      annualSalary: 195000,
      status: 'NOTICE'
    };

    const res = await request(app)
      .put(`/api/v1/employee/${createdEmployeeId}`)
      .send(updatePayload);

    assert(res.status === 200, `Expected 200, got ${res.status}`);
    assert(res.body.role === 'Principal Engineer', 'Expected role to be updated');
    assert(Number(res.body.annualSalary) === 195000, 'Expected salary to be updated');
    assert(res.body.status === 'NOTICE', 'Expected status to be updated');

    // Verify in PostgreSQL
    const dbRecord = await prisma.employee.findUnique({
      where: { id: createdEmployeeId }
    });
    assert(dbRecord.role === 'Principal Engineer', 'PostgreSQL role must match update');
    assert(Number(dbRecord.annualSalary) === 195000, 'PostgreSQL salary must match update');
    assert(dbRecord.status === 'NOTICE', 'PostgreSQL status must match update');
  });

  console.log('\n--- 6. Error Cases & Validation ---');

  await runTest('Missing required fields on create returns 400 Bad Request', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        companyId,
        firstName: 'Incomplete'
        // Missing lastName, email, role, annualSalary
      });

    assert(res.status === 400, `Expected 400, got ${res.status}`);
    assert(res.body.success === false, 'Expected success: false');
    assert(res.body.message.includes('required'), 'Expected error message mentioning required fields');
  });

  await runTest('Missing companyId on create returns 400 Bad Request', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        firstName: 'No',
        lastName: 'Company',
        email: `nocomp_${Date.now()}@test.com`,
        role: 'Intern',
        annualSalary: 50000
      });

    assert(res.status === 400, `Expected 400, got ${res.status}`);
  });

  await runTest('Nonexistent companyId on create returns 404 Not Found', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        companyId: '00000000-0000-0000-0000-000000000000',
        firstName: 'Ghost',
        lastName: 'Worker',
        email: `ghost_${Date.now()}@test.com`,
        role: 'Ghost',
        annualSalary: 60000
      });

    assert(res.status === 404, `Expected 404, got ${res.status}`);
    assert(res.body.message.includes('Company not found'), 'Expected "Company not found"');
  });

  await runTest('Nonexistent companyId on GET /company/:companyId returns 404', async () => {
    const res = await request(app).get('/api/v1/employee/company/00000000-0000-0000-0000-000000000000');
    assert(res.status === 404, `Expected 404, got ${res.status}`);
    assert(res.body.message.includes('Company not found'), 'Expected "Company not found"');
  });

  await runTest('Invalid/nonexistent employee ID on GET returns 404', async () => {
    const res = await request(app).get('/api/v1/employee/00000000-0000-0000-0000-000000000000');
    assert(res.status === 404, `Expected 404, got ${res.status}`);
    assert(res.body.message.includes('Employee not found'), 'Expected "Employee not found"');
  });

  await runTest('Invalid/nonexistent employee ID on PUT returns 404', async () => {
    const res = await request(app)
      .put('/api/v1/employee/00000000-0000-0000-0000-000000000000')
      .send({ role: 'Nobody' });
    assert(res.status === 404, `Expected 404, got ${res.status}`);
  });

  await runTest('Invalid/nonexistent employee ID on DELETE returns 404', async () => {
    const res = await request(app).delete('/api/v1/employee/00000000-0000-0000-0000-000000000000');
    assert(res.status === 404, `Expected 404, got ${res.status}`);
  });

  await runTest('Negative annualSalary returns 400 Bad Request', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        companyId,
        firstName: 'Bad',
        lastName: 'Salary',
        email: `badsal_${Date.now()}@test.com`,
        role: 'Tester',
        annualSalary: -1000
      });

    assert(res.status === 400, `Expected 400, got ${res.status}`);
    assert(res.body.message.includes('annualSalary'), 'Expected error on annualSalary');
  });

  await runTest('Non-numeric annualSalary returns 400 Bad Request', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        companyId,
        firstName: 'Bad',
        lastName: 'SalaryText',
        email: `badsal2_${Date.now()}@test.com`,
        role: 'Tester',
        annualSalary: 'one-million'
      });

    assert(res.status === 400, `Expected 400, got ${res.status}`);
  });

  await runTest('Invalid date format for joinedAt returns 400 Bad Request', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        companyId,
        firstName: 'Bad',
        lastName: 'Date',
        email: `baddate_${Date.now()}@test.com`,
        role: 'Tester',
        annualSalary: 80000,
        joinedAt: 'yesterday'
      });

    assert(res.status === 400, `Expected 400, got ${res.status}`);
    assert(res.body.message.includes('joinedAt'), 'Expected error on joinedAt');
  });

  await runTest('Invalid date format for exitedAt returns 400 Bad Request', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        companyId,
        firstName: 'Bad',
        lastName: 'ExitDate',
        email: `badexit_${Date.now()}@test.com`,
        role: 'Tester',
        annualSalary: 80000,
        exitedAt: 'invalid-date'
      });

    assert(res.status === 400, `Expected 400, got ${res.status}`);
    assert(res.body.message.includes('exitedAt'), 'Expected error on exitedAt');
  });

  await runTest('Nonexistent departmentId returns 404 Department not found', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        companyId,
        departmentId: '00000000-0000-0000-0000-000000000000',
        firstName: 'Bad',
        lastName: 'Dept',
        email: `baddept_${Date.now()}@test.com`,
        role: 'Tester',
        annualSalary: 80000
      });

    assert(res.status === 404, `Expected 404, got ${res.status}`);
    assert(res.body.message.includes('Department not found'), 'Expected "Department not found"');
  });

  await runTest('Duplicate email on create returns 400 Bad Request', async () => {
    const res = await request(app)
      .post('/api/v1/employee')
      .send({
        companyId,
        firstName: 'Duplicate',
        lastName: 'Email',
        email: testEmail1, // already used by first employee
        role: 'Tester',
        annualSalary: 90000
      });

    assert(res.status === 400, `Expected 400, got ${res.status}`);
    assert(res.body.message.includes('already exists'), 'Expected email already exists error');
  });

  await runTest('Duplicate email on update returns 400 Bad Request', async () => {
    // Attempt to update second employee's email to testEmail1
    const res = await request(app)
      .put(`/api/v1/employee/${secondEmployeeId}`)
      .send({
        email: testEmail1
      });

    assert(res.status === 400, `Expected 400, got ${res.status}`);
    assert(res.body.message.includes('already exists'), 'Expected email already exists error');
  });

  console.log('\n--- 7. Company → Employee & Department → Employee Relations in PostgreSQL ---');

  await runTest('Company relation query returns employee in company.employees', async () => {
    const companyWithEmployees = await prisma.company.findUnique({
      where: { id: companyId },
      include: { employees: true }
    });

    assert(companyWithEmployees !== null, 'Company must exist');
    const found = companyWithEmployees.employees.some(e => e.id === createdEmployeeId);
    assert(found, 'Created employee must be part of company.employees relation');
  });

  await runTest('Department relation query returns employee in department.employees', async () => {
    const deptWithEmployees = await prisma.department.findUnique({
      where: { id: departmentId },
      include: { employees: true }
    });

    assert(deptWithEmployees !== null, 'Department must exist');
    const found = deptWithEmployees.employees.some(e => e.id === createdEmployeeId);
    assert(found, 'Created employee must be part of department.employees relation');
  });

  console.log('\n--- 8. DELETE /api/v1/employee/:id (Delete Employee & Verify PostgreSQL) ---');

  await runTest('Delete first employee via /api/v1/employee/:id succeeds with 200', async () => {
    const res = await request(app).delete(`/api/v1/employee/${createdEmployeeId}`);
    assert(res.status === 200, `Expected 200, got ${res.status}`);
    assert(res.body.success === true, 'Expected success: true');
  });

  await runTest('Deleted employee is completely removed from PostgreSQL', async () => {
    const dbRecord = await prisma.employee.findUnique({
      where: { id: createdEmployeeId }
    });
    assert(dbRecord === null, 'Employee must no longer exist in PostgreSQL');
  });

  await runTest('GET on deleted employee returns 404 Not Found', async () => {
    const res = await request(app).get(`/api/v1/employee/${createdEmployeeId}`);
    assert(res.status === 404, `Expected 404, got ${res.status}`);
  });

  await runTest('Delete second employee via dual route /api/v1/employees/:id succeeds', async () => {
    const res = await request(app).delete(`/api/v1/employees/${secondEmployeeId}`);
    assert(res.status === 200, `Expected 200, got ${res.status}`);

    const dbRecord = await prisma.employee.findUnique({
      where: { id: secondEmployeeId }
    });
    assert(dbRecord === null, 'Second employee must be deleted from PostgreSQL');
  });

  await runTest('Company and Department remain intact after employee deletions', async () => {
    const companyAfter = await prisma.company.findUnique({ where: { id: companyId } });
    const deptAfter = await prisma.department.findUnique({ where: { id: departmentId } });
    assert(companyAfter !== null, 'Company must still exist');
    assert(deptAfter !== null, 'Department must still exist');
  });

  console.log('\n======================================================');
  console.log(`📊 TEST RESULTS: ${passedCount} PASSED, ${failedCount} FAILED (${passedCount + failedCount} TOTAL)`);
  console.log('======================================================\n');

  await prisma.$disconnect();

  if (failedCount > 0) {
    process.exit(1);
  }
}

main().catch(async (err) => {
  console.error('\n💥 FATAL ERROR during test execution:', err);
  await prisma.$disconnect();
  process.exit(1);
});
