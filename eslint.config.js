import js from '@eslint/js'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  {
    ignores: [
      'lib/**',
      'coverage/**',
      'node_modules/**',
      'docs/**',
      'tools/client-build.js',
      '**/*.cjs',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2024,
      sourceType: 'module',
      globals: {
        AbortController: 'readonly',
        console: 'readonly',
        document: 'readonly',
        navigator: 'readonly',
        process: 'readonly',
        structuredClone: 'readonly',
        URL: 'readonly',
      },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/ban-ts-comment': 'off',
      '@typescript-eslint/no-empty-object-type': 'off',
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
        },
      ],
      'no-unused-vars': 'off',
      'no-empty': ['error', { allowEmptyCatch: true }],
      // Ceiling is the current worst function. CI fails when a function gets harder to follow.
      complexity: ['error', 225],
      // Ceiling is just above Insights.tsx. CI fails when a file grows past that.
      'max-lines': ['error', { max: 2300, skipBlankLines: true, skipComments: true }],
    },
  },
)
