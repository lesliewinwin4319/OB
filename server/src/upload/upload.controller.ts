import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PresignUploadDto } from './dto/presign-upload.dto';
import { UploadService } from './upload.service';

@Controller('upload')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @Post('presign')
  @UseGuards(JwtAuthGuard)
  @HttpCode(201)
  async presign(@Body() dto: PresignUploadDto) {
    const result = await this.uploadService.generatePresignedUrl(dto);
    return { data: result };
  }
}
