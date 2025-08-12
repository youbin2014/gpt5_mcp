import OpenAI from 'openai';
import {
  GPT5QueryRequest,
  OpenAIRequest,
  OpenAIResponse,
  GPT5ClientError,
  ServerConfig
} from './types.js';

export class GPT5Client {
  private openai: OpenAI;
  private config: ServerConfig;

  constructor(config: ServerConfig) {
    this.config = config;
    
    if (!config.openai.apiKey) {
      throw new GPT5ClientError('OpenAI API key is required');
    }

    this.openai = new OpenAI({
      apiKey: config.openai.apiKey,
      baseURL: config.openai.baseURL,
      timeout: config.openai.timeout,
    });
  }

  /**
   * Query GPT-5 with the provided request
   */
  async query(request: GPT5QueryRequest): Promise<OpenAIResponse> {
    try {
      const openaiRequest = this.formatRequest(request);
      
      if (this.config.logging.logRequests) {
        console.log('🚀 GPT-5 Request:', JSON.stringify(openaiRequest, null, 2));
      }

      const startTime = Date.now();
      
      // Use the Chat Completions API (compatible with GPT-5)
      const response = await this.openai.chat.completions.create({
        model: openaiRequest.model,
        messages: openaiRequest.input,
        max_tokens: openaiRequest.max_output_tokens,
        temperature: openaiRequest.temperature,
      } as any);
      
      const endTime = Date.now();
      const responseTime = endTime - startTime;

      const formattedResponse: OpenAIResponse = {
        output_text: response.choices?.[0]?.message?.content || '',
        usage: {
          prompt_tokens: response.usage?.prompt_tokens || 0,
          completion_tokens: response.usage?.completion_tokens || 0,
          total_tokens: response.usage?.total_tokens || 0,
        },
        model_fingerprint: (response as any).system_fingerprint || '',
        created: response.created || Math.floor(startTime / 1000),
      };

      if (this.config.logging.logResponses) {
        console.log(`✅ GPT-5 Response (${responseTime}ms):`, {
          content: formattedResponse.output_text.substring(0, 200) + '...',
          tokens: formattedResponse.usage.total_tokens
        });
      }

      return formattedResponse;

    } catch (error) {
      console.error('❌ GPT-5 Client Error:', error);
      
      if (error instanceof OpenAI.APIError) {
        throw new GPT5ClientError(
          `OpenAI API Error: ${error.message}`,
          error.status,
          error
        );
      }
      
      throw new GPT5ClientError(
        `Unexpected error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        undefined,
        error instanceof Error ? error : undefined
      );
    }
  }

  /**
   * Format MCP request to OpenAI API format
   */
  private formatRequest(request: GPT5QueryRequest): OpenAIRequest {
    const messages: OpenAIRequest['input'] = [
      {
        role: 'user',
        content: request.context 
          ? `Context: ${request.context}\n\nRequest: ${request.prompt}`
          : request.prompt
      }
    ];

    const openaiRequest: OpenAIRequest = {
      model: request.model,
      input: messages,
      verbosity: request.verbosity,
      reasoning_effort: request.reasoning_effort,
    };

    if (request.max_tokens) {
      openaiRequest.max_output_tokens = request.max_tokens;
    }

    if (request.temperature !== undefined) {
      openaiRequest.temperature = request.temperature;
    }

    return openaiRequest;
  }

  /**
   * Test connection to OpenAI API
   */
  async testConnection(): Promise<boolean> {
    try {
      const testRequest: GPT5QueryRequest = {
        prompt: 'Hello, this is a connection test.',
        model: 'gpt-5-nano', // Use smallest model for testing
        verbosity: 'low',
        reasoning_effort: 'minimal',
        max_tokens: 10
      };
      
      await this.query(testRequest);
      return true;
    } catch (error) {
      console.error('Connection test failed:', error);
      return false;
    }
  }

  /**
   * Get available models (for validation)
   */
  getAvailableModels(): string[] {
    return ['gpt-5', 'gpt-5-mini', 'gpt-5-nano'];
  }
}