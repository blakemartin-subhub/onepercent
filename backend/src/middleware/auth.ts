import { Request, Response, NextFunction } from 'express';

/**
 * Simple device token authentication middleware
 * 
 * For MVP, we use anonymous device tokens.
 * In production, consider Sign in with Apple for better security.
 */
export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // For now, allow unauthenticated requests but log them
    console.warn('[Auth] Request without authorization header');
    next();
    return;
  }

  const token = authHeader.split(' ')[1];
  
  // Validate token format (UUID)
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(token)) {
    res.status(401).json({
      error: 'Invalid authorization token',
      code: 'INVALID_TOKEN',
    });
    return;
  }

  // Attach device ID to request for logging/rate limiting
  (req as any).deviceId = token;
  
  next();
}

/**
 * Validate Sign in with Apple token
 * 
 * This is a placeholder for production implementation.
 * See: https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api
 */
export async function validateAppleToken(identityToken: string): Promise<{
  valid: boolean;
  userId?: string;
  email?: string;
}> {
  // TODO: Implement Sign in with Apple token validation
  // 1. Decode the JWT
  // 2. Verify signature using Apple's public keys
  // 3. Check issuer, audience, expiration
  // 4. Extract user ID and email
  
  console.warn('[Auth] Sign in with Apple validation not implemented');
  
  return {
    valid: false,
  };
}
