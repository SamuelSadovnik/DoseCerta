import { SetMetadata } from "@nestjs/common";

export type HateoasLink = {
  href: string;
  method: string;
};

export type HateoasItemOptions<T extends Record<string, unknown>> = {
  itemLinks: (item: T) => Record<string, HateoasLink>;
};

export const HATEOAS_ITEM_KEY = "hateoas:item";

export const HateoasItem = <T extends Record<string, unknown>>(
  options: HateoasItemOptions<T>,
) => SetMetadata(HATEOAS_ITEM_KEY, options);
