# Code Review Guidelines

Example Code Review Guidelines: https://github.com/ping-rocks/eng-gemini-review/blob/main/examples/basic/CODE_REVIEW_GUIDE.md 

## Critical Requirements

### Security
- All user inputs must be validated
- No hardcoded secrets, credentials, or API keys
- All endpoints require authentication unless explicitly public

### Testing

### Exception Handling
- Use appropriate exception types
- Log exceptions with sufficient context
- Don't catch generic `Exception` unless necessary

## Important Standards

### Code Organization
- Follow Single Responsibility Principle
- Functions or Methods should not exceed 50 lines
- Classes should have clear, focused purposes
- Avoid deep nesting (maximum 5 levels)

### Naming Conventions
- Use descriptive names for variables and methods
- Boolean methods/variables should start with `is`, `has`, or `should`
- Constants in UPPER_SNAKE_CASE
- Class names in PascalCase, methods and functions use lowercase and underscores between words

### Documentation
- Complex business logic needs inline comments
- Document non-obvious design decisions

### Resource Management
- Avoid resource leaks in error paths

## Performance
- Use pagination for large result sets
- Cache frequently accessed data when appropriate