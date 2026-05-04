import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface RequestUser {
  id: string;
  email: string;
  accountType: string;
}

/**
 * Pulls the user injected by the upstream gateway via the
 * `x-user-*` headers (gateway already validated the JWT).
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): RequestUser => {
    const req = ctx.switchToHttp().getRequest();
    return {
      id: req.headers['x-user-id'] as string,
      email: req.headers['x-user-email'] as string,
      accountType: req.headers['x-user-account-type'] as string,
    };
  },
);
