# 📖 Usage Guide

Detailed usage examples and best practices for the GPT-5 Claude MCP Server.

## 🎯 Basic Usage Patterns

### Simple Text Queries

```javascript
// Ask GPT-5 a straightforward question
gpt5_query({
  "prompt": "What are the benefits of using TypeScript over JavaScript?"
})
```

### Code-Related Queries

```javascript
// Code review and suggestions
gpt5_query({
  "prompt": "Review this React component for performance issues",
  "context": "const MyComponent = () => { const [data, setData] = useState([]); useEffect(() => { fetch('/api/data').then(r => r.json()).then(setData); }, []); return <div>{data.map(item => <div key={item.id}>{item.name}</div>)}</div>; };"
})
```

### Technical Explanations

```javascript
// Get detailed technical explanations
gpt5_query({
  "prompt": "Explain how async/await works in JavaScript",
  "verbosity": "high",
  "reasoning_effort": "extended"
})
```

## 🔧 Advanced Usage

### Model Selection Strategy

Choose the right GPT-5 variant for your use case:

#### GPT-5 (Full Model)
- **Best for**: Complex analysis, detailed explanations, creative tasks
- **Use cases**: Architecture reviews, detailed documentation, complex problem-solving

```javascript
gpt5_query({
  "prompt": "Design a scalable microservices architecture for an e-commerce platform",
  "model": "gpt-5",
  "verbosity": "high",
  "reasoning_effort": "extended"
})
```

#### GPT-5 Mini
- **Best for**: Quick questions, code snippets, brief explanations
- **Use cases**: Quick debugging, simple explanations, code formatting

```javascript
gpt5_query({
  "prompt": "Fix this SQL query syntax error",
  "context": "SELECT * FROM users WHERE id = ?",
  "model": "gpt-5-mini",
  "verbosity": "low"
})
```

#### GPT-5 Nano
- **Best for**: Very quick responses, simple tasks, high-frequency queries
- **Use cases**: Code completion, simple calculations, brief answers

```javascript
gpt5_query({
  "prompt": "Convert this to arrow function: function add(a, b) { return a + b; }",
  "model": "gpt-5-nano",
  "verbosity": "low",
  "reasoning_effort": "minimal"
})
```

### Parameter Optimization

#### Verbosity Control

```javascript
// Low verbosity - concise answers
gpt5_query({
  "prompt": "What is React?",
  "verbosity": "low"
})

// Medium verbosity - balanced detail
gpt5_query({
  "prompt": "What is React?",
  "verbosity": "medium"
})

// High verbosity - comprehensive explanations
gpt5_query({
  "prompt": "What is React?",
  "verbosity": "high"
})
```

#### Reasoning Effort

```javascript
// Minimal reasoning - quick responses
gpt5_query({
  "prompt": "Is this code correct?",
  "context": "const x = 5; console.log(x);",
  "reasoning_effort": "minimal"
})

// Standard reasoning - balanced analysis
gpt5_query({
  "prompt": "How can I optimize this algorithm?",
  "context": "nested loop code...",
  "reasoning_effort": "standard"
})

// Extended reasoning - deep analysis
gpt5_query({
  "prompt": "Analyze potential security vulnerabilities in this system",
  "context": "complex system architecture...",
  "reasoning_effort": "extended"
})
```

#### Temperature Control

```javascript
// Low temperature - more deterministic, factual
gpt5_query({
  "prompt": "Explain the steps to deploy a Node.js app",
  "temperature": 0.1
})

// Medium temperature - balanced creativity
gpt5_query({
  "prompt": "Suggest creative solutions for this UX problem",
  "temperature": 0.7
})

// High temperature - more creative, varied
gpt5_query({
  "prompt": "Generate creative variable names for a game project",
  "temperature": 1.2
})
```

## 🎨 Use Case Examples

### Code Review

```javascript
gpt5_query({
  "prompt": "Review this code for best practices, performance, and security",
  "context": `
function processUserData(userData) {
  const users = [];
  for (let i = 0; i < userData.length; i++) {
    const user = userData[i];
    if (user.age > 18) {
      users.push({
        name: user.name,
        email: user.email,
        isAdult: true
      });
    }
  }
  return users;
}
  `,
  "model": "gpt-5",
  "verbosity": "high",
  "reasoning_effort": "extended"
})
```

### API Design

