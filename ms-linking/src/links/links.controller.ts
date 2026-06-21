import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from "@nestjs/common";
import {
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiSecurity,
  ApiTags,
} from "@nestjs/swagger";
import { HateoasItem } from "../common/decorators/hateoas-item.decorator";
import { HateoasList } from "../common/decorators/hateoas-list.decorator";
import { ApiKeyGuard } from "../common/guards/api-key.guard";
import { ActivateLinkDto } from "./dto/activate-link.dto";
import type { ActivationCodeResponseDto } from "./dto/activation-code-response.dto";
import { GenerateLinkCodeDto } from "./dto/generate-link-code.dto";
import { LinkQueryDto } from "./dto/link-query.dto";
import type { LinkResponseDto } from "./dto/link-response.dto";
import { LinksService } from "./links.service";

const linkItemLinks = (item: Record<string, unknown>) => ({
  self: { href: `/api/v1/links/${item.id}`, method: "GET" },
  all: { href: "/api/v1/links", method: "GET" },
  delete: { href: `/api/v1/links/${item.id}`, method: "DELETE" },
});

@ApiTags("links")
@ApiSecurity("api-key")
@UseGuards(ApiKeyGuard)
@Controller("links")
export class LinksController {
  constructor(private readonly linksService: LinksService) {}

  @Post("generate")
  @ApiOperation({ summary: "Generate an activation code for a dependent" })
  @ApiCreatedResponse({ description: "Activation code generated" })
  @ApiConflictResponse({ description: "Caregiver and dependent already linked" })
  @HateoasItem<ActivationCodeResponseDto>({
    itemLinks: (item) => ({
      self: { href: "/api/v1/links/generate", method: "POST" },
      activate: { href: "/api/v1/links/activate", method: "POST" },
    }),
  })
  async generate(
    @Body() body: GenerateLinkCodeDto,
  ): Promise<ActivationCodeResponseDto> {
    return this.linksService.generateCode(body);
  }

  @Post("activate")
  @ApiOperation({ summary: "Activate a caregiver/dependent link using a code" })
  @ApiCreatedResponse({ description: "Link established" })
  @ApiConflictResponse({ description: "Code used or link already exists" })
  @ApiNotFoundResponse({ description: "Activation code not found" })
  @HateoasItem<LinkResponseDto>({ itemLinks: linkItemLinks })
  async activate(@Body() body: ActivateLinkDto): Promise<LinkResponseDto> {
    return this.linksService.activate(body);
  }

  @Get()
  @ApiOperation({ summary: "List active links" })
  @HateoasList<LinkResponseDto>({
    basePath: "/api/v1/links",
    itemLinks: linkItemLinks,
  })
  async list(@Query() query: LinkQueryDto) {
    return this.linksService.list(query);
  }

  @Get(":id")
  @ApiOperation({ summary: "Get a link by ID" })
  @ApiNotFoundResponse({ description: "Link not found" })
  @HateoasItem<LinkResponseDto>({ itemLinks: linkItemLinks })
  async findById(
    @Param("id", ParseUUIDPipe) id: string,
  ): Promise<LinkResponseDto> {
    return this.linksService.findById(id);
  }

  @Delete(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: "Deactivate a caregiver/dependent link" })
  @ApiNoContentResponse({ description: "Link deactivated" })
  @ApiNotFoundResponse({ description: "Active link not found" })
  async remove(@Param("id", ParseUUIDPipe) id: string): Promise<void> {
    await this.linksService.remove(id);
  }
}
