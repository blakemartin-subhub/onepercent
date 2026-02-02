import { Request, Response, NextFunction } from 'express';

/**
 * Global error handler middleware
 */
export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  console.error('[Error]', err);

  // OpenAI specific errors
  if (err.message?.includes('OpenAI')) {
    res.status(502).json({
      error: 'AI service temporarily unavailable',
      code: 'OPENAI_ERROR',
    });
    return;
  }

  // Rate limiting errors
  if (err.message?.includes('rate limit')) {
    res.status(429).json({
      error: 'Too many requests. Please try again later.',
      code: 'RATE_LIMITED',
    });
    return;
  }

  // Validation errors
  if (err.name === 'ZodError') {
    res.status(400).json({
      error: 'Invalid request data',
      code: 'VALIDATION_ERROR',
      details: err,
    });
    return;
  }

  // Default error response
  res.status(500).json({
    error: 'An unexpected error occurred',
    code: 'INTERNAL_ERROR',
  });
}
