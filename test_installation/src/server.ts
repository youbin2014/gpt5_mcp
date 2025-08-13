#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { GPT5Client } from './gpt5-client.js';
import { MessageProcessor } from './message-processor.js';
import { loadConfiguration } from './config.js';
import {
  GPT5QueryRequestSchema,
  GPT5ClientError,
  ConfigurationError,
  VERBOSITY_LEVELS,
  REASONING_EFFORT_LEVELS,
  GPT5_MODELS
} from './types.js';

class GPT5MCPServer {
  private server: Server;
  private gpt5Client: GPT5Client;
  private messageProcessor: MessageProcessor;

  constructor() {
    // Load configuration
    const config = loadConfiguration();
    
    // Initialize components
    this.gpt5Client = new GPT5Client(config);
    this.messageProcessor = new MessageProcessor(config);
    
    // Initialize MCP server
    this.server = new Server(
      {
        name: config.server.name,
        version: config.server.version,
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  private setupHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'gpt5_query',
            description: 'Query GPT-5 model with Claude\'s original prompt and context. Supports all GPT-5 variants with advanced parameters.',
            inputSchema: {
              type: 'object',
              properties: {
                prompt: {
                  type: 'string',
                  description: 'The main prompt/question to send to GPT-5',
                },
                context: {
                  type: 'string',
                  description: 'Additional context or conversation history (optional)',
                },
                model: {
                  type: 'string',
                  enum: GPT5_MODELS,
                  default: 'gpt-5',
                  description: 'GPT-5 model variant to use',
                },
                verbosity: {
                  type: 'string',
                  enum: VERBOSITY_LEVELS,
                  default: 'medium',
                  description: 'Response verbosity level',
                },
                reasoning_effort: {
                  type: 'string',
                  enum: REASONING_EFFORT_LEVELS,
                  default: 'standard',
                  description: 'Amount of reasoning effort to apply',
                },
                max_tokens: {
                  type: 'number',
                  minimum: 1,
                  maximum: 128000,
                  description: 'Maximum tokens in response (optional)',
                },
                temperature: {
                  type: 'number',
                  minimum: 0,
                  maximum: 2,
                  description: 'Randomness in response (0-2, optional)',
                },
              },
              required: ['prompt'],
            },
          },
          {
            name: 'gpt5_test_connection',
            description: 'Test connection to OpenAI GPT-5 API',
            inputSchema: {
              type: 'object',
              properties: {},
            },
          },
        ],
      };
    });

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'gpt5_query':
            return await this.handleGPT5Query(args);
          
          case 'gpt5_test_connection':
            return await this.handleTestConnection();
          
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        console.error(`❌ Tool execution error for ${name}:`, error);
        
        const errorResponse = this.messageProcessor.createErrorResponse(
          error instanceof Error ? error : new Error('Unknown error'),
          name === 'gpt5_query' ? args : undefined
        );

        return {
          content: [
            {
              type: 'text',
              text: errorResponse.content,
            },
          ],
        };
      }
    });
  }

  private async handleGPT5Query(args: any) {
    const startTime = Date.now();
    
    try {
      // Validate and sanitize request
      const validatedRequest = this.messageProcessor.validateRequest(args);
      
      // Additional validation using Zod schema
      const parsedRequest = GPT5QueryRequestSchema.parse(validatedRequest);
      
      // Truncate if needed to prevent token limit issues
      const finalRequest = this.messageProcessor.truncateIfNeeded(parsedRequest);
      
      console.log(`🚀 Processing GPT-5 query: ${finalRequest.prompt.substring(0, 100)}...`);
      
      // Query GPT-5
      const openaiResponse = await this.gpt5Client.query(finalRequest);
      
      // Format response for Claude Code
      const processingTime = Date.now() - startTime;
      const response = this.messageProcessor.formatResponse(
        openaiResponse,
        finalRequest,
        processingTime
      );
      
      console.log(`✅ GPT-5 query completed in ${processingTime}ms`);
      
      return {
        content: [
          {
            type: 'text',
            text: response.content,
          },
        ],
        isError: false,
      };
      
    } catch (error) {
      console.error('❌ GPT-5 query failed:', error);
      
      const errorResponse = this.messageProcessor.createErrorResponse(
        error instanceof Error ? error : new Error('Unknown error'),
        args
      );
      
      return {
        content: [
          {
            type: 'text',
            text: errorResponse.content,
          },
        ],
        isError: true,
      };
    }
  }

  private async handleTestConnection() {
    try {
      console.log('🔍 Testing GPT-5 connection...');
      
      const isConnected = await this.gpt5Client.testConnection();
      
      if (isConnected) {
        const successMessage = `✅ **GPT-5 Connection Successful**

Connected to OpenAI GPT-5 API successfully!

**Available Models**: ${this.gpt5Client.getAvailableModels().join(', ')}
**Status**: Ready to process queries
**Timestamp**: ${new Date().toISOString()}`;

        console.log('✅ GPT-5 connection test passed');
        
        return {
          content: [
            {
              type: 'text',
              text: successMessage,
            },
          ],
          isError: false,
        };
      } else {
        throw new Error('Connection test failed');
      }
      
    } catch (error) {
      console.error('❌ GPT-5 connection test failed:', error);
      
      const errorMessage = `❌ **GPT-5 Connection Failed**

Could not connect to OpenAI GPT-5 API.

**Error**: ${error instanceof Error ? error.message : 'Unknown error'}
**Possible causes**:
- Invalid OpenAI API key
- Network connectivity issues
- OpenAI service outage

Please check your API key configuration and try again.`;
      
      return {
        content: [
          {
            type: 'text',
            text: errorMessage,
          },
        ],
        isError: true,
      };
    }
  }

  async start() {
    try {
      console.log('🚀 Starting GPT-5 MCP Server...');
      
      // Test connection on startup
      const isConnected = await this.gpt5Client.testConnection();
      if (!isConnected) {
        console.warn('⚠️ Warning: Could not connect to GPT-5 API on startup');
      } else {
        console.log('✅ GPT-5 API connection verified');
      }
      
      const transport = new StdioServerTransport();
      await this.server.connect(transport);
      
      console.log('✅ GPT-5 MCP Server started successfully');
      console.log('📡 Ready to receive Claude Code requests...');
      
    } catch (error) {
      console.error('❌ Failed to start GPT-5 MCP Server:', error);
      
      if (error instanceof ConfigurationError) {
        console.error('🔧 Configuration Error:', error.message);
        console.error('Please check your environment variables and configuration files.');
      } else if (error instanceof GPT5ClientError) {
        console.error('🤖 GPT-5 Client Error:', error.message);
        console.error('Please check your OpenAI API key and network connectivity.');
      }
      
      process.exit(1);
    }
  }
}

// Start the server if this file is run directly
if (import.meta.url === `file://${process.argv[1]}`) {
  const server = new GPT5MCPServer();
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down GPT-5 MCP Server...');
    process.exit(0);
  });
  
  process.on('SIGTERM', () => {
    console.log('\n🛑 Shutting down GPT-5 MCP Server...');
    process.exit(0);
  });
  
  server.start().catch((error) => {
    console.error('💥 Fatal error:', error);
    process.exit(1);
  });
}

export { GPT5MCPServer };