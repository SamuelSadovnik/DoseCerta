import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { Observable } from "rxjs";
import { map } from "rxjs/operators";
import {
  HATEOAS_ITEM_KEY,
  type HateoasItemOptions,
} from "../decorators/hateoas-item.decorator";
import {
  HATEOAS_LIST_KEY,
  type HateoasListOptions,
} from "../decorators/hateoas-list.decorator";
import type { PaginatedResult } from "../types/paginated-result";

type Linkable = Record<string, unknown>;

@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const listOptions = this.reflector.get<HateoasListOptions<Linkable>>(
      HATEOAS_LIST_KEY,
      context.getHandler(),
    );
    const itemOptions = this.reflector.get<HateoasItemOptions<Linkable>>(
      HATEOAS_ITEM_KEY,
      context.getHandler(),
    );

    return next.handle().pipe(
      map((data: unknown) => {
        if (listOptions) {
          return this.toHateoasList(
            data as PaginatedResult<Linkable>,
            listOptions,
          );
        }

        if (itemOptions) {
          return this.toHateoasItem(data as Linkable | null, itemOptions);
        }

        return data;
      }),
    );
  }

  private toHateoasList(
    paginated: PaginatedResult<Linkable>,
    options: HateoasListOptions<Linkable>,
  ) {
    const totalPages = Math.max(1, Math.ceil(paginated.total / paginated.limit));

    return {
      data: paginated.data.map((item) => ({
        ...item,
        _links: options.itemLinks(item),
      })),
      meta: {
        totalItems: paginated.total,
        itemsPerPage: paginated.limit,
        currentPage: paginated.page,
        totalPages,
      },
      _links: {
        self: {
          href: `${options.basePath}?_page=${paginated.page}&_size=${paginated.limit}`,
          method: "GET",
        },
        next:
          paginated.page < totalPages
            ? {
                href: `${options.basePath}?_page=${paginated.page + 1}&_size=${paginated.limit}`,
                method: "GET",
              }
            : null,
        prev:
          paginated.page > 1
            ? {
                href: `${options.basePath}?_page=${paginated.page - 1}&_size=${paginated.limit}`,
                method: "GET",
              }
            : null,
      },
    };
  }

  private toHateoasItem(
    item: Linkable | null,
    options: HateoasItemOptions<Linkable>,
  ) {
    if (!item) return null;

    return {
      ...item,
      _links: options.itemLinks(item),
    };
  }
}
