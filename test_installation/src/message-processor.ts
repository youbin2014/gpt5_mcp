import {
  GPT5QueryRequest,
  GPT5QueryResponse,
  OpenAIResponse,
  ServerConfig
} from './types.js';

export class MessageProcessor {
  private config: ServerConfig;

  constructor(config: ServerConfig) {
    this.config = config;
  }

  /**
   * Validate and sanitize incoming request
   */
  validateRequest(rawRequest: any): GPT5QueryRequest {
    // Basic validation
    if (!rawRequest || typeof rawRequest !== 'object') {
      throw new Error('Invalid request: must be an object');
    }

    if (!rawRequest.prompt || typeof rawRequest.prompt !== 'string') {
      throw new Error('Invalid request: prompt is required and must be a string');
    }

    // Sanitize and set defaults
    const request: GPT5QueryRequest = {
      prompt: this.sanitizeText(rawRequest.prompt),
      model: rawRequest.model || this.config.openai.defaultModel,
      verbosity: rawRequest.verbosity || 'medium',
      reasoning_effort: rawRequest.reasoning_effort || 'standard'
    };

    // Optional fields
    if (rawRequest.context && typeof rawRequest.context === 'string') {
      request.context = this.sanitizeText(rawRequest.context);
    }

    if (rawRequest.max_tokens && typeof rawRequest.max_tokens === 'number') {
      request.max_tokens = Math.min(Math.max(rawRequest.max_tokens, 1), 128000);
    }

    if (rawRequest.temperature !== undefined && typeof rawRequest.temperature === 'number') {
      request.temperature = Math.min(Math.max(rawRequest.temperature, 0), 2);
    }

    return request;
  }

  /**
   * Format OpenAI response for Claude Code consumption
   */
  formatResponse(
    openaiResponse: OpenAIResponse,
    originalRequest: GPT5QueryRequest,
    processingTimeMs: number
  ): GPT5QueryResponse {
    // Clean and format the response content
    const content = this.formatResponseContent(openaiResponse.output_text);

    const response: GPT5QueryResponse = {
      content,
      metadata: {
        model: originalRequest.model,
        tokens_used: openaiResponse.usage.total_tokens,
        model_fingerprint: openaiResponse.model_fingerprint,
        timestamp: Date.now(),
        reasoning_time: processingTimeMs
      }
    };

    return response;
  }

  /**
   * Sanitize text input to prevent issues
   */
  private sanitizeText(text: string): string {
    return text
      .trim()
      .replace(/\x00/g, '') // Remove null bytes
      .replace(/[\x01-\x1F\x7F]/g, '') // Remove control characters except newlines/tabs
      .substring(0, 100000); // Limit length to prevent abuse
  }

  /**
   * Format response content for optimal Claude Code display
   */
  private formatResponseContent(content: string): string {
    if (!content) {
      return 'No response generated.';
    }

    // Clean up the content
    let formatted = content.trim();

    // Add metadata header for clarity
    const header = '🤖 **GPT-5 Response**\n\n';
    
    // Ensure proper markdown formatting if the response contains code
    if (this.containsCode(formatted)) {
      formatted = this.formatCodeBlocks(formatted);
    }

    // Add line breaks for better readability
    formatted = formatted.replace(/\n\n\n+/g, '\n\n');

    return header + formatted;
  }

  /**
   * Check if content contains code
   */
  private containsCode(content: string): boolean {
    const codeIndicators = [
      '```',
      'function ',
      'class ',
      'import ',
      'const ',
      'let ',
      'var ',
      'def ',
      'public ',
      'private ',
      '#include',
      'SELECT ',
      'FROM '
    ];

    return codeIndicators.some(indicator => 
      content.toLowerCase().includes(indicator.toLowerCase())
    );
  }

  /**
   * Improve code block formatting
   */
  private formatCodeBlocks(content: string): string {
    // Ensure code blocks are properly formatted
    let formatted = content;

    // Fix incomplete code blocks
    const codeBlockCount = (formatted.match(/```/g) || []).length;
    if (codeBlockCount % 2 !== 0) {
      formatted += '\n```';
    }

    // Add language hints to unmarked code blocks
    formatted = formatted.replace(
      /```\n(?![\w-]+\n)/g,
      '```text\n'
    );

    return formatted;
  }

  /**
   * Create error response for Claude Code
   */
  createErrorResponse(error: Error, originalRequest?: Partial<GPT5QueryRequest>): GPT5QueryResponse {
    const errorMessage = `❌ **Error**: ${error.message}\n\nPlease check your OpenAI API key and try again.`;
    
    return {
      content: errorMessage,
      metadata: {
        model: originalRequest?.model || 'gpt-5',
        tokens_used: 0,
        model_fingerprint: 'error',
        timestamp: Date.now(),
        reasoning_time: 0
      }
    };
  }

  /**
   * Estimate token count (rough approximation)
   */
  estimateTokens(text: string): number {
    // Rough estimation: ~4 characters per token for English text
    return Math.ceil(text.length / 4);
  }

  /**
   * Truncate request if it's too long
   */
  truncateIfNeeded(request: GPT5QueryRequest): GPT5QueryRequest {
    const maxPromptTokens = 380000; // Leave room for response
    const estimatedTokens = this.estimateTokens(request.prompt + (request.context || ''));

    if (estimatedTokens > maxPromptTokens) {
      console.warn(`⚠️ Request too long (${estimatedTokens} tokens), truncating...`);
      
      const maxChars = maxPromptTokens * 4;
      const totalLength = request.prompt.length + (request.context?.length || 0);
      
      if (request.context && totalLength > maxChars) {
        // Truncate context first
        const contextLimit = Math.max(0, maxChars - request.prompt.length);
        request.context = request.context.substring(0, contextLimit) + '...[truncated]';
      }
      
      if (request.prompt.length > maxChars) {
        // Truncate prompt if still too long
        request.prompt = request.prompt.substring(0, maxChars - 100) + '...[truncated]';
      }
    }

    return request;
  }
}