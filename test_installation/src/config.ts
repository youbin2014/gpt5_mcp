import { config } from 'dotenv';
import { readFileSync } from 'fs';
import { join } from 'path';
import { ServerConfig, ConfigurationError } from './types.js';

// Load environment variables
config();

/**
 * Load configuration from environment variables and config files
 */
export function loadConfiguration(): ServerConfig {
  try {
    // Load default configuration
    const defaultConfig = loadDefaultConfig();
    
    // Override with environment variables
    const serverConfig: ServerConfig = {
      openai: {
        apiKey: getRequiredEnvVar('OPENAI_API_KEY'),
        baseURL: process.env.OPENAI_BASE_URL,
        defaultModel: (process.env.GPT5_DEFAULT_MODEL as any) || defaultConfig.openai.defaultModel,
        timeout: parseInt(process.env.OPENAI_TIMEOUT || '60000'),
      },
      server: {
        name: process.env.SERVER_NAME || defaultConfig.server.name,
        version: defaultConfig.server.version,
        maxRetries: parseInt(process.env.MAX_RETRIES || '3'),
        retryDelay: parseInt(process.env.RETRY_DELAY || '1000'),
      },
      logging: {
        level: (process.env.LOG_LEVEL as any) || defaultConfig.logging.level,
        logRequests: process.env.LOG_REQUESTS === 'true',
        logResponses: process.env.LOG_RESPONSES === 'true',
      },
    };

    // Validate configuration
    validateConfiguration(serverConfig);
    
    return serverConfig;
  } catch (error) {
    throw new ConfigurationError(
      `Failed to load configuration: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}

/**
 * Load default configuration from config file
 */
function loadDefaultConfig(): ServerConfig {
  try {
    const configPath = join(process.cwd(), 'config', 'default.json');
    const configFile = readFileSync(configPath, 'utf-8');
    return JSON.parse(configFile);
  } catch (error) {
    // If config file doesn't exist, use hardcoded defaults
    console.warn('⚠️ Could not load config file, using defaults');
    
    return {
      openai: {
        apiKey: '', // Must be provided via env var
        baseURL: undefined,
        defaultModel: 'gpt-5',
        timeout: 60000,
      },
      server: {
        name: 'gpt5-claude-mcp',
        version: '1.0.0',
        maxRetries: 3,
        retryDelay: 1000,
      },
      logging: {
        level: 'info',
        logRequests: false,
        logResponses: false,
      },
    };
  }
}

/**
 * Get required environment variable or throw error
 */
function getRequiredEnvVar(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new ConfigurationError(
      `Required environment variable ${name} is not set. ` +
      `Please set it in your environment or .env file.`
    );
  }
  return value;
}

/**
 * Validate configuration object
 */
function validateConfiguration(config: ServerConfig): void {
  // Validate OpenAI configuration
  if (!config.openai.apiKey) {
    throw new ConfigurationError('OpenAI API key is required');
  }
  
  if (!config.openai.apiKey.startsWith('sk-')) {
    throw new ConfigurationError('OpenAI API key appears to be invalid (should start with "sk-")');
  }
  
  if (config.openai.timeout < 1000) {
    throw new ConfigurationError('OpenAI timeout must be at least 1000ms');
  }
  
  // Validate server configuration
  if (!config.server.name) {
    throw new ConfigurationError('Server name is required');
  }
  
  if (!config.server.version) {
    throw new ConfigurationError('Server version is required');
  }
  
  if (config.server.maxRetries < 0 || config.server.maxRetries > 10) {
    throw new ConfigurationError('Max retries must be between 0 and 10');
  }
  
  if (config.server.retryDelay < 100) {
    throw new ConfigurationError('Retry delay must be at least 100ms');
  }
  
  // Validate logging configuration
  const validLogLevels = ['debug', 'info', 'warn', 'error'];
  if (!validLogLevels.includes(config.logging.level)) {
    throw new ConfigurationError(`Log level must be one of: ${validLogLevels.join(', ')}`);
  }
}

/**
 * Get configuration summary for logging
 */
export function getConfigSummary(config: ServerConfig): string {
  return `
🔧 Configuration Summary:
  - Server: ${config.server.name} v${config.server.version}
  - Default Model: ${config.openai.defaultModel}
  - Timeout: ${config.openai.timeout}ms
  - Max Retries: ${config.server.maxRetries}
  - Log Level: ${config.logging.level}
  - Request Logging: ${config.logging.logRequests ? 'ON' : 'OFF'}
  - Response Logging: ${config.logging.logResponses ? 'ON' : 'OFF'}
  - Custom Base URL: ${config.openai.baseURL || 'Default'}
`;
}