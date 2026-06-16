import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import type { Request, Response } from "express";

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const isHttpException = exception instanceof HttpException;
    const status = isHttpException
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;
    const exceptionResponse = isHttpException
      ? exception.getResponse()
      : "Internal server error";

    if (!isHttpException) {
      this.logger.error("Unhandled exception", exception);
    }

    response.status(status).json({
      statusCode: status,
      error:
        typeof exceptionResponse === "object" && exceptionResponse !== null
          ? exceptionResponse
          : { message: exceptionResponse },
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
