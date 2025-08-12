import { z } from 'zod';

// GPT-5 Model variants
export const GPT5_MODELS = ['gpt-5', 'gpt-5-mini', 'gpt-5-nano'] as const;
export type GPT5Model = typeof GPT5_MODELS[number];

// Verbosity levels for GPT-5
export const VERBOSITY_LEVELS = ['low', 'medium', 'high'] as const;
export type VerbosityLevel = typeof VERBOSITY_LEVELS[number];

// Reasoning effort levels
export const REASONING_EFFORT_LEVELS = ['minimal', 'standard', 'extended'] as const;
export type ReasoningEffortLevel = typeof REASONING_EFFORT_LEVELS[number];

// MCP Tool Request Schema
export const GPT5QueryRequestSchema = z.object({
  prompt: z.string().min(1, 'Prompt cannot be empty'),
  context: z.string().optional(),
  model: z.enum(GPT5_MODELS).default('gpt-5'),
  verbosity: z.enum(VERBOSITY_LEVELS).default('medium'),
  reasoning_effort: z.enum(REASONING_EFFORT_LEVELS).default('standard'),
  max_tokens: z.number().min(1).max(128000).optional(),
  temperature: z.number().min(0).max(2).optional()
});

export type GPT5QueryRequest = z.infer<typeof GPT5QueryRequestSchema>;

// OpenAI API Request format
export interface OpenAIRequest {
  model: string;
  input: Array<{
    role: 'user' | 'assistant' | 'system';
    content: string;
  }>;
  max_output_tokens?: number;
  verbosity?: VerbosityLevel;
  reasoning_effort?: ReasoningEffortLevel;
  temperature?: number;
}

// OpenAI API Response format
export interface OpenAIResponse {
  output_text: string;
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
  model_fingerprint: string;
  created: number;
}

// MCP Tool Response format
export interface GPT5QueryResponse {
  content: string;
  metadata: {
    model: string;
    tokens_used: number;
    reasoning_time?: number;
    model_fingerprint: string;
    timestamp: number;
  };
}

// Configuration interface
export interface ServerConfig {
  openai: {
    apiKey: string;
    baseURL?: string;
    defaultModel: GPT5Model;
    timeout: number;
  };
  server: {
    name: string;
    version: string;
    maxRetries: number;
    retryDelay: number;
  };
  logging: {
    level: 'debug' | 'info' | 'warn' | 'error';
    logRequests: boolean;
    logResponses: boolean;
  };
}

// Error types
export class GPT5ClientError extends Error {
  constructor(
    message: string,
    public statusCode?: number,
    public originalError?: Error
  ) {
    super(message);
    this.name = 'GPT5ClientError';
  }
}

export class ConfigurationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ConfigurationError';
  }
}