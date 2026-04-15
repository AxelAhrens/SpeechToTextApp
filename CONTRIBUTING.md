# Contributing to SpeechToTextApp

Contributions are welcome! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

## Getting Started

1. **Fork the repository**
   ```bash
   gh repo fork AxelAhrens/SpeechToTextApp --clone
   cd SpeechToTextApp
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set up development environment**
   ```bash
   # Install Swift (macOS comes with Swift)
   swift --version
   
   # Open in Xcode
   open Package.swift
   ```

4. **Make your changes**
   - Follow the existing code style
   - Add tests for new features
   - Update documentation as needed

5. **Test your changes**
   ```bash
   swift build
   swift test
   ```

6. **Commit and push**
   ```bash
   git commit -m "feat: Add your feature description"
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Describe your changes clearly
   - Reference any related issues
   - Ensure all tests pass

## Code Style Guidelines

### Swift
- Follow [Google's Swift Style Guide](https://google.github.io/swift/)
- Use meaningful variable names
- Keep functions small and focused
- Add comments for complex logic
- Use `// MARK:` for section organization

### Project Structure
- Keep related code in the same directory
- Keep Views, Models, and Services separate
- Use clear, consistent naming conventions

### Naming Conventions
- Classes: PascalCase (e.g., `AudioRecorder`)
- Functions/Variables: camelCase (e.g., `recordingDuration`)
- Constants: UPPER_CASE (e.g., `API_TIMEOUT`)
- Enums: PascalCase (e.g., `TranscriptionMode`)

## Reporting Issues

If you find a bug or have a feature request:

1. **Check existing issues** to avoid duplicates
2. **Create a new issue** with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - macOS version and system info
   - Screenshots if applicable

## Testing

### Writing Tests
- Add tests to `Sources/Tests/`
- Use XCTest framework
- Test critical functionality
- Keep tests focused and isolated

### Running Tests
```bash
swift test
```

## Documentation

### Code Documentation
- Add comments to complex functions
- Use doc comments (///) for public APIs
- Keep README updated

### Files to Update
- `README.md` - User-facing documentation
- `CHANGELOG.md` - Changes for this version
- Code comments - Implementation details

## Git Workflow

### Commit Messages
```
type(scope): short description

Longer description explaining the changes and why.

- Bullet points for multiple changes
- Reference issues with #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `test`: Tests
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `chore`: Build, dependencies, etc.

## Review Process

1. **Automated checks** must pass
2. **Code review** by maintainers
3. **Approval** before merging
4. **Squash and merge** to main branch

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

- Open a GitHub Discussion
- Check existing issues
- Review the README and documentation

Thank you for contributing! 🙏
