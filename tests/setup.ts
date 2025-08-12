import { config } from 'dotenv';

// Load test environment variables
config({ path: '.env.test' });

// Set default test environment variables if not provided
process.env.OPENAI_API_KEY = process.env.OPENAI_API_KEY || 'sk-test-key';
process.env.GPT5_DEFAULT_MODEL = process.env.GPT5_DEFAULT_MODEL || 'gpt-5-nano';
process.env.LOG_LEVEL = process.env.LOG_LEVEL || 'error';
process.env.LOG_REQUESTS = process.env.LOG_REQUESTS || 'false';
process.env.LOG_RESPONSES = process.env.LOG_RESPONSES || 'false';

// Global test timeout
jest.setTimeout(30000);

// Mock console methods to reduce test noise
const originalConsoleLog = console.log;
const originalConsoleWarn = console.warn;
const originalConsoleError = console.error;

beforeAll(() => {
  console.log = jest.fn();
  console.warn = jest.fn();
  console.error = jest.fn();
});

afterAll(() => {
  console.log = originalConsoleLog;
  console.warn = originalConsoleWarn;
  console.error = originalConsoleError;
});