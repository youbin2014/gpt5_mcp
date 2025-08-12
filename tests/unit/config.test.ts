import { loadConfiguration, getConfigSummary } from '../../src/config.js';
import { ConfigurationError } from '../../src/types.js';

describe('Configuration', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    // Reset environment before each test
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  describe('loadConfiguration', () => {
    it('should load configuration with valid API key', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key-1234567890';

      const config = loadConfiguration();

      expect(config.openai.apiKey).toBe('sk-test-key-1234567890');
      expect(config.openai.defaultModel).toBe('gpt-5');
      expect(config.server.name).toBe('gpt5-claude-mcp');
      expect(config.logging.level).toBe('info');
    });

    it('should throw error for missing API key', () => {
      delete process.env.OPENAI_API_KEY;

      expect(() => loadConfiguration()).toThrow(ConfigurationError);
      expect(() => loadConfiguration()).toThrow('Required environment variable OPENAI_API_KEY is not set');
    });

    it('should throw error for invalid API key format', () => {
      process.env.OPENAI_API_KEY = 'invalid-key-format';

      expect(() => loadConfiguration()).toThrow(ConfigurationError);
      expect(() => loadConfiguration()).toThrow('OpenAI API key appears to be invalid');
    });

    it('should use custom configuration values', () => {
      process.env.OPENAI_API_KEY = 'sk-custom-key';
      process.env.GPT5_DEFAULT_MODEL = 'gpt-5-mini';
      process.env.OPENAI_TIMEOUT = '30000';
      process.env.SERVER_NAME = 'custom-server';
      process.env.LOG_LEVEL = 'debug';
      process.env.LOG_REQUESTS = 'true';
      process.env.MAX_RETRIES = '5';

      const config = loadConfiguration();

      expect(config.openai.apiKey).toBe('sk-custom-key');
      expect(config.openai.defaultModel).toBe('gpt-5-mini');
      expect(config.openai.timeout).toBe(30000);
      expect(config.server.name).toBe('custom-server');
      expect(config.logging.level).toBe('debug');
      expect(config.logging.logRequests).toBe(true);
      expect(config.server.maxRetries).toBe(5);
    });

    it('should validate timeout values', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key';
      process.env.OPENAI_TIMEOUT = '500'; // Too low

      expect(() => loadConfiguration()).toThrow(ConfigurationError);
      expect(() => loadConfiguration()).toThrow('OpenAI timeout must be at least 1000ms');
    });

    it('should validate retry values', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key';
      process.env.MAX_RETRIES = '15'; // Too high

      expect(() => loadConfiguration()).toThrow(ConfigurationError);
      expect(() => loadConfiguration()).toThrow('Max retries must be between 0 and 10');
    });

    it('should validate log level', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key';
      process.env.LOG_LEVEL = 'invalid';

      expect(() => loadConfiguration()).toThrow(ConfigurationError);
      expect(() => loadConfiguration()).toThrow('Log level must be one of: debug, info, warn, error');
    });

    it('should handle optional base URL', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key';
      process.env.OPENAI_BASE_URL = 'https://custom.openai.com/v1';

      const config = loadConfiguration();

      expect(config.openai.baseURL).toBe('https://custom.openai.com/v1');
    });

    it('should parse boolean environment variables correctly', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key';
      process.env.LOG_REQUESTS = 'true';
      process.env.LOG_RESPONSES = 'false';

      const config = loadConfiguration();

      expect(config.logging.logRequests).toBe(true);
      expect(config.logging.logResponses).toBe(false);
    });

    it('should handle missing optional environment variables', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key';
      // Don't set optional variables

      const config = loadConfiguration();

      expect(config.openai.baseURL).toBeUndefined();
      expect(config.logging.logRequests).toBe(false);
      expect(config.logging.logResponses).toBe(false);
    });
  });

  describe('getConfigSummary', () => {
    it('should generate configuration summary', () => {
      const config = {
        openai: {
          apiKey: 'sk-test-key',
          defaultModel: 'gpt-5-mini' as const,
          timeout: 45000,
          baseURL: 'https://custom.api.com/v1',
        },
        server: {
          name: 'test-server',
          version: '2.0.0',
          maxRetries: 2,
          retryDelay: 1500,
        },
        logging: {
          level: 'debug' as const,
          logRequests: true,
          logResponses: false,
        },
      };

      const summary = getConfigSummary(config);

      expect(summary).toContain('test-server v2.0.0');
      expect(summary).toContain('gpt-5-mini');
      expect(summary).toContain('45000ms');
      expect(summary).toContain('Max Retries: 2');
      expect(summary).toContain('Log Level: debug');
      expect(summary).toContain('Request Logging: ON');
      expect(summary).toContain('Response Logging: OFF');
      expect(summary).toContain('https://custom.api.com/v1');
    });

    it('should show default base URL when not configured', () => {
      const config = {
        openai: {
          apiKey: 'sk-test-key',
          defaultModel: 'gpt-5' as const,
          timeout: 60000,
        },
        server: {
          name: 'default-server',
          version: '1.0.0',
          maxRetries: 3,
          retryDelay: 1000,
        },
        logging: {
          level: 'info' as const,
          logRequests: false,
          logResponses: false,
        },
      };

      const summary = getConfigSummary(config);

      expect(summary).toContain('Custom Base URL: Default');
    });
  });

  describe('edge cases', () => {
    it('should handle numeric strings in environment variables', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key';
      process.env.OPENAI_TIMEOUT = '  60000  '; // With spaces
      process.env.MAX_RETRIES = '3.5'; // Float value

      const config = loadConfiguration();

      expect(config.openai.timeout).toBe(60000);
      expect(config.server.maxRetries).toBe(3); // Should parse as integer
    });

    it('should handle empty string environment variables', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key';
      process.env.OPENAI_BASE_URL = ''; // Empty string
      process.env.SERVER_NAME = ''; // Empty string

      const config = loadConfiguration();

      expect(config.openai.baseURL).toBe(''); // Empty string preserved
      expect(config.server.name).toBe(''); // Empty string preserved, will fail validation
    });

    it('should validate empty server name', () => {
      process.env.OPENAI_API_KEY = 'sk-test-key';
      process.env.SERVER_NAME = '';

      expect(() => loadConfiguration()).toThrow(ConfigurationError);
      expect(() => loadConfiguration()).toThrow('Server name is required');
    });
  });
});