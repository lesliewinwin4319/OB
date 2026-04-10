import { Controller, Get } from '@nestjs/common';
import { Public } from '../common/decorators/public.decorator';
import { SkipProfileCheck } from '../common/decorators/skip-profile-check.decorator';

@Controller('health')
export class HealthController {
  /**
   * GET /api/v1/health
   *
   * Railway / k8s 健康检查探针，无需鉴权。
   * Response 200: { status: 'ok', timestamp: string }
   */
  @Public()
  @SkipProfileCheck()
  @Get()
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };
  }
}
