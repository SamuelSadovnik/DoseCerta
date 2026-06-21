import { SetMetadata } from "@nestjs/common";
import type { HateoasLink } from "./hateoas-item.decorator";

export type HateoasListOptions<T extends Record<string, unknown>> = {
  basePath: string;
  itemLinks: (item: T) => Record<string, HateoasLink>;
};

export const HATEOAS_LIST_KEY = "hateoas:list";

export const HateoasList = <T extends Record<string, unknown>>(
  options: HateoasListOptions<T>,
) => SetMetadata(HATEOAS_LIST_KEY, options);
