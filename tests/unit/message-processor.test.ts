import { MessageProcessor } from '../../src/message-processor.js';
import { ServerConfig, OpenAIResponse, GPT5QueryRequest } from '../../src/types.js';

describe('MessageProcessor', () => {
  let messageProcessor: MessageProcessor;
  let mockConfig: ServerConfig;

  beforeEach(() => {
    mockConfig = {
      openai: {
        apiKey: 'sk-test-key',
        defaultModel: 'gpt-5-nano',
        timeout: 30000,
      },
      server: {
        name: 'test-server',
        version: '1.0.0',
        maxRetries: 3,
        retryDelay: 1000,
      },
      logging: {
        level: 'error',
        logRequests: false,
        logResponses: false,
      },
    };

    messageProcessor = new MessageProcessor(mockConfig);
  });

  describe('validateRequest', () => {
    it('should validate a simple request correctly', () => {
      const rawRequest = {
        prompt: 'Test prompt',
      };

      const result = messageProcessor.validateRequest(rawRequest);

      expect(result).toEqual({
        prompt: 'Test prompt',
        model: 'gpt-5-nano',
        verbosity: 'medium',
        reasoning_effort: 'standard',
      });
    });

    it('should validate a complex request correctly', () => {
      const rawRequest = {
        prompt: 'Test prompt',
        context: 'Test context',
        model: 'gpt-5',
        verbosity: 'high',
        reasoning_effort: 'extended',
        max_tokens: 1000,
        temperature: 0.7,
      };

      const result = messageProcessor.validateRequest(rawRequest);

      expect(result).toEqual({
        prompt: 'Test prompt',
        context: 'Test context',
        model: 'gpt-5',
        verbosity: 'high',
        reasoning_effort: 'extended',
        max_tokens: 1000,
        temperature: 0.7,
      });
    });

    it('should throw error for invalid request', () => {
      const rawRequest = null;

      expect(() => messageProcessor.validateRequest(rawRequest)).toThrow(
        'Invalid request: must be an object'
      );
    });

    it('should throw error for missing prompt', () => {
      const rawRequest = {
        model: 'gpt-5',
      };

      expect(() => messageProcessor.validateRequest(rawRequest)).toThrow(
        'Invalid request: prompt is required and must be a string'
      );
    });

    it('should sanitize text input', () => {
      const rawRequest = {
        prompt: '   Test prompt with null bytes\\x00 and control chars\\x01   ',
      };

      const result = messageProcessor.validateRequest(rawRequest);

      expect(result.prompt).toBe('Test prompt with null bytes and control chars');
    });

    it('should limit token counts correctly', () => {
      const rawRequest = {
        prompt: 'Test prompt',
        max_tokens: 200000, // Too high
        temperature: 3.0, // Too high
      };

      const result = messageProcessor.validateRequest(rawRequest);

      expect(result.max_tokens).toBe(128000); // Clamped to max
      expect(result.temperature).toBe(2); // Clamped to max
    });
  });

  describe('formatResponse', () => {
    it('should format OpenAI response correctly', () => {
      const openaiResponse: OpenAIResponse = {
        output_text: 'This is a test response from GPT-5.',
        usage: {
          prompt_tokens: 10,
          completion_tokens: 20,
          total_tokens: 30,
        },
        model_fingerprint: 'test-fingerprint',
        created: 1234567890,
      };

      const originalRequest: GPT5QueryRequest = {
        prompt: 'Test prompt',
        model: 'gpt-5',
        verbosity: 'medium',
        reasoning_effort: 'standard',
      };

      const processingTime = 1500;

      const result = messageProcessor.formatResponse(
        openaiResponse,
        originalRequest,
        processingTime
      );

      expect(result.content).toContain('🤖 **GPT-5 Response**');
      expect(result.content).toContain('This is a test response from GPT-5.');
      expect(result.metadata.model).toBe('gpt-5');
      expect(result.metadata.tokens_used).toBe(30);
      expect(result.metadata.reasoning_time).toBe(1500);
      expect(result.metadata.model_fingerprint).toBe('test-fingerprint');
    });

    it('should handle empty response', () => {
      const openaiResponse: OpenAIResponse = {
        output_text: '',
        usage: {
          prompt_tokens: 10,
          completion_tokens: 0,
          total_tokens: 10,
        },
        model_fingerprint: 'test-fingerprint',
        created: 1234567890,
      };

      const originalRequest: GPT5QueryRequest = {
        prompt: 'Test prompt',
        model: 'gpt-5',
        verbosity: 'medium',
        reasoning_effort: 'standard',
      };

      const result = messageProcessor.formatResponse(openaiResponse, originalRequest, 100);

      expect(result.content).toContain('No response generated.');
    });

    it('should format code blocks correctly', () => {
      const openaiResponse: OpenAIResponse = {
        output_text: 'Here is some code:\\n```\\nfunction test() {\\n  return true;\\n}',
        usage: {
          prompt_tokens: 10,
          completion_tokens: 20,
          total_tokens: 30,
        },
        model_fingerprint: 'test-fingerprint',
        created: 1234567890,
      };

      const originalRequest: GPT5QueryRequest = {
        prompt: 'Show me code',
        model: 'gpt-5',
        verbosity: 'medium',
        reasoning_effort: 'standard',
      };

      const result = messageProcessor.formatResponse(openaiResponse, originalRequest, 100);

      expect(result.content).toContain('```text');
    });
  });

  describe('createErrorResponse', () => {
    it('should create error response correctly', () => {
      const error = new Error('Test error message');
      const originalRequest = {
        prompt: 'Test prompt',
        model: 'gpt-5' as const,
      };

      const result = messageProcessor.createErrorResponse(error, originalRequest);

      expect(result.content).toContain('❌ **Error**: Test error message');
      expect(result.metadata.model).toBe('gpt-5');
      expect(result.metadata.tokens_used).toBe(0);
      expect(result.metadata.model_fingerprint).toBe('error');
    });
  });

  describe('estimateTokens', () => {
    it('should estimate tokens correctly', () => {
      const text = 'This is a test string with about twenty characters';
      const estimated = messageProcessor.estimateTokens(text);

      // Rough estimation: ~4 characters per token
      expect(estimated).toBeGreaterThan(10);
      expect(estimated).toBeLessThan(20);
    });
  });

  describe('truncateIfNeeded', () => {
    it('should not truncate short requests', () => {
      const request: GPT5QueryRequest = {
        prompt: 'Short prompt',
        model: 'gpt-5',
        verbosity: 'medium',
        reasoning_effort: 'standard',
      };

      const result = messageProcessor.truncateIfNeeded(request);

      expect(result.prompt).toBe('Short prompt');
    });

    it('should truncate very long requests', () => {
      const longPrompt = 'A'.repeat(2000000); // Very long prompt
      const request: GPT5QueryRequest = {
        prompt: longPrompt,
        model: 'gpt-5',
        verbosity: 'medium',
        reasoning_effort: 'standard',
      };

      const result = messageProcessor.truncateIfNeeded(request);

      expect(result.prompt.length).toBeLessThan(longPrompt.length);
      expect(result.prompt).toContain('...[truncated]');
    });

    it('should truncate context before prompt', () => {
      const longContext = 'B'.repeat(2000000);
      const request: GPT5QueryRequest = {
        prompt: 'Important prompt',
        context: longContext,
        model: 'gpt-5',
        verbosity: 'medium',
        reasoning_effort: 'standard',
      };

      const result = messageProcessor.truncateIfNeeded(request);

      expect(result.prompt).toBe('Important prompt'); // Prompt preserved
      expect(result.context!.length).toBeLessThan(longContext.length);
      expect(result.context).toContain('...[truncated]');
    });
  });
});