```javascript
gpt5_query({
  "prompt": "Design a RESTful API for a task management system",
  "context": "Features needed: user management, projects, tasks, assignments, due dates, priority levels",
  "model": "gpt-5",
  "verbosity": "high",
  "max_tokens": 4000
})
```

### Debugging Help

```javascript
gpt5_query({
  "prompt": "Help me debug this error",
  "context": `
Error: Cannot read property 'map' of undefined
Stack trace:
  at TodoList.render (TodoList.jsx:15)
  at React component render

Code:
const TodoList = ({ todos }) => {
  return (
    <ul>
      {todos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
};
  `,
  "model": "gpt-5-mini",
  "verbosity": "medium"
})
```

### Documentation Generation

```javascript
gpt5_query({
  "prompt": "Generate comprehensive JSDoc documentation for this function",
  "context": `
function calculateTotalPrice(items, discountCode, taxRate) {
  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const discount = discountCode ? applyDiscount(subtotal, discountCode) : 0;
  const discountedTotal = subtotal - discount;
  const tax = discountedTotal * taxRate;
  return discountedTotal + tax;
}
  `,
  "model": "gpt-5",
  "verbosity": "high"
})
```

### Performance Optimization

```javascript
gpt5_query({
  "prompt": "Optimize this React component for better performance",
  "context": `
const UserList = ({ users, onUserClick }) => {
  return (
    <div>
      {users.map(user => (
        <div key={user.id} onClick={() => onUserClick(user)}>
          <img src={user.avatar} alt={user.name} />
          <h3>{user.name}</h3>
          <p>{user.email}</p>
          <p>{user.role}</p>
        </div>
      ))}
    </div>
  );
};
  `,
  "model": "gpt-5",
  "verbosity": "high",
  "reasoning_effort": "extended"
})
```

## 🔄 Workflow Integration

### Code Development Workflow

1. **Initial Development**: Use GPT-5 for generating boilerplate code
2. **Code Review**: Get detailed analysis and suggestions
3. **Debugging**: Quickly identify and fix issues
4. **Documentation**: Generate comprehensive documentation
5. **Optimization**: Improve performance and maintainability

### Team Collaboration

```javascript
// Code review for pull requests
gpt5_query({
  "prompt": "Review this pull request for team standards compliance",
  "context": "PR description and code diff...",
  "model": "gpt-5",
  "verbosity": "high"
})

// Architecture discussions
gpt5_query({
  "prompt": "Evaluate pros and cons of this architectural decision",
  "context": "Technical specification...",
  "model": "gpt-5",
  "reasoning_effort": "extended"
})
```

## 📊 Best Practices

### Token Management

1. **Use Context Wisely**: Only include relevant context to save tokens
2. **Choose Right Model**: Use nano for simple tasks, full GPT-5 for complex ones
3. **Optimize Verbosity**: Match verbosity to your needs
4. **Monitor Usage**: Track token consumption for cost optimization

### Quality Optimization

1. **Be Specific**: Provide clear, specific prompts
2. **Include Context**: Add relevant background information
3. **Set Parameters**: Use appropriate verbosity and reasoning effort
4. **Iterate**: Refine prompts based on results

### Error Handling

1. **Test Connection**: Use `gpt5_test_connection` to verify setup
2. **Handle Failures**: Have fallback strategies for API failures
3. **Monitor Logs**: Check console output for debugging information
4. **Rate Limiting**: Be mindful of API rate limits

## 🚀 Pro Tips

### Effective Prompting

```javascript
// ❌ Vague prompt
gpt5_query({
  "prompt": "Make this better"
})

// ✅ Specific prompt
gpt5_query({
  "prompt": "Improve this function's performance and readability while maintaining the same functionality",
  "context": "specific code here..."
})
```

### Context Management

```javascript
// ✅ Structured context
gpt5_query({
  "prompt": "Review this component for accessibility issues",
  "context": `
Component: UserProfile
Purpose: Display user information with editing capabilities
Current issues: Screen reader compatibility
Code: [component code here]
Requirements: WCAG 2.1 AA compliance
  `
})
```

### Batch Processing

For multiple related queries, structure them efficiently:

```javascript
// Process related queries in sequence
const codeReviewResults = await gpt5_query({
  "prompt": "Comprehensive code review including: 1) Security vulnerabilities 2) Performance issues 3) Best practices violations 4) Maintainability concerns",
  "context": "large codebase context...",
  "model": "gpt-5",
  "verbosity": "high",
  "max_tokens": 8000
})
```

This approach is more efficient than multiple separate queries for related concerns